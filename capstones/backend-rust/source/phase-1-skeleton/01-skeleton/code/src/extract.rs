use axum::{
    body::Bytes,
    extract::{FromRequest, Request},
    http::StatusCode,
};
use serde::de::DeserializeOwned;

use crate::{
    error::{AppError, FieldError},
    validation::Validate,
};

/// A JSON body that is parsed and validated before the handler runs.
/// Not JSON at all gives 400; JSON with a wrong, missing or unknown field gives 422.
pub struct ValidJson<T>(pub T);

impl<S, T> FromRequest<S> for ValidJson<T>
where
    S: Send + Sync,
    T: DeserializeOwned + Validate,
{
    type Rejection = AppError;

    async fn from_request(request: Request, state: &S) -> Result<Self, Self::Rejection> {
        let bytes = Bytes::from_request(request, state).await.map_err(|rejection| {
            if rejection.status() == StatusCode::PAYLOAD_TOO_LARGE {
                AppError::PayloadTooLarge
            } else {
                AppError::BadRequest(rejection.body_text())
            }
        })?;
        let value: T = serde_json::from_slice(&bytes).map_err(|err| {
            if err.is_data() {
                AppError::Validation(vec![FieldError::new("", err.to_string())])
            } else {
                AppError::BadRequest(format!("The body is not valid JSON: {err}"))
            }
        })?;
        value.validate()?;
        Ok(Self(value))
    }
}
