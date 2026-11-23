use axum::{
    Json,
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
};
use uuid::Uuid;

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    models::{Member, MemberPut, Page},
    state::AppState,
};

pub async fn list_members(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Member>>, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    Ok(Json(app.store.list_members(team_id, &params.page()?).await?))
}

pub async fn put_member(
    State(app): State<AppState>,
    user: AuthUser,
    Path((team_id, member_id)): Path<(Uuid, Uuid)>,
    ValidJson(body): ValidJson<MemberPut>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let (member, created) = app.store.put_member(&user, team_id, member_id, body.role).await?;
    let status = if created { StatusCode::CREATED } else { StatusCode::OK };
    Ok((status, Json(member)).into_response())
}

pub async fn remove_member(
    State(app): State<AppState>,
    user: AuthUser,
    Path((team_id, member_id)): Path<(Uuid, Uuid)>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    app.store.remove_member(&user, team_id, member_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
