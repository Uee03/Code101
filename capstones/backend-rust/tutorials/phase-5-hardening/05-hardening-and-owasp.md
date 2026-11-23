---
track: capstone
level: 301
phase: 5
phase_name: hardening
lesson: 05
title: "Hardening and OWASP"
time: 90 min
prerequisites: [capstone-backend-rust-04]
versions: { rust: "1.100.0", axum: "0.8.9", tower-http: "0.7.1", docker: "29.9.3" }
verified: 2026-11-23 on Windows 11, Rust 1.100.0, Docker CLI/Engine 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-rust/source/phase-5-hardening/05-hardening-and-owasp/
assets: []
---

# 05. Hardening and OWASP

## Why it matters
A shop with a good lock on the door can still be robbed: a crowd can block the entrance, someone can push through a delivery of a thousand crates, a stranger can read the price list through the window, and nobody notices because no one keeps a diary. Hardening is everything around the lock: queue limits, size limits, what the window shows, and a diary of who was turned away. It is also the last step before the platform's own test, the conformance script, finally says `18 passed`.

## What you will build
- A **rate limiter** that counts requests per user (100 per minute) or per client address when nobody is signed in (30 per minute), answers `429 Too Many Requests` with `Retry-After`, and puts `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` on every response.
- **CORS** for exactly the two web origins, **security headers**, a **1 MiB body limit**, a **30 second request timeout**.
- **Logging** that records who did what and every refused request, never a token or a body.
- The **OWASP API Security Top 10** walk-through, with the line of code that answers each risk.
At the end: `18 passed, 0 failed`.

## Before you start
- Chapter 04 done (or its pack unzipped). This chapter's pack is `backend-rust-phase-5-hardening.zip`, folder `05-hardening-and-owasp/code`: the finished project.
- Docker running, host ports 5432, 8000 and 8180 free.
- Unchanged from earlier chapters, so not repeated here: `Dockerfile`, `.dockerignore`, `.gitignore`, `rustfmt.toml`, `docker-compose.yml`, `db/`, `keycloak/`, `scripts/`, and in `src/`: `error.rs`, `extract.rs`, `http.rs`, `jwks.rs`, `models.rs`, `validation.rs`, `handlers/` and `store/`.

## Steps
### Step 1. Crates and settings: `Cargo.toml`, `.env.example`, `src/config.rs`
**File: `Cargo.toml`**
```toml
[package]
name = "tasks-api"
version = "1.0.0"
edition = "2024"
rust-version = "1.88"
description = "Tasks and Teams API (Code101 capstone, Rust backend)"
publish = false

[dependencies]
axum = "0.8"
base64 = "0.23"
chrono = { version = "0.4", features = ["serde"] }
dotenvy = "0.15"
hex = "0.4"
jsonwebtoken = { version = "12", default-features = false, features = ["rust_crypto"] }
reqwest = { version = "0.13", default-features = false, features = ["json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
serde_urlencoded = "0.7"
sha2 = "0.11"
sqlx = { version = "0.9", default-features = false, features = ["chrono", "derive", "json", "postgres", "runtime-tokio", "uuid"] }
thiserror = "2"
tokio = { version = "1", features = ["io-util", "macros", "net", "rt-multi-thread", "signal", "time"] }
tower = { version = "0.5", features = ["util"] }
tower-http = { version = "0.7", features = ["cors", "request-id", "set-header", "timeout", "trace"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
uuid = { version = "1", features = ["serde", "v4"] }

[profile.release]
lto = "thin"
codegen-units = 1
strip = true
```
Only `tower-http` changed: three more of its optional layers are switched on: `cors` (answers browser preflight requests and adds the CORS headers), `set-header` (adds a header to every response) and `timeout` (cuts off slow requests). Everything else is already known.

**File: `.env.example`**
```text
# Disposable local practice only. Never reuse these values for a real system.
# Platform stack (read by docker-compose.yml)
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net
# Rust API (read by the program through dotenvy)
BIND_ADDR=127.0.0.1:8000
PUBLIC_BASE_URL=http://localhost:8000
DATABASE_URL=postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams
TOKEN_ISSUER=http://localhost:8180/realms/tasksteams
TOKEN_AUDIENCE=tasks-api
JWKS_URL=http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs
CORS_ORIGINS=http://localhost:4200,http://localhost:5173
RATE_LIMIT_USER=100
RATE_LIMIT_ANON=30
RATE_LIMIT_WINDOW_SECS=60
RUST_LOG=info
```
Four new settings: `CORS_ORIGINS` (a comma-separated list: Angular on port 4200 and React/Vite on 5173), and the three rate-limit numbers: calls per window for a signed-in user, calls per window for an anonymous address, and the window length in seconds. Copy the file again to `.env`.

