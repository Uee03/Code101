use axum::{
    Router,
    body::Body,
    http::Request,
    middleware,
    routing::{get, post},
};
use tower::ServiceBuilder;
use tower_http::{
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    trace::{DefaultOnResponse, TraceLayer},
};
use tracing::Level;

use crate::{error::render_problems, handlers};

pub fn router() -> Router {
    let trace = TraceLayer::new_for_http()
        .make_span_with(|request: &Request<Body>| {
            let request_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).unwrap_or("-");
            tracing::info_span!("request", method = %request.method(), path = request.uri().path(), request_id)
        })
        .on_response(DefaultOnResponse::new().level(Level::INFO));

    Router::new()
        .route("/health", get(handlers::health::get_health))
        .route("/v1/me", get(handlers::me::get_me))
        .route("/v1/teams", post(handlers::teams::create_team))
        .fallback(handlers::not_found)
        // The first layer is the outermost: it sees the request first and the response last.
        .layer(
            ServiceBuilder::new()
                .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
                .layer(PropagateRequestIdLayer::x_request_id())
                .layer(trace)
                .layer(middleware::from_fn(render_problems)),
        )
}
