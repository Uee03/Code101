use axum::{
    extract::FromRequestParts,
    http::{HeaderMap, header, request::Parts},
};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use serde::Deserialize;
use uuid::Uuid;

use crate::{error::AppError, state::AppState};

pub const READ: &str = "tasks:read";
pub const WRITE: &str = "tasks:write";
pub const ADMIN: &str = "tasks:admin";

/// The caller, as described by the access token.
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub display_name: String,
    pub roles: Vec<String>,
    pub scopes: Vec<String>,
}

impl AuthUser {
    pub fn is_admin(&self) -> bool {
        self.roles.iter().any(|role| role == "admin")
    }

    /// The scope says what the client may do on the user's behalf. A missing scope is a 403, not a 401.
    pub fn require_scope(&self, scope: &str) -> Result<(), AppError> {
        if self.scopes.iter().any(|granted| granted == scope) {
            Ok(())
        } else {
            Err(AppError::Forbidden(format!("The {scope} scope is required.")))
        }
    }

    pub fn require_admin(&self) -> Result<(), AppError> {
        if self.is_admin() { Ok(()) } else { Err(AppError::Forbidden("The admin role is required.".to_owned())) }
    }
}

#[derive(Debug, Deserialize)]
pub struct Claims {
    pub sub: Uuid,
    pub preferred_username: Option<String>,
    pub email: Option<String>,
    pub name: Option<String>,
    #[serde(default)]
    pub scope: String,
    pub realm_access: Option<RealmAccess>,
}

#[derive(Debug, Deserialize)]
pub struct RealmAccess {
    #[serde(default)]
    pub roles: Vec<String>,
}

impl From<Claims> for AuthUser {
    fn from(claims: Claims) -> Self {
        let username = claims.preferred_username.unwrap_or_else(|| format!("user-{}", claims.sub.simple()));
        Self {
            id: claims.sub,
            email: claims.email.unwrap_or_else(|| format!("{username}@unknown.invalid")),
            display_name: claims.name.filter(|name| !name.trim().is_empty()).unwrap_or_else(|| username.clone()),
            username,
            roles: claims.realm_access.map(|access| access.roles).unwrap_or_default(),
            scopes: claims.scope.split_whitespace().map(str::to_owned).collect(),
        }
    }
}

/// UNSAFE, for phase 2 only: reads the payload of the token and trusts it. A forged token with
/// `"realm_access": {"roles": ["admin"]}` would be accepted. Phase 3 replaces this with real validation.
fn unverified_claims(token: &str) -> Result<Claims, AppError> {
    let payload = token.split('.').nth(1).ok_or(AppError::InvalidToken)?;
    let bytes = URL_SAFE_NO_PAD.decode(payload).map_err(|_| AppError::InvalidToken)?;
    serde_json::from_slice(&bytes).map_err(|_| AppError::InvalidToken)
}

fn bearer_token(headers: &HeaderMap) -> Result<&str, AppError> {
    let value = headers.get(header::AUTHORIZATION).ok_or(AppError::Unauthorized)?;
    let value = value.to_str().map_err(|_| AppError::InvalidToken)?;
    match value.split_once(' ') {
        Some((scheme, token)) if scheme.eq_ignore_ascii_case("bearer") && !token.trim().is_empty() => Ok(token.trim()),
        _ => Err(AppError::Unauthorized),
    }
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, state: &AppState) -> Result<Self, AppError> {
        let token = bearer_token(&parts.headers)?;
        let user = AuthUser::from(unverified_claims(token)?);
        state.store.ensure_user(&user).await?;
        Ok(user)
    }
}
