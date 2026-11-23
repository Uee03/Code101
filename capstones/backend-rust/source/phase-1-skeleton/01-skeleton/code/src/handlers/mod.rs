use axum::http::Uri;

use crate::error::AppError;

pub mod health;
pub mod me;
pub mod teams;

pub async fn not_found(uri: Uri) -> AppError {
    AppError::NotFound(format!("There is no route for {}.", uri.path()))
}
