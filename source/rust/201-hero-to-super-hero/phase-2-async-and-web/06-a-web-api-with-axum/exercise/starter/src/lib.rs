use axum::{
    body::{to_bytes, Body},
    extract::{DefaultBodyLimit, Path},
    http::{Request, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use tower::ServiceExt;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CreateNote {
    pub title: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct NoteDto {
    pub id: u64,
    pub title: String,
}

#[derive(Serialize)]
struct ErrorDto {
    code: &'static str,
}

pub enum ApiError {
    InvalidTitle,
    NotFound,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code) = match self {
            Self::InvalidTitle => (StatusCode::UNPROCESSABLE_ENTITY, "invalid_title"),
            Self::NotFound => (StatusCode::NOT_FOUND, "not_found"),
        };
        (status, Json(ErrorDto { code })).into_response()
    }
}

pub fn valid_title(title: &str) -> bool {
    let length = title.trim().chars().count();
    // TODO: cap titles at 40 characters, still rejecting empty titles.
    (1..=80).contains(&length)
}

async fn read_note(Path(id): Path<u64>) -> Result<Json<NoteDto>, ApiError> {
    if id != 7 {
        return Err(ApiError::NotFound);
    }
    Ok(Json(NoteDto { id, title: "seed".into() }))
}

async fn create_note(Json(input): Json<CreateNote>) -> Result<(StatusCode, Json<NoteDto>), ApiError> {
    if !valid_title(&input.title) {
        return Err(ApiError::InvalidTitle);
    }
    let note = NoteDto { id: 8, title: input.title.trim().into() };
    Ok((StatusCode::CREATED, Json(note)))
}

pub fn app() -> Router {
    Router::new()
        .route("/notes/{id}", get(read_note))
        .route("/notes", post(create_note))
        .layer(DefaultBodyLimit::max(4096))
}

pub async fn self_check() -> anyhow::Result<()> {
    let response = app().oneshot(Request::builder().uri("/notes/7").body(Body::empty())?).await?;
    assert_eq!(response.status(), StatusCode::OK);
    let bytes = to_bytes(response.into_body(), 4096).await?;
    let note: NoteDto = serde_json::from_slice(&bytes)?;
    assert_eq!(note.title, "seed");
    let response = app().oneshot(Request::builder()
        .method("POST").uri("/notes").header("content-type", "application/json")
        .body(Body::from(r#"{"title":" "}"#))?).await?;
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
    println!("GET seed: 200; POST blank: 422");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn title_boundaries() {
        assert!(!valid_title(" "));
        assert!(valid_title(&"a".repeat(40)));
        assert!(!valid_title(&"a".repeat(41)));
    }

    #[tokio::test]
    async fn routes_work_without_a_socket() {
        self_check().await.unwrap();
    }

    #[tokio::test]
    async fn post_returns_a_dto() {
        let response = app().oneshot(Request::builder()
            .method("POST").uri("/notes").header("content-type", "application/json")
            .body(Body::from(r#"{"title":" Rust "}"#)).unwrap()).await.unwrap();
        assert_eq!(response.status(), StatusCode::CREATED);
        let bytes = to_bytes(response.into_body(), 4096).await.unwrap();
        let note: NoteDto = serde_json::from_slice(&bytes).unwrap();
        assert_eq!(note.title, "Rust");
    }
}
