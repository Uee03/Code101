use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode, header},
    response::{IntoResponse, Response},
};
use uuid::Uuid;

use super::{load_project, load_task};
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, ReassignRequest, Task, TaskCreate, TaskUpdate},
    state::AppState,
    store::tasks::TaskFilter,
};

pub async fn list_tasks(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Task>>, AppError> {
    user.require_scope(auth::READ)?;
    load_project(&app, &user, project_id).await?;
    let filter = TaskFilter {
        statuses: params.all("status")?,
        priorities: params.all("priority")?,
        assignee_id: params.parse("assigneeId")?,
        due_before: params.parse("dueBefore")?,
        due_after: params.parse("dueAfter")?,
        q: params.text("q", 100)?,
        sort: params.parse("sort")?.unwrap_or_default(),
    };
    Ok(Json(app.store.list_tasks(project_id, &filter, &params.page()?).await?))
}

pub async fn create_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TaskCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?;
    let path = format!("/v1/projects/{project_id}/tasks");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let task = app.store.create_task(&user, project_id, &body).await?;
        Created::new(format!("/v1/tasks/{}", task.id), Some(task.version), &task)
    })
    .await
}

pub async fn get_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    let (task, _) = load_task(&app, &user, task_id).await?;
    if http::if_none_match_hit(&headers, task.version) {
        return Ok((StatusCode::NOT_MODIFIED, [(header::ETAG, http::etag(task.version))]).into_response());
    }
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}

pub async fn update_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TaskUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    let (task, _) = load_task(&app, &user, task_id).await?;
    let version = http::require_if_match(&headers)?;
    let updated = app.store.update_task(&user, &task, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, updated.version, &updated))
}

pub async fn delete_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?.1.require_lead()?;
    app.store.delete_task(&user, task_id, http::optional_if_match(&headers)?).await?;
    Ok(StatusCode::NO_CONTENT)
}

/// The rules live in the `complete_task` stored function; this handler only checks who may call it.
pub async fn complete_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?;
    let version = http::require_if_match(&headers)?;
    let task = app.store.complete_task(&user, task_id, version).await?;
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}

pub async fn reassign_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ReassignRequest>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?.1.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let task = app.store.reassign_task(&user, task_id, body.assignee_id, version).await?;
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}
