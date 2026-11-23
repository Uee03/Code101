---
track: capstone
level: 301
phase: 1
phase_name: skeleton
lesson: 01
title: "Skeleton and problem details"
time: 60 min
prerequisites: [rust-101, capstone-platform-04]
versions: { rust: "1.100.0", axum: "0.8.9", tokio: "1.54.1", tower-http: "0.7.1", python: "3.10+ (author run: 3.15.2)", keycloak_image: "quay.io/keycloak/keycloak:26.8.2", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Rust 1.100.0, Docker CLI/Engine 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-rust/source/phase-1-skeleton/01-skeleton/
assets: []
---

# 01. Skeleton and problem details

## Why it matters
A restaurant opens with an empty dining room, a door and a menu on the wall before it serves a single dish. The skeleton of an API is the same: the door (a port that answers), the menu (the routes) and one rule for what the waiter says when something goes wrong. If every dish fails in its own way, no customer can learn the rules. In this chapter every failure of the Rust backend will speak one language, RFC 9457 problem details, from the first line of code.

## What you will build
A small Axum program, `tasks-api`, that listens on port 8000 and answers `GET /health`, a stub `GET /v1/me` and `POST /v1/teams` (which only validates the body). Every error, even a wrong URL or a wrong method, comes back as `application/problem+json` with a `traceId`. You also meet the platform stack (Postgres and Keycloak), the conformance script (it passes **6 of 18** checks today) and a small helper, `scripts/api.py`, that you will use in every chapter.

## Before you start
- Rust 1.100 or newer: `rustc --version` should print `rustc 1.100.0` or higher. Install from https://rustup.rs if needed, then **close the terminal and open a new one**.
- Docker running in Linux-container mode, and Python 3.10 or newer.
- Host ports 5432 (Postgres), 8180 (Keycloak) and 8000 (this API) are free.
- The platform capstone folder `capstones/platform` (or its zip `platform-phase-4-conformance.zip`): you copy five files from it.
- Source pack: unzip `backend-rust-phase-1-skeleton.zip` (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip`) and open folder `01-skeleton/code`. You can follow the steps and type the files yourself, or compare with the pack.

Check your tools:

**Terminal (any folder)**
```text
rustc --version
cargo --version
docker --version
```
Expected result:
```text
rustc 1.100.0 (0ef1bc386 2026-11-09)
cargo 1.100.0 (3acc79c0c 2026-11-05)
Docker version 29.9.3, build 5457199
```
Your build numbers may differ; the first two versions must be 1.100.0 or newer.

## Steps
### Step 1. Create the project folder and the platform files
Choose a folder for your work, for example `code101` in your home folder, and create the project there.

**Terminal (folder: your work folder)**
```text
cargo new tasks-api --lib
cd tasks-api
```
`cargo new --lib` makes `Cargo.toml` and `src/lib.rs`. The text before `>` or `$` in your prompt tells you the current folder; if you get lost, `cd` back into `tasks-api`. We will replace both files and add `src/main.rs` ourselves.

The backend does not own the database or the identity setup. It uses the **platform** files, byte for byte. Copy these into `tasks-api` (replace `PLATFORM` with the path to `capstones/platform/source/phase-4-conformance/04-conformance-script/code`):

**Terminal, Windows PowerShell (folder: `tasks-api`)**
```text
New-Item -ItemType Directory db, keycloak, scripts | Out-Null
Copy-Item PLATFORM\db\schema.sql, PLATFORM\db\seed.sql db\
Copy-Item PLATFORM\keycloak\realm-tasksteams.json keycloak\
Copy-Item PLATFORM\scripts\conformance.py scripts\
Copy-Item PLATFORM\docker-compose.yml .
```
**Terminal, macOS or Linux (folder: `tasks-api`)**
```text
mkdir db keycloak scripts
cp PLATFORM/db/schema.sql PLATFORM/db/seed.sql db/
cp PLATFORM/keycloak/realm-tasksteams.json keycloak/
cp PLATFORM/scripts/conformance.py scripts/
cp PLATFORM/docker-compose.yml .
```
Never edit these five files here: `db/schema.sql`, `db/seed.sql`, `keycloak/realm-tasksteams.json`, `scripts/conformance.py` and `docker-compose.yml` belong to the platform capstone (chapters 02, 03 and 04 there show them in full). Of these, only the Compose file is short enough to repeat. It is the infrastructure you will run next to your code:

**File: `docker-compose.yml`** (copied from the platform capstone)
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./db/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro
      - ./db/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
      - ./db:/scripts:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 3s
      timeout: 3s
      retries: 30
      start_period: 5s
    networks:
      - tasksteams
  keycloak:
    image: quay.io/keycloak/keycloak:26.8.2
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KEYCLOAK_ADMIN}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KC_HOSTNAME: http://localhost:${KEYCLOAK_PORT:-8180}
      KC_HOSTNAME_BACKCHANNEL_DYNAMIC: "true"
      KC_HEALTH_ENABLED: "true"
    ports:
      - "127.0.0.1:${KEYCLOAK_PORT:-8180}:8080"
    volumes:
      - ./keycloak/realm-tasksteams.json:/opt/keycloak/data/import/realm-tasksteams.json:ro
    healthcheck:
      test: ["CMD", "bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/9000 && printf 'GET /health/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n' >&3 && grep -q UP <&3"]
      interval: 5s
      timeout: 5s
      retries: 60
      start_period: 30s
    networks:
      - tasksteams
networks:
  tasksteams:
    name: ${TASKS_NETWORK:-tasksteams-net}
volumes:
  pg_data:
```
In short: `db` is Postgres 17 that runs `schema.sql` and `seed.sql` once on an empty volume; `keycloak` imports the realm file once; both publish their ports on `127.0.0.1` only (nothing outside your machine can reach them) and both have health checks, so `docker compose up --wait` returns when they are ready. The network is called `tasksteams-net`; in chapter 04 your API joins it. The `${NAME}` values come from a file called `.env`, which you create in step 2.

Expected result: the folder `tasks-api` now holds `Cargo.toml`, `src/lib.rs`, `db/`, `keycloak/`, `scripts/conformance.py` and `docker-compose.yml`.

### Step 2. Configuration files: `.env.example`, `.gitignore`, `rustfmt.toml`
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
RUST_LOG=info
```
The first block feeds `docker-compose.yml`. `BIND_ADDR` is where the API listens (loopback only, so no other computer can call it while you learn). `RUST_LOG` chooses how much the program logs (`info`, or `debug` for more). All passwords are fake and local. Copy the file to the name `.env`, which is the one that is really read and is never committed:

**Terminal, Windows PowerShell (folder: `tasks-api`)**
```text
Copy-Item .env.example .env
```
**Terminal, macOS or Linux (folder: `tasks-api`)**
```text
cp .env.example .env
```

**File: `.gitignore`**
```text
target/
.env
```
`target/` is where Cargo puts compiled code (large, rebuilt on demand); `.env` holds real settings and must not reach Git.

**File: `rustfmt.toml`**
```text
max_width = 120
use_small_heuristics = "Max"
```
`cargo fmt` formats Rust code. These two lines make it use lines up to 120 characters and keep short `struct` and `if` expressions on one line, which keeps the listings in this chapter compact. If you format your code with `cargo fmt`, nothing in the chapter files will change.

### Step 3. `Cargo.toml`
Replace the generated file with this one.

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
dotenvy = "0.15"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
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
Line by line:
- `name`, `version`, `description`: the crate is called `tasks-api`; its library is `tasks_api` (Cargo turns `-` into `_`) and its program is `tasks-api`. `publish = false` stops an accidental upload to crates.io.
- `edition = "2024"`: the Rust language edition. `rust-version = "1.88"` is the oldest compiler that may build it; an older one stops with a clear message.
- `axum`: the web framework (routes, extractors, JSON). `tokio`: the async runtime; its features are switched on one by one: `macros` (`#[tokio::main]`), `net` (TCP listener), `rt-multi-thread` (worker threads) and `signal` (Ctrl+C and SIGTERM).
- `tower` (feature `util`) gives `ServiceBuilder`, which stacks middleware in readable order. `tower-http` supplies ready-made layers: `request-id` (a unique id per request) and `trace` (one log line per request).
- `serde` and `serde_json` turn structs into JSON and back; `thiserror` writes the `Display` code of our error type; `uuid` (feature `serde`) is the type of every id; `dotenvy` reads `.env`; `tracing` and `tracing-subscriber` (features `env-filter` and `json`) write structured JSON logs.
- `[profile.release]`: used by `cargo build --release` in chapter 04. `lto = "thin"` and `codegen-units = 1` give a smaller, faster program; `strip = true` removes debug symbols. Changing them makes release builds faster or slower, never different in behaviour.

A version like `"0.8"` means "0.8.x, any patch": `Cargo.lock` (created by the first build) pins the exact versions, and you must commit it so everyone gets the same crates.

### Step 4. Configuration code: `src/config.rs`
**File: `src/config.rs`**
```rust
use std::{env, net::SocketAddr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        Ok(Self { bind_addr })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}
```
All settings come from environment variables, read once at start-up into one `Config` value. `var_or` takes a default; `.parse()` turns the text into a `SocketAddr` and a bad value becomes a readable error before anything else starts. `Config` does **not** derive `Debug`: later it will hold a database password, and a value that cannot be printed cannot leak into a log by accident.

### Step 5. The error type: `src/error.rs`
This is the most important file of the chapter. A handler returns `Result<T, AppError>`; whatever the error is, one place decides how it looks on the wire.

**File: `src/error.rs`**
```rust
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
```
How the pieces fit:
1. **`AppError`** is a Rust `enum`: a value is exactly one of the listed cases, and a case may carry data (`NotFound(String)`). `#[derive(thiserror::Error)]` writes the `Display` text from each `#[error("...")]`; that text goes to logs, not to the client. Some cases (rate limit, conflict, forbidden) are used only in later chapters; they exist now so the whole contract of error types is visible once.
2. **`Problem`** is the JSON body of RFC 9457: `type` (a URL that names the kind of problem), `title`, `status`, `detail`, plus our extensions `instance` (the request path), `traceId` (the request id, to find the log line), `code` and `errors[]` (one entry per invalid field, with a JSON Pointer such as `/name`). `skip_serializing_if` leaves out empty parts. In Rust `type` is a keyword, so the field is `kind` and `#[serde(rename = "type")]` fixes the name.
3. **`impl IntoResponse for AppError`** is what lets a handler return `Err(AppError::NotFound(..))`. It builds the `Problem`, sets the status and the right headers (`WWW-Authenticate` for 401, `Retry-After` for 429) and stores the `Problem` in the response *extensions* (a typed side pocket of the response). The body is still empty.
4. **`render_problems`** is a *middleware*, a function that wraps every request. It remembers the path and the request id, lets the request run, and then looks at the response: if an `AppError` stored a `Problem`, it adds `instance` and `traceId` and writes the JSON body with the content type `application/problem+json`. If the answer is an error that Axum produced itself (for example 405 Method Not Allowed or a malformed path id), it wraps that too, using `Problem::from_status`. For a 5xx answer the real text is logged and the client only sees a fixed sentence: error messages of the server must not leak internals.
5. Two answers bypass the problem renderer on purpose: successes, and 304 (not an error).

### Step 6. Validation: `src/validation.rs`
**File: `src/validation.rs`**
```rust
use crate::error::{AppError, FieldError};

pub trait Validate {
    fn validate(&self) -> Result<(), AppError>;
}

/// Collects every problem of a body, so the client sees all of them at once.
#[derive(Default)]
pub struct Check {
    errors: Vec<FieldError>,
}

impl Check {
    pub fn fail(&mut self, pointer: &str, detail: impl Into<String>) {
        self.errors.push(FieldError::new(pointer, detail));
    }

    /// Text whose trimmed length must be between `min` and `max` characters (the database checks `btrim`).
    pub fn text(&mut self, pointer: &str, value: &str, min: usize, max: usize) {
        let length = value.trim().chars().count();
        if length < min || length > max {
            self.fail(pointer, format!("must be between {min} and {max} characters"));
        }
    }

    pub fn max_chars(&mut self, pointer: &str, value: &str, max: usize) {
        if value.chars().count() > max {
            self.fail(pointer, format!("must be at most {max} characters"));
        }
    }

    pub fn finish(self) -> Result<(), AppError> {
        if self.errors.is_empty() { Ok(()) } else { Err(AppError::Validation(self.errors)) }
    }
}
```
A *trait* is a promise of behaviour: any request body that implements `Validate` can check itself. `Check` is a small collector: each rule adds an error instead of stopping at the first, and `finish` turns the list into one 422 answer. Lengths count characters (`chars().count()`), not bytes, the same way Postgres counts them, so a name with accents is measured fairly. The same limits as the contract (and as the database `CHECK` constraints) are repeated here so the client gets a precise message instead of a database error.

### Step 7. The JSON extractor: `src/extract.rs`
An *extractor* turns part of a request into a typed handler argument. Axum's own `Json<T>` rejects bad bodies with a plain-text answer, so we write our own that speaks problem details.

**File: `src/extract.rs`**
```rust
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
```
`ValidJson<T>` works for any type `T` that can be read from JSON (`DeserializeOwned`) and checks itself (`Validate`). It reads the raw bytes first (the body size limit of chapter 05 applies here), then lets `serde_json` parse them. `err.is_data()` separates "valid JSON, wrong shape" (a missing field, a number where text is expected, an unknown field) from "not JSON at all": the first is a 422 with a message, the second a 400. Only then does `validate()` run the length rules. A handler that takes a `ValidJson<TeamCreate>` can therefore trust its data completely.

### Step 8. The models: `src/models.rs`
**File: `src/models.rs`**
```rust
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    error::AppError,
    validation::{Check, Validate},
};

#[derive(Debug, Serialize)]
pub struct Health {
    pub status: &'static str,
    pub version: &'static str,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Me {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub display_name: String,
    pub roles: Vec<String>,
    pub scopes: Vec<String>,
    pub teams: Vec<MeTeam>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MeTeam {
    pub team_id: Uuid,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TeamCreate {
    pub name: String,
    #[serde(default)]
    pub description: String,
    pub lead_user_id: Option<Uuid>,
}

impl Validate for TeamCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/name", &self.name, 1, 80);
        check.max_chars("/description", &self.description, 500);
        check.finish()
    }
}
```
These are the *DTOs* (data transfer objects): the shapes that cross the wire, kept apart from database rows. The contract names JSON members in `camelCase` and Rust names fields in `snake_case`; `#[serde(rename_all = "camelCase")]` translates. Responses derive `Serialize`; the request body `TeamCreate` derives `Deserialize` with `deny_unknown_fields`, so a body with an extra field (a typo, or an attempt to set a field it must not set) is refused instead of silently ignored: the contract says `additionalProperties: false`. `#[serde(default)]` makes `description` optional with an empty text, and `Option<Uuid>` is the optional `leadUserId`.

### Step 9. The handlers: `src/handlers/`
A handler is an `async fn` whose arguments are extractors and whose result is something Axum can turn into a response. Create the folder `src/handlers` and these four files.

**File: `src/handlers/mod.rs`**
```rust
use axum::http::Uri;

use crate::error::AppError;

pub mod health;
pub mod me;
pub mod teams;

pub async fn not_found(uri: Uri) -> AppError {
    AppError::NotFound(format!("There is no route for {}.", uri.path()))
}
```
`mod.rs` lists the handler modules and holds `not_found`, the fallback for every URL that matches no route. It returns an `AppError`, which is a response (because of `IntoResponse`), so even an unknown URL gets a problem body.

**File: `src/handlers/health.rs`**
```rust
use axum::Json;

use crate::models::Health;

pub async fn get_health() -> Json<Health> {
    Json(Health { status: "ok", version: env!("CARGO_PKG_VERSION") })
}
```
`env!("CARGO_PKG_VERSION")` is replaced at compile time by the `version` of `Cargo.toml`, so the health answer always names the real build.

**File: `src/handlers/me.rs`**
```rust
use axum::Json;
use uuid::uuid;

use crate::models::Me;

/// A stub: always alice. Phase 3 replaces it with the caller found in the access token.
pub async fn get_me() -> Json<Me> {
    Json(Me {
        id: uuid!("a11ce000-0000-4000-8000-000000000001"),
        username: "alice".to_owned(),
        email: "alice@tasksteams.test".to_owned(),
        display_name: "Alice Admin".to_owned(),
        roles: vec!["admin".to_owned()],
        scopes: ["tasks:read", "tasks:write", "tasks:admin"].map(str::to_owned).to_vec(),
        teams: Vec::new(),
    })
}
```
A deliberate stub: it shows the response shape of the contract (`Me`) without any identity yet. The `uuid!` macro checks the id when the program compiles.

**File: `src/handlers/teams.rs`**
```rust
use axum::response::Response;

use crate::{error::AppError, extract::ValidJson, models::TeamCreate};

/// Phase 1 only validates the body. Phase 2 stores the team with the `create_team` function.
pub async fn create_team(ValidJson(_body): ValidJson<TeamCreate>) -> Result<Response, AppError> {
    Err(AppError::NotImplemented("Teams are stored from phase 2 on.".to_owned()))
}
```
By the time `create_team` runs, `ValidJson` has already parsed and checked the body. A valid body reaches the function, which answers 501 for now. The pattern `ValidJson(_body)` takes the inner value out of the wrapper; the leading underscore tells the compiler that we know it is unused.

### Step 10. The router: `src/app.rs`
**File: `src/app.rs`**
```rust
use axum::{
    Router,
    body::Body,
    http::Request,
    middleware,
    routing::{get, post},
};
use tower::ServiceBuilder;
use tower_http::{
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    trace::{DefaultOnResponse, TraceLayer},
};
use tracing::Level;

use crate::{error::render_problems, handlers};

pub fn router() -> Router {
    let trace = TraceLayer::new_for_http()
        .make_span_with(|request: &Request<Body>| {
            let request_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).unwrap_or("-");
            tracing::info_span!("request", method = %request.method(), path = request.uri().path(), request_id)
        })
        .on_response(DefaultOnResponse::new().level(Level::INFO));

    Router::new()
        .route("/health", get(handlers::health::get_health))
        .route("/v1/me", get(handlers::me::get_me))
        .route("/v1/teams", post(handlers::teams::create_team))
        .fallback(handlers::not_found)
        // The first layer is the outermost: it sees the request first and the response last.
        .layer(
            ServiceBuilder::new()
                .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
                .layer(PropagateRequestIdLayer::x_request_id())
                .layer(trace)
                .layer(middleware::from_fn(render_problems)),
        )
}
```
`router()` returns the `Router`: three routes plus the fallback. The layers around it form the *middleware chain*; the first one listed is the outermost:
1. `SetRequestIdLayer` gives every request a new UUID in the header `x-request-id` (unless the client sent one).
2. `PropagateRequestIdLayer` copies that header to the response, so a client can quote it in a bug report.
3. `TraceLayer` opens a *span* (a labelled scope of the log) with the method, the path and the request id, and writes one log line when the response is ready. It logs the path only: no headers, no body, so no token can reach the log.
4. `render_problems` (step 5) is innermost, so it sees the handler's result before the outer layers do.

### Step 11. The library and the program: `src/lib.rs`, `src/main.rs`
**File: `src/lib.rs`**
```rust
pub mod app;
pub mod config;
pub mod error;
pub mod extract;
pub mod handlers;
pub mod models;
pub mod validation;
```
`lib.rs` is the root of the library `tasks_api`: it only declares the modules. The project is a library plus a thin program (`main.rs`) on purpose. Items of a library are public, so the compiler does not warn about error cases or helpers that later chapters will start using.

**File: `src/main.rs`**
```rust
use tasks_api::{app, config::Config};
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
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(address = %config.bind_addr, "listening");
    axum::serve(listener, app::router()).with_graceful_shutdown(shutdown_signal()).await?;
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
In order: `dotenvy::dotenv().ok()` loads `.env` (and ignores a missing file); the logger is set to print one JSON object per line, filtered by `RUST_LOG` (default `info`); `Config::from_env()?` reads the settings (`?` returns the error from `main`, which prints it and exits with code 1); `TcpListener::bind` opens the port; `axum::serve` runs the router until `shutdown_signal` finishes. That function waits for Ctrl+C or, on Linux and macOS, SIGTERM, the signal `docker stop` sends; the `#[cfg(unix)]` lines exist only when compiling for those systems. After the signal, Axum finishes the requests that are running and then returns: a *graceful shutdown*.

### Step 12. The helper script: `scripts/api.py`
Typing JSON into `curl` differs between Windows PowerShell, cmd and bash (quotes are treated differently). This 80-line Python script does the same everywhere, prints the status line, the response headers and the formatted body, and can ask Keycloak for a token (`--as alice`). You use it from chapter 02 on; today it needs no token.

**File: `scripts/api.py`**
```python
#!/usr/bin/env python3
"""A small HTTP client for the lessons, so the same commands work on Windows, macOS and Linux. Standard library only.

  python scripts/api.py GET /health
  python scripts/api.py --as alice GET /v1/me
  python scripts/api.py --as alice POST /v1/teams name="Rust Team" description="Made by hand"
  python scripts/api.py --as alice PATCH /v1/tasks/ID --if-match 1 status=done assigneeId:=null
  python scripts/api.py --raw '{bad' POST /v1/teams
  python scripts/api.py --as alice --token

name=text sends a JSON string. name:=value sends raw JSON (a number, true, false, null).
--raw TEXT sends TEXT as the body; --raw @- reads the body from standard input.
--if-match 3 sends If-Match: "3" (the quotes of an ETag are easy to lose in a shell, so the script adds them).
--as alice|bob asks Keycloak for an access token first (the smoke client of the platform realm).
Environment: BASE_URL (default http://127.0.0.1:8000), KEYCLOAK_URL (default http://127.0.0.1:8180).
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake"}


def send(method, url, headers=None, data=None):
    request = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, response.headers, response.read()
    except urllib.error.HTTPError as err:  # 4xx and 5xx answers are results, not crashes
        return err.code, err.headers, err.read()


def token_for(username):
    form = urllib.parse.urlencode({
        "grant_type": "password",
        "client_id": "tasks-smoke",
        "username": username,
        "password": PASSWORDS[username],
        "scope": "openid tasks:read tasks:write tasks:admin",
    }).encode()
    url = f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token"
    status, _, body = send("POST", url, {"Content-Type": "application/x-www-form-urlencoded"}, form)
    if status != 200:
        sys.exit(f"Keycloak answered {status}: {body.decode()[:200]}")
    return json.loads(body)["access_token"]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--as", dest="user", choices=sorted(PASSWORDS), help="send a bearer token for this user")
    parser.add_argument("--token", action="store_true", help="print the access token and stop")
    parser.add_argument("--raw", help="send this text as the body, exactly as written")
    parser.add_argument("-H", dest="headers", action="append", default=[], help="extra header, 'Name: value'")
    parser.add_argument("--if-match", metavar="VERSION", help="send If-Match with the version in quotes")
    parser.add_argument("--if-none-match", metavar="VERSION", help="send If-None-Match with the version in quotes")
    parser.add_argument("method", nargs="?", help="GET, POST, PUT, PATCH or DELETE")
    parser.add_argument("path", nargs="?", help="for example /v1/me")
    parser.add_argument("fields", nargs="*", help="name=text or name:=json")
    args = parser.parse_args()

    if args.token:
        print(token_for(args.user or "alice"))
        return 0
    if not args.method or not args.path:
        parser.error("give a method and a path")

    headers = {"Accept": "application/json"}
    if args.user:
        headers["Authorization"] = f"Bearer {token_for(args.user)}"
    for line in args.headers:
        name, _, value = line.partition(":")
        headers[name.strip()] = value.strip()
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'

    data = None
    if args.raw is not None:
        data = sys.stdin.buffer.read() if args.raw == "@-" else args.raw.encode()
    elif args.fields:
        body = {}
        for field in args.fields:
            if ":=" in field:
                name, _, value = field.partition(":=")
                body[name] = json.loads(value)
            else:
                name, _, value = field.partition("=")
                body[name] = value
        data = json.dumps(body).encode()
    if data is not None:
        headers.setdefault("Content-Type", "application/json")

    status, response_headers, raw = send(args.method.upper(), BASE_URL + args.path, headers, data)
    print(f"HTTP {status}")
    for name, value in response_headers.items():
        if name.lower() not in ("date", "content-length", "connection", "transfer-encoding", "keep-alive"):
            print(f"{name}: {value}")
    text = raw.decode("utf-8", errors="replace")
    if text:
        try:
            text = json.dumps(json.loads(text), indent=2)
        except json.JSONDecodeError:
            pass
        print()
        print(text)
    return 0 if status < 400 else 1


if __name__ == "__main__":
    sys.exit(main())
```
Reading it: `send` makes one HTTP call and returns 4xx and 5xx answers as normal results; `token_for` asks Keycloak for a token with the *password grant* of the client `tasks-smoke` (a client that exists only for scripts; real apps use the code flow with PKCE, see the platform TDD); `main` builds the headers and the JSON body from the `name=value` words and prints the result. The exit code is 0 for answers below 400, so a script can test it.

## Run it
### 1. Start the platform stack
**Terminal (folder: `tasks-api`)**
```text
docker compose -p backend up -d --wait
```
`-p backend` is the project name (it prefixes container names), `up -d` starts in the background and `--wait` returns when the health checks pass. The first start downloads images and takes a minute or two. Expected result: lines ending in `Healthy` for `db` and `keycloak`, and the command returns.

### 2. Compile and run the API
**Terminal (folder: `tasks-api`)**
```text
cargo run
```
The first build downloads and compiles every crate and takes a minute or two (the tail of the output shows the last lines):
```text
   Compiling axum v0.8.9
   Compiling tasks-api v1.0.0 (F:\code101\tasks-api)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 57.15s
     Running `target\debug\tasks-api.exe`
{"timestamp":"2026-11-23T07:58:49.817787Z","level":"INFO","fields":{"message":"listening","address":"127.0.0.1:8000"},"target":"tasks_api"}
```
The path in `Compiling tasks-api` and the time will be yours. The last line is the log: one JSON object per line. Leave this terminal running.

### 3. Try it from a second terminal
**Terminal 2 (folder: `tasks-api`)**
```text
python scripts/api.py GET /health
```
Expected result:
```text
HTTP 200
content-type: application/json
x-request-id: 9f565c1e-9617-45f4-ac8e-91720dc08d4d

{
  "status": "ok",
  "version": "1.0.0"
}
```
The `x-request-id` is different every time. Now the same call with a bad body, once with an empty name and once with an unknown field:

```text
python scripts/api.py POST /v1/teams name=
```
```text
HTTP 422
content-type: application/problem+json
x-request-id: 1b9004a0-1f6c-41c6-861e-13785233c1dc

{
  "type": "https://code101.example/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "One or more fields are invalid.",
  "instance": "/v1/teams",
  "traceId": "1b9004a0-1f6c-41c6-861e-13785233c1dc",
  "errors": [
    {
      "pointer": "/name",
      "detail": "must be between 1 and 80 characters"
    }
  ]
}
```
```text
python scripts/api.py POST /v1/teams name=Ok colour=red
```
```text
HTTP 422
content-type: application/problem+json
x-request-id: 9c56b1dc-c675-4d49-a41a-43b5d4f72d29

{
  "type": "https://code101.example/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "One or more fields are invalid.",
  "instance": "/v1/teams",
  "traceId": "9c56b1dc-c675-4d49-a41a-43b5d4f72d29",
  "errors": [
    {
      "pointer": "",
      "detail": "unknown field `colour`, expected one of `name`, `description`, `leadUserId` at line 1 column 23"
    }
  ]
}
```
A body that is not JSON, an unknown URL, a wrong method and a valid body (which this chapter cannot store yet):
```text
python scripts/api.py --raw "{bad" POST /v1/teams
```
```text
HTTP 400
content-type: application/problem+json
x-request-id: 69c5e8a1-d3e2-4863-872c-c6e76d7e6d6b

{
  "type": "https://code101.example/problems/bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "The body is not valid JSON: key must be a string at line 1 column 2",
  "instance": "/v1/teams",
  "traceId": "69c5e8a1-d3e2-4863-872c-c6e76d7e6d6b"
}
```
```text
python scripts/api.py GET /v1/nothing
```
```text
HTTP 404
content-type: application/problem+json
x-request-id: 2842a99b-72e5-4ec3-b96d-f7a90bc58257

{
  "type": "https://code101.example/problems/not-found",
  "title": "Not found",
  "status": 404,
  "detail": "There is no route for /v1/nothing.",
  "instance": "/v1/nothing",
  "traceId": "2842a99b-72e5-4ec3-b96d-f7a90bc58257"
}
```
```text
python scripts/api.py DELETE /health
```
```text
HTTP 405
content-type: application/problem+json
x-request-id: 36632ff6-c1f9-4dfa-922a-4f7dd272d301
allow: GET,HEAD

{
  "type": "https://code101.example/problems/bad-request",
  "title": "Method Not Allowed",
  "status": 405,
  "detail": "Method Not Allowed",
  "instance": "/health",
  "traceId": "36632ff6-c1f9-4dfa-922a-4f7dd272d301"
}
```
```text
python scripts/api.py POST /v1/teams name="Rust Team"
```
```text
HTTP 501
content-type: application/problem+json
x-request-id: 442e3cc3-169a-414c-b82a-7e2b21663b3b

{
  "type": "https://code101.example/problems/not-implemented",
  "title": "Not implemented",
  "status": 501,
  "detail": "Teams are stored from phase 2 on.",
  "instance": "/v1/teams",
  "traceId": "442e3cc3-169a-414c-b82a-7e2b21663b3b"
}
```
The 405 answer came from Axum itself and still has the problem shape: that is `render_problems` working on a response it did not create.

### 4. Run the conformance script
The conformance script is the platform's black-box test; every backend must pass all 18 checks in the end. Today it can pass the ones that need nothing more than an answering server.

**Terminal 2 (folder: `tasks-api`)**
```text
python scripts/conformance.py
```
Expected result (the ids and the cut-off error texts differ in your run):
```text
PASS  keycloak discovery (issuer matches, PKCE S256 offered)
PASS  token for alice (iss, aud tasks-api, sub, role admin, three scopes)
PASS  token for bob (role member only)
PASS  postgres reachable (127.0.0.1:5432 answers the Postgres protocol)
PASS  health (200, status ok, no token needed)
FAIL  me: header RateLimit-Limit missing or not a number
FAIL  create team: expected HTTP 201, got 501: {"type":"https://code101.example/problems/not-implemented","title":"Not implemented","status":501,"detail":"Teams are stored from phase 2 on.","instance":"/v1/teams","traceId":"077d8d1c-3382-4ba3-aeba
FAIL  create project: needs the result of an earlier check (team)
FAIL  create task with Idempotency-Key: needs the result of an earlier check (project)
FAIL  get task with ETag: needs the result of an earlier check (task)
FAIL  update with If-Match: needs the result of an earlier check (task)
FAIL  stale If-Match gives 412: needs the result of an earlier check (task)
FAIL  cursor pagination: needs the result of an earlier check (project)
FAIL  401 without token: expected HTTP 401, got 200: {"id":"a11ce000-0000-4000-8000-000000000001","username":"alice","email":"alice@tasksteams.test","displayName":"Alice Admin","roles":["admin"],"scopes":["tasks:read","tasks:write","tasks:admin"],"teams
FAIL  403 for member on admin route: expected HTTP 403, got 404: {"type":"https://code101.example/problems/not-found","title":"Not found","status":404,"detail":"There is no route for /v1/audit-log.","instance":"/v1/audit-log","traceId":"c4824ab2-4e5b-417c-88ba-d019
PASS  problem details shape (422 with errors[/name], 404 with type, title and status)
FAIL  audit log: needs the result of an earlier check (task)
FAIL  cleanup: needs the result of an earlier check (team)
6 passed, 12 failed
```
Read the result like a to-do list: `me` waits for the `RateLimit-*` headers (chapter 05); every check that creates something waits for the database (chapter 02); `401 without token` fails because our stub answers 200 to everyone (chapter 03). `problem details shape` already passes: it needs a 422 with `errors[/name]` and a 404 with `type`, `title` and `status`, which is what this chapter built.

### 5. Stop and clean up
Press Ctrl+C in the terminal that runs the API; the log shows `shutting down`. Then:

**Terminal (folder: `tasks-api`)**
```text
docker compose -p backend down -v --remove-orphans
```
Expected result: the containers, the network `tasksteams-net` and the volume are removed. Check with `docker ps -a` (nothing of yours is left).

## How it works
Follow one request, `POST /v1/teams` with `{"name": ""}`:
1. The kernel hands the TCP connection to Tokio; Axum parses the HTTP request.
2. The layers run outside in: the request id is created, the trace span opens, `render_problems` notes the path and the id.
3. The router matches `POST /v1/teams` and prepares the handler arguments. The extractor `ValidJson<TeamCreate>` reads the body, parses it, runs `validate`, and fails: its `Rejection` type is `AppError`, so Axum turns it into a response with `AppError::into_response`. The handler never runs.
4. That response has an empty body and a `Problem` in its extensions. On the way back out, `render_problems` finds it, adds `instance` and `traceId`, serialises the JSON and sets `application/problem+json`.
5. The trace layer logs `finished processing request` with the status, and the response travels to the client.

New terms: **crate** (a Rust package), **library crate** and **binary crate**, **enum** (a type with a fixed set of cases), **trait** (a promise of behaviour), **extractor** (turns a request into a typed argument), **middleware** and **layer** (code that wraps every request), **DTO** (the shape of a request or response body), **problem details** (RFC 9457, the standard JSON for errors), **JSON Pointer** (`/name`, a path inside a JSON body), **span** (a labelled scope of a log).

## Try it
Starter: `exercise/starter` (a tiny Cargo project, no dependencies). The function `problem_slug` must return the last part of the problem `type` URL for an HTTP status: 400 `bad-request`, 401 `unauthorized`, 403 `forbidden`, 404 `not-found`, 409 `conflict`, 412 `precondition-failed`, 422 `validation-error`, 428 `precondition-required`, 429 `rate-limited` and `internal-error` for everything else. Copy the folder `exercise/starter` next to your project, open it and run `cargo run`; until you replace the `todo!()` it stops with `not yet implemented`.

**File: `exercise/starter/src/main.rs`**
```rust
const PROBLEM_BASE: &str = "https://code101.example/problems/";

/// The last part of the `type` URL for an HTTP status, as the contract lists them:
/// 400 bad-request, 401 unauthorized, 403 forbidden, 404 not-found, 409 conflict,
/// 412 precondition-failed, 422 validation-error, 428 precondition-required, 429 rate-limited,
/// and internal-error for everything else.
fn problem_slug(status: u16) -> &'static str {
    todo!("map {status} to a slug")
}

fn main() {
    for status in [400, 401, 403, 404, 409, 412, 422, 428, 429, 500] {
        println!("{status} {PROBLEM_BASE}{}", problem_slug(status));
    }
}
```
The starter folder also holds this `Cargo.toml`:
```toml
[package]
name = "problem-types"
version = "0.1.0"
edition = "2024"
```

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.rs`**
```rust
const PROBLEM_BASE: &str = "https://code101.example/problems/";

/// The last part of the `type` URL for an HTTP status, as the contract lists them:
/// 400 bad-request, 401 unauthorized, 403 forbidden, 404 not-found, 409 conflict,
/// 412 precondition-failed, 422 validation-error, 428 precondition-required, 429 rate-limited,
/// and internal-error for everything else.
fn problem_slug(status: u16) -> &'static str {
    match status {
        400 => "bad-request",
        401 => "unauthorized",
        403 => "forbidden",
        404 => "not-found",
        409 => "conflict",
        412 => "precondition-failed",
        422 => "validation-error",
        428 => "precondition-required",
        429 => "rate-limited",
        _ => "internal-error",
    }
}

fn main() {
    for status in [400, 401, 403, 404, 409, 412, 422, 428, 429, 500] {
        println!("{status} {PROBLEM_BASE}{}", problem_slug(status));
    }
}
```
A `match` must cover every value; the last arm `_` is the catch-all. Expected output of `cargo run`:
```text
400 https://code101.example/problems/bad-request
401 https://code101.example/problems/unauthorized
403 https://code101.example/problems/forbidden
404 https://code101.example/problems/not-found
409 https://code101.example/problems/conflict
412 https://code101.example/problems/precondition-failed
422 https://code101.example/problems/validation-error
428 https://code101.example/problems/precondition-required
429 https://code101.example/problems/rate-limited
500 https://code101.example/problems/internal-error
```
</details>

## Check yourself
1. Why does `AppError::into_response` not write the JSON body itself? <details><summary>Answer</summary>It does not know the request path or the request id. The middleware `render_problems` sees the request and the response, so it adds `instance` and `traceId` in one place, and it can also wrap errors that Axum produced itself (405, bad path id).</details>
2. A client sends `{"name": "Ok", "colour": "red"}`. Which status do they get and why? <details><summary>Answer</summary>422. The body is valid JSON but `TeamCreate` has `deny_unknown_fields`, so `serde_json` reports a data error (`is_data()`), which `ValidJson` maps to `AppError::Validation`.</details>
3. Why is the library separated from `main.rs`? <details><summary>Answer</summary>The library's items are public, so unused error cases and helpers do not trigger warnings while the chapters grow the code, and the same code could be linked into a test program. `main.rs` only wires configuration, logging and the server.</details>
4. Why does `Config` not implement `Debug`? <details><summary>Answer</summary>From chapter 02 on it holds the database URL with a password. A type that cannot be printed with `{:?}` cannot leak into a log line by accident.</details>
5. What does `#[cfg(unix)]` do in `main.rs`? <details><summary>Answer</summary>It compiles the next item only for Unix-like systems (Linux, macOS). Only they have the SIGTERM signal that `docker stop` sends; on Windows a never-ready future takes its place.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| ``error[E0277]: the trait bound `fn() -> impl std::future::Future<Output = Json<Health>> {get_health}: Handler<_, _>` is not satisfied`` ... `note: Consider using `#[axum::debug_handler]` to improve the error message` | `Health` lacks `#[derive(Serialize)]`, so `Json<Health>` is not a response and the function is not a handler | Add `Serialize` to the derive list. The message points at the route, not at the struct: add `#[axum::debug_handler]` above the handler (needs the axum feature `macros`) for a message that names the real cause |
| ``error[E0432]: unresolved import `crate::validation` `` ... ``could not find `validation` in the crate root`` | `pub mod validation;` is missing in `src/lib.rs` | Declare every module in `lib.rs` (or `main.rs`); a file that is not declared is not compiled |
| `Error: Os { code: 10048, kind: AddrInUse, message: "Only one usage of each socket address (protocol/network address/port) is normally permitted." }` (Windows; Linux and macOS say `Address already in use`) | Another program, often an older copy of this API, already listens on port 8000 | Stop it (Ctrl+C in its terminal) or set another port: `BIND_ADDR=127.0.0.1:8001` in `.env` |
| `FAIL  token for alice` or `HTTP error ... Connection refused` from `scripts/api.py` / the conformance script | Keycloak is not running | `docker compose -p backend up -d --wait` in the project folder, then retry |
| Edits to `.env.example` have no effect | Only `.env` is read | Copy it again, or edit `.env` |

The first two rows are the real compiler output (shortened); to see them yourself remove `Serialize` from `Health` in `src/models.rs`, or delete `pub mod validation;` from `src/lib.rs`, and run `cargo build`. Put the line back afterwards.

## Best practice
Make every error one type with one place that renders it, and return the standard shape (RFC 9457). Clients, tests and logs then see the same structure whether the failure came from your code, a validator or the framework. Source: RFC 9457 Problem Details for HTTP APIs https://www.rfc-editor.org/info/rfc9457

## Next lesson
02. Data and stored functions: a SQLx connection pool, a store module for every resource, the stored functions `create_team`, `complete_task` and `reassign_task`, ETag and `If-Match`, cursor pagination and `Idempotency-Key`. The conformance score goes from 6 to 17.