**File: `src/config.rs`**
```rust
use std::{env, net::SocketAddr, str::FromStr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
    pub token_issuer: String,
    pub token_audience: String,
    pub jwks_url: String,
    pub cors_origins: Vec<String>,
    pub rate_limit_user: u32,
    pub rate_limit_anon: u32,
    pub rate_limit_window_secs: u64,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is not set".to_owned())?;
        let public_base_url = var_or("PUBLIC_BASE_URL", "http://localhost:8000").trim_end_matches('/').to_owned();
        // The issuer is compared with the `iss` claim as plain text; the JWKS URL is where the keys are fetched.
        // They differ inside Docker: tokens say localhost:8180, the API reaches Keycloak as keycloak:8080.
        let token_issuer = var_or("TOKEN_ISSUER", "http://localhost:8180/realms/tasksteams");
        let token_audience = var_or("TOKEN_AUDIENCE", "tasks-api");
        let jwks_url = var_or("JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs");
        let cors_origins = var_or("CORS_ORIGINS", "http://localhost:4200,http://localhost:5173")
            .split(',')
            .map(|origin| origin.trim().to_owned())
            .filter(|origin| !origin.is_empty())
            .collect();
        Ok(Self {
            bind_addr,
            database_url,
            public_base_url,
            token_issuer,
            token_audience,
            jwks_url,
            cors_origins,
            rate_limit_user: number("RATE_LIMIT_USER", 100)?,
            rate_limit_anon: number("RATE_LIMIT_ANON", 30)?,
            rate_limit_window_secs: number("RATE_LIMIT_WINDOW_SECS", 60)?,
        })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}

fn number<T: FromStr>(name: &str, default: T) -> Result<T, String> {
    match env::var(name) {
        Ok(text) => text.parse().map_err(|_| format!("{name} is not a number: {text}")),
        Err(_) => Ok(default),
    }
}
```
`number` is generic over any type that can be parsed from text (`T: FromStr`): the same helper reads the `u32` limits and the `u64` window, and a bad value is a start-up error that names the variable.

### Step 2. The rate limiter: `src/ratelimit.rs`
**File: `src/ratelimit.rs`**
```rust
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
```
- **Fixed window.** Each key (`user:<id>` or `ip:<address>`) has a window start and a counter. A call inside the window increments the counter; when the counter reaches the limit, further calls are refused until the window (60 seconds) ends and a new one starts. It is the simplest correct limiter. Its known weakness: a client can send a full burst at the end of one window and another at the start of the next. Alternatives are a sliding window or a token bucket; the headers would stay the same.
- **Whose budget?** The middleware checks the token with the same `Authenticator` as the handlers. A **valid** token counts against the user (100 per window); anything else, including a forged or expired token, counts against the client address (30 per window). The key is never taken from a token that was not verified: otherwise an attacker could put somebody else's `sub` into a forged token and use up that person's budget.
- **No second check.** After a successful verification the middleware stores the `Claims` in the request *extensions* (a typed side pocket of the request); the `AuthUser` extractor looks there first (step 3), so each request is verified once.
- **Headers on every answer.** `RateLimit-Limit` is the limit, `RateLimit-Remaining` what is left in this window, `RateLimit-Reset` the seconds until the window ends (at least 1). A refused call gets `AppError::RateLimited`, which `render_problems` renders as a 429 problem with `Retry-After`; the three headers are added to it as well, because they are set after `next.run` or after the refusal.
- **Memory.** The map has one entry per key. Above 10,000 entries the limiter first drops windows that already ended, so a flood of different addresses cannot grow it without end. The `Mutex` is held only for a few microseconds and never across an `.await`.
- **What it does not do.** The counters live in this process. With three API replicas each counts alone, so the real limit is three times higher; a production system uses a shared store (Redis) or the reverse proxy. And behind a reverse proxy every client has the proxy's address, so anonymous clients share one budget; honouring `X-Forwarded-For` would need a list of trusted proxies.

### Step 3. State, modules and identity: `src/state.rs`, `src/lib.rs`, `src/auth.rs`
**File: `src/state.rs`**
```rust
use std::sync::Arc;

use crate::{config::Config, jwks::Authenticator, ratelimit::RateLimiter, store::Store};

/// Everything a handler may need. Cloning is cheap: the pool, the key cache, the limiter and the config are shared.
#[derive(Clone)]
pub struct AppState {
    pub store: Store,
    pub auth: Arc<Authenticator>,
    pub limiter: Arc<RateLimiter>,
    pub config: Arc<Config>,
}
```
**File: `src/lib.rs`**
```rust
pub mod app;
pub mod auth;
pub mod config;
pub mod error;
pub mod extract;
pub mod handlers;
pub mod http;
pub mod jwks;
pub mod models;
pub mod ratelimit;
pub mod state;
pub mod store;
pub mod validation;
```
**File: `src/auth.rs`**
```rust
use axum::{
    extract::FromRequestParts,
    http::{HeaderMap, header, request::Parts},
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{error::AppError, state::AppState};

pub const READ: &str = "tasks:read";
pub const WRITE: &str = "tasks:write";
pub const ADMIN: &str = "tasks:admin";

/// The caller, as described by the access token.
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub display_name: String,
    pub roles: Vec<String>,
    pub scopes: Vec<String>,
}

impl AuthUser {
    pub fn is_admin(&self) -> bool {
        self.roles.iter().any(|role| role == "admin")
    }

    /// The scope says what the client may do on the user's behalf. A missing scope is a 403, not a 401.
    pub fn require_scope(&self, scope: &str) -> Result<(), AppError> {
        if self.scopes.iter().any(|granted| granted == scope) {
            Ok(())
        } else {
            Err(AppError::Forbidden(format!("The {scope} scope is required.")))
        }
    }

    pub fn require_admin(&self) -> Result<(), AppError> {
        if self.is_admin() { Ok(()) } else { Err(AppError::Forbidden("The admin role is required.".to_owned())) }
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub preferred_username: Option<String>,
    pub email: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub scope: String,
    pub realm_access: Option<RealmAccess>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct RealmAccess {
    #[serde(default)]
    pub roles: Vec<String>,
}

impl From<Claims> for AuthUser {
    fn from(claims: Claims) -> Self {
        let username = claims.preferred_username.unwrap_or_else(|| format!("user-{}", claims.sub.simple()));
        Self {
            id: claims.sub,
            email: claims.email.unwrap_or_else(|| format!("{username}@unknown.invalid")),
            display_name: claims.name.filter(|name| !name.trim().is_empty()).unwrap_or_else(|| username.clone()),
            username,
            roles: claims.realm_access.map(|access| access.roles).unwrap_or_default(),
            scopes: claims.scope.split_whitespace().map(str::to_owned).collect(),
        }
    }
}

pub fn bearer_token(headers: &HeaderMap) -> Result<&str, AppError> {
    let value = headers.get(header::AUTHORIZATION).ok_or(AppError::Unauthorized)?;
    let value = value.to_str().map_err(|_| AppError::InvalidToken)?;
    match value.split_once(' ') {
        Some((scheme, token)) if scheme.eq_ignore_ascii_case("bearer") && !token.trim().is_empty() => Ok(token.trim()),
        _ => Err(AppError::Unauthorized),
    }
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, AppError> {
        // The rate limiter has already verified the token and left the claims in the request extensions.
        let claims = match parts.extensions.get::<Claims>() {
            Some(claims) => claims.clone(),
            None => state.auth.verify(bearer_token(&parts.headers)?).await?,
        };
        let user = AuthUser::from(claims);
        state.store.ensure_user(&user).await?;
        // The user id joins the request log line: who did what, without ever logging the token.
        tracing::Span::current().record("user_id", tracing::field::display(user.id));
        Ok(user)
    }
}
```
Three small changes since chapter 03: `Claims` and `RealmAccess` are `Clone` (they now travel in request extensions), `bearer_token` is `pub` (the rate limiter uses it), and the extractor first looks for the claims the rate limiter already verified. The last line **records the user id into the log span** that the trace layer opened in chapter 01 (the field `user_id` is declared empty in step 4): every log line of the request now says who did it.

