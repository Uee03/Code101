use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use super::load_project;
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, Project, ProjectCreate, ProjectUpdate},
    state::AppState,
};

pub async fn list_projects(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Project>>, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    let archived = params.parse::<bool>("archived")?.unwrap_or(false);
    let projects = app.store.list_projects(team_id, archived, params.newest_first()?, &params.page()?).await?;
    Ok(Json(projects))
}

pub async fn create_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ProjectCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let path = format!("/v1/teams/{team_id}/projects");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let project = app.store.create_project(&user, team_id, &body).await?;
        Created::new(format!("/v1/projects/{}", project.id), Some(project.version), &project)
    })
    .await
}

pub async fn get_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    let (project, _) = load_project(&app, &user, project_id).await?;
    Ok(http::with_etag(StatusCode::OK, project.version, &project))
}

pub async fn update_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ProjectUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?.1.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let project = app.store.update_project(&user, project_id, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, project.version, &project))
}

pub async fn delete_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?.1.require_lead()?;
    app.store.delete_project(&user, project_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
