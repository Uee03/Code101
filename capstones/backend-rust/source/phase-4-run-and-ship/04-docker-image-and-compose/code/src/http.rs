use std::future::Future;

use axum::{
    Json,
    http::{HeaderMap, HeaderValue, StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::{auth::AuthUser, error::AppError, state::AppState, store::idempotency::Claim};

/// The strong ETag of a resource is its quoted `version`.
pub fn etag(version: i32) -> String {
    format!("\"{version}\"")
}

pub fn with_etag<T: Serialize>(status: StatusCode, version: i32, body: &T) -> Response {
    (status, [(header::ETAG, etag(version))], Json(body)).into_response()
}

fn parse_etag(value: &str) -> Option<i32> {
    value.trim().strip_prefix('"')?.strip_suffix('"')?.parse().ok()
}

/// `If-Match` is optional here (task delete); a value that is not one of our ETags never matches (412).
pub fn optional_if_match(headers: &HeaderMap) -> Result<Option<i32>, AppError> {
    let Some(value) = headers.get(header::IF_MATCH) else { return Ok(None) };
    let version = value.to_str().ok().and_then(parse_etag);
    version
        .map(Some)
        .ok_or_else(|| AppError::PreconditionFailed("The If-Match value is not a current ETag.".to_owned()))
}

/// Updates must say which version they were based on: missing is 428, stale is 412 (decided by the store).
pub fn require_if_match(headers: &HeaderMap) -> Result<i32, AppError> {
    optional_if_match(headers)?.ok_or(AppError::PreconditionRequired)
}

pub fn if_none_match_hit(headers: &HeaderMap, version: i32) -> bool {
    let Some(value) = headers.get(header::IF_NONE_MATCH).and_then(|value| value.to_str().ok()) else {
        return false;
    };
    let current = etag(version);
    value.split(',').map(str::trim).any(|candidate| candidate == "*" || candidate.trim_start_matches("W/") == current)
}

/// What a create answered, kept in `idempotency_keys.response_body` so a retry can get the same answer.
#[derive(Debug, Serialize, Deserialize)]
pub struct Created {
    pub location: String,
    pub etag: Option<String>,
    pub body: serde_json::Value,
}

impl Created {
    pub fn new<T: Serialize>(location: String, version: Option<i32>, body: &T) -> Result<Self, AppError> {
        let body = serde_json::to_value(body).map_err(|err| AppError::Internal(err.to_string()))?;
        Ok(Self { location, etag: version.map(etag), body })
    }
}

fn created_response(base_url: &str, created: Created, replayed: bool) -> Response {
    let mut response = (StatusCode::CREATED, Json(created.body)).into_response();
    let headers = response.headers_mut();
    if let Ok(location) = HeaderValue::from_str(&format!("{base_url}{}", created.location)) {
        headers.insert(header::LOCATION, location);
    }
    if let Some(etag) = created.etag.and_then(|etag| HeaderValue::from_str(&etag).ok()) {
        headers.insert(header::ETAG, etag);
    }
    if replayed {
        headers.insert("idempotent-replayed", HeaderValue::from_static("true"));
    }
    response
}

fn idempotency_key(headers: &HeaderMap) -> Result<Option<String>, AppError> {
    let Some(value) = headers.get("idempotency-key") else { return Ok(None) };
    let key = value.to_str().map_err(|_| AppError::BadRequest("The Idempotency-Key is not text.".to_owned()))?;
    if (8..=128).contains(&key.len()) {
        Ok(Some(key.to_owned()))
    } else {
        Err(AppError::BadRequest("The Idempotency-Key must be 8 to 128 characters.".to_owned()))
    }
}

/// Runs `create` once per `Idempotency-Key`. Without a key it just runs.
pub async fn create_once<B, F, Fut>(
    app: &AppState,
    user: &AuthUser,
    headers: &HeaderMap,
    path: &str,
    request_body: &B,
    create: F,
) -> Result<Response, AppError>
where
    B: Serialize,
    F: FnOnce() -> Fut,
    Fut: Future<Output = Result<Created, AppError>>,
{
    let base_url = &app.config.public_base_url;
    let Some(key) = idempotency_key(headers)? else {
        return Ok(created_response(base_url, create().await?, false));
    };
    let fingerprint = format!("{path}\n{}", serde_json::to_string(request_body).unwrap_or_default());
    let request_hash = hex::encode(Sha256::digest(fingerprint.as_bytes()));
    match app.store.claim_key(user.id, &key, &request_hash).await? {
        Claim::Fresh => match create().await {
            Ok(created) => {
                let stored = serde_json::to_value(&created).map_err(|err| AppError::Internal(err.to_string()))?;
                app.store.finish_key(user.id, &key, &stored).await?;
                Ok(created_response(base_url, created, false))
            }
            Err(err) => {
                app.store.release_key(user.id, &key).await?;
                Err(err)
            }
        },
        Claim::Replay(stored) => {
            let created = serde_json::from_value(stored).map_err(|err| AppError::Internal(err.to_string()))?;
            Ok(created_response(base_url, created, true))
        }
        Claim::Mismatch => {
            Err(AppError::Unprocessable("This Idempotency-Key was already used with a different request.".to_owned()))
        }
        Claim::InProgress => Err(AppError::conflict("A request with this Idempotency-Key is still running.")),
    }
}