### Step 4. The router with CORS, security headers and limits: `src/app.rs`
**File: `src/app.rs`**
```rust
use std::time::Duration;

use axum::{
    Router,
    body::Body,
    extract::DefaultBodyLimit,
    http::{HeaderName, HeaderValue, Method, Request, Response, StatusCode, header},
    middleware,
    routing::{delete, get, post, put},
};
use tower::ServiceBuilder;
use tower_http::{
    cors::CorsLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    set_header::SetResponseHeaderLayer,
    timeout::TimeoutLayer,
    trace::TraceLayer,
};
use tracing::Span;

use crate::{
    config::Config,
    error::render_problems,
    handlers::{self, audit, comments, health, me, members, projects, tasks, teams, users},
    ratelimit,
    state::AppState,
};

/// The largest request body: 1 MiB. Every JSON body of this API is far smaller.
const MAX_BODY_BYTES: usize = 1024 * 1024;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);

/// Only the configured web origins may call the API from a browser; no wildcard.
fn cors(config: &Config) -> CorsLayer {
    let origins: Vec<HeaderValue> = config.cors_origins.iter().filter_map(|origin| origin.parse().ok()).collect();
    let expose = [
        "etag",
        "location",
        "retry-after",
        "idempotent-replayed",
        "ratelimit-limit",
        "ratelimit-remaining",
        "ratelimit-reset",
    ];
    CorsLayer::new()
        .allow_origin(origins)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::PATCH, Method::DELETE])
        .allow_headers([
            header::AUTHORIZATION,
            header::CONTENT_TYPE,
            header::IF_MATCH,
            header::IF_NONE_MATCH,
            HeaderName::from_static("idempotency-key"),
        ])
        .expose_headers(expose.map(HeaderName::from_static))
        .max_age(Duration::from_secs(600))
}

fn security_header(name: HeaderName, value: &'static str) -> SetResponseHeaderLayer<HeaderValue> {
    SetResponseHeaderLayer::if_not_present(name, HeaderValue::from_static(value))
}

pub fn router(state: AppState) -> Router {
    let trace = TraceLayer::new_for_http()
        .make_span_with(|request: &Request<Body>| {
            let request_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).unwrap_or("-");
            // `user_id` stays empty until the extractor knows who is calling (see auth.rs).
            tracing::info_span!(
                "request",
                method = %request.method(),
                path = request.uri().path(),
                request_id,
                user_id = tracing::field::Empty
            )
        })
        .on_response(|response: &Response<Body>, latency: Duration, _span: &Span| {
            // A refused request is a security event: it gets WARN so it stands out in the log.
            let status = response.status().as_u16();
            let latency_ms = latency.as_millis();
            if matches!(status, 401 | 403 | 429) {
                tracing::warn!(status, latency_ms, "request denied");
            } else {
                tracing::info!(status, latency_ms, "request finished");
            }
        });

    let cors = cors(&state.config);
    let rate_limit = middleware::from_fn_with_state(state.clone(), ratelimit::rate_limit);

    Router::new()
        .route("/health", get(health::get_health))
        .route("/v1/me", get(me::get_me))
        .route("/v1/users", get(users::list_users))
        .route("/v1/teams", get(teams::list_teams).post(teams::create_team))
        .route("/v1/teams/{team_id}", get(teams::get_team).patch(teams::update_team).delete(teams::delete_team))
        .route("/v1/teams/{team_id}/members", get(members::list_members))
        .route("/v1/teams/{team_id}/members/{user_id}", put(members::put_member).delete(members::remove_member))
        .route("/v1/teams/{team_id}/projects", get(projects::list_projects).post(projects::create_project))
        .route(
            "/v1/projects/{project_id}",
            get(projects::get_project).patch(projects::update_project).delete(projects::delete_project),
        )
        .route("/v1/projects/{project_id}/tasks", get(tasks::list_tasks).post(tasks::create_task))
        .route("/v1/tasks/{task_id}", get(tasks::get_task).patch(tasks::update_task).delete(tasks::delete_task))
        .route("/v1/tasks/{task_id}/complete", post(tasks::complete_task))
        .route("/v1/tasks/{task_id}/reassign", post(tasks::reassign_task))
        .route("/v1/tasks/{task_id}/comments", get(comments::list_comments).post(comments::create_comment))
        .route("/v1/comments/{comment_id}", delete(comments::delete_comment))
        .route("/v1/audit-log", get(audit::list_audit))
        .fallback(handlers::not_found)
        .with_state(state)
        // The first layer is the outermost: it sees the request first and the response last.
        .layer(
            ServiceBuilder::new()
                .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
                .layer(PropagateRequestIdLayer::x_request_id())
                .layer(trace)
                .layer(cors)
                .layer(security_header(header::X_CONTENT_TYPE_OPTIONS, "nosniff"))
                .layer(security_header(header::CACHE_CONTROL, "no-store"))
                .layer(security_header(header::CONTENT_SECURITY_POLICY, "default-src 'none'; frame-ancestors 'none'"))
                .layer(security_header(header::REFERRER_POLICY, "no-referrer"))
                .layer(middleware::from_fn(render_problems))
                .layer(TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, REQUEST_TIMEOUT))
                .layer(rate_limit)
                .layer(DefaultBodyLimit::max(MAX_BODY_BYTES)),
        )
}
```
The order of the layers is a design decision: **outermost first**.
1. Request id and **trace** first: even a request that is later refused is logged with its id. The trace layer's `on_response` closure logs `request denied` at WARN for 401, 403 and 429 and `request finished` at INFO for everything else, together with the status and the time in milliseconds. Only the **path** is in the span, never the query string, the headers or a body.
2. **CORS** next, so that browser preflight requests (`OPTIONS`) are answered here, never reach the limiter, and every later answer, errors included, carries the CORS headers. The allow-list is the configured origins only (no `*`), the five methods and the headers the contract names; the `expose` list is what a browser script may *read* from the response (without it a client could not see `ETag`, `Location` or `RateLimit-*`). `max_age` lets the browser cache the preflight answer for 10 minutes.
3. **Security headers** on every response: `X-Content-Type-Options: nosniff` (the browser must not guess another content type), `Cache-Control: no-store` (nobody may cache answers that contain personal data; clients that want the benefit of ETags ask with `If-None-Match` themselves), `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` (an API answer is data, not a page: it may load nothing and may not be put in a frame) and `Referrer-Policy: no-referrer`. `if_not_present` keeps a header that a handler set itself. `Strict-Transport-Security` is deliberately absent: it belongs to the TLS-terminating proxy in front of the API, not to an HTTP service.
4. `render_problems` (chapter 01) is inside the headers, outside the limiter: so a 429 produced by the limiter, or a 408 produced by the timeout, also becomes a problem document.
5. **Timeout**: a request that runs longer than 30 seconds is cut off with 408.
6. The **rate limiter**, then the **body limit**: `DefaultBodyLimit::max(1 MiB)` makes the `ValidJson` extractor reject a bigger body with `PayloadTooLarge` (413) before parsing it. An attacker cannot make the server buffer a gigabyte.

