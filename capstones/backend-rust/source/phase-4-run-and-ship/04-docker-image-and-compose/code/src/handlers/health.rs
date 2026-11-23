use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};

use crate::{models::Health, state::AppState};

pub async fn get_health(State(app): State<AppState>) -> Response {
    let up = app.store.ping().await;
    let health = Health {
        status: if up { "ok" } else { "degraded" },
        version: env!("CARGO_PKG_VERSION"),
        database: Some(if up { "up" } else { "down" }),
    };
    let status = if up { StatusCode::OK } else { StatusCode::SERVICE_UNAVAILABLE };
    (status, Json(health)).into_response()
}
