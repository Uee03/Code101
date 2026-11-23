use std::sync::Arc;

use crate::{config::Config, store::Store};

/// Everything a handler may need. Cloning is cheap: the pool and the config are shared.
#[derive(Clone)]
pub struct AppState {
    pub store: Store,
    pub config: Arc<Config>,
}