### Step 5. The program: `src/main.rs`
**File: `src/main.rs`**
```rust
use std::{error::Error, net::SocketAddr, sync::Arc, time::Duration};

use tasks_api::{app, config::Config, jwks::Authenticator, ratelimit::RateLimiter, state::AppState, store::Store};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    signal,
    time::timeout,
};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    dotenvy::dotenv().ok();
    let config = Config::from_env()?;
    // `tasks-api healthcheck` is what Docker runs: the image has no shell, curl or wget.
    if std::env::args().nth(1).as_deref() == Some("healthcheck") {
        return healthcheck(&config).await.inspect_err(|err| eprintln!("unhealthy: {err}"));
    }
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let store = Store::connect(&config.database_url).await?;
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(address = %config.bind_addr, "listening");
    let state = AppState {
        store,
        auth: Arc::new(Authenticator::new(&config)),
        limiter: Arc::new(RateLimiter::new(Duration::from_secs(config.rate_limit_window_secs))),
        config: Arc::new(config),
    };
    // `ConnectInfo` hands the client address to the rate limiter.
    let service = app::router(state).into_make_service_with_connect_info::<SocketAddr>();
    axum::serve(listener, service).with_graceful_shutdown(shutdown_signal()).await?;
    Ok(())
}

/// Asks the running server on this machine for `GET /health` and succeeds only on a 200.
async fn healthcheck(config: &Config) -> Result<(), Box<dyn Error>> {
    let limit = Duration::from_secs(3);
    let mut stream = timeout(limit, TcpStream::connect(("127.0.0.1", config.bind_addr.port()))).await??;
    stream.write_all(b"GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n").await?;
    let mut reply = String::new();
    timeout(limit, stream.read_to_string(&mut reply)).await??;
    match reply.lines().next() {
        Some(status) if status.starts_with("HTTP/1.1 200") => Ok(()),
        other => Err(format!("the server answered {}", other.unwrap_or("nothing")).into()),
    }
}

/// Resolves on Ctrl+C (all systems) or SIGTERM (what `docker stop` sends).
async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c().await.expect("cannot listen for Ctrl+C");
    };
    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate()).expect("cannot listen for SIGTERM").recv().await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        _ = ctrl_c => {}
        _ = terminate => {}
    }
    tracing::info!("shutting down");
}
```
`into_make_service_with_connect_info::<SocketAddr>()` makes Axum record the peer address of each connection, which the `ConnectInfo` extractor of the rate limiter reads. Forget it and every request fails with a 500 (see *Common mistakes*). The Docker health check comes from loopback inside the container and has its own address bucket (`ip:127.0.0.1`), separate from your calls.

