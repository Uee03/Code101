use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::Params,
    models::{Page, UserSummary},
    state::AppState,
};

pub async fn list_users(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<UserSummary>>, AppError> {
    user.require_scope(auth::READ)?;
    let q = params.text("q", 100)?;
    Ok(Json(app.store.list_users(q.as_deref(), &params.page()?).await?))
}
