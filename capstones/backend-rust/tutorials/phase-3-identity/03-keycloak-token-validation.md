---
track: capstone
level: 301
phase: 3
phase_name: identity
lesson: 03
title: "Keycloak token validation"
time: 90 min
prerequisites: [capstone-backend-rust-02, capstone-platform-03]
versions: { rust: "1.100.0", jsonwebtoken: "12.0.0", reqwest: "0.13.5", keycloak_image: "quay.io/keycloak/keycloak:26.8.2" }
verified: 2026-11-23 on Windows 11, Rust 1.100.0, Docker CLI/Engine 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-rust/source/phase-3-identity/03-keycloak-token-validation/
assets: []
---

# 03. Keycloak token validation

## Why it matters
At passport control the officer does not just read the name on the passport; they check the hologram, the stamp, the expiry date and that it is a passport of *this* kind for *this* country. Reading is not checking. In chapter 02 our API only read the token, and you walked through the border with a passport you printed yourself. This chapter makes the API a real border officer: it checks the signature with the issuer's public key, the issuer, the audience, the dates, and then applies roles and scopes.

## What you will build
`src/jwks.rs`, an `Authenticator` that validates Keycloak access tokens with the `jsonwebtoken` crate and a cached JWKS (the issuer's public keys), and the one-line change in `AuthUser` that uses it. Afterwards the forged token of chapter 02 gets a 401, bob (a member) is refused on admin routes even though his token carries the admin *scope*, and the conformance script still passes **17 of 18** checks (the `RateLimit-*` headers are chapter 05).

## Before you start
- Chapter 02 done (or its pack unzipped). This chapter's pack is `backend-rust-phase-3-identity.zip`, folder `03-keycloak-token-validation/code`, the whole project at the end of the chapter.
- Docker running, host ports 5432, 8000 and 8180 free.
- Unchanged from chapters 01 and 02, so not repeated here: `src/app.rs`, `error.rs`, `extract.rs`, `http.rs`, `models.rs`, `validation.rs`, everything in `src/handlers/` and `src/store/`, `docker-compose.yml`, `.gitignore`, `rustfmt.toml`, `db/`, `keycloak/` and `scripts/`.

The platform realm `tasksteams` (Keycloak 26.8.2) signs access tokens with **RS256**: an RSA private key that only Keycloak holds. Everybody can fetch the matching public keys from a URL (the *JWKS*, JSON Web Key Set) and check a signature, but nobody can make one.

## Steps
### Step 1. Look inside a real token
Start the stack and ask Keycloak for a token as alice (the helper script from chapter 01 prints it).

**Terminal (folder: `tasks-api`)**
```text
docker compose -p backend up -d --wait
python scripts/api.py --as alice --token
```
You get one long line of three parts separated by dots: `header.payload.signature`. The payload is base64url-encoded JSON. This command decodes it (and drops some noise):

**Terminal, Windows PowerShell (folder: `tasks-api`)**
```text
$token = python scripts/api.py --as alice --token
python -c "import base64,json,sys;t=sys.argv[1].split('.')[1];c=json.loads(base64.urlsafe_b64decode(t+'==='));[c.pop(k,None) for k in ('jti','sid','typ','azp','acr','allowed-origins','resource_access','email_verified','given_name','family_name','session_state','auth_time','iat')];print(json.dumps(c,indent=2))" $token
```
**Terminal, macOS or Linux (folder: `tasks-api`)**
```text
token=$(python3 scripts/api.py --as alice --token)
python3 -c "import base64,json,sys;t=sys.argv[1].split('.')[1];c=json.loads(base64.urlsafe_b64decode(t+'==='));[c.pop(k,None) for k in ('jti','sid','typ','azp','acr','allowed-origins','resource_access','email_verified','given_name','family_name','session_state','auth_time','iat')];print(json.dumps(c,indent=2))" "$token"
```
Expected result (the `exp` number is yours: seconds since 1970, five minutes after the token was issued):
```text
{
  "exp": 1795423799,
  "iss": "http://localhost:8180/realms/tasksteams",
  "aud": "tasks-api",
  "sub": "a11ce000-0000-4000-8000-000000000001",
  "realm_access": {
    "roles": [
      "admin"
    ]
  },
  "scope": "openid tasks:write tasks:admin email tasks:read profile",
  "name": "Alice Admin",
  "preferred_username": "alice",
  "email": "alice@tasksteams.test"
}
```
The claims we use: `iss` (who issued it), `aud` (for which API; here a single string, but it can be a list), `exp` (expiry), `sub` (the user id, equal to `users.id`), `realm_access.roles` (the realm roles) and `scope` (a space-separated list).

### Step 2. Add the crates: `Cargo.toml`
**File: `Cargo.toml`**
```toml
[package]
name = "tasks-api"
version = "1.0.0"
edition = "2024"
rust-version = "1.88"
description = "Tasks and Teams API (Code101 capstone, Rust backend)"
publish = false

[dependencies]
axum = "0.8"
base64 = "0.23"
chrono = { version = "0.4", features = ["serde"] }
dotenvy = "0.15"
hex = "0.4"
jsonwebtoken = { version = "12", default-features = false, features = ["rust_crypto"] }
reqwest = { version = "0.13", default-features = false, features = ["json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
serde_urlencoded = "0.7"
sha2 = "0.11"
sqlx = { version = "0.9", default-features = false, features = ["chrono", "derive", "json", "postgres", "runtime-tokio", "uuid"] }
thiserror = "2"
tokio = { version = "1", features = ["macros", "net", "rt-multi-thread", "signal"] }
tower = { version = "0.5", features = ["util"] }
tower-http = { version = "0.7", features = ["request-id", "trace"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
uuid = { version = "1", features = ["serde", "v4"] }

[profile.release]
lto = "thin"
codegen-units = 1
strip = true
```
Two new lines:
- `jsonwebtoken` 12 checks and decodes JWTs. Since version 10 it needs a *crypto provider* chosen by a feature: `rust_crypto` (pure Rust, no C compiler needed) or `aws_lc_rs`. Enable exactly one; with exactly one enabled the crate picks it automatically. (Enable none and the first `decode` panics with a message that tells you to.)
- `reqwest` is the HTTP client that downloads the JWKS. `default-features = false` removes TLS and everything else; `json` adds `.json()`. Our JWKS URL is plain `http` inside the Docker network. **For an `https` issuer** add the feature `rustls` to this line: `features = ["json", "rustls"]`.

### Step 3. New settings: `.env.example`, `src/config.rs`
**File: `.env.example`**
```text
# Disposable local practice only. Never reuse these values for a real system.
# Platform stack (read by docker-compose.yml)
POSTGRES_DB=tasksteams
POSTGRES_USER=tasks_admin
POSTGRES_PASSWORD=tasks_admin_local_only
POSTGRES_PORT=5432
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=kcadmin_local_only
KEYCLOAK_PORT=8180
TASKS_NETWORK=tasksteams-net
# Rust API (read by the program through dotenvy)
BIND_ADDR=127.0.0.1:8000
PUBLIC_BASE_URL=http://localhost:8000
DATABASE_URL=postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams
TOKEN_ISSUER=http://localhost:8180/realms/tasksteams
TOKEN_AUDIENCE=tasks-api
JWKS_URL=http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs
RUST_LOG=info
```
`TOKEN_ISSUER` must equal the `iss` claim **character for character**, so it says `localhost`. `JWKS_URL` is where the program downloads keys; on your machine `127.0.0.1` works too. Keep these two apart: in Docker (chapter 04) they differ. Copy the file again (`Copy-Item .env.example .env -Force` or `cp .env.example .env`).

**File: `src/config.rs`**
```rust
use std::{env, net::SocketAddr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
    pub token_issuer: String,
    pub token_audience: String,
    pub jwks_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is not set".to_owned())?;
        let public_base_url = var_or("PUBLIC_BASE_URL", "http://localhost:8000").trim_end_matches('/').to_owned();
        // The issuer is compared with the `iss` claim as plain text; the JWKS URL is where the keys are fetched.
        // They differ inside Docker: tokens say localhost:8180, the API reaches Keycloak as keycloak:8080.
        let token_issuer = var_or("TOKEN_ISSUER", "http://localhost:8180/realms/tasksteams");
        let token_audience = var_or("TOKEN_AUDIENCE", "tasks-api");
        let jwks_url = var_or("JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs");
        Ok(Self { bind_addr, database_url, public_base_url, token_issuer, token_audience, jwks_url })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}
```

### Step 4. The validator: `src/jwks.rs`
**File: `src/jwks.rs`**
```rust
use std::{
    collections::HashMap,
    time::{Duration, Instant},
};

use jsonwebtoken::{
    Algorithm, DecodingKey, Validation, decode, decode_header,
    jwk::{JwkSet, KeyAlgorithm, PublicKeyUse},
};
use tokio::sync::{Mutex, RwLock};

use crate::{auth::Claims, config::Config, error::AppError};

/// Keycloak is asked for its keys again at most this often when a token names a key we do not know.
const REFETCH_COOLDOWN: Duration = Duration::from_secs(10);

/// Validates access tokens: signature (keys from the JWKS endpoint, cached), issuer, audience and expiry.
pub struct Authenticator {
    http: reqwest::Client,
    jwks_url: String,
    validation: Validation,
    keys: RwLock<HashMap<String, DecodingKey>>,
    refresh: Mutex<Refresh>,
}

#[derive(Default)]
struct Refresh {
    at: Option<Instant>,
    failed: bool,
}

impl Authenticator {
    pub fn new(config: &Config) -> Self {
        // Only RS256 is accepted, so a token with `alg: none` or an HMAC `alg` is rejected before any key is used.
        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_issuer(&[&config.token_issuer]);
        validation.set_audience(&[&config.token_audience]);
        validation.set_required_spec_claims(&["exp", "iss", "aud", "sub"]);
        validation.validate_nbf = true;
        validation.leeway = 30;
        let http = reqwest::Client::builder().timeout(Duration::from_secs(5)).build().expect("HTTP client");
        Self { http, jwks_url: config.jwks_url.clone(), validation, keys: RwLock::default(), refresh: Mutex::default() }
    }

    pub async fn verify(&self, token: &str) -> Result<Claims, AppError> {
        let header = decode_header(token).map_err(|_| AppError::InvalidToken)?;
        let kid = header.kid.ok_or(AppError::InvalidToken)?;
        let key = self.key(&kid).await?;
        decode::<Claims>(token, &key, &self.validation).map(|data| data.claims).map_err(|err| {
            // The reason helps an operator; it is never sent to the client and never contains the token.
            tracing::debug!(reason = %err, "access token rejected");
            AppError::InvalidToken
        })
    }

    async fn key(&self, kid: &str) -> Result<DecodingKey, AppError> {
        if let Some(key) = self.keys.read().await.get(kid) {
            return Ok(key.clone());
        }
        // Unknown key id: one task at a time asks Keycloak, and not more often than the cooldown allows,
        // so a client that invents key ids cannot turn this API into a request flood against Keycloak.
        let mut refresh = self.refresh.lock().await;
        if let Some(key) = self.keys.read().await.get(kid) {
            return Ok(key.clone());
        }
        if refresh.at.is_some_and(|at| at.elapsed() < REFETCH_COOLDOWN) {
            return Err(if refresh.failed {
                AppError::Internal("the signing keys are not available".to_owned())
            } else {
                AppError::InvalidToken
            });
        }
        refresh.at = Some(Instant::now());
        match self.fetch_keys().await {
            Ok(fetched) => {
                refresh.failed = false;
                let key = fetched.get(kid).cloned();
                *self.keys.write().await = fetched;
                key.ok_or(AppError::InvalidToken)
            }
            Err(err) => {
                refresh.failed = true;
                Err(AppError::Internal(format!("cannot fetch the signing keys: {err}")))
            }
        }
    }

    async fn fetch_keys(&self) -> Result<HashMap<String, DecodingKey>, reqwest::Error> {
        let set: JwkSet = self.http.get(&self.jwks_url).send().await?.error_for_status()?.json().await?;
        let keys = set
            .keys
            .iter()
            .filter(|jwk| !matches!(jwk.common.public_key_use, Some(PublicKeyUse::Encryption)))
            .filter(|jwk| matches!(jwk.common.key_algorithm, None | Some(KeyAlgorithm::RS256)))
            .filter_map(|jwk| Some((jwk.common.key_id.clone()?, DecodingKey::from_jwk(jwk).ok()?)))
            .collect();
        Ok(keys)
    }
}
```
Read it in two halves.

**What is checked (`Authenticator::new` and `verify`).** `Validation::new(Algorithm::RS256)` allows exactly one algorithm. That single line stops two classic attacks: a token whose header says `alg: none` (no signature at all, the forged token of chapter 02) and a token that claims to be signed with an *HMAC* using the public key as the secret. Then:
- `set_issuer`: `iss` must equal our configured issuer (a token from some other Keycloak, or the same Keycloak under another host name, is refused).
- `set_audience`: the token must be meant for **this API** (`aud` contains `tasks-api`). The crate accepts `aud` as one string **or** a list, as the contract requires. Without this check a token that Keycloak issued for another API of yours would open this one.
- `set_required_spec_claims`: `exp`, `iss`, `aud` and `sub` must be present; a token without an expiry would live forever.
- `validate_nbf = true` and `leeway = 30`: refuse tokens "not valid before" a time in the future, and allow 30 seconds of clock difference between Keycloak and this machine for `exp` and `nbf`.
`decode_header` reads only the unsigned header to get the key id (`kid`); nothing from the header is trusted beyond choosing the key, and the algorithm must still be RS256. If anything fails, the reason goes to the log at DEBUG level and the client only gets `invalid bearer token` (no hints for an attacker).

**Where the keys come from (`key` and `fetch_keys`).** Downloading the JWKS for every request would be slow and would make Keycloak a single point of failure for every call. Instead `keys` is a map `kid -> DecodingKey`, read under a cheap `RwLock` read lock. Only for an **unknown** `kid` does the code go to Keycloak (this also handles *key rotation*: when Keycloak starts signing with a new key, the first token that names it triggers one download). Three protections:
1. A `Mutex` lets only one task download at a time; the others wait and then find the key in the cache (the second `get` after taking the lock).
2. `REFETCH_COOLDOWN`: at most one download per 10 seconds. A client that sends tokens with invented `kid` values cannot make this API hammer Keycloak.
3. A failed download (`Keycloak is down`) is an internal error (500, logged), remembered for the cooldown so that every request does not wait for the 5-second HTTP timeout.
`fetch_keys` keeps only keys that can verify RS256 signatures: Keycloak also publishes an `RSA-OAEP` key for *encryption*, which is skipped.

### Step 5. State, modules and the extractor: `src/state.rs`, `src/lib.rs`, `src/auth.rs`, `src/main.rs`
**File: `src/state.rs`**
```rust
use std::sync::Arc;

use crate::{config::Config, jwks::Authenticator, store::Store};

/// Everything a handler may need. Cloning is cheap: the pool, the key cache and the config are shared.
#[derive(Clone)]
pub struct AppState {
    pub store: Store,
    pub auth: Arc<Authenticator>,
    pub config: Arc<Config>,
}
```
**File: `src/lib.rs`**
```rust
pub mod app;
pub mod auth;
pub mod config;
pub mod error;
pub mod extract;
pub mod handlers;
pub mod http;
pub mod jwks;
pub mod models;
pub mod state;
pub mod store;
pub mod validation;
```
**File: `src/auth.rs`**
```rust
use axum::{
    extract::FromRequestParts,
    http::{HeaderMap, header, request::Parts},
};
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
        let user = AuthUser::from(state.auth.verify(token).await?);
        state.store.ensure_user(&user).await?;
        Ok(user)
    }
}
```
Compared with chapter 02 the whole difference is: the `base64` import and `unverified_claims` are **gone**, and the extractor calls `state.auth.verify(token).await?`. Everything that used `AuthUser` is unchanged: that is the payoff of keeping identity behind one extractor. `Claims` is what we read out of a *verified* token; roles come from `realm_access.roles`, scopes from the space-separated `scope`. The check order of every handler is therefore: valid token (401) -> scope (403) -> team access (404) -> role (403).

**File: `src/main.rs`**
```rust
use std::sync::Arc;

use tasks_api::{app, config::Config, jwks::Authenticator, state::AppState, store::Store};
use tokio::{net::TcpListener, signal};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let config = Config::from_env()?;
    let store = Store::connect(&config.database_url).await?;
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(address = %config.bind_addr, "listening");
    let state = AppState { store, auth: Arc::new(Authenticator::new(&config)), config: Arc::new(config) };
    axum::serve(listener, app::router(state)).with_graceful_shutdown(shutdown_signal()).await?;
    Ok(())
}

/// Resolves on Ctrl+C (all systems) or SIGTERM (what `docker stop` sends).
async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c().await.expect("cannot listen for Ctrl+C");
    };
    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate()).expect("cannot listen for SIGTERM").recv().await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        _ = ctrl_c => {}
        _ = terminate => {}
    }
    tracing::info!("shutting down");
}
```
The `Authenticator` is created once and shared through the state (`Arc`), so all requests use the same key cache. It downloads nothing at start-up: the first request with an unknown `kid` does, which means the API can start before Keycloak is ready.

## Run it
**Terminal 1 (folder: `tasks-api`; the Compose stack is running)**
```text
cargo run
```
**Terminal 2 (folder: `tasks-api`)**
```text
python scripts/api.py --as alice GET /v1/me
```
```text
HTTP 200
content-type: application/json
x-request-id: 39095652-bba7-499e-b67e-e0946334c74c

{
  "id": "a11ce000-0000-4000-8000-000000000001",
  "username": "alice",
  "email": "alice@tasksteams.test",
  "displayName": "Alice Admin",
  "roles": [
    "admin"
  ],
  "scopes": [
    "openid",
    "tasks:write",
    "tasks:admin",
    "email",
    "tasks:read",
    "profile"
  ],
  "teams": [
    {
      "teamId": "7ea00000-0000-4000-8000-000000000001",
      "name": "Platform Team",
      "role": "lead"
    }
  ]
}
```
A real token works. Now the attacks. **The forged token of chapter 02** (header `alg: none`, no signature):

**Terminal 2, Windows PowerShell**
```text
$forged = python -c "import base64,json;b=lambda d:base64.urlsafe_b64encode(json.dumps(d).encode()).rstrip(b'=').decode();print(b({'alg':'none'})+'.'+b({'sub':'b0b00000-0000-4000-8000-000000000002','scope':'tasks:read tasks:write tasks:admin','realm_access':{'roles':['admin']}})+'.x')"
python scripts/api.py GET /v1/audit-log -H "Authorization: Bearer $forged"
```
**Terminal 2, macOS or Linux**
```text
forged=$(python3 -c "import base64,json;b=lambda d:base64.urlsafe_b64encode(json.dumps(d).encode()).rstrip(b'=').decode();print(b({'alg':'none'})+'.'+b({'sub':'b0b00000-0000-4000-8000-000000000002','scope':'tasks:read tasks:write tasks:admin','realm_access':{'roles':['admin']}})+'.x')")
python3 scripts/api.py GET /v1/audit-log -H "Authorization: Bearer $forged"
```
```text
HTTP 401
www-authenticate: Bearer realm="tasksteams", error="invalid_token"
content-type: application/problem+json
x-request-id: 90237756-8977-4ab2-9042-ab2285a506e8

{
  "type": "https://code101.example/problems/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "invalid bearer token",
  "instance": "/v1/audit-log",
  "traceId": "90237756-8977-4ab2-9042-ab2285a506e8"
}
```
**A tampered token**: take bob's real token and change only the payload (add the admin role). The signature no longer matches the payload:

**Terminal 2, Windows PowerShell**
```text
$bob = python scripts/api.py --as bob --token
$tampered = python -c "import base64,json,sys;t=sys.argv[1].split('.');p=json.loads(base64.urlsafe_b64decode(t[1]+'==='));p['realm_access']['roles']=['admin'];t[1]=base64.urlsafe_b64encode(json.dumps(p).encode()).rstrip(b'=').decode();print('.'.join(t))" $bob
python scripts/api.py GET /v1/audit-log -H "Authorization: Bearer $tampered"
```
The answer is the same 401. With `RUST_LOG=info,tasks_api=debug` the log of the server names the reason, which the client never sees:
```text
{"timestamp":"2026-11-23T08:44:59.975293Z","level":"DEBUG","fields":{"message":"access token rejected","reason":"InvalidSignature"},"target":"tasks_api::jwks","span":{"method":"GET","path":"/v1/audit-log","request_id":"64e83c9b-0d36-443b-b19a-6f13e9b542f5","name":"request"},"spans":[{"method":"GET","path":"/v1/audit-log","request_id":"64e83c9b-0d36-443b-b19a-6f13e9b542f5","name":"request"}]}
```
Garbage and a wrong scheme:
```text
python scripts/api.py GET /v1/me -H "Authorization: Bearer not.a.token"
```
```text
HTTP 401
www-authenticate: Bearer realm="tasksteams", error="invalid_token"
content-type: application/problem+json
x-request-id: 073c710d-baa9-4345-a687-6244dec093b4

{
  "type": "https://code101.example/problems/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "invalid bearer token",
  "instance": "/v1/me",
  "traceId": "073c710d-baa9-4345-a687-6244dec093b4"
}
```
```text
python scripts/api.py GET /v1/me -H "Authorization: Basic YWxpY2U6cGFzcw=="
```
```text
HTTP 401
www-authenticate: Bearer realm="tasksteams"
content-type: application/problem+json
x-request-id: a9b20967-fd41-49ea-8c98-78bcce89f40d

{
  "type": "https://code101.example/problems/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "a bearer access token is required",
  "instance": "/v1/me",
  "traceId": "a9b20967-fd41-49ea-8c98-78bcce89f40d"
}
```
Note the two challenges: no token (or the wrong scheme) is `Bearer realm="tasksteams"`; a token that failed validation adds `error="invalid_token"` (RFC 6750). **Roles and scopes.** bob's token has the scope `tasks:admin` (the smoke client grants all three), but bob is a `member`:
```text
python scripts/api.py --as bob GET /v1/audit-log
```
```text
HTTP 403
content-type: application/problem+json
x-request-id: 0afb843d-e3f3-442a-8c64-a5536a86353d

{
  "type": "https://code101.example/problems/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "The admin role is required.",
  "instance": "/v1/audit-log",
  "traceId": "0afb843d-e3f3-442a-8c64-a5536a86353d"
}
```
Effective permission = scope **and** role. (In this realm the smoke client always receives all three scopes, so a scope refusal cannot be shown with a smoke token; the web and mobile clients get `tasks:admin` only when they ask for it, which is where the check matters.) **Non-members and members.** Alice creates a team led by carol; bob gets a 404 for it, but a 403 when he tries to change a team he belongs to:
```text
python scripts/api.py --as alice POST /v1/teams name="Secret Team" leadUserId=ca401000-0000-4000-8000-000000000003
python scripts/api.py --as bob GET /v1/teams/ID_FROM_THE_ANSWER
python scripts/api.py --as bob PATCH /v1/teams/7ea00000-0000-4000-8000-000000000001 --if-match 1 description=hacked
```
```text
HTTP 404
content-type: application/problem+json
x-request-id: 6920444f-4c33-4d85-a787-11f17a20a4f4

{
  "type": "https://code101.example/problems/not-found",
  "title": "Not found",
  "status": 404,
  "detail": "The team does not exist.",
  "instance": "/v1/teams/e5b67519-9227-4329-9f25-0bfbcc7a9363",
  "traceId": "6920444f-4c33-4d85-a787-11f17a20a4f4"
}
```
```text
HTTP 403
content-type: application/problem+json
x-request-id: 872d5611-e164-4a3a-86d5-5148aec49bd0

{
  "type": "https://code101.example/problems/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "A team lead or an admin is required.",
  "instance": "/v1/teams/7ea00000-0000-4000-8000-000000000001",
  "traceId": "872d5611-e164-4a3a-86d5-5148aec49bd0"
}
```
Finally the conformance script:
```text
python scripts/conformance.py
```
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
PASS  create team (201, Location and ETag set, team 67803f2c-91bc-4395-b51a-fc2dc5b0b9e7)
PASS  create project (201, project cc41288f-ce65-469c-8058-b2af1c26c9af)
PASS  create task with Idempotency-Key (created once, replay returned the same task, other body gave 422)
PASS  get task with ETag (ETag "1", If-None-Match gave 304)
PASS  update with If-Match (200, version 1 -> 2)
PASS  stale If-Match gives 412 (stale If-Match gave 412, missing If-Match gave 428)
PASS  cursor pagination (2 + 1 tasks, no overlap, last page has nextCursor null)
PASS  401 without token (401 problem details with a Bearer challenge)
PASS  403 for member on admin route (bob (member) gets 403 on the audit log and on creating a team)
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
PASS  audit log (task create and update are in the audit trail)
PASS  cleanup (team deleted, then 404)
17 passed, 1 failed
```
Stop the API (Ctrl+C) and clean up with `docker compose -p backend down -v --remove-orphans`.

## How it works
```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant X as AuthUser extractor
    participant A as Authenticator
    participant K as Keycloak JWKS
    C->>X: Authorization Bearer token
    X->>A: verify(token)
    A->>A: header: alg RS256, kid present
    A->>K: GET JWKS (only for an unknown kid, at most every 10 s)
    A->>A: signature, iss, aud, exp, nbf, sub
    A-->>X: Claims
    X->>X: Claims to AuthUser (id, roles, scopes)
    X-->>C: handler runs, then scope, team access, role
```
- **Why the signature matters.** The signature covers header and payload. Change one character of the payload and the signature check fails: the tampered token of this chapter. Only whoever holds Keycloak's private key can produce a valid one.
- **Why `iss` and `aud` matter even with a valid signature.** A perfectly signed token from another realm, or one issued for a different API of the same realm, must not open this API.
- **Authorization is a second step.** Authentication answers *who*; the handlers then decide *what*: the scope (client permission), the role (user permission) and the team (data permission). Scope and role are an intersection: both must allow it.
- **Revocation.** The API validates locally: it never asks Keycloak whether a token is still wanted. A token stays valid until it expires (5 minutes in this realm); that is the price of no network hop per request and the reason for short lifetimes.
- **Authentik appendix.** With another OIDC provider only configuration changes: `TOKEN_ISSUER` (its issuer URL), `JWKS_URL` (its JWKS endpoint), `TOKEN_AUDIENCE` (an audience mapper that adds your API id), and the role claim: Authentik puts groups in `groups`; either map them to `realm_access.roles` with a property mapping or adapt `Claims` and `AuthUser::from`.
- **New terms:** **JWT** and **JWS** (a signed token), **JWKS** (the issuer's public keys), **kid** (key id), **audience**, **issuer**, **leeway**, **key rotation**, **scope** versus **role**.

## Try it
Starter: `exercise/starter` (a tiny Cargo project, no dependencies). Two functions model the rules of this chapter: `audience_ok` (the `aud` claim is one string or a list) and `may_read_audit_log` (scope **and** role). Make `cargo run` print `true true false false true`, one per line.

**File: `exercise/starter/src/main.rs`**
```rust
/// The `aud` claim of a token is either one string or a list of strings.
enum Audience {
    One(&'static str),
    Many(&'static [&'static str]),
}

/// True when the token was issued for `wanted`, whichever form `aud` has.
fn audience_ok(aud: &Audience, wanted: &str) -> bool {
    todo!("compare one string, or look through the list")
}

/// The effective permission is the intersection of the scope and the role: both must be present.
fn may_read_audit_log(scopes: &[&str], roles: &[&str]) -> bool {
    todo!("tasks:admin scope and admin role")
}

fn main() {
    println!("{}", audience_ok(&Audience::One("tasks-api"), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account", "tasks-api"]), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account"]), "tasks-api"));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["member"]));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["admin"]));
}
```
The starter folder also holds a `Cargo.toml` (`name = "audience-check"`, `edition = "2024"`).

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.rs`**
```rust
/// The `aud` claim of a token is either one string or a list of strings.
enum Audience {
    One(&'static str),
    Many(&'static [&'static str]),
}

/// True when the token was issued for `wanted`, whichever form `aud` has.
fn audience_ok(aud: &Audience, wanted: &str) -> bool {
    match aud {
        Audience::One(single) => *single == wanted,
        Audience::Many(list) => list.contains(&wanted),
    }
}

/// The effective permission is the intersection of the scope and the role: both must be present.
fn may_read_audit_log(scopes: &[&str], roles: &[&str]) -> bool {
    scopes.contains(&"tasks:admin") && roles.contains(&"admin")
}

fn main() {
    println!("{}", audience_ok(&Audience::One("tasks-api"), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account", "tasks-api"]), "tasks-api"));
    println!("{}", audience_ok(&Audience::Many(&["account"]), "tasks-api"));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["member"]));
    println!("{}", may_read_audit_log(&["tasks:read", "tasks:admin"], &["admin"]));
}
```
Expected output:
```text
true
true
false
false
true
```
</details>