### Step 6. The Compose file: `docker-compose.override.yml`
**File: `docker-compose.override.yml`**
```yaml
# Compose merges this file into docker-compose.yml (the platform file) automatically.
# It adds the API as a third service on the same network as Postgres and Keycloak.
services:
  api:
    build: .
    image: code101/tasks-api-rust:local
    depends_on:
      db:
        condition: service_healthy
      keycloak:
        condition: service_healthy
    environment:
      BIND_ADDR: 0.0.0.0:8000
      PUBLIC_BASE_URL: http://localhost:8000
      DATABASE_URL: postgres://tasks_app:tasks_app_local_only@db:5432/${POSTGRES_DB:-tasksteams}
      TOKEN_ISSUER: http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams
      TOKEN_AUDIENCE: tasks-api
      JWKS_URL: http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs
      CORS_ORIGINS: ${CORS_ORIGINS:-http://localhost:4200,http://localhost:5173}
      RATE_LIMIT_USER: ${RATE_LIMIT_USER:-100}
      RATE_LIMIT_ANON: ${RATE_LIMIT_ANON:-30}
      RATE_LIMIT_WINDOW_SECS: ${RATE_LIMIT_WINDOW_SECS:-60}
      RUST_LOG: info
    ports:
      - "127.0.0.1:8000:8000"
    healthcheck:
      test: ["CMD", "/usr/local/bin/tasks-api", "healthcheck"]
      interval: 5s
      timeout: 5s
      retries: 12
      start_period: 3s
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    networks:
      - tasksteams
```
The three new `environment` lines pass the CORS and rate-limit settings from your `.env` (or from your shell, which wins) into the container, each with the default after `:-`.

## Run it
**Terminal (folder: `tasks-api`; no other stack running)**
```text
docker compose -p backend up -d --build --wait
python scripts/api.py --as alice GET /v1/me
```
The answer now carries the hardening headers (the body is the same as before and is shortened here):
```text
HTTP 200
content-type: application/json
ratelimit-limit: 100
ratelimit-remaining: 99
ratelimit-reset: 60
referrer-policy: no-referrer
content-security-policy: default-src 'none'; frame-ancestors 'none'
cache-control: no-store
x-content-type-options: nosniff
vary: origin
access-control-expose-headers: etag,location,retry-after,idempotent-replayed,ratelimit-limit,ratelimit-remaining,ratelimit-reset
x-request-id: 91a84b04-7204-4165-b8e3-b100c368d7ac

{
  "id": "a11ce000-0000-4000-8000-000000000001",
  "username": "alice",
  ... (the rest of the profile)
}
```
An error answer has them too, and an anonymous caller gets the stricter limit of 30 (`ratelimit-limit: 30`; the run below uses 3 for the 429 demo):
```text
python scripts/api.py GET /v1/me
```
```text
HTTP 401
www-authenticate: Bearer realm="tasksteams"
ratelimit-limit: 3
ratelimit-remaining: 2
ratelimit-reset: 60
content-type: application/problem+json
referrer-policy: no-referrer
content-security-policy: default-src 'none'; frame-ancestors 'none'
cache-control: no-store
x-content-type-options: nosniff
vary: origin
access-control-expose-headers: etag,location,retry-after,idempotent-replayed,ratelimit-limit,ratelimit-remaining,ratelimit-reset
x-request-id: 3c54961f-73c9-4583-83bf-9784b895ee9b

{
  "type": "https://code101.example/problems/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "a bearer access token is required",
  "instance": "/v1/me",
  "traceId": "3c54961f-73c9-4583-83bf-9784b895ee9b"
}
```
**CORS.** A browser first sends a *preflight* (`OPTIONS`) before a call that is not simple. From the Angular origin it is answered with the allowed methods and headers; from an unknown origin the answer lacks `access-control-allow-origin`, so the browser refuses the real call:
```text
python scripts/api.py OPTIONS /v1/tasks/7a500000-0000-4000-8000-000000000004 -H "Origin: http://localhost:4200" -H "Access-Control-Request-Method: PATCH" -H "Access-Control-Request-Headers: authorization,if-match,content-type"
```
```text
HTTP 200
vary: origin
access-control-allow-methods: GET,POST,PUT,PATCH,DELETE
access-control-allow-headers: authorization,content-type,if-match,if-none-match,idempotency-key
access-control-max-age: 600
access-control-allow-origin: http://localhost:4200
x-request-id: 44804877-5968-4a0c-8801-0c653029b08d
allow: GET,HEAD,PATCH,DELETE
```
```text
python scripts/api.py OPTIONS /v1/tasks/7a500000-0000-4000-8000-000000000004 -H "Origin: http://evil.example" -H "Access-Control-Request-Method: PATCH"
```
```text
HTTP 200
vary: origin
access-control-allow-methods: GET,POST,PUT,PATCH,DELETE
access-control-allow-headers: authorization,content-type,if-match,if-none-match,idempotency-key
access-control-max-age: 600
x-request-id: 7d71639c-c9be-4791-aeb2-78346b98451a
allow: GET,HEAD,PATCH,DELETE
```
**The body limit.** A body of 1.1 MB (generated on the fly and piped in with `--raw @-`) is refused before it is read:

