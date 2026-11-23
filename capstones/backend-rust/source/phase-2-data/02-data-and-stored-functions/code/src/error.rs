use axum::{
    body::{self, Body},
    extract::Request,
    http::{HeaderValue, StatusCode, header},
    middleware::Next,
    response::{IntoResponse, Response},
};
use serde::Serialize;

const PROBLEM_BASE: &str = "https://code101.example/problems/";

#[derive(Debug, Clone, Serialize)]
pub struct FieldError {
    pub pointer: String,
    pub detail: String,
}

impl FieldError {
    pub fn new(pointer: &str, detail: impl Into<String>) -> Self {
        Self { pointer: pointer.to_owned(), detail: detail.into() }
    }
}

/// Every failure a handler can return. The `IntoResponse` impl below is the only place that knows
/// how an error looks on the wire.
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("bad request: {0}")]
    BadRequest(String),
    #[error("a bearer access token is required")]
    Unauthorized,
    #[error("invalid bearer token")]
    InvalidToken,
    #[error("forbidden: {0}")]
    Forbidden(String),
    #[error("not found: {0}")]
    NotFound(String),
    #[error("conflict: {detail}")]
    Conflict { detail: String, code: Option<&'static str> },
    #[error("precondition failed: {0}")]
    PreconditionFailed(String),
    #[error("request body too large")]
    PayloadTooLarge,
    #[error("validation failed")]
    Validation(Vec<FieldError>),
    #[error("unprocessable: {0}")]
    Unprocessable(String),
    #[error("If-Match is required")]
    PreconditionRequired,
    #[error("rate limit exceeded")]
    RateLimited { retry_after: u64 },
    #[error("not implemented: {0}")]
    NotImplemented(String),
    #[error("internal error: {0}")]
    Internal(String),
}

/// RFC 9457 problem details. `instance` and `trace_id` are filled in by `render_problems`.
#[derive(Debug, Clone, Serialize)]
pub struct Problem {
    #[serde(rename = "type")]
    pub kind: String,
    pub title: String,
    pub status: u16,
    pub detail: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instance: Option<String>,
    #[serde(rename = "traceId", skip_serializing_if = "Option::is_none")]
    pub trace_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<&'static str>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub errors: Vec<FieldError>,
}

impl Problem {
    fn new(status: StatusCode, slug: &str, title: &str, detail: impl Into<String>) -> Self {
        Self {
            kind: format!("{PROBLEM_BASE}{slug}"),
            title: title.to_owned(),
            status: status.as_u16(),
            detail: detail.into(),
            instance: None,
            trace_id: None,
            code: None,
            errors: Vec::new(),
        }
    }

    /// For answers produced by the framework itself (a 405, a bad path id, a 413).
    fn from_status(status: StatusCode, text: String) -> Self {
        let slug = match status {
            StatusCode::NOT_FOUND => "not-found",
            StatusCode::PAYLOAD_TOO_LARGE => "payload-too-large",
            s if s.is_server_error() => "internal-error",
            _ => "bad-request",
        };
        let title = status.canonical_reason().unwrap_or("Error");
        let detail = if status.is_server_error() {
            "An unexpected error occurred.".to_owned()
        } else if text.is_empty() {
            title.to_owned()
        } else {
            text
        };
        Self::new(status, slug, title, detail)
    }
}

impl AppError {
    pub fn conflict(detail: impl Into<String>) -> Self {
        Self::Conflict { detail: detail.into(), code: None }
    }

