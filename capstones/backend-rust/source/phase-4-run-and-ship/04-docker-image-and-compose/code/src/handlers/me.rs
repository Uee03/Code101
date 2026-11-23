use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    models::Me,
    state::AppState,
};

pub async fn get_me(State(app): State<AppState>, user: AuthUser) -> Result<Json<Me>, AppError> {
    user.require_scope(auth::READ)?;
    let teams = app.store.my_teams(user.id).await?;
    let roles = user.roles.iter().filter(|role| matches!(role.as_str(), "admin" | "member")).cloned().collect();
    Ok(Json(Me {
        id: user.id,
        username: user.username,
        email: user.email,
        display_name: user.display_name,
        roles,
        scopes: user.scopes,
        teams,
    }))
}