**Terminal, Windows PowerShell**
```text
python -c "print('x' * 1100000)" | python scripts/api.py --as alice --raw "@-" POST /v1/teams
```
**Terminal, macOS or Linux**
```text
python3 -c "print('x' * 1100000)" | python3 scripts/api.py --as alice --raw @- POST /v1/teams
```
```text
HTTP 413
ratelimit-limit: 100
ratelimit-remaining: 97
ratelimit-reset: 59
content-type: application/problem+json
referrer-policy: no-referrer
content-security-policy: default-src 'none'; frame-ancestors 'none'
cache-control: no-store
x-content-type-options: nosniff
vary: origin
access-control-expose-headers: etag,location,retry-after,idempotent-replayed,ratelimit-limit,ratelimit-remaining,ratelimit-reset
x-request-id: e71830a7-99bd-4fcf-8571-d3f8ef9ccf94

{
  "type": "https://code101.example/problems/payload-too-large",
  "title": "Payload too large",
  "status": 413,
  "detail": "request body too large",
  "instance": "/v1/teams",
  "traceId": "e71830a7-99bd-4fcf-8571-d3f8ef9ccf94"
}
```
**The rate limit.** To see a 429 without sending a hundred requests, restart the stack with a small anonymous limit. The variable must be set in the shell **before** `docker compose` runs, because Compose reads it:

**Terminal, Windows PowerShell**
```text
docker compose -p backend down
$env:RATE_LIMIT_ANON = "3"
docker compose -p backend up -d --wait
1..5 | ForEach-Object { python scripts/api.py GET /health | Select-String -Pattern "^HTTP|^ratelimit|^retry-after" }
```
**Terminal, macOS or Linux**
```text
docker compose -p backend down
export RATE_LIMIT_ANON=3
docker compose -p backend up -d --wait
for i in 1 2 3 4 5; do python3 scripts/api.py GET /health | grep -E "^HTTP|^ratelimit|^retry-after"; done
```
```text
HTTP 200
ratelimit-limit: 3
ratelimit-remaining: 1
ratelimit-reset: 59
HTTP 200
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 59
HTTP 429
retry-after: 58
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 58
HTTP 429
retry-after: 58
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 58
HTTP 429
retry-after: 58
ratelimit-limit: 3
ratelimit-remaining: 0
ratelimit-reset: 58
```
(The first of the five calls found `remaining: 1` because a call of the 401 example above already used one of the three in this window.) The 429 body is a problem document:
```text
{
  "type": "https://code101.example/problems/rate-limited",
  "title": "Too many requests",
  "status": 429,
  "detail": "Slow down and retry later.",
  "instance": "/health",
  "traceId": "263131b6-bb36-4d2c-9649-f979b1d9e432"
}
```
A signed-in user has a separate budget: `python scripts/api.py --as alice GET /v1/me` still answers 200 with `ratelimit-limit: 100`. Unset the variable afterwards (`Remove-Item Env:RATE_LIMIT_ANON`, or `unset RATE_LIMIT_ANON`).

**The log.** After a successful call, a call by bob to the admin route, and a call without a token, `docker compose -p backend logs api --no-log-prefix` shows one line per request (the `spans` list at the end of each line repeats `span` and is cut here; the lines are real):
```text
{"timestamp":"2026-11-23T09:31:53.587523Z","level":"INFO","fields":{"message":"request finished","status":200,"latency_ms":"27"},"target":"tasks_api::app","span":{"method":"GET","path":"/v1/me","request_id":"f2175857-baf6-4318-88e5-e12b45f6dccd","user_id":"a11ce000-0000-4000-8000-000000000001","name":"request"},"spans":[...]}
{"timestamp":"2026-11-23T09:31:53.792416Z","level":"WARN","fields":{"message":"request denied","status":403,"latency_ms":"0"},"target":"tasks_api::app","span":{"method":"GET","path":"/v1/audit-log","request_id":"2a0948bc-f6d6-470d-b0df-f6c99be6768b","user_id":"b0b00000-0000-4000-8000-000000000002","name":"request"},"spans":[...]}
{"timestamp":"2026-11-23T09:31:53.916767Z","level":"WARN","fields":{"message":"request denied","status":401,"latency_ms":"0"},"target":"tasks_api::app","span":{"method":"GET","path":"/v1/me","request_id":"da01dcba-f9e0-4432-8c2e-2b5708a2a7e9","name":"request"},"spans":[...]}
```
The 403 names the user (`b0b00000-...`, bob) and the route; the 401 has no `user_id` because nobody was identified. There is no token, no query string and no body in any line.