    fn problem(&self) -> Problem {
        use StatusCode as S;
        match self {
            Self::BadRequest(detail) => Problem::new(S::BAD_REQUEST, "bad-request", "Bad request", detail),
            Self::Unauthorized => Problem::new(S::UNAUTHORIZED, "unauthorized", "Unauthorized", self.to_string()),
            Self::InvalidToken => Problem::new(S::UNAUTHORIZED, "unauthorized", "Unauthorized", self.to_string()),
            Self::Forbidden(detail) => Problem::new(S::FORBIDDEN, "forbidden", "Forbidden", detail),
            Self::NotFound(detail) => Problem::new(S::NOT_FOUND, "not-found", "Not found", detail),
            Self::Conflict { detail, code } => {
                let mut problem = Problem::new(S::CONFLICT, "conflict", "Conflict", detail);
                problem.code = *code;
                problem
            }
            Self::PreconditionFailed(detail) => {
                Problem::new(S::PRECONDITION_FAILED, "precondition-failed", "Precondition failed", detail)
            }
            Self::PayloadTooLarge => {
                Problem::new(S::PAYLOAD_TOO_LARGE, "payload-too-large", "Payload too large", self.to_string())
            }
            Self::Validation(errors) => {
                let mut problem = Problem::new(
                    S::UNPROCESSABLE_ENTITY,
                    "validation-error",
                    "Validation failed",
                    "One or more fields are invalid.",
                );
                problem.errors = errors.clone();
                problem
            }
            Self::Unprocessable(detail) => {
                Problem::new(S::UNPROCESSABLE_ENTITY, "validation-error", "Validation failed", detail)
            }
            Self::PreconditionRequired => Problem::new(
                S::PRECONDITION_REQUIRED,
                "precondition-required",
                "Precondition required",
                "Send the ETag you last read in an If-Match header.",
            ),
            Self::RateLimited { .. } => {
                Problem::new(S::TOO_MANY_REQUESTS, "rate-limited", "Too many requests", "Slow down and retry later.")
            }
            Self::NotImplemented(detail) => {
                Problem::new(S::NOT_IMPLEMENTED, "not-implemented", "Not implemented", detail)
            }
            Self::Internal(_) => Problem::new(
                S::INTERNAL_SERVER_ERROR,
                "internal-error",
                "Internal server error",
                "An unexpected error occurred.",
            ),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        if let Self::Internal(message) = &self {
            tracing::error!(%message, "internal error");
        }
        let problem = self.problem();
        let mut response =
            StatusCode::from_u16(problem.status).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR).into_response();
        let headers = response.headers_mut();
        match self {
            Self::Unauthorized => {
                headers.insert(header::WWW_AUTHENTICATE, HeaderValue::from_static(r#"Bearer realm="tasksteams""#));
            }
            Self::InvalidToken => {
                headers.insert(
                    header::WWW_AUTHENTICATE,
                    HeaderValue::from_static(r#"Bearer realm="tasksteams", error="invalid_token""#),
                );
            }
            Self::RateLimited { retry_after } => {
                headers.insert(header::RETRY_AFTER, HeaderValue::from(retry_after));
            }
            _ => {}
        }
        response.extensions_mut().insert(problem);
        response
    }
}

/// Middleware: turns every error answer into `application/problem+json` and adds `instance` and `traceId`.
pub async fn render_problems(request: Request, next: Next) -> Response {
    let instance = request.uri().path().to_owned();
    let trace_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).map(str::to_owned);
    let response = next.run(request).await;
    let status = response.status();
    let (mut parts, body) = response.into_parts();
    let mut problem = match parts.extensions.remove::<Problem>() {
        Some(problem) => problem,
        None if status.is_client_error() || status.is_server_error() => {
            let text = match body::to_bytes(body, 1024).await {
                Ok(bytes) => String::from_utf8_lossy(&bytes).into_owned(),
                Err(_) => String::new(),
            };
            if status.is_server_error() {
                tracing::error!(%status, %text, "error answered by the framework");
            }
            Problem::from_status(status, text)
        }
        None => return Response::from_parts(parts, body),
    };
    problem.instance = Some(instance);
    problem.trace_id = trace_id;
    let bytes = serde_json::to_vec(&problem).unwrap_or_default();
    parts.headers.remove(header::CONTENT_LENGTH);
    parts.headers.insert(header::CONTENT_TYPE, HeaderValue::from_static("application/problem+json"));
    Response::from_parts(parts, Body::from(bytes))
}
