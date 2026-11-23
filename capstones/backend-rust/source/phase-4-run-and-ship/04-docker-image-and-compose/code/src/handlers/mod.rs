use axum::http::Uri;
use uuid::Uuid;

use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Project, Task},
    state::AppState,
    store::teams::Access,
};

pub mod audit;
pub mod comments;
pub mod health;
pub mod me;
pub mod members;
pub mod projects;
pub mod tasks;
pub mod teams;
pub mod users;

pub async fn not_found(uri: Uri) -> AppError {
    AppError::NotFound(format!("There is no route for {}.", uri.path()))
}

/// A caller outside the team must not learn that the object exists: they get the 404 text of a missing id.
fn hide(what: &'static str) -> impl FnOnce(AppError) -> AppError {
    move |err| match err {
        AppError::NotFound(_) => AppError::NotFound(format!("The {what} does not exist.")),
        other => other,
    }
}

pub async fn load_project(app: &AppState, user: &AuthUser, project_id: Uuid) -> Result<(Project, Access), AppError> {
    let project = app.store.project(project_id).await?;
    let access = app.store.team_access(user, project.team_id).await.map_err(hide("project"))?;
    Ok((project, access))
}

pub async fn load_task(app: &AppState, user: &AuthUser, task_id: Uuid) -> Result<(Task, Access), AppError> {
    let task = app.store.task(task_id).await?;
    let team_id = app.store.team_of_project(task.project_id).await?;
    let access = app.store.team_access(user, team_id).await.map_err(hide("task"))?;
    Ok((task, access))
}
