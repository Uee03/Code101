use axum::response::Response;

use crate::{error::AppError, extract::ValidJson, models::TeamCreate};

/// Phase 1 only validates the body. Phase 2 stores the team with the `create_team` function.
pub async fn create_team(ValidJson(_body): ValidJson<TeamCreate>) -> Result<Response, AppError> {
    Err(AppError::NotImplemented("Teams are stored from phase 2 on.".to_owned()))
}