**All 18 checks.** Restart with the default limits (`down`, unset the variable, `up --wait`) and run the script:
```text
python scripts/conformance.py
```
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
PASS  me (alice is admin, RateLimit headers present)
PASS  create team (201, Location and ETag set, team d0acf4a9-fce5-4650-ae74-c9c973878d56)
PASS  create project (201, project 43bd53f2-f753-4b45-9c44-e02869eab284)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
PASS  401 without token (401 problem details with a Bearer challenge)
PASS  403 for member on admin route (bob (member) gets 403 on the audit log and on creating a team)
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
18 passed, 0 failed
```
**18 passed, 0 failed**: the Rust backend honours the whole contract. Clean up:
```text
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasks-api-rust:local
```

## How it works
- **Defence in layers.** No single control is trusted: the token is checked (chapter 03), the scope, the role and the team are checked, the database enforces its own constraints and the `tasks_app` role cannot change the schema, the container is non-root with a read-only file system, the port is on loopback. A flaw in one layer meets the next.
- **Security events.** `request denied` lines (401, 403, 429) with the request id, the path and, when known, the `user_id` let an operator see an attack (many 401s from one address) without any secret in the log. What is **never** logged: tokens, passwords, request or response bodies, query strings.
- **Production checklist.** (1) A TLS-terminating reverse proxy in front, which also adds `Strict-Transport-Security`; (2) `https` issuer and database over TLS (`reqwest` feature `rustls`, SQLx feature `tls-rustls`); (3) secrets from a secret store, not from a file in the repository; (4) a shared rate limiter if you run more than one replica; (5) backups of the database (from the platform capstone: `docker compose exec -T db pg_dump -U tasks_admin tasksteams > backup.sql`; restore into an empty database with `psql`); (6) image scanning and a rebuild when the base image gets security fixes; (7) log shipping and alerts on bursts of 401 and 429.

### The OWASP API Security Top 10 (2023) against this code
| Risk | What could go wrong here | Where this code answers it |
|------|--------------------------|----------------------------|
| API1 Broken object level authorization | Reading or changing another team's task by guessing its id | `Store::team_access` runs before every object read or write; a non-member gets the same 404 as for a missing id (`handlers::hide`); ids are random UUIDs |
| API2 Broken authentication | Forged, expired or foreign tokens; brute force | `jwks.rs`: RS256 only, `iss`, `aud`, `exp`, `nbf`, signature from the issuer's keys; invalid tokens count against the stricter anonymous limit in `ratelimit.rs`; Keycloak does brute-force protection and short token lifetimes |
| API3 Broken object property level authorization | Setting fields the client must not set (`id`, `version`, `createdBy`, a role) | `models.rs`: request types have only the writable fields and `deny_unknown_fields`; versions and ids come from the database; a team role changes only through `PUT members` by a lead |
| API4 Unrestricted resource consumption | Huge bodies, huge pages, slow requests, floods | `DefaultBodyLimit` 1 MiB, `TimeoutLayer` 30 s, `limit` at most 100 (`extract.rs`), pool of 10 connections with a 5 s wait (`store/mod.rs`), rate limits, a bounded limiter map |
| API5 Broken function level authorization | A member calling an admin operation | Every handler calls `require_scope`, then `require_admin` or `require_lead`; effective permission is scope **and** role (bob gets 403 on `/v1/audit-log` with the `tasks:admin` scope) |
| API6 Unrestricted access to sensitive business flows | Replayed creates, mass team creation | `Idempotency-Key` handling in `http::create_once`; team creation needs the admin role; the rate limiter slows automation |
| API7 Server-side request forgery | Making the server call attacker-chosen URLs | The only outgoing request is the JWKS download from `JWKS_URL`, which is configuration, never input |
| API8 Security misconfiguration | Verbose errors, open CORS, root containers, exposed ports | 5xx details are fixed text (`error.rs`), CORS lists exact origins, security headers (`app.rs`), distroless non-root image, read-only file system, no capabilities, loopback port publishing (`docker-compose.override.yml`) |
| API9 Improper inventory management | Forgotten debug or old routes | The router holds exactly the 27 contract routes under `/v1` plus `/health`; every other path is a 404 problem (`handlers::not_found`) |
| API10 Unsafe consumption of APIs | Trusting what another service returns | Keys and claims are accepted only from the configured issuer, parsed into typed structs (anything else is a rejection), and database rows are typed and guarded by `CHECK` constraints |

## Try it
Starter: `exercise/starter` (a tiny Cargo project, no dependencies). The limiter of this chapter reads the clock with `Instant::now()`, which makes it hard to try. Write `Limiter::check` with the time passed in as `now` (seconds): a call after the window ended starts a new window, a refused call does not count, and every key has its own window. `cargo run` must print the lines shown in the solution.

**File: `exercise/starter/src/main.rs`**
```rust
use std::collections::HashMap;

/// A rate limiter whose clock is a parameter (`now`, in seconds), so it can be tried without waiting.
struct Limiter {
    limit: u32,
    window: u64,
    seen: HashMap<String, (u64, u32)>, // key -> (second the window started, calls used)
}

impl Limiter {
    fn new(limit: u32, window: u64) -> Self {
        Self { limit, window, seen: HashMap::new() }
    }

    /// Returns (allowed, remaining). A call that arrives after the window ended starts a new window.
    /// A refused call does not count.
    fn check(&mut self, key: &str, now: u64) -> (bool, u32) {
        todo!("start or continue the window of {key} at second {now}")
    }
}