## Check yourself
1. Why must the validator pin the algorithm to RS256 instead of using the `alg` of the token header? <details><summary>Answer</summary>The header is written by the sender. Believing it lets an attacker choose `none` (no signature) or an HMAC that uses the public key as the secret. The server decides which algorithm it accepts.</details>
2. A token is correctly signed by your Keycloak but was issued for the audience `account`. What happens? <details><summary>Answer</summary>`InvalidAudience`: 401. It is a real token, but not meant for this API.</details>
3. Keycloak rotates its signing key. How does the API notice, and what limits the load on Keycloak? <details><summary>Answer</summary>The first token that names the new `kid` is not in the cache, so the API downloads the JWKS once. The mutex allows one download at a time and the 10 second cooldown limits how often an unknown `kid` can trigger one.</details>
4. Bob's token contains `tasks:admin`. Why does `GET /v1/audit-log` answer 403 anyway? <details><summary>Answer</summary>The scope only says that the client app may ask for admin operations; the person must also have the admin role. Both are required.</details>
5. Why does the 401 answer say only `invalid bearer token`? <details><summary>Answer</summary>A detailed reason ("wrong audience", "expired") helps an attacker probe the validation. The reason goes to the server log instead.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `HTTP 500` `An unexpected error occurred.` and the log line ``"message":"cannot fetch the signing keys: error sending request for url (http://127.0.0.1:9/certs)"`` | `JWKS_URL` points at something that is not Keycloak (here port 9), or Keycloak is not running | Start Keycloak (`docker compose -p backend up -d --wait`), fix `JWKS_URL`; within 10 seconds the next request retries |
| `HTTP 401` for good tokens and, with `RUST_LOG=info,tasks_api=debug`, ``"message":"access token rejected","reason":"InvalidIssuer"`` | `TOKEN_ISSUER` is `http://127.0.0.1:8180/...` but the tokens say `http://localhost:8180/...`: the issuer is compared as text | Copy the `iss` value of a real token (step 1) into `TOKEN_ISSUER` |
| `HTTP 401` for good tokens and ``"reason":"InvalidAudience"`` | `TOKEN_AUDIENCE` is not the `aud` of the token (here `other-api`) | Use `tasks-api`, or add the audience mapper to your Keycloak client |

The three rows are real runs of this chapter's program with the setting changed (log lines shortened). To reproduce one, start the API with the variable set, for example in PowerShell `$env:TOKEN_AUDIENCE = "other-api"; cargo run`, and call `/v1/me` as alice. Two more failures to know, not shown here because they need waiting or a changed `Cargo.toml`: a token older than five minutes plus the 30 seconds of leeway is rejected as expired (ask for a new one), and `jsonwebtoken` 12 needs exactly one crypto feature (`rust_crypto` or `aws_lc_rs`) in `Cargo.toml`, otherwise decoding panics with a message that says so.

## Best practice
Validate every token on every request: pinned algorithm, issuer, audience, expiry and signature, from keys that you fetch from the issuer and cache with a refetch limit. Never decode a token without verifying it, never accept the algorithm from the token, and never log the token. Source: RFC 8725 JSON Web Token Best Current Practices https://www.rfc-editor.org/info/rfc8725

## Next lesson
04. Docker image and Compose: a multi-stage `Dockerfile` with a cached dependency layer, a small non-root runtime image and a Compose override that adds the API to the platform stack.
