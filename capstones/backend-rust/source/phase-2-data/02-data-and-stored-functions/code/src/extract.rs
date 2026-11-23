use std::str::FromStr;

use axum::{
    body::Bytes,
    extract::{FromRequest, FromRequestParts, Request},
    http::{StatusCode, request::Parts},
};
use serde::de::DeserializeOwned;

use crate::{
    error::{AppError, FieldError},
    store::page::PageRequest,
    validation::Validate,
};

/// The query string as a list of pairs, so a parameter may repeat (`status=todo&status=done`).
/// Every bad value is a 400 that names the parameter.
pub struct Params(Vec<(String, String)>);

impl<S: Send + Sync> FromRequestParts<S> for Params {
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, AppError> {
        let query = parts.uri.query().unwrap_or("");
        let pairs = serde_urlencoded::from_str(query)
            .map_err(|_| AppError::BadRequest("The query string is not valid.".to_owned()))?;
        Ok(Self(pairs))
    }
}

fn invalid(name: &str) -> AppError {
    AppError::BadRequest(format!("The query parameter {name} is not valid."))
}

impl Params {
    fn first(&self, name: &str) -> Option<&str> {
        self.0.iter().find(|(key, _)| key == name).map(|(_, value)| value.as_str())
    }

    pub fn parse<T: FromStr>(&self, name: &str) -> Result<Option<T>, AppError> {
        self.first(name).map(|value| value.parse().map_err(|_| invalid(name))).transpose()
    }

    /// Every value of a repeated parameter.
    pub fn all<T: FromStr>(&self, name: &str) -> Result<Vec<T>, AppError> {
        self.0
            .iter()
            .filter(|(key, _)| key == name)
            .map(|(_, value)| value.parse().map_err(|_| invalid(name)))
            .collect()
    }

    pub fn text(&self, name: &str, max: usize) -> Result<Option<String>, AppError> {
        match self.first(name) {
            None => Ok(None),
            Some(value) if (1..=max).contains(&value.chars().count()) => Ok(Some(value.to_owned())),
            Some(_) => Err(invalid(name)),
        }
    }

    /// `limit` 1 to 100 (default 25) and the opaque `cursor`.
    pub fn page(&self) -> Result<PageRequest, AppError> {
        let limit = self.parse::<i64>("limit")?.unwrap_or(25);
        if !(1..=100).contains(&limit) {
            return Err(invalid("limit"));
        }
        Ok(PageRequest { limit, cursor: self.text("cursor", 512)? })
    }

    /// `sort=-createdAt` (the default) is newest first, `sort=createdAt` oldest first.
    pub fn newest_first(&self) -> Result<bool, AppError> {
        match self.first("sort") {
            None | Some("-createdAt") => Ok(true),
            Some("createdAt") => Ok(false),
            Some(_) => Err(invalid("sort")),
        }
    }
}

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