fn main() {
    let mut limiter = Limiter::new(3, 60);
    for second in [0, 1, 2, 3, 59, 60, 61] {
        let (allowed, remaining) = limiter.check("ip:10.0.0.1", second);
        println!("t={second:>2} allowed={allowed} remaining={remaining}");
    }
    println!("other key: {:?}", limiter.check("ip:10.0.0.2", 3));
}
```
The starter folder also holds a `Cargo.toml` (`name = "fixed-window"`, `edition = "2024"`).

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.rs`**
```rust
use std::collections::HashMap;

/// A rate limiter whose clock is a parameter (`now`, in seconds), so it can be tried without waiting.
struct Limiter {
    limit: u32,
    window: u64,
    seen: HashMap<String, (u64, u32)>, // key -> (second the window started, calls used)
}

impl Limiter {
    fn new(limit: u32, window: u64) -> Self {
        Self { limit, window, seen: HashMap::new() }
    }

    /// Returns (allowed, remaining). A call that arrives after the window ended starts a new window.
    /// A refused call does not count.
    fn check(&mut self, key: &str, now: u64) -> (bool, u32) {
        let entry = self.seen.entry(key.to_owned()).or_insert((now, 0));
        if now - entry.0 >= self.window {
            *entry = (now, 0);
        }
        let allowed = entry.1 < self.limit;
        if allowed {
            entry.1 += 1;
        }
        (allowed, self.limit - entry.1)
    }
}

fn main() {
    let mut limiter = Limiter::new(3, 60);
    for second in [0, 1, 2, 3, 59, 60, 61] {
        let (allowed, remaining) = limiter.check("ip:10.0.0.1", second);
        println!("t={second:>2} allowed={allowed} remaining={remaining}");
    }
    println!("other key: {:?}", limiter.check("ip:10.0.0.2", 3));
}
```
Expected output:
```text
t= 0 allowed=true remaining=2
t= 1 allowed=true remaining=1
t= 2 allowed=true remaining=0
t= 3 allowed=false remaining=0
t=59 allowed=false remaining=0
t=60 allowed=true remaining=2
t=61 allowed=true remaining=1
other key: (true, 2)
```
`entry` is a mutable reference into the map: changing `entry.1` changes the stored counter. Injecting the clock (a parameter instead of calling the system clock inside) is the standard way to make time-dependent code testable.
</details>

## Check yourself
1. Why does the rate limiter count a request with a forged token against the client address and not against the `sub` inside the token? <details><summary>Answer</summary>The `sub` of an unverified token is attacker-chosen. Using it as the key would let an attacker spend a victim's budget. Only a verified token names a user; everything else is limited by address.</details>
2. Which layer must come before the rate limiter so that browser preflights are not counted or refused? <details><summary>Answer</summary>`CorsLayer`: it answers the `OPTIONS` preflight itself and never calls the inner layers.</details>
3. What is the weakness of a fixed window, and when does it matter? <details><summary>Answer</summary>A client can use its whole budget at the end of one window and again at the start of the next, so for a moment it sends twice the limit. It matters for strict protection of an expensive endpoint; a sliding window or a token bucket smooths it.</details>
4. The limiter map is `Mutex<HashMap<..>>`. Why is it safe to use a standard `Mutex` in async code here? <details><summary>Answer</summary>The lock is taken and released within one function with no `.await` in between, so it never blocks the Tokio worker for long and cannot deadlock across a suspended task.</details>
5. Why is `Cache-Control: no-store` on every answer, and what does it cost? <details><summary>Answer</summary>Answers contain personal data; shared caches and browsers must not keep them. It costs the caching benefit of ETags: a client that wants a 304 must send `If-None-Match` itself (the contract's `GET /v1/tasks/{id}` supports it).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Every request answers `HTTP 500` with `"detail": "An unexpected error occurred."`; the log has ``"message":"error answered by the framework","status":"500 Internal Server Error","text":"Missing request extension: Extension of type `axum::extract::connect_info::ConnectInfo<core::net::socket_addr::SocketAddr>` was not found. Perhaps you forgot to add it? See `axum::Extension`."`` | `main.rs` serves `app::router(state)` directly; the limiter's `ConnectInfo` extractor needs `into_make_service_with_connect_info::<SocketAddr>()` | Use the service built with `into_make_service_with_connect_info`, as in step 5 |
| The browser console says it blocked the request because there is no `Access-Control-Allow-Origin` header, and the preflight answer (see above) lacks that header | The page's origin is not in `CORS_ORIGINS` (here `http://evil.example`; for your own app maybe `http://127.0.0.1:4200` instead of `http://localhost:4200`: they are different origins) | Add the exact origin, scheme and port included, to `CORS_ORIGINS` and restart |
| `HTTP 429` during normal development | You (or a script, or a browser tab that polls) used the 30 anonymous or 100 user calls of the window | Wait for `Retry-After` seconds, or raise `RATE_LIMIT_ANON` and `RATE_LIMIT_USER` in `.env` |
| `docker compose up` ignores `RATE_LIMIT_ANON=3` that you set in `.env` after starting | Compose reads the variables when it creates the container | `docker compose -p backend up -d --wait --force-recreate` |
| `Error: "RATE_LIMIT_ANON is not a number: three"` at start-up | The setting is not a whole number | Write digits only |

The first row and the CORS row are real output of this chapter's program; the 429 row is the demonstration above. The last row follows from `Config::number` and was not run.

## Best practice
Treat limits as part of the contract: every size, count and time has a number, that number is configurable, and exceeding it has a defined, logged answer. Source: OWASP API Security Top 10 2023, API4 Unrestricted Resource Consumption https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/

## Next lesson
This is the last chapter of the Rust backend. Next: a web client capstone (`web-angular` or `web-react`) that points `API_BASE_URL` at `http://localhost:8000`, or write the same contract in another language (`backend-python`, `backend-dotnet`, `backend-go`) and compare how each stack solves ETags, cursors, problem details and rate limits.
