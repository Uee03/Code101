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
