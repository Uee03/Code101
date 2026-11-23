use axum::{
    Router,
    body::Body,
    http::Request,
    middleware,
    routing::{delete, get, post, put},
};
use tower::ServiceBuilder;
use tower_http::{
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    trace::{DefaultOnResponse, TraceLayer},
};
use tracing::Level;

use crate::{
    error::render_problems,
    handlers::{self, audit, comments, health, me, members, projects, tasks, teams, users},
    state::AppState,
};

pub fn router(state: AppState) -> Router {
    let trace = TraceLayer::new_for_http()
        .make_span_with(|request: &Request<Body>| {
            let request_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).unwrap_or("-");
            tracing::info_span!("request", method = %request.method(), path = request.uri().path(), request_id)
        })
        .on_response(DefaultOnResponse::new().level(Level::INFO));

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
                .layer(middleware::from_fn(render_problems)),
        )
}
