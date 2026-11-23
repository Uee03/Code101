use std::sync::Arc;

use crate::{config::Config, jwks::Authenticator, store::Store};

/// Everything a handler may need. Cloning is cheap: the pool, the key cache and the config are shared.
#[derive(Clone)]
pub struct AppState {
    pub store: Store,
    pub auth: Arc<Authenticator>,
    pub config: Arc<Config>,
}
