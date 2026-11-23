use axum::{
    body::{to_bytes, Body},
    extract::{DefaultBodyLimit, Path, State},
    http::{Request, StatusCode},
    response::{IntoResponse, Response},
    routing::get,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::{collections::BTreeMap, sync::Arc};
use tokio::sync::Mutex;
use tower::ServiceExt;

const MAX_NOTES: usize = 100;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Note {
    pub id: u64,
    pub title: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CreateNote {
    pub title: String,
}

#[derive(Default)]
struct Store {
    next_id: u64,
    notes: BTreeMap<u64, Note>,
}

type Shared = Arc<Mutex<Store>>;

pub enum ApiError {
    InvalidTitle,
    NotFound,
    Full,
}

#[derive(Serialize)]
struct ErrorDto {
    code: &'static str,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code) = match self {
            Self::InvalidTitle => (StatusCode::UNPROCESSABLE_ENTITY, "invalid_title"),
            Self::NotFound => (StatusCode::NOT_FOUND, "not_found"),
            Self::Full => (StatusCode::CONFLICT, "store_full"),
        };
        (status, Json(ErrorDto { code })).into_response()
    }
}

pub fn normalize_title(input: &str) -> Result<String, ApiError> {
    let title = input.trim();
    if !(1..=80).contains(&title.chars().count()) {
        return Err(ApiError::InvalidTitle);
    }
    Ok(title.to_owned())
}

async fn create(State(state): State<Shared>, Json(input): Json<CreateNote>)
    -> Result<(StatusCode, Json<Note>), ApiError>
{
    let title = normalize_title(&input.title)?;
    let note = {
        let mut store = state.lock().await;
        if store.notes.len() >= MAX_NOTES {
            return Err(ApiError::Full);
        }
        store.next_id = store.next_id.checked_add(1).ok_or(ApiError::Full)?;
        let note = Note { id: store.next_id, title };
        store.notes.insert(note.id, note.clone());
        note
    };
    tracing::info!(note_id = note.id, "note_created");
    Ok((StatusCode::CREATED, Json(note)))
}

async fn list(State(state): State<Shared>) -> Json<Vec<Note>> {
    let notes = state.lock().await.notes.values().cloned().collect();
    Json(notes)
}

async fn read(State(state): State<Shared>, Path(id): Path<u64>) -> Result<Json<Note>, ApiError> {
    let store = state.lock().await;
    store.notes.get(&id).cloned().map(Json).ok_or(ApiError::NotFound)
}

async fn remove(State(state): State<Shared>, Path(id): Path<u64>) -> Result<StatusCode, ApiError> {
    let mut store = state.lock().await;
    store.notes.remove(&id).ok_or(ApiError::NotFound)?;
    Ok(StatusCode::NO_CONTENT)
}

pub fn app() -> Router {
    Router::new()
        .route("/health", get(|| async { "ok" }))
        .route("/version", get(|| async { "0.1.0" }))
        .route("/notes", get(list).post(create))
        .route("/notes/{id}", get(read).delete(remove))
        .layer(DefaultBodyLimit::max(4096))
        .with_state(Arc::new(Mutex::new(Store::default())))
}

pub async fn self_check() -> anyhow::Result<()> {
    let app = app();
    let response = app.clone().oneshot(Request::builder()
        .method("POST").uri("/notes").header("content-type", "application/json")
        .body(Body::from(r#"{"title":" Rust "}"#))?).await?;
    assert_eq!(response.status(), StatusCode::CREATED);
    let bytes = to_bytes(response.into_body(), 4096).await?;
    let note: Note = serde_json::from_slice(&bytes)?;
    assert_eq!(note.id, 1);
    assert_eq!(note.title, "Rust");
    let response = app.clone().oneshot(Request::builder().uri("/notes/1").body(Body::empty())?).await?;
    assert_eq!(response.status(), StatusCode::OK);
    let response = app.clone().oneshot(Request::builder()
        .method("DELETE").uri("/notes/1").body(Body::empty())?).await?;
    assert_eq!(response.status(), StatusCode::NO_CONTENT);
    let response = app.oneshot(Request::builder().uri("/notes/1").body(Body::empty())?).await?;
    assert_eq!(response.status(), StatusCode::NOT_FOUND);
    println!("create: 201; read: 200; delete: 204; missing: 404");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn title_policy() {
        assert!(normalize_title(" Rust ").is_ok());
        assert!(normalize_title(" ").is_err());
        assert!(normalize_title(&"a".repeat(81)).is_err());
    }
}
