use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::Mutex,
    time::{Duration, Instant},
};

use axum::{
    extract::{ConnectInfo, Request, State},
    http::HeaderValue,
    middleware::Next,
    response::{IntoResponse, Response},
};

use crate::{auth::bearer_token, error::AppError, state::AppState};

/// Above this many entries the limiter first drops windows that already ended, so the map cannot grow without end.
const SWEEP_AT: usize = 10_000;

struct Window {
    started: Instant,
    used: u32,
}

pub struct Decision {
    pub allowed: bool,
    pub limit: u32,
    pub remaining: u32,
    pub reset_secs: u64,
}

/// A fixed-window counter per key, in memory. One instance per process: with several API replicas
/// every replica counts alone, so the real limit is `limit x replicas` (see the chapter for the alternatives).
pub struct RateLimiter {
    window: Duration,
    windows: Mutex<HashMap<String, Window>>,
}

impl RateLimiter {
    pub fn new(window: Duration) -> Self {
        Self { window, windows: Mutex::default() }
    }

    pub fn check(&self, key: &str, limit: u32) -> Decision {
        let now = Instant::now();
        let mut windows = self.windows.lock().expect("rate limiter lock");
        if windows.len() >= SWEEP_AT {
            windows.retain(|_, window| now.duration_since(window.started) < self.window);
        }
        let entry = windows.entry(key.to_owned()).or_insert(Window { started: now, used: 0 });
        if now.duration_since(entry.started) >= self.window {
            *entry = Window { started: now, used: 0 };
        }
        let reset_secs = self.window.saturating_sub(now.duration_since(entry.started)).as_secs().max(1);
        let allowed = entry.used < limit;
        if allowed {
            entry.used += 1;
        }
        Decision { allowed, limit, remaining: limit.saturating_sub(entry.used), reset_secs }
    }
}

/// Counts every request: per user when the token is valid, per client address otherwise (a stricter limit).
/// The key is never taken from an unverified token, so nobody can spend someone else's budget.
pub async fn rate_limit(
    State(app): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    mut request: Request,
    next: Next,
) -> Response {
    let claims = match bearer_token(request.headers()) {
        Ok(token) => app.auth.verify(token).await.ok(),
        Err(_) => None,
    };
    let (key, limit) = match &claims {
        Some(claims) => (format!("user:{}", claims.sub), app.config.rate_limit_user),
        None => (format!("ip:{}", peer.ip()), app.config.rate_limit_anon),
    };
    let decision = app.limiter.check(&key, limit);
    let mut response = if decision.allowed {
        if let Some(claims) = claims {
            // The extractor in auth.rs finds the verified claims here and does not check the token a second time.
            request.extensions_mut().insert(claims);
        }
        next.run(request).await
    } else {
        AppError::RateLimited { retry_after: decision.reset_secs }.into_response()
    };
    let headers = response.headers_mut();
    headers.insert("ratelimit-limit", HeaderValue::from(decision.limit));
    headers.insert("ratelimit-remaining", HeaderValue::from(decision.remaining));
    headers.insert("ratelimit-reset", HeaderValue::from(decision.reset_secs));
    response
}
