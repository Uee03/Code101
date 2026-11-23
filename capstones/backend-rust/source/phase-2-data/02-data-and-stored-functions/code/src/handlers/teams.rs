use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, Team, TeamCreate, TeamUpdate},
    state::AppState,
};

pub async fn list_teams(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<Team>>, AppError> {
    user.require_scope(auth::READ)?;
    let q = params.text("q", 100)?;
    let teams = app.store.list_teams(&user, q.as_deref(), params.newest_first()?, &params.page()?).await?;
    Ok(Json(teams))
}

pub async fn create_team(
    State(app): State<AppState>,
    user: AuthUser,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TeamCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    user.require_admin()?;
    http::create_once(&app, &user, &headers, "/v1/teams", &body, || async {
        let team = app.store.create_team(&user, &body).await?;
        Created::new(format!("/v1/teams/{}", team.id), Some(team.version), &team)
    })
    .await
}

pub async fn get_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    let team = app.store.team(team_id).await?;
    Ok(http::with_etag(StatusCode::OK, team.version, &team))
}

pub async fn update_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TeamUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let team = app.store.update_team(&user, team_id, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, team.version, &team))
}

pub async fn delete_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::ADMIN)?;
    user.require_admin()?;
    app.store.delete_team(&user, team_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
