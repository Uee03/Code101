use axum::{body::Body, http::{Request, StatusCode}};
use tower::ServiceExt;

#[tokio::test]
async fn lifecycle() {
    notes_api::self_check().await.unwrap();
}

#[tokio::test]
async fn empty_title_is_rejected() {
    let response = notes_api::app().oneshot(Request::builder()
        .method("POST").uri("/notes").header("content-type", "application/json")
        .body(Body::from(r#"{"title":" "}"#)).unwrap()).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn version_is_available() {
    let response = notes_api::app().oneshot(Request::builder()
        .uri("/version").body(Body::empty()).unwrap()).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);
    let bytes = axum::body::to_bytes(response.into_body(), 4096).await.unwrap();
    assert_eq!(bytes.as_ref(), b"0.1.0");
}
