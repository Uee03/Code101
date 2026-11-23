use axum::{
    body::Body,
    extract::{Request, State},
    http::{header, StatusCode},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::get,
    Extension, Json, Router,
};
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use tower::{ServiceBuilder, ServiceExt};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Claims {
    pub sub: String,
    pub exp: u64,
    pub nbf: u64,
    pub iss: String,
    pub aud: String,
}

#[derive(Clone)]
pub struct Auth {
    key: DecodingKey,
    validation: Validation,
}

impl Auth {
    pub fn new(secret: &[u8]) -> anyhow::Result<Self> {
        anyhow::ensure!(secret.len() >= 32, "JWT_SECRET needs at least 32 bytes");
        let mut validation = Validation::new(Algorithm::HS256);
        validation.set_issuer(&["code101-local"]);
        validation.set_audience(&["notes-api"]);
        validation.set_required_spec_claims(&["exp", "nbf", "iss", "aud", "sub"]);
        validation.validate_nbf = true;
        validation.leeway = 0;
        // TODO: restrict the subject to reader using Validation.sub.
        Ok(Self { key: DecodingKey::from_secret(secret), validation })
    }

    pub fn verify(&self, token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
        let data = decode::<Claims>(token, &self.key, &self.validation)?;
        Ok(data.claims)
    }
}

fn unauthorized() -> Response {
    let mut response = (StatusCode::UNAUTHORIZED, "unauthorized").into_response();
    response.headers_mut().insert(header::WWW_AUTHENTICATE, "Bearer".parse().unwrap());
    response
}

async fn authenticate(State(auth): State<Auth>, mut request: Request, next: Next) -> Response {
    let claims = request.headers().get(header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "))
        .and_then(|token| auth.verify(token).ok());
    match claims {
        Some(claims) if !claims.sub.trim().is_empty() => {
            request.extensions_mut().insert(claims);
            next.run(request).await
        }
        _ => unauthorized(),
    }
}

#[derive(Serialize)]
struct Me {
    subject: String,
}

async fn me(Extension(claims): Extension<Claims>) -> Json<Me> {
    Json(Me { subject: claims.sub })
}

pub fn app(auth: Auth) -> Router {
    let protected = Router::new().route("/me", get(me))
        .route_layer(ServiceBuilder::new().layer(middleware::from_fn_with_state(auth, authenticate)));
    Router::new().route("/health", get(|| async { "ok" })).merge(protected)
}

pub async fn self_check(auth: Auth) -> anyhow::Result<()> {
    let request = Request::builder().uri("/me").body(Body::empty())?;
    let response = app(auth).oneshot(request).await?;
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    println!("missing bearer: 401");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use jsonwebtoken::{encode, EncodingKey, Header};

    fn bearer_headers(token: &str) -> axum::http::HeaderMap {
        let mut headers = axum::http::HeaderMap::new();
        headers.insert(header::AUTHORIZATION, format!("Bearer {token}").parse().unwrap());
        headers
    }


    // Public, test-only bytes; never used by the running server.
    const TEST_KEY: &[u8] = b"test-only-not-a-real-secret-32-bytes";

    fn claims() -> Claims {
        Claims { sub: "reader".into(), exp: 4_102_444_800, nbf: 0,
            iss: "code101-local".into(), aud: "notes-api".into() }
    }

    fn token(claims: &Claims, key: &[u8]) -> String {
        encode(&Header::new(Algorithm::HS256), claims, &EncodingKey::from_secret(key)).unwrap()
    }

    #[test]
    fn rejects_wrong_audience_expiry_and_signature() {
        let auth = Auth::new(TEST_KEY).unwrap();
        assert_eq!(auth.verify(&token(&claims(), TEST_KEY)).unwrap().sub, "reader");
        let mut wrong = claims();
        wrong.aud = "other-api".into();
        assert!(auth.verify(&token(&wrong, TEST_KEY)).is_err());
        wrong = claims();
        wrong.sub = "writer".into();
        assert!(auth.verify(&token(&wrong, TEST_KEY)).is_err());
        wrong = claims();
        wrong.iss = "unknown-issuer".into();
        assert!(auth.verify(&token(&wrong, TEST_KEY)).is_err());
        wrong = claims();
        wrong.nbf = 4_102_444_800;
        assert!(auth.verify(&token(&wrong, TEST_KEY)).is_err());
        wrong = claims();
        wrong.exp = 1;
        assert!(auth.verify(&token(&wrong, TEST_KEY)).is_err());
        assert!(auth.verify(&token(&claims(), b"different-test-key-not-for-production")).is_err());
    }

    #[tokio::test]
    async fn layer_accepts_valid_token_and_rejects_missing_token() {
        let auth = Auth::new(TEST_KEY).unwrap();
        self_check(auth.clone()).await.unwrap();
        let signed = token(&claims(), TEST_KEY);
        let mut request = Request::builder().uri("/me").body(Body::empty()).unwrap();
        *request.headers_mut() = bearer_headers(&signed);
        assert_eq!(app(auth).oneshot(request).await.unwrap().status(), StatusCode::OK);
    }
}
