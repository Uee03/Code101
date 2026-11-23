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
