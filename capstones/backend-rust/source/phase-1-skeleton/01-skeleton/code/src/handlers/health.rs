use axum::Json;

use crate::models::Health;

pub async fn get_health() -> Json<Health> {
    Json(Health { status: "ok", version: env!("CARGO_PKG_VERSION") })
}
