use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use super::{hide, load_task};
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Comment, CommentCreate, Page},
    state::AppState,
};

pub async fn list_comments(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Comment>>, AppError> {
    user.require_scope(auth::READ)?;
    load_task(&app, &user, task_id).await?;
    Ok(Json(app.store.list_comments(task_id, &params.page()?).await?))
}

pub async fn create_comment(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<CommentCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?;
    let path = format!("/v1/tasks/{task_id}/comments");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let comment = app.store.create_comment(&user, task_id, &body.body).await?;
        Created::new(format!("/v1/comments/{}", comment.id), None, &comment)
    })
    .await
}

/// Allowed for the comment's author, a lead of the team, or an admin.
pub async fn delete_comment(
    State(app): State<AppState>,
    user: AuthUser,
    Path(comment_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    let (team_id, author_id) = app.store.comment_context(comment_id).await?;
    let access = app.store.team_access(&user, team_id).await.map_err(hide("comment"))?;
    if author_id != user.id {
        access.require_lead()?;
    }
    app.store.delete_comment(&user, comment_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
