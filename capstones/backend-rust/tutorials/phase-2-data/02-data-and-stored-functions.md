---
track: capstone
level: 301
phase: 2
phase_name: data
lesson: 02
title: "Data and stored functions"
time: 180 min
prerequisites: [capstone-backend-rust-01, databases-101, capstone-platform-02]
versions: { rust: "1.100.0", axum: "0.8.9", sqlx: "0.9.1", tokio: "1.54.1", chrono: "0.4.45", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Rust 1.100.0, Docker CLI/Engine 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-rust/source/phase-2-data/02-data-and-stored-functions/
assets: []
---

# 02. Data and stored functions

## Why it matters
A bank teller does not invent rules at the counter: the rules (a withdrawal needs enough money, a closed account takes no deposit) live in the bank's system, and the teller only asks it. Our API is the teller; Postgres is the bank's system. The platform schema already holds the rules (constraints, triggers and three stored functions). This chapter connects Rust to it, safely: parameters instead of string pasting, one transaction per write, and the *who* of every change recorded for the audit trail. It is the longest chapter because all 27 operations of the contract get implemented here.

## What you will build
The whole API on top of Postgres: a connection pool, a `store` module (the only code that writes SQL), handlers for every operation, ETag and `If-Match`, cursor pagination, filters, and `Idempotency-Key`. At the end the conformance script passes **17 of 18** checks; only the `RateLimit-*` headers of `me` are missing (chapter 05). **Warning:** to keep the chapter on data, the token is *read but not verified* here. That is unsafe on purpose: you will forge a token in this chapter and see it accepted, and chapter 03 fixes it.

## Before you start
- Chapter 01 done (or its pack unzipped): the project folder `tasks-api` with `db/`, `keycloak/`, `docker-compose.yml`, `scripts/` and the files of chapter 01. This chapter's pack `backend-rust-phase-2-data.zip` (folder `02-data-and-stored-functions/code`) holds the whole project at the end of the chapter.
- Docker running, host ports 5432, 8000 and 8180 free, Rust 1.100 or newer.
- Unchanged from chapter 01, so not repeated here: `.gitignore`, `rustfmt.toml`, `docker-compose.yml`, `db/`, `keycloak/`, `scripts/api.py`, `scripts/conformance.py`, `src/validation.rs` and `src/error.rs`.

What the database offers (from the platform schema; you do not change it):

| Piece | What it does for the API |
|-------|--------------------------|
| role `tasks_app` | The login the API uses. It can read and write rows and run functions; it cannot change tables and cannot update or delete `audit_log` |
| triggers | `version` goes up and `updated_at` changes on every real change of a team, project or task; `completed_at` follows `status`; every change of a team, member, project, task or comment adds a row to `audit_log` |
| `app.current_user_id` | A session setting the audit trigger reads to know the actor. The API sets it at the start of **every write transaction** with `set_config('app.current_user_id', $1, true)`; `true` means "only until this transaction ends" |
| `create_team(name, description, lead, actor)` | Creates a team and its first lead in one step |
| `complete_task(task, actor, expected_version)` | Locks the row, checks the version, refuses a cancelled task, sets `status = 'done'` |
| `reassign_task(task, assignee, actor, expected_version)` | Locks the row, checks the version, refuses a done or cancelled task, checks that the assignee belongs to the project's team |
| SQLSTATE `TS404`, `TS409`, `TS412`, `TS422` | The functions raise these custom codes; the API maps them to 404, 409, 412 and 422 |

## Steps
### Step 1. Start the database and Keycloak
**Terminal (folder: `tasks-api`)**
```text
docker compose -p backend up -d --wait
```
Expected result: `db` and `keycloak` are `Healthy` (see chapter 01). The database already contains the seed data: users alice (admin), bob and carol, two teams, three projects and eight tasks.

### Step 2. Add the dependencies: `Cargo.toml`
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
New lines compared with chapter 01:
- `sqlx` is the database driver. `default-features = false` switches off everything we do not use; the features we want are `postgres` (the driver), `runtime-tokio` (use Tokio), `uuid` and `chrono` (map `uuid` and `timestamptz`/`date` columns to Rust types), `json` (map `jsonb` to `serde_json::Value`) and `derive` (`#[derive(FromRow)]`). There is no TLS feature: the database is on the same machine or the same Docker network. For a database across a network add `tls-rustls`.
- `chrono` (with `serde`) holds dates and instants. `base64` encodes cursors (and, in this chapter only, decodes a token). `sha2` and `hex` make the fingerprint of an idempotent request. `serde_urlencoded` parses query strings into a list of pairs.
- We never use SQLx's compile-time-checked `query!` macros: they need a live database (or saved metadata) at build time. Plain `query_as` functions check nothing until the program runs, which is why the smoke script matters, but the project then builds anywhere, including inside Docker.

### Step 3. Settings: `.env.example`, `src/config.rs`
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
RUST_LOG=info
```
Two new settings. `DATABASE_URL` uses the limited role `tasks_app`, **not** the administrator `tasks_admin`: even if someone found a flaw in the API, the connection could not drop a table or rewrite the audit log. `PUBLIC_BASE_URL` is what the absolute `Location` header of a created resource starts with; the program does not derive it from the `Host` header, because a client controls that header. Copy the file again if you already have a `.env`: `Copy-Item .env.example .env -Force` (Windows PowerShell) or `cp .env.example .env`.

**File: `src/config.rs`**
```rust
use std::{env, net::SocketAddr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is not set".to_owned())?;
        let public_base_url = var_or("PUBLIC_BASE_URL", "http://localhost:8000").trim_end_matches('/').to_owned();
        Ok(Self { bind_addr, database_url, public_base_url })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}
```
`DATABASE_URL` has no default on purpose: a missing connection string is an error to fix, not something to guess.

### Step 4. Shared state and the module list: `src/state.rs`, `src/lib.rs`
**File: `src/state.rs`**
```rust
use std::sync::Arc;

use crate::{config::Config, store::Store};

/// Everything a handler may need. Cloning is cheap: the pool and the config are shared.
#[derive(Clone)]
pub struct AppState {
    pub store: Store,
    pub config: Arc<Config>,
}
```
Handlers receive `AppState` through Axum's `State` extractor. Axum clones it for every request, so it must be cheap to clone: `Store` holds a connection pool (a handle to shared connections) and `Arc<Config>` is a shared, reference-counted pointer.

**File: `src/lib.rs`**
```rust
pub mod app;
pub mod auth;
pub mod config;
pub mod error;
pub mod extract;
pub mod handlers;
pub mod http;
pub mod models;
pub mod state;
pub mod store;
pub mod validation;
```

### Step 5. All request and response types: `src/models.rs`
Replace the file of chapter 01.

**File: `src/models.rs`**
```rust
use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Deserializer, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use crate::{
    error::AppError,
    validation::{Check, Validate},
};

/// Declares a text enum: serde names, `as_str` for SQL binds and `FromStr` for query parameters.
macro_rules! string_enum {
    ($name:ident { $($variant:ident => $text:literal),+ $(,)? }) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
        pub enum $name {
            $( #[serde(rename = $text)] $variant ),+
        }

        impl $name {
            pub fn as_str(self) -> &'static str {
                match self { $( Self::$variant => $text ),+ }
            }
        }

        impl std::str::FromStr for $name {
            type Err = ();

            fn from_str(text: &str) -> Result<Self, ()> {
                match text { $( $text => Ok(Self::$variant), )+ _ => Err(()) }
            }
        }
    };
}

string_enum!(TeamRole { Lead => "lead", Member => "member" });
string_enum!(TaskStatus { Todo => "todo", InProgress => "in_progress", Blocked => "blocked", Done => "done", Cancelled => "cancelled" });
string_enum!(TaskPriority { Low => "low", Medium => "medium", High => "high", Urgent => "urgent" });
string_enum!(EntityType { Team => "team", Member => "member", Project => "project", Task => "task", Comment => "comment" });

// Responses -----------------------------------------------------------------

#[derive(Debug, Serialize)]
pub struct Health {
    pub status: &'static str,
    pub version: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub database: Option<&'static str>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PageInfo {
    pub limit: i64,
    pub next_cursor: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub page: PageInfo,
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

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct MeTeam {
    pub team_id: Uuid,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct UserSummary {
    pub id: Uuid,
    pub username: String,
    pub display_name: String,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Team {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub member_count: i64,
    pub created_by: Uuid,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Member {
    pub user_id: Uuid,
    pub username: String,
    pub display_name: String,
    pub role: String,
    pub joined_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Project {
    pub id: Uuid,
    pub team_id: Uuid,
    pub key: String,
    pub name: String,
    pub description: String,
    pub archived: bool,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct Task {
    pub id: Uuid,
    pub project_id: Uuid,
    pub title: String,
    pub description: String,
    pub status: String,
    pub priority: String,
    pub assignee_id: Option<Uuid>,
    pub due_date: Option<NaiveDate>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_by: Uuid,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Comment {
    pub id: Uuid,
    pub task_id: Uuid,
    pub author: UserSummary,
    pub body: String,
    pub created_at: DateTime<Utc>,
}

/// One row of the comments query; `Comment` nests the author the way the contract wants it.
#[derive(Debug, FromRow)]
pub struct CommentRow {
    pub id: Uuid,
    pub task_id: Uuid,
    pub author_id: Uuid,
    pub author_username: String,
    pub author_display_name: String,
    pub body: String,
    pub created_at: DateTime<Utc>,
}

impl From<CommentRow> for Comment {
    fn from(row: CommentRow) -> Self {
        Self {
            id: row.id,
            task_id: row.task_id,
            author: UserSummary {
                id: row.author_id,
                username: row.author_username,
                display_name: row.author_display_name,
            },
            body: row.body,
            created_at: row.created_at,
        }
    }
}

#[derive(Debug, Serialize, FromRow)]
#[serde(rename_all = "camelCase")]
pub struct AuditEntry {
    pub id: i64,
    pub occurred_at: DateTime<Utc>,
    pub actor_id: Option<Uuid>,
    pub action: String,
    pub entity_type: String,
    pub entity_id: Uuid,
    pub details: serde_json::Value,
}

// Requests ------------------------------------------------------------------

/// JSON Merge Patch: a missing member stays `None`, an explicit `null` becomes `Some(None)`.
fn patch_field<'de, D, T>(deserializer: D) -> Result<Option<Option<T>>, D::Error>
where
    D: Deserializer<'de>,
    T: Deserialize<'de>,
{
    Option::<T>::deserialize(deserializer).map(Some)
}

#[derive(Debug, Serialize, Deserialize)]
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

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TeamUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
}

impl Validate for TeamUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        if self.name.is_none() && self.description.is_none() {
            check.fail("", "send at least one field");
        }
        if let Some(name) = &self.name {
            check.text("/name", name, 1, 80);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 500);
        }
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct MemberPut {
    pub role: TeamRole,
}

impl Validate for MemberPut {
    fn validate(&self) -> Result<(), AppError> {
        Ok(())
    }
}

fn check_project_key(check: &mut Check, key: &str) {
    let mut chars = key.chars();
    let valid = (2..=10).contains(&key.len())
        && chars.next().is_some_and(|c| c.is_ascii_uppercase())
        && chars.all(|c| c.is_ascii_uppercase() || c.is_ascii_digit());
    if !valid {
        check.fail("/key", "must match ^[A-Z][A-Z0-9]{1,9}$");
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProjectCreate {
    pub key: String,
    pub name: String,
    #[serde(default)]
    pub description: String,
}

impl Validate for ProjectCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check_project_key(&mut check, &self.key);
        check.text("/name", &self.name, 1, 120);
        check.max_chars("/description", &self.description, 2000);
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProjectUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
    pub archived: Option<bool>,
}

impl Validate for ProjectUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        if self.name.is_none() && self.description.is_none() && self.archived.is_none() {
            check.fail("", "send at least one field");
        }
        if let Some(name) = &self.name {
            check.text("/name", name, 1, 120);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 2000);
        }
        check.finish()
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TaskCreate {
    pub title: String,
    #[serde(default)]
    pub description: String,
    pub priority: Option<TaskPriority>,
    pub assignee_id: Option<Uuid>,
    pub due_date: Option<NaiveDate>,
}

impl Validate for TaskCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/title", &self.title, 1, 200);
        check.max_chars("/description", &self.description, 10000);
        check.finish()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TaskUpdate {
    pub title: Option<String>,
    pub description: Option<String>,
    pub status: Option<TaskStatus>,
    pub priority: Option<TaskPriority>,
    #[serde(default, deserialize_with = "patch_field")]
    pub assignee_id: Option<Option<Uuid>>,
    #[serde(default, deserialize_with = "patch_field")]
    pub due_date: Option<Option<NaiveDate>>,
}

impl Validate for TaskUpdate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        let empty = self.title.is_none()
            && self.description.is_none()
            && self.status.is_none()
            && self.priority.is_none()
            && self.assignee_id.is_none()
            && self.due_date.is_none();
        if empty {
            check.fail("", "send at least one field");
        }
        if let Some(title) = &self.title {
            check.text("/title", title, 1, 200);
        }
        if let Some(description) = &self.description {
            check.max_chars("/description", description, 10000);
        }
        check.finish()
    }
}

/// `assigneeId` is required but may be `null` (unassign): no `default`, so a missing member is an error.
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReassignRequest {
    #[serde(deserialize_with = "Option::deserialize")]
    pub assignee_id: Option<Uuid>,
}

impl Validate for ReassignRequest {
    fn validate(&self) -> Result<(), AppError> {
        Ok(())
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CommentCreate {
    pub body: String,
}

impl Validate for CommentCreate {
    fn validate(&self) -> Result<(), AppError> {
        let mut check = Check::default();
        check.text("/body", &self.body, 1, 2000);
        check.finish()
    }
}
```
Things worth a slow read:
- **`macro_rules! string_enum`** writes the same code four times: an `enum` whose JSON names are the lower-case words of the contract (`in_progress`), an `as_str` for SQL binds and a `FromStr` for query parameters (`status=todo`). The part between `$( ... ),+` repeats for every variant you list. The rows keep `status` and `priority` as plain `String` (what Postgres returns); the enums guard the *input*.
- **`#[derive(FromRow)]`** lets SQLx build a struct from a result row by matching column names to field names: `Team.member_count` is filled by a column called `member_count`.
- **Merge patch.** `PATCH` is JSON Merge Patch (RFC 7396): a member that is absent means "leave it", `null` means "clear it". A plain `Option<Uuid>` cannot tell the two apart, so `assignee_id` and `due_date` of `TaskUpdate` are `Option<Option<..>>` filled by `patch_field`: `None` = absent, `Some(None)` = explicit `null`, `Some(Some(x))` = a value. `#[serde(default, ...)]` makes the absent case `None`.
- **`ReassignRequest`** wants the opposite: the member `assigneeId` is *required* but may be `null` (unassign). Without `default`, serde reports a missing member as an error, and `deserialize_with = "Option::deserialize"` allows the `null`.
- The create types also derive `Serialize`: the idempotency code hashes their canonical JSON.

### Step 6. The data layer: `src/store/mod.rs`
From here on, all SQL lives under `src/store/`. Create the folder `src/store` and this file first.

**File: `src/store/mod.rs`**
```rust
use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
    time::Duration,
};

use sqlx::{PgPool, Postgres, Transaction, postgres::PgPoolOptions};
use uuid::Uuid;

use crate::error::AppError;

pub mod audit;
pub mod comments;
pub mod idempotency;
pub mod page;
pub mod projects;
pub mod tasks;
pub mod teams;
pub mod users;

pub type Tx = Transaction<'static, Postgres>;

/// The data layer: every SQL statement of the API lives in this module tree.
#[derive(Clone)]
pub struct Store {
    pool: PgPool,
    known_users: Arc<Mutex<HashSet<Uuid>>>,
}

impl Store {
    pub async fn connect(database_url: &str) -> Result<Self, sqlx::Error> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .acquire_timeout(Duration::from_secs(5))
            .connect(database_url)
            .await?;
        Ok(Self { pool, known_users: Arc::default() })
    }

    pub async fn ping(&self) -> bool {
        sqlx::query("SELECT 1").execute(&self.pool).await.is_ok()
    }

    /// Starts a write transaction and tells the audit trigger who is acting (`set_config(..., true)` is local to it).
    async fn begin_as(&self, actor: Uuid) -> Result<Tx, sqlx::Error> {
        let mut tx = self.pool.begin().await?;
        sqlx::query("SELECT set_config('app.current_user_id', $1, true)")
            .bind(actor.to_string())
            .execute(&mut *tx)
            .await?;
        Ok(tx)
    }
}

/// Maps database failures to problem types. The custom SQLSTATE codes are raised by the stored functions
/// in `db/schema.sql`: TS404 not found, TS409 rule violated, TS412 stale version, TS422 invalid input.
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        if let Some(db) = err.as_database_error() {
            let message = db.message().to_owned();
            match db.code().as_deref() {
                Some("TS404") => return Self::NotFound(message),
                Some("TS409") => return Self::conflict(message),
                Some("TS412") => return Self::PreconditionFailed(message),
                Some("TS422") => return Self::Unprocessable(message),
                Some("23505") => return Self::conflict("A record with the same name or key already exists."),
                Some("23503") => return Self::Unprocessable("A referenced record does not exist.".to_owned()),
                Some("23514") => return Self::Unprocessable("A value breaks a rule of the data model.".to_owned()),
                _ => {}
            }
        }
        if matches!(err, sqlx::Error::RowNotFound) {
            return Self::NotFound("The record does not exist.".to_owned());
        }
        Self::Internal(err.to_string())
    }
}
```
- **`PgPool`** is a pool of at most 10 open connections, shared by all requests. A request borrows one for the duration of a query. `acquire_timeout(5 s)` means: when all ten are busy, a request waits at most five seconds and then fails instead of hanging forever (a resource limit, OWASP API4).
- **`begin_as`** is the most important helper. It starts a transaction and runs `SELECT set_config('app.current_user_id', $1, true)` *inside* it, so every row the transaction changes is attributed to that user by the audit trigger. The `$1` is a bind parameter: the value travels separately from the SQL text, which is what makes SQL injection impossible. Every write in the store starts with `begin_as`; if the code returns early with `?`, the transaction is dropped and rolled back.
- **`known_users`** remembers which Keycloak users already have a row in `users`, so `ensure_user` (step 8) writes at most once per user and process.
- **`impl From<sqlx::Error> for AppError`** is the SQLSTATE mapping of the TDD in code: the stored functions raise `TS404`, `TS409`, `TS412` and `TS422`, and `?` turns any `sqlx::Error` into the matching problem. Two Postgres codes are mapped too: `23505` (unique violation, for example a duplicate team name) is a 409 and `23503` (foreign key) a 422. Anything unknown becomes `Internal`: logged in full, but the client only sees the fixed text of chapter 01.

### Step 7. Keyset pagination: `src/store/page.rs`
**File: `src/store/page.rs`**
```rust
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use serde::{Serialize, de::DeserializeOwned};
use sqlx::{Encode, FromRow, PgPool, Postgres, QueryBuilder, Type, postgres::PgRow};

use crate::{
    error::AppError,
    models::{Page, PageInfo},
};

/// The opaque cursor is the sort key and id of the last item, as JSON, in base64url.
pub fn encode_cursor<T: Serialize>(key: &T) -> String {
    URL_SAFE_NO_PAD.encode(serde_json::to_vec(key).unwrap_or_default())
}

pub fn decode_cursor<T: DeserializeOwned>(cursor: &str) -> Result<T, AppError> {
    URL_SAFE_NO_PAD
        .decode(cursor)
        .ok()
        .and_then(|bytes| serde_json::from_slice(&bytes).ok())
        .ok_or_else(|| AppError::BadRequest("The cursor is not valid.".to_owned()))
}

/// Escapes `%`, `_` and `\` so user text is matched literally by LIKE and ILIKE.
pub fn like_escape(text: &str) -> String {
    text.replace('\\', "\\\\").replace('%', "\\%").replace('_', "\\_")
}

pub struct PageRequest {
    pub limit: i64,
    pub cursor: Option<String>,
}

impl PageRequest {
    /// Appends the keyset condition for a cursor, then ORDER BY and LIMIT. `I` is the type of the id column.
    pub fn keyset<I>(
        &self,
        query: &mut QueryBuilder<Postgres>,
        at: &str,
        id: &str,
        descending: bool,
    ) -> Result<(), AppError>
    where
        I: DeserializeOwned + for<'q> Encode<'q, Postgres> + Type<Postgres> + Send,
    {
        if let Some(cursor) = &self.cursor {
            let (last_at, last_id): (chrono::DateTime<chrono::Utc>, I) = decode_cursor(cursor)?;
            let comparison = if descending { "<" } else { ">" };
            query.push(format!(" AND ({at}, {id}) {comparison} ("));
            query.push_bind(last_at).push(", ").push_bind(last_id).push(")");
        }
        let direction = if descending { "DESC" } else { "ASC" };
        self.order_and_limit(query, &format!("{at} {direction}, {id} {direction}"));
        Ok(())
    }

    /// One more row than asked for tells us whether there is a next page.
    pub fn order_and_limit(&self, query: &mut QueryBuilder<Postgres>, order_by: &str) {
        query.push(format!(" ORDER BY {order_by} LIMIT "));
        query.push_bind(self.limit + 1);
    }

    pub async fn fetch<R, K>(
        &self,
        mut query: QueryBuilder<Postgres>,
        pool: &PgPool,
        next_key: impl Fn(&R) -> K,
    ) -> Result<Page<R>, AppError>
    where
        R: for<'r> FromRow<'r, PgRow> + Send + Unpin,
        K: Serialize,
    {
        let mut items: Vec<R> = query.build_query_as::<R>().fetch_all(pool).await?;
        let more = items.len() as i64 > self.limit;
        items.truncate(self.limit as usize);
        let next_cursor = match items.last() {
            Some(last) if more => Some(encode_cursor(&next_key(last))),
            _ => None,
        };
        Ok(Page { items, page: PageInfo { limit: self.limit, next_cursor } })
    }
}
```
Offset paging (`OFFSET 50`) gets slow and skips or repeats rows when data changes between pages. **Keyset paging** remembers where it stopped: the sort values of the last row, here `(created_at, id)`. The next page asks for rows *after* that pair: `WHERE (created_at, id) > ($1, $2) ORDER BY created_at, id LIMIT n`. The row comparison is lexicographic, and the unique `id` breaks ties between rows created in the same instant (the seed rows share one timestamp). The existing indexes `(created_at DESC, id DESC)` serve it directly.
- The *cursor* is that pair as JSON in base64url: opaque to the client, and harmless if tampered with, because it is only ever used as bind parameters. A cursor that does not decode is a 400.
- `keyset` is generic over the id type `I`: users, teams and tasks use `Uuid`, the audit log uses `i64`.
- `order_and_limit` asks for **one more row** than the limit. If it arrives, there is a next page and the cursor comes from the last row we keep; if not, `nextCursor` is `null`. This costs no second `COUNT` query.
- **`QueryBuilder`** builds SQL from pieces while every value goes through `push_bind`. The text we push is only column names and keywords that we typed ourselves, never user input. `like_escape` neutralises `%` and `_` in the search text, so `q=100%` looks for a literal percent sign.

### Step 8. Users and "who am I": `src/store/users.rs`
**File: `src/store/users.rs`**
```rust
use chrono::{DateTime, Utc};
use sqlx::{FromRow, QueryBuilder};
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, like_escape},
};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{MeTeam, Page, UserSummary},
};

impl Store {
    /// Creates the user row on the first request of a new Keycloak user. Remembered in memory afterwards.
    pub async fn ensure_user(&self, user: &AuthUser) -> Result<(), AppError> {
        if self.known_users.lock().expect("known_users lock").contains(&user.id) {
            return Ok(());
        }
        sqlx::query(
            "INSERT INTO users (id, username, email, display_name) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING",
        )
        .bind(user.id)
        .bind(&user.username)
        .bind(&user.email)
        .bind(&user.display_name)
        .execute(&self.pool)
        .await?;
        self.known_users.lock().expect("known_users lock").insert(user.id);
        Ok(())
    }

    pub async fn my_teams(&self, user_id: Uuid) -> Result<Vec<MeTeam>, AppError> {
        let teams = sqlx::query_as::<_, MeTeam>(
            "SELECT t.id AS team_id, t.name, m.role FROM team_members m JOIN teams t ON t.id = m.team_id \
             WHERE m.user_id = $1 ORDER BY t.name",
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await?;
        Ok(teams)
    }

    pub async fn list_users(&self, q: Option<&str>, page: &PageRequest) -> Result<Page<UserSummary>, AppError> {
        let mut query =
            QueryBuilder::new("SELECT u.id, u.username, u.display_name, u.created_at FROM users u WHERE TRUE");
        if let Some(q) = q {
            let prefix = format!("{}%", like_escape(q));
            query.push(" AND (u.username ILIKE ").push_bind(prefix.clone());
            query.push(" OR u.display_name ILIKE ").push_bind(prefix).push(")");
        }
        page.keyset::<Uuid>(&mut query, "u.created_at", "u.id", false)?;
        let rows = page.fetch(query, &self.pool, |user: &UserRow| (user.created_at, user.id)).await?;
        let items = rows
            .items
            .into_iter()
            .map(|user| UserSummary { id: user.id, username: user.username, display_name: user.display_name })
            .collect();
        Ok(Page { items, page: rows.page })
    }
}

/// The summary plus the column the cursor needs.
#[derive(FromRow)]
struct UserRow {
    id: Uuid,
    username: String,
    display_name: String,
    created_at: DateTime<Utc>,
}
```
Users are created by Keycloak, not by this API, but the other tables point to `users(id)` with foreign keys. `ensure_user` therefore inserts the row the first time a token for a new person arrives (`ON CONFLICT DO NOTHING`: if the row exists, nothing happens). The three seed users already exist, so for them it changes nothing. `my_teams` feeds `GET /v1/me`. The backslash at the end of a Rust string line continues the string on the next line without a line break.

### Step 9. Teams, members and the access rule: `src/store/teams.rs`
**File: `src/store/teams.rs`**
```rust
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, like_escape},
};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Member, Page, Team, TeamCreate, TeamRole, TeamUpdate},
};

macro_rules! team_cols {
    () => {
        "t.id, t.name, t.description, (SELECT count(*) FROM team_members m WHERE m.team_id = t.id) AS member_count, \
         t.created_by, t.version, t.created_at, t.updated_at"
    };
}

macro_rules! member_cols {
    () => {
        "m.user_id, u.username, u.display_name, m.role, m.joined_at"
    };
}

/// What the caller may do inside one team. A non-member never gets an `Access`: they get a 404.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Access {
    Admin,
    Lead,
    Member,
}

impl Access {
    pub fn require_lead(self) -> Result<(), AppError> {
        match self {
            Self::Admin | Self::Lead => Ok(()),
            Self::Member => Err(AppError::Forbidden("A team lead or an admin is required.".to_owned())),
        }
    }
}

impl Store {
    pub async fn team_access(&self, user: &AuthUser, team_id: Uuid) -> Result<Access, AppError> {
        let not_found = || AppError::NotFound("The team does not exist.".to_owned());
        if user.is_admin() {
            let exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM teams WHERE id = $1)")
                .bind(team_id)
                .fetch_one(&self.pool)
                .await?;
            return if exists { Ok(Access::Admin) } else { Err(not_found()) };
        }
        let role: Option<String> =
            sqlx::query_scalar("SELECT role FROM team_members WHERE team_id = $1 AND user_id = $2")
                .bind(team_id)
                .bind(user.id)
                .fetch_optional(&self.pool)
                .await?;
        match role.as_deref() {
            Some("lead") => Ok(Access::Lead),
            Some(_) => Ok(Access::Member),
            None => Err(not_found()),
        }
    }

    pub async fn team_of_project(&self, project_id: Uuid) -> Result<Uuid, AppError> {
        let team: Option<Uuid> = sqlx::query_scalar("SELECT team_id FROM projects WHERE id = $1")
            .bind(project_id)
            .fetch_optional(&self.pool)
            .await?;
        team.ok_or_else(|| AppError::NotFound("The project does not exist.".to_owned()))
    }

    pub async fn list_teams(
        &self,
        user: &AuthUser,
        q: Option<&str>,
        descending: bool,
        page: &PageRequest,
    ) -> Result<Page<Team>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", team_cols!(), " FROM teams t WHERE TRUE"));
        if !user.is_admin() {
            query.push(" AND EXISTS (SELECT 1 FROM team_members x WHERE x.team_id = t.id AND x.user_id = ");
            query.push_bind(user.id).push(")");
        }
        if let Some(q) = q {
            query.push(" AND t.name ILIKE ").push_bind(format!("{}%", like_escape(q)));
        }
        page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", descending)?;
        page.fetch(query, &self.pool, |team: &Team| (team.created_at, team.id)).await
    }

    pub async fn team(&self, team_id: Uuid) -> Result<Team, AppError> {
        let team = sqlx::query_as::<_, Team>(concat!("SELECT ", team_cols!(), " FROM teams t WHERE t.id = $1"))
            .bind(team_id)
            .fetch_optional(&self.pool)
            .await?;
        team.ok_or_else(|| AppError::NotFound("The team does not exist.".to_owned()))
    }

    /// Calls the stored function: team and first lead are created in one transaction.
    pub async fn create_team(&self, user: &AuthUser, body: &TeamCreate) -> Result<Team, AppError> {
        let lead = body.lead_user_id.unwrap_or(user.id);
        let id: Uuid = sqlx::query_scalar("SELECT id FROM create_team($1, $2, $3, $4)")
            .bind(&body.name)
            .bind(&body.description)
            .bind(lead)
            .bind(user.id)
            .fetch_one(&self.pool)
            .await?;
        self.team(id).await
    }

    pub async fn update_team(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        expected_version: i32,
        body: &TeamUpdate,
    ) -> Result<Team, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let updated: Option<Uuid> = sqlx::query_scalar(
            "UPDATE teams SET name = COALESCE($3, name), description = COALESCE($4, description) \
             WHERE id = $1 AND version = $2 RETURNING id",
        )
        .bind(team_id)
        .bind(expected_version)
        .bind(&body.name)
        .bind(&body.description)
        .fetch_optional(&mut *tx)
        .await?;
        if updated.is_none() {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM teams WHERE id = $1")
                .bind(team_id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("team", current));
        }
        tx.commit().await?;
        self.team(team_id).await
    }

    pub async fn delete_team(&self, user: &AuthUser, team_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM teams WHERE id = $1").bind(team_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The team does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }

    pub async fn list_members(&self, team_id: Uuid, page: &PageRequest) -> Result<Page<Member>, AppError> {
        let mut query = QueryBuilder::new(concat!(
            "SELECT ",
            member_cols!(),
            " FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = "
        ));
        query.push_bind(team_id);
        page.keyset::<Uuid>(&mut query, "m.joined_at", "m.user_id", false)?;
        page.fetch(query, &self.pool, |member: &Member| (member.joined_at, member.user_id)).await
    }

    /// Adds a member or changes the role. Returns the member and whether it was newly added.
    pub async fn put_member(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        member_id: Uuid,
        role: TeamRole,
    ) -> Result<(Member, bool), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let members = lock_members(&mut tx, team_id).await?;
        let existing = members.iter().find(|(id, _)| *id == member_id);
        let leads = members.iter().filter(|(_, role)| role == "lead").count();
        if matches!(existing, Some((_, current)) if current == "lead") && role != TeamRole::Lead && leads == 1 {
            return Err(last_lead());
        }
        let user_exists: bool = sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)")
            .bind(member_id)
            .fetch_one(&mut *tx)
            .await?;
        if !user_exists {
            return Err(AppError::NotFound("The user does not exist.".to_owned()));
        }
        sqlx::query(
            "INSERT INTO team_members (team_id, user_id, role) VALUES ($1, $2, $3) \
             ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role",
        )
        .bind(team_id)
        .bind(member_id)
        .bind(role.as_str())
        .execute(&mut *tx)
        .await?;
        tx.commit().await?;
        let member = sqlx::query_as::<_, Member>(concat!(
            "SELECT ",
            member_cols!(),
            " FROM team_members m JOIN users u ON u.id = m.user_id WHERE m.team_id = $1 AND m.user_id = $2"
        ))
        .bind(team_id)
        .bind(member_id)
        .fetch_one(&self.pool)
        .await?;
        Ok((member, existing.is_none()))
    }

    pub async fn remove_member(&self, user: &AuthUser, team_id: Uuid, member_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let members = lock_members(&mut tx, team_id).await?;
        let Some((_, role)) = members.iter().find(|(id, _)| *id == member_id) else {
            return Err(AppError::NotFound("The user is not a member of this team.".to_owned()));
        };
        if role == "lead" && members.iter().filter(|(_, role)| role == "lead").count() == 1 {
            return Err(last_lead());
        }
        sqlx::query("DELETE FROM team_members WHERE team_id = $1 AND user_id = $2")
            .bind(team_id)
            .bind(member_id)
            .execute(&mut *tx)
            .await?;
        tx.commit().await?;
        Ok(())
    }
}

/// Locks the member rows of a team, so two requests cannot both remove the last two leads.
async fn lock_members(tx: &mut super::Tx, team_id: Uuid) -> Result<Vec<(Uuid, String)>, AppError> {
    let members = sqlx::query_as("SELECT user_id, role FROM team_members WHERE team_id = $1 FOR UPDATE")
        .bind(team_id)
        .fetch_all(&mut **tx)
        .await?;
    Ok(members)
}

fn last_lead() -> AppError {
    AppError::Conflict { detail: "A team needs at least one lead.".to_owned(), code: Some("last_lead") }
}

/// After an UPDATE matched no row: the row is gone (404) or its version moved on (412).
pub fn stale_or_missing(what: &str, current: Option<i32>) -> AppError {
    match current {
        Some(version) => {
            AppError::PreconditionFailed(format!("The {what} changed since you read it (current version {version})."))
        }
        None => AppError::NotFound(format!("The {what} does not exist.")),
    }
}
```
This file holds the access rule of the whole API.
- **`Access`** says what the caller may do in one team. `team_access` returns `Admin` for the admin role (after checking the team exists), `Lead` or `Member` from the `team_members` row, and **`NotFound` for everyone else**. A non-member must not learn that a team exists, so "not yours" and "not there" look identical: both are 404. `require_lead` then turns the weaker `Member` into a 403: a member *knows* the team, so refusing is honest.
- **`create_team`** calls the stored function: `SELECT id FROM create_team($1, $2, $3, $4)`. The function inserts the team and its first lead in one step and sets the actor itself. The API does not need a transaction of its own here, which is the point of stored functions: the rule lives in one place for all four backends.
- **`update_team`** is optimistic concurrency again, as in the projects file of step 10, with the helper **`stale_or_missing`**.
- **`put_member` and `remove_member`** protect the rule "a team keeps at least one lead". `lock_members` reads the member rows with `FOR UPDATE`, which locks them until the transaction ends, so two requests that each remove "the other" lead cannot both succeed. The conflict carries the machine-readable `code` `last_lead`. `INSERT ... ON CONFLICT DO UPDATE` adds a member or changes the role with one statement, and `existing.is_none()` tells the handler whether to answer 201 (added) or 200 (changed).


### Step 10. Projects: `src/store/projects.rs`
**File: `src/store/projects.rs`**
```rust
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest, teams::stale_or_missing};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Page, Project, ProjectCreate, ProjectUpdate},
};

macro_rules! project_cols {
    () => {
        "p.id, p.team_id, p.key, p.name, p.description, p.archived, p.version, p.created_at, p.updated_at"
    };
}

impl Store {
    pub async fn list_projects(
        &self,
        team_id: Uuid,
        archived: bool,
        descending: bool,
        page: &PageRequest,
    ) -> Result<Page<Project>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", project_cols!(), " FROM projects p WHERE p.team_id = "));
        query.push_bind(team_id);
        if !archived {
            query.push(" AND NOT p.archived");
        }
        page.keyset::<Uuid>(&mut query, "p.created_at", "p.id", descending)?;
        page.fetch(query, &self.pool, |project: &Project| (project.created_at, project.id)).await
    }

    pub async fn project(&self, project_id: Uuid) -> Result<Project, AppError> {
        let project =
            sqlx::query_as::<_, Project>(concat!("SELECT ", project_cols!(), " FROM projects p WHERE p.id = $1"))
                .bind(project_id)
                .fetch_optional(&self.pool)
                .await?;
        project.ok_or_else(|| AppError::NotFound("The project does not exist.".to_owned()))
    }

    pub async fn create_project(
        &self,
        user: &AuthUser,
        team_id: Uuid,
        body: &ProjectCreate,
    ) -> Result<Project, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let project = sqlx::query_as::<_, Project>(concat!(
            "INSERT INTO projects AS p (team_id, key, name, description, created_by) VALUES ($1, $2, $3, $4, $5) ",
            "RETURNING ",
            project_cols!()
        ))
        .bind(team_id)
        .bind(&body.key)
        .bind(&body.name)
        .bind(&body.description)
        .bind(user.id)
        .fetch_one(&mut *tx)
        .await?;
        tx.commit().await?;
        Ok(project)
    }

    pub async fn update_project(
        &self,
        user: &AuthUser,
        project_id: Uuid,
        expected_version: i32,
        body: &ProjectUpdate,
    ) -> Result<Project, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let updated = sqlx::query_as::<_, Project>(concat!(
            "UPDATE projects p SET name = COALESCE($3, p.name), description = COALESCE($4, p.description), ",
            "archived = COALESCE($5, p.archived) WHERE p.id = $1 AND p.version = $2 RETURNING ",
            project_cols!()
        ))
        .bind(project_id)
        .bind(expected_version)
        .bind(&body.name)
        .bind(&body.description)
        .bind(body.archived)
        .fetch_optional(&mut *tx)
        .await?;
        let Some(project) = updated else {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM projects WHERE id = $1")
                .bind(project_id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("project", current));
        };
        tx.commit().await?;
        Ok(project)
    }

    pub async fn delete_project(&self, user: &AuthUser, project_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM projects WHERE id = $1").bind(project_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The project does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }
}
```
The `project_cols!` macro is a tiny trick forced by SQLx 0.9: its `query_as` accepts **only string literals** (`&'static str`) as SQL, to make it hard to build SQL by pasting user text together. A normal `const` cannot be used inside `concat!`, but a macro that expands to a literal can, so the column list is written once and the compiler glues the full statement together at build time. The update shows **optimistic concurrency**: `WHERE p.id = $1 AND p.version = $2` changes the row only if nobody else changed it since the client read it. `COALESCE($3, p.name)` means "use the new value if one was sent (not `NULL`), else keep the old one". When no row was updated, one extra `SELECT version` tells *why*: no row at all is a 404, a different version is a 412.

### Step 11. Tasks, filters and the stored functions: `src/store/tasks.rs`
**File: `src/store/tasks.rs`**
```rust
use std::str::FromStr;

use chrono::NaiveDate;
use serde_json::json;
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, decode_cursor, like_escape},
    teams::stale_or_missing,
};
use crate::{
    auth::AuthUser,
    error::{AppError, FieldError},
    models::{Page, Task, TaskCreate, TaskPriority, TaskStatus, TaskUpdate},
};

macro_rules! task_cols {
    () => {
        "t.id, t.project_id, t.title, t.description, t.status, t.priority, t.assignee_id, \
         t.due_date, t.completed_at, t.created_by, t.version, t.created_at, t.updated_at"
    };
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum TaskSort {
    #[default]
    CreatedDesc,
    CreatedAsc,
    DueDate,
}

impl FromStr for TaskSort {
    type Err = ();

    fn from_str(text: &str) -> Result<Self, ()> {
        match text {
            "-createdAt" => Ok(Self::CreatedDesc),
            "createdAt" => Ok(Self::CreatedAsc),
            "dueDate" => Ok(Self::DueDate),
            _ => Err(()),
        }
    }
}

#[derive(Debug, Default)]
pub struct TaskFilter {
    pub statuses: Vec<TaskStatus>,
    pub priorities: Vec<TaskPriority>,
    pub assignee_id: Option<Uuid>,
    pub due_before: Option<NaiveDate>,
    pub due_after: Option<NaiveDate>,
    pub q: Option<String>,
    pub sort: TaskSort,
}

impl Store {
    pub async fn list_tasks(
        &self,
        project_id: Uuid,
        filter: &TaskFilter,
        page: &PageRequest,
    ) -> Result<Page<Task>, AppError> {
        let mut query = QueryBuilder::new(concat!("SELECT ", task_cols!(), " FROM tasks t WHERE t.project_id = "));
        query.push_bind(project_id);
        if !filter.statuses.is_empty() {
            let names: Vec<String> = filter.statuses.iter().map(|s| s.as_str().to_owned()).collect();
            query.push(" AND t.status = ANY(").push_bind(names).push(")");
        }
        if !filter.priorities.is_empty() {
            let names: Vec<String> = filter.priorities.iter().map(|p| p.as_str().to_owned()).collect();
            query.push(" AND t.priority = ANY(").push_bind(names).push(")");
        }
        if let Some(assignee) = filter.assignee_id {
            query.push(" AND t.assignee_id = ").push_bind(assignee);
        }
        if let Some(day) = filter.due_before {
            query.push(" AND t.due_date <= ").push_bind(day);
        }
        if let Some(day) = filter.due_after {
            query.push(" AND t.due_date >= ").push_bind(day);
        }
        if let Some(q) = &filter.q {
            query.push(" AND t.title ILIKE ").push_bind(format!("%{}%", like_escape(q)));
        }
        let by_due_date = filter.sort == TaskSort::DueDate;
        match filter.sort {
            TaskSort::CreatedDesc => page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", true)?,
            TaskSort::CreatedAsc => page.keyset::<Uuid>(&mut query, "t.created_at", "t.id", false)?,
            TaskSort::DueDate => {
                // Tasks without a due date come last, so "after the cursor" has a special case for NULL.
                if let Some(cursor) = &page.cursor {
                    let (due, last_id): (Option<NaiveDate>, Uuid) = decode_cursor(cursor)?;
                    match due {
                        Some(due) => {
                            query.push(" AND (t.due_date > ").push_bind(due);
                            query.push(" OR (t.due_date = ").push_bind(due);
                            query.push(" AND t.id > ").push_bind(last_id);
                            query.push(") OR t.due_date IS NULL)");
                        }
                        None => {
                            query.push(" AND t.due_date IS NULL AND t.id > ").push_bind(last_id);
                        }
                    }
                }
                page.order_and_limit(&mut query, "t.due_date ASC NULLS LAST, t.id ASC");
            }
        }
        let next_key = |task: &Task| {
            if by_due_date { json!([task.due_date, task.id]) } else { json!([task.created_at, task.id]) }
        };
        page.fetch(query, &self.pool, next_key).await
    }

    pub async fn task(&self, task_id: Uuid) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM tasks t WHERE t.id = $1"))
            .bind(task_id)
            .fetch_optional(&self.pool)
            .await?;
        task.ok_or_else(|| AppError::NotFound("The task does not exist.".to_owned()))
    }

    pub async fn create_task(&self, user: &AuthUser, project_id: Uuid, body: &TaskCreate) -> Result<Task, AppError> {
        if let Some(assignee) = body.assignee_id {
            self.ensure_assignable(project_id, assignee).await?;
        }
        let mut tx = self.begin_as(user.id).await?;
        let task = sqlx::query_as::<_, Task>(concat!(
            "INSERT INTO tasks AS t (project_id, title, description, priority, assignee_id, due_date, created_by) ",
            "VALUES ($1, $2, $3, COALESCE($4, 'medium'), $5, $6, $7) RETURNING ",
            task_cols!()
        ))
        .bind(project_id)
        .bind(&body.title)
        .bind(&body.description)
        .bind(body.priority.map(|p| p.as_str()))
        .bind(body.assignee_id)
        .bind(body.due_date)
        .bind(user.id)
        .fetch_one(&mut *tx)
        .await?;
        tx.commit().await?;
        Ok(task)
    }

    /// JSON Merge Patch: `COALESCE` keeps absent fields; the CASE flags tell "absent" from an explicit `null`.
    pub async fn update_task(
        &self,
        user: &AuthUser,
        task: &Task,
        expected_version: i32,
        body: &TaskUpdate,
    ) -> Result<Task, AppError> {
        let (set_assignee, assignee) = match body.assignee_id {
            Some(value) => (true, value),
            None => (false, None),
        };
        let (set_due_date, due_date) = match body.due_date {
            Some(value) => (true, value),
            None => (false, None),
        };
        if let Some(assignee) = assignee {
            self.ensure_assignable(task.project_id, assignee).await?;
        }
        let mut tx = self.begin_as(user.id).await?;
        let updated = sqlx::query_as::<_, Task>(concat!(
            "UPDATE tasks t SET title = COALESCE($3, t.title), description = COALESCE($4, t.description), ",
            "status = COALESCE($5, t.status), priority = COALESCE($6, t.priority), ",
            "assignee_id = CASE WHEN $7 THEN $8 ELSE t.assignee_id END, ",
            "due_date = CASE WHEN $9 THEN $10 ELSE t.due_date END ",
            "WHERE t.id = $1 AND t.version = $2 RETURNING ",
            task_cols!()
        ))
        .bind(task.id)
        .bind(expected_version)
        .bind(&body.title)
        .bind(&body.description)
        .bind(body.status.map(|s| s.as_str()))
        .bind(body.priority.map(|p| p.as_str()))
        .bind(set_assignee)
        .bind(assignee)
        .bind(set_due_date)
        .bind(due_date)
        .fetch_optional(&mut *tx)
        .await?;
        let Some(updated) = updated else {
            let current: Option<i32> = sqlx::query_scalar("SELECT version FROM tasks WHERE id = $1")
                .bind(task.id)
                .fetch_optional(&mut *tx)
                .await?;
            return Err(stale_or_missing("task", current));
        };
        tx.commit().await?;
        Ok(updated)
    }

    pub async fn delete_task(&self, user: &AuthUser, task_id: Uuid, expected: Option<i32>) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let current: Option<i32> = sqlx::query_scalar("SELECT version FROM tasks WHERE id = $1 FOR UPDATE")
            .bind(task_id)
            .fetch_optional(&mut *tx)
            .await?;
        match (current, expected) {
            (None, _) => return Err(stale_or_missing("task", None)),
            (Some(version), Some(expected)) if version != expected => {
                return Err(stale_or_missing("task", Some(version)));
            }
            _ => {}
        }
        sqlx::query("DELETE FROM tasks WHERE id = $1").bind(task_id).execute(&mut *tx).await?;
        tx.commit().await?;
        Ok(())
    }

    /// The stored function locks the row, checks the version and the rules, and stamps `completed_at`.
    pub async fn complete_task(&self, user: &AuthUser, task_id: Uuid, expected_version: i32) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM complete_task($1, $2, $3) t"))
            .bind(task_id)
            .bind(user.id)
            .bind(expected_version)
            .fetch_one(&self.pool)
            .await?;
        Ok(task)
    }

    pub async fn reassign_task(
        &self,
        user: &AuthUser,
        task_id: Uuid,
        assignee: Option<Uuid>,
        expected_version: i32,
    ) -> Result<Task, AppError> {
        let task = sqlx::query_as::<_, Task>(concat!("SELECT ", task_cols!(), " FROM reassign_task($1, $2, $3, $4) t"))
            .bind(task_id)
            .bind(assignee)
            .bind(user.id)
            .bind(expected_version)
            .fetch_one(&self.pool)
            .await?;
        Ok(task)
    }

    async fn ensure_assignable(&self, project_id: Uuid, assignee: Uuid) -> Result<(), AppError> {
        let member: bool = sqlx::query_scalar(
            "SELECT EXISTS (SELECT 1 FROM projects p JOIN team_members m ON m.team_id = p.team_id \
             WHERE p.id = $1 AND m.user_id = $2)",
        )
        .bind(project_id)
        .bind(assignee)
        .fetch_one(&self.pool)
        .await?;
        if member {
            Ok(())
        } else {
            Err(AppError::Validation(vec![FieldError::new("/assigneeId", "must be a member of the project's team")]))
        }
    }
}
```
The file in four parts:
1. **Filters.** Every filter the client sent adds a piece of SQL and a bind: `status=todo&status=blocked` becomes `t.status = ANY($2)` with a Postgres `text[]` bound as one parameter; `q` becomes `ILIKE '%text%'` (the trigram index on `title` serves it) with `%` and `_` escaped.
2. **Sorting and the cursor.** For `createdAt` sorts the shared `keyset` helper does the work. For `sort=dueDate` the order is `due_date ASC NULLS LAST, id ASC` (tasks without a due date come last), so "rows after the cursor" has a special case: after a dated task come later dates, same dates with a bigger id, **and** every undated task; after an undated task come only undated tasks with a bigger id. The cursor key is then `[dueDate, id]` instead of `[createdAt, id]`; `serde_json::json!` builds either one.
3. **Updates.** `update_task` is the merge-patch SQL: `COALESCE($3, t.title)` keeps the old title when none was sent, and `CASE WHEN $7 THEN $8 ELSE t.assignee_id END` uses the flag `$7` ("was `assigneeId` in the body at all?") to tell "leave it" from "set it, maybe to `NULL`". The `WHERE ... version = $2` is the ETag check. Setting `status` here is allowed; the trigger in the database stamps or clears `completed_at`.
4. **Stored functions.** `complete_task` and `reassign_task` are one `SELECT ... FROM function(...)` each. The function locks the row (`FOR UPDATE`), compares the version (raising `TS412` on a mismatch, which becomes our 412), applies the rules (`TS409` for a cancelled task, `TS422` for an assignee outside the team) and returns the new row. `ensure_assignable` gives `create_task` and `update_task` the same team rule, as a 422 with the pointer `/assigneeId`.

### Step 11b. Why a macro for the column list
You have seen `task_cols!()` inside `concat!(...)`. SQLx 0.9 changed `query` and `query_as` to accept only `&'static str`, so that nobody builds SQL by pasting user data into a `format!`. If you try, the compiler stops you (see *Common mistakes*). A normal `const COLS: &str = ...` cannot be spliced by `concat!`, but a `macro_rules!` that expands to a string literal can, and the whole statement is then a literal known at build time.

### Step 12. Comments: `src/store/comments.rs`
**File: `src/store/comments.rs`**
```rust
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Comment, CommentRow, Page},
};

macro_rules! comment_cols {
    () => {
        "c.id, c.task_id, c.author_id, u.username AS author_username, \
         u.display_name AS author_display_name, c.body, c.created_at"
    };
}

impl Store {
    pub async fn list_comments(&self, task_id: Uuid, page: &PageRequest) -> Result<Page<Comment>, AppError> {
        let mut query = QueryBuilder::new(concat!(
            "SELECT ",
            comment_cols!(),
            " FROM comments c JOIN users u ON u.id = c.author_id WHERE c.task_id = "
        ));
        query.push_bind(task_id);
        page.keyset::<Uuid>(&mut query, "c.created_at", "c.id", false)?;
        let rows = page.fetch(query, &self.pool, |row: &CommentRow| (row.created_at, row.id)).await?;
        Ok(Page { items: rows.items.into_iter().map(Comment::from).collect(), page: rows.page })
    }

    pub async fn create_comment(&self, user: &AuthUser, task_id: Uuid, body: &str) -> Result<Comment, AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let id: Uuid =
            sqlx::query_scalar("INSERT INTO comments (task_id, author_id, body) VALUES ($1, $2, $3) RETURNING id")
                .bind(task_id)
                .bind(user.id)
                .bind(body)
                .fetch_one(&mut *tx)
                .await?;
        tx.commit().await?;
        let row = sqlx::query_as::<_, CommentRow>(concat!(
            "SELECT ",
            comment_cols!(),
            " FROM comments c JOIN users u ON u.id = c.author_id WHERE c.id = $1"
        ))
        .bind(id)
        .fetch_one(&self.pool)
        .await?;
        Ok(row.into())
    }

    /// The team of the comment's task and the comment's author, for the delete permission check.
    pub async fn comment_context(&self, comment_id: Uuid) -> Result<(Uuid, Uuid), AppError> {
        let context: Option<(Uuid, Uuid)> = sqlx::query_as(
            "SELECT p.team_id, c.author_id FROM comments c JOIN tasks t ON t.id = c.task_id \
             JOIN projects p ON p.id = t.project_id WHERE c.id = $1",
        )
        .bind(comment_id)
        .fetch_optional(&self.pool)
        .await?;
        context.ok_or_else(|| AppError::NotFound("The comment does not exist.".to_owned()))
    }

    pub async fn delete_comment(&self, user: &AuthUser, comment_id: Uuid) -> Result<(), AppError> {
        let mut tx = self.begin_as(user.id).await?;
        let result = sqlx::query("DELETE FROM comments WHERE id = $1").bind(comment_id).execute(&mut *tx).await?;
        if result.rows_affected() == 0 {
            return Err(AppError::NotFound("The comment does not exist.".to_owned()));
        }
        tx.commit().await?;
        Ok(())
    }
}
```
A comment is created in a write transaction and read back afterwards with its author joined in; `comment_context` returns the team and the author of a comment, which the delete handler needs for its rule "author, team lead or admin".

### Step 13. The audit trail: `src/store/audit.rs`
**File: `src/store/audit.rs`**
```rust
use chrono::{DateTime, Utc};
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest};
use crate::{
    error::AppError,
    models::{AuditEntry, EntityType, Page},
};

#[derive(Debug, Default)]
pub struct AuditFilter {
    pub entity_type: Option<EntityType>,
    pub entity_id: Option<Uuid>,
    pub actor_id: Option<Uuid>,
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
}

impl Store {
    /// Newest first. The `tasks_app` role can read and append to `audit_log`, never change it.
    pub async fn list_audit(&self, filter: &AuditFilter, page: &PageRequest) -> Result<Page<AuditEntry>, AppError> {
        let mut query = QueryBuilder::new(
            "SELECT a.id, a.occurred_at, a.actor_id, a.action, a.entity_type, a.entity_id, a.details \
             FROM audit_log a WHERE TRUE",
        );
        if let Some(entity_type) = filter.entity_type {
            query.push(" AND a.entity_type = ").push_bind(entity_type.as_str());
        }
        if let Some(entity_id) = filter.entity_id {
            query.push(" AND a.entity_id = ").push_bind(entity_id);
        }
        if let Some(actor_id) = filter.actor_id {
            query.push(" AND a.actor_id = ").push_bind(actor_id);
        }
        if let Some(from) = filter.from {
            query.push(" AND a.occurred_at >= ").push_bind(from);
        }
        if let Some(to) = filter.to {
            query.push(" AND a.occurred_at < ").push_bind(to);
        }
        page.keyset::<i64>(&mut query, "a.occurred_at", "a.id", true)?;
        page.fetch(query, &self.pool, |entry: &AuditEntry| (entry.occurred_at, entry.id)).await
    }
}
```
The API never writes the audit log itself: the database triggers do, because the actor was set in each write transaction. The API only reads it. Filters are added only when the client sent them, each with `push_bind`.

### Step 14. Idempotency keys: `src/store/idempotency.rs`
**File: `src/store/idempotency.rs`**
```rust
use serde_json::Value;
use uuid::Uuid;

use super::Store;
use crate::error::AppError;

pub enum Claim {
    /// The key is new: the caller owns it and must run the request.
    Fresh,
    /// The same request already finished: send the stored response again.
    Replay(Value),
    /// The same key arrived with another request body.
    Mismatch,
    /// The first request with this key has not finished yet.
    InProgress,
}

impl Store {
    pub async fn claim_key(&self, user_id: Uuid, key: &str, request_hash: &str) -> Result<Claim, AppError> {
        sqlx::query("DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2 AND expires_at < now()")
            .bind(user_id)
            .bind(key)
            .execute(&self.pool)
            .await?;
        let inserted = sqlx::query(
            "INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
        )
        .bind(user_id)
        .bind(key)
        .bind(request_hash)
        .execute(&self.pool)
        .await?;
        if inserted.rows_affected() == 1 {
            return Ok(Claim::Fresh);
        }
        let (stored_hash, response): (String, Option<Value>) =
            sqlx::query_as("SELECT request_hash, response_body FROM idempotency_keys WHERE user_id = $1 AND key = $2")
                .bind(user_id)
                .bind(key)
                .fetch_one(&self.pool)
                .await?;
        Ok(match response {
            _ if stored_hash != request_hash => Claim::Mismatch,
            Some(body) => Claim::Replay(body),
            None => Claim::InProgress,
        })
    }

    pub async fn finish_key(&self, user_id: Uuid, key: &str, response: &Value) -> Result<(), AppError> {
        sqlx::query(
            "UPDATE idempotency_keys SET status_code = 201, response_body = $3 WHERE user_id = $1 AND key = $2",
        )
        .bind(user_id)
        .bind(key)
        .bind(response)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    /// A failed request must not keep its key, otherwise the client could never retry it.
    pub async fn release_key(&self, user_id: Uuid, key: &str) -> Result<(), AppError> {
        sqlx::query("DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2")
            .bind(user_id)
            .bind(key)
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}
```
A network can fail after the server created something but before the client saw the answer; the client then retries and would create a duplicate. With an `Idempotency-Key` the retry is recognised. `claim_key` first removes the caller's expired key, then tries to **insert** the key; the primary key `(user_id, key)` lets only one insert succeed, even with two simultaneous requests. The winner (`Fresh`) runs the request and calls `finish_key` with the response; a later request with the same key and the same request hash gets `Replay`; the same key with another hash is a `Mismatch` (422); a key that was claimed but has no stored response yet is `InProgress` (409). `release_key` frees the key when the request failed.

### Step 15. Who is calling (unsafe for now): `src/auth.rs`
**File: `src/auth.rs`**
```rust
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
```
`AuthUser` is an extractor too (`FromRequestParts`: it reads only the headers, never the body). A handler that lists `user: AuthUser` among its arguments cannot run without a bearer token: no header is a 401 with the challenge `Bearer realm="tasksteams"`, a header that is not `Bearer <token>` the same.

A JWT is three base64url parts separated by dots: header, payload, signature. The payload is plain JSON. **`unverified_claims` reads the payload and believes it. That is the bug of this chapter**: anyone can write a payload that says `"roles": ["admin"]` and any `sub`. You will do exactly that in *Run it*. Chapter 03 replaces this single function with real validation; nothing else changes, because the rest of the code only sees `AuthUser`.

Two ideas to keep: the **scope** lists what the *client app* may do on behalf of the user (`tasks:read`, `tasks:write`, `tasks:admin`), the **role** says what the *person* is (`admin` or `member`). An action needs both. Missing scope or role is a 403, a missing or bad token a 401.

### Step 16. Query strings and bodies: `src/extract.rs`
Replace the file of chapter 01: `ValidJson` stays the same, and `Params` is new.

**File: `src/extract.rs`**
```rust
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
```
Axum's own `Query` extractor cannot read a repeated parameter into a list (`status=todo&status=blocked`), so `Params` keeps the query string as a list of pairs and offers typed accessors: `parse::<Uuid>("assigneeId")`, `all::<TaskStatus>("status")`, `text("q", 100)`. Each bad value becomes a 400 that names the parameter, as the contract demands. Everything the user can type is checked here before it touches SQL: `limit` between 1 and 100, text lengths, enum words.

### Step 17. ETag, `If-Match` and idempotent creates: `src/http.rs`
**File: `src/http.rs`**
```rust
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
```
**ETag.** The strong ETag of a team, project or task is its quoted `version` (`"3"`); the database trigger raises it on every real change. `with_etag` adds it to a response. A client that wants to change a resource sends the ETag it read in `If-Match`: `require_if_match` answers **428** if the header is missing and **412** if it is not a valid ETag; the store answers 412 if the version moved on. `if_none_match_hit` lets `GET` answer **304 Not Modified** with no body when the client already has the current version.

**Idempotent creates.** `create_once` wraps the work of a `POST`. Without an `Idempotency-Key` it just runs. With one it: (1) hashes the request (path plus canonical JSON body) with SHA-256; (2) asks the store to claim the key; (3) runs the real work only when the claim is `Fresh` and then stores the response (location, ETag, body) with the key; (4) on a repeat answers with the stored response and the header `Idempotent-Replayed: true`; (5) refuses a different body with 422 and a still-running request with 409. The work is passed in as a closure, `|| async { ... }`; `F: FnOnce() -> Fut` says "a function that returns a future, called once".

### Step 18. The handlers: `src/handlers/`
A handler does four things in a fixed order: (1) check the **scope** of the token, (2) find the object and check the caller's **access** to its team (404 for strangers), (3) check the **role** within the team (403) and the **preconditions** (`If-Match`), (4) call the store and shape the answer. Create the folder `src/handlers` (chapter 01 made it) and replace or add these files.

**File: `src/handlers/mod.rs`**
```rust
use axum::http::Uri;
use uuid::Uuid;

use crate::{
    auth::AuthUser,
    error::AppError,
    models::{Project, Task},
    state::AppState,
    store::teams::Access,
};

pub mod audit;
pub mod comments;
pub mod health;
pub mod me;
pub mod members;
pub mod projects;
pub mod tasks;
pub mod teams;
pub mod users;

pub async fn not_found(uri: Uri) -> AppError {
    AppError::NotFound(format!("There is no route for {}.", uri.path()))
}

/// A caller outside the team must not learn that the object exists: they get the 404 text of a missing id.
fn hide(what: &'static str) -> impl FnOnce(AppError) -> AppError {
    move |err| match err {
        AppError::NotFound(_) => AppError::NotFound(format!("The {what} does not exist.")),
        other => other,
    }
}

pub async fn load_project(app: &AppState, user: &AuthUser, project_id: Uuid) -> Result<(Project, Access), AppError> {
    let project = app.store.project(project_id).await?;
    let access = app.store.team_access(user, project.team_id).await.map_err(hide("project"))?;
    Ok((project, access))
}

pub async fn load_task(app: &AppState, user: &AuthUser, task_id: Uuid) -> Result<(Task, Access), AppError> {
    let task = app.store.task(task_id).await?;
    let team_id = app.store.team_of_project(task.project_id).await?;
    let access = app.store.team_access(user, team_id).await.map_err(hide("task"))?;
    Ok((task, access))
}
```
`load_project` and `load_task` fetch an object and its team access in one go. `hide` makes the 404 for "you are not in that team" carry the same text as the 404 for "no such id" (`The project does not exist.`), so even the wording does not reveal that an object exists.

**File: `src/handlers/health.rs`**
```rust
use axum::{
    Json,
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
};

use crate::{models::Health, state::AppState};

pub async fn get_health(State(app): State<AppState>) -> Response {
    let up = app.store.ping().await;
    let health = Health {
        status: if up { "ok" } else { "degraded" },
        version: env!("CARGO_PKG_VERSION"),
        database: Some(if up { "up" } else { "down" }),
    };
    let status = if up { StatusCode::OK } else { StatusCode::SERVICE_UNAVAILABLE };
    (status, Json(health)).into_response()
}
```
Health now asks the database (`SELECT 1`) and answers 503 with `"status": "degraded"` when it cannot be reached; a load balancer or Docker can act on that.

**File: `src/handlers/me.rs`**
```rust
use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    models::Me,
    state::AppState,
};

pub async fn get_me(State(app): State<AppState>, user: AuthUser) -> Result<Json<Me>, AppError> {
    user.require_scope(auth::READ)?;
    let teams = app.store.my_teams(user.id).await?;
    let roles = user.roles.iter().filter(|role| matches!(role.as_str(), "admin" | "member")).cloned().collect();
    Ok(Json(Me {
        id: user.id,
        username: user.username,
        email: user.email,
        display_name: user.display_name,
        roles,
        scopes: user.scopes,
        teams,
    }))
}
```

**File: `src/handlers/users.rs`**
```rust
use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::Params,
    models::{Page, UserSummary},
    state::AppState,
};

pub async fn list_users(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<UserSummary>>, AppError> {
    user.require_scope(auth::READ)?;
    let q = params.text("q", 100)?;
    Ok(Json(app.store.list_users(q.as_deref(), &params.page()?).await?))
}
```

**File: `src/handlers/teams.rs`**
```rust
use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, Team, TeamCreate, TeamUpdate},
    state::AppState,
};

pub async fn list_teams(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<Team>>, AppError> {
    user.require_scope(auth::READ)?;
    let q = params.text("q", 100)?;
    let teams = app.store.list_teams(&user, q.as_deref(), params.newest_first()?, &params.page()?).await?;
    Ok(Json(teams))
}

pub async fn create_team(
    State(app): State<AppState>,
    user: AuthUser,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TeamCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    user.require_admin()?;
    http::create_once(&app, &user, &headers, "/v1/teams", &body, || async {
        let team = app.store.create_team(&user, &body).await?;
        Created::new(format!("/v1/teams/{}", team.id), Some(team.version), &team)
    })
    .await
}

pub async fn get_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    let team = app.store.team(team_id).await?;
    Ok(http::with_etag(StatusCode::OK, team.version, &team))
}

pub async fn update_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TeamUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let team = app.store.update_team(&user, team_id, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, team.version, &team))
}

pub async fn delete_team(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::ADMIN)?;
    user.require_admin()?;
    app.store.delete_team(&user, team_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
```
Read `create_team` slowly; the other handlers repeat its pattern. The **order of the arguments matters**: `ValidJson` consumes the request body, so it must be the **last** argument; the extractors before it only read headers and the URL. Axum checks that at compile time (see *Common mistakes*).

**File: `src/handlers/members.rs`**
```rust
use axum::{
    Json,
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
};
use uuid::Uuid;

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    models::{Member, MemberPut, Page},
    state::AppState,
};

pub async fn list_members(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Member>>, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    Ok(Json(app.store.list_members(team_id, &params.page()?).await?))
}

pub async fn put_member(
    State(app): State<AppState>,
    user: AuthUser,
    Path((team_id, member_id)): Path<(Uuid, Uuid)>,
    ValidJson(body): ValidJson<MemberPut>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let (member, created) = app.store.put_member(&user, team_id, member_id, body.role).await?;
    let status = if created { StatusCode::CREATED } else { StatusCode::OK };
    Ok((status, Json(member)).into_response())
}

pub async fn remove_member(
    State(app): State<AppState>,
    user: AuthUser,
    Path((team_id, member_id)): Path<(Uuid, Uuid)>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    app.store.remove_member(&user, team_id, member_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
```

**File: `src/handlers/projects.rs`**
```rust
use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use super::load_project;
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, Project, ProjectCreate, ProjectUpdate},
    state::AppState,
};

pub async fn list_projects(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Project>>, AppError> {
    user.require_scope(auth::READ)?;
    app.store.team_access(&user, team_id).await?;
    let archived = params.parse::<bool>("archived")?.unwrap_or(false);
    let projects = app.store.list_projects(team_id, archived, params.newest_first()?, &params.page()?).await?;
    Ok(Json(projects))
}

pub async fn create_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(team_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ProjectCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    app.store.team_access(&user, team_id).await?.require_lead()?;
    let path = format!("/v1/teams/{team_id}/projects");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let project = app.store.create_project(&user, team_id, &body).await?;
        Created::new(format!("/v1/projects/{}", project.id), Some(project.version), &project)
    })
    .await
}

pub async fn get_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    let (project, _) = load_project(&app, &user, project_id).await?;
    Ok(http::with_etag(StatusCode::OK, project.version, &project))
}

pub async fn update_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ProjectUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?.1.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let project = app.store.update_project(&user, project_id, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, project.version, &project))
}

pub async fn delete_project(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?.1.require_lead()?;
    app.store.delete_project(&user, project_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
```

**File: `src/handlers/tasks.rs`**
```rust
use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode, header},
    response::{IntoResponse, Response},
};
use uuid::Uuid;

use super::{load_project, load_task};
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Page, ReassignRequest, Task, TaskCreate, TaskUpdate},
    state::AppState,
    store::tasks::TaskFilter,
};

pub async fn list_tasks(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Task>>, AppError> {
    user.require_scope(auth::READ)?;
    load_project(&app, &user, project_id).await?;
    let filter = TaskFilter {
        statuses: params.all("status")?,
        priorities: params.all("priority")?,
        assignee_id: params.parse("assigneeId")?,
        due_before: params.parse("dueBefore")?,
        due_after: params.parse("dueAfter")?,
        q: params.text("q", 100)?,
        sort: params.parse("sort")?.unwrap_or_default(),
    };
    Ok(Json(app.store.list_tasks(project_id, &filter, &params.page()?).await?))
}

pub async fn create_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(project_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TaskCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_project(&app, &user, project_id).await?;
    let path = format!("/v1/projects/{project_id}/tasks");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let task = app.store.create_task(&user, project_id, &body).await?;
        Created::new(format!("/v1/tasks/{}", task.id), Some(task.version), &task)
    })
    .await
}

pub async fn get_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Response, AppError> {
    user.require_scope(auth::READ)?;
    let (task, _) = load_task(&app, &user, task_id).await?;
    if http::if_none_match_hit(&headers, task.version) {
        return Ok((StatusCode::NOT_MODIFIED, [(header::ETAG, http::etag(task.version))]).into_response());
    }
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}

pub async fn update_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<TaskUpdate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    let (task, _) = load_task(&app, &user, task_id).await?;
    let version = http::require_if_match(&headers)?;
    let updated = app.store.update_task(&user, &task, version, &body).await?;
    Ok(http::with_etag(StatusCode::OK, updated.version, &updated))
}

pub async fn delete_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?.1.require_lead()?;
    app.store.delete_task(&user, task_id, http::optional_if_match(&headers)?).await?;
    Ok(StatusCode::NO_CONTENT)
}

/// The rules live in the `complete_task` stored function; this handler only checks who may call it.
pub async fn complete_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?;
    let version = http::require_if_match(&headers)?;
    let task = app.store.complete_task(&user, task_id, version).await?;
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}

pub async fn reassign_task(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<ReassignRequest>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?.1.require_lead()?;
    let version = http::require_if_match(&headers)?;
    let task = app.store.reassign_task(&user, task_id, body.assignee_id, version).await?;
    Ok(http::with_etag(StatusCode::OK, task.version, &task))
}
```
`get_task` shows the conditional GET: when the client's `If-None-Match` equals the current ETag, the answer is `304 Not Modified` with only the `ETag` header and no body. A member may read, create, patch and complete tasks of their team; only a lead (or an admin) may delete or reassign them.

**File: `src/handlers/comments.rs`**
```rust
use axum::{
    Json,
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    response::Response,
};
use uuid::Uuid;

use super::{hide, load_task};
use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::{Params, ValidJson},
    http::{self, Created},
    models::{Comment, CommentCreate, Page},
    state::AppState,
};

pub async fn list_comments(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    params: Params,
) -> Result<Json<Page<Comment>>, AppError> {
    user.require_scope(auth::READ)?;
    load_task(&app, &user, task_id).await?;
    Ok(Json(app.store.list_comments(task_id, &params.page()?).await?))
}

pub async fn create_comment(
    State(app): State<AppState>,
    user: AuthUser,
    Path(task_id): Path<Uuid>,
    headers: HeaderMap,
    ValidJson(body): ValidJson<CommentCreate>,
) -> Result<Response, AppError> {
    user.require_scope(auth::WRITE)?;
    load_task(&app, &user, task_id).await?;
    let path = format!("/v1/tasks/{task_id}/comments");
    http::create_once(&app, &user, &headers, &path, &body, || async {
        let comment = app.store.create_comment(&user, task_id, &body.body).await?;
        Created::new(format!("/v1/comments/{}", comment.id), None, &comment)
    })
    .await
}

/// Allowed for the comment's author, a lead of the team, or an admin.
pub async fn delete_comment(
    State(app): State<AppState>,
    user: AuthUser,
    Path(comment_id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    user.require_scope(auth::WRITE)?;
    let (team_id, author_id) = app.store.comment_context(comment_id).await?;
    let access = app.store.team_access(&user, team_id).await.map_err(hide("comment"))?;
    if author_id != user.id {
        access.require_lead()?;
    }
    app.store.delete_comment(&user, comment_id).await?;
    Ok(StatusCode::NO_CONTENT)
}
```

**File: `src/handlers/audit.rs`**
```rust
use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::Params,
    models::{AuditEntry, Page},
    state::AppState,
    store::audit::AuditFilter,
};

/// Admin role and `tasks:admin` scope: both are needed, either one alone gives 403.
pub async fn list_audit(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<AuditEntry>>, AppError> {
    user.require_scope(auth::ADMIN)?;
    user.require_admin()?;
    let filter = AuditFilter {
        entity_type: params.parse("entityType")?,
        entity_id: params.parse("entityId")?,
        actor_id: params.parse("actorId")?,
        from: params.parse("from")?,
        to: params.parse("to")?,
    };
    Ok(Json(app.store.list_audit(&filter, &params.page()?).await?))
}
```

### Step 19. The router and the program: `src/app.rs`, `src/main.rs`
**File: `src/app.rs`**
```rust
use axum::{
    Router,
    body::Body,
    http::Request,
    middleware,
    routing::{delete, get, post, put},
};
use tower::ServiceBuilder;
use tower_http::{
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    trace::{DefaultOnResponse, TraceLayer},
};
use tracing::Level;

use crate::{
    error::render_problems,
    handlers::{self, audit, comments, health, me, members, projects, tasks, teams, users},
    state::AppState,
};

pub fn router(state: AppState) -> Router {
    let trace = TraceLayer::new_for_http()
        .make_span_with(|request: &Request<Body>| {
            let request_id = request.headers().get("x-request-id").and_then(|value| value.to_str().ok()).unwrap_or("-");
            tracing::info_span!("request", method = %request.method(), path = request.uri().path(), request_id)
        })
        .on_response(DefaultOnResponse::new().level(Level::INFO));

    Router::new()
        .route("/health", get(health::get_health))
        .route("/v1/me", get(me::get_me))
        .route("/v1/users", get(users::list_users))
        .route("/v1/teams", get(teams::list_teams).post(teams::create_team))
        .route("/v1/teams/{team_id}", get(teams::get_team).patch(teams::update_team).delete(teams::delete_team))
        .route("/v1/teams/{team_id}/members", get(members::list_members))
        .route("/v1/teams/{team_id}/members/{user_id}", put(members::put_member).delete(members::remove_member))
        .route("/v1/teams/{team_id}/projects", get(projects::list_projects).post(projects::create_project))
        .route(
            "/v1/projects/{project_id}",
            get(projects::get_project).patch(projects::update_project).delete(projects::delete_project),
        )
        .route("/v1/projects/{project_id}/tasks", get(tasks::list_tasks).post(tasks::create_task))
        .route("/v1/tasks/{task_id}", get(tasks::get_task).patch(tasks::update_task).delete(tasks::delete_task))
        .route("/v1/tasks/{task_id}/complete", post(tasks::complete_task))
        .route("/v1/tasks/{task_id}/reassign", post(tasks::reassign_task))
        .route("/v1/tasks/{task_id}/comments", get(comments::list_comments).post(comments::create_comment))
        .route("/v1/comments/{comment_id}", delete(comments::delete_comment))
        .route("/v1/audit-log", get(audit::list_audit))
        .fallback(handlers::not_found)
        .with_state(state)
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
The router lists exactly the 27 operations of the contract (16 `route` calls cover them, because several methods share a path). `{team_id}` is a **path parameter**; Axum 0.8 uses braces (older versions used `:team_id`). `.with_state(state)` hands the `AppState` to every handler; the layers are unchanged from chapter 01.

**File: `src/main.rs`**
```rust
use std::sync::Arc;

use tasks_api::{app, config::Config, state::AppState, store::Store};
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
    let state = AppState { store, config: Arc::new(config) };
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
New in `main`: the pool is created before the listener (`Store::connect`), so a wrong `DATABASE_URL` stops the program at once with a clear error instead of failing on the first request.

## Run it
### 1. Compile and start
**Terminal (folder: `tasks-api`; the Compose stack from step 1 is running)**
```text
cargo run
```
Expected result: after the compile, `Running ...` and the log line `{"timestamp":"2026-11-23T08:37:34.617324Z","level":"INFO","fields":{"message":"listening","address":"127.0.0.1:8000"},"target":"tasks_api"}`. Leave it running and open a second terminal in the same folder.

### 2. Health, identity and lists
**Terminal 2 (folder: `tasks-api`)**
```text
python scripts/api.py GET /health
```
```text
HTTP 200
content-type: application/json
x-request-id: 2f71285e-e01e-4e38-b602-b10491d68850

{
  "status": "ok",
  "version": "1.0.0",
  "database": "up"
}
```
`--as bob` makes the script get a token from Keycloak first. `/v1/me` reads the caller from the token and his teams from the database:
```text
python scripts/api.py --as bob GET /v1/me
```
```text
HTTP 200
content-type: application/json
x-request-id: 20c49f4a-fc10-4694-916a-20f5989aa8de

{
  "id": "b0b00000-0000-4000-8000-000000000002",
  "username": "bob",
  "email": "bob@tasksteams.test",
  "displayName": "Bob Member",
  "roles": [
    "member"
  ],
  "scopes": [
    "openid",
    "tasks:write",
    "email",
    "tasks:admin",
    "tasks:read",
    "profile"
  ],
  "teams": [
    {
      "teamId": "7ea00000-0000-4000-8000-000000000002",
      "name": "Mobile Team",
      "role": "member"
    },
    {
      "teamId": "7ea00000-0000-4000-8000-000000000001",
      "name": "Platform Team",
      "role": "member"
    }
  ]
}
```
Without a token the answer is a 401 with the Bearer challenge (the order of the `scopes` differs per request: it is a set):
```text
python scripts/api.py GET /v1/me
```
```text
HTTP 401
www-authenticate: Bearer realm="tasksteams"
content-type: application/problem+json
x-request-id: dfc9aee4-d8fe-4a03-a857-699221b8dd95

{
  "type": "https://code101.example/problems/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "a bearer access token is required",
  "instance": "/v1/me",
  "traceId": "dfc9aee4-d8fe-4a03-a857-699221b8dd95"
}
```

### 3. Pages, filters and sorting
The seed project `PLAT` has five tasks. Two per page, oldest first (the output is shortened: each task object is cut to its first lines):
```text
python scripts/api.py --as alice GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?limit=2&sort=createdAt"
```
```text
HTTP 200
content-type: application/json
x-request-id: b3b0f829-f9b4-44c4-83a5-1855cca05fac

{
  "items": [
    {
      "id": "7a500000-0000-4000-8000-000000000001",
      "projectId": "9a000000-0000-4000-8000-000000000001",
      "title": "Write the OpenAPI contract",
      ... (the other 10 fields of the task)
    },
    {
      "id": "7a500000-0000-4000-8000-000000000002",
      "projectId": "9a000000-0000-4000-8000-000000000001",
      "title": "Design the database",
      ... (the other 10 fields of the task)
    }
  ],
  "page": {
    "limit": 2,
    "nextCursor": "WyIyMDI2LTExLTIzVDA4OjM3OjQ3LjA0MTE0MloiLCI3YTUwMDAwMC0wMDAwLTQwMDAtODAwMC0wMDAwMDAwMDAwMDIiXQ"
  }
}
```
The cursor is opaque to a client, but it is just base64url of `["2026-11-23T08:37:47.041142Z","7a500000-0000-4000-8000-000000000002"]`. Pass it back as `cursor=` to get the next two tasks (`Configure Keycloak` and `Run the conformance script`) and a new `nextCursor`; the fifth task comes on a last page whose `nextCursor` is `null`. Filters: two statuses at once, a bad `limit` and a bad cursor:
```text
python scripts/api.py --as alice GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?status=todo&status=blocked&limit=10"
```
```text
HTTP 200
content-type: application/json
x-request-id: 857f180a-09c6-460b-b199-935379c9d400

{
  "items": [
    {
      "id": "7a500000-0000-4000-8000-000000000005",
      "projectId": "9a000000-0000-4000-8000-000000000001",
      "title": "Add rate limiting",
      ... (the other 10 fields of the task)
    },
    {
      "id": "7a500000-0000-4000-8000-000000000004",
      "projectId": "9a000000-0000-4000-8000-000000000001",
      "title": "Run the conformance script",
      ... (the other 10 fields of the task)
    }
  ],
  "page": {
    "limit": 10,
    "nextCursor": null
  }
}
```
```text
python scripts/api.py --as alice GET "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks?limit=500"
```
```text
HTTP 400
content-type: application/problem+json
x-request-id: 994c9a2e-666e-4c60-9dee-e9ee67ab94e0

{
  "type": "https://code101.example/problems/bad-request",
  "title": "Bad request",
  "status": 400,
  "detail": "The query parameter limit is not valid.",
  "instance": "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks",
  "traceId": "994c9a2e-666e-4c60-9dee-e9ee67ab94e0"
}
```
`?cursor=abc` answers 400 with `The cursor is not valid.`

### 4. ETag, `If-Match` and the stored functions
Read task 4 (it is `todo`, version 1) and ask again with its ETag:
```text
python scripts/api.py --as alice GET /v1/tasks/7a500000-0000-4000-8000-000000000004
```
```text
HTTP 200
content-type: application/json
etag: "1"
x-request-id: 760f8c4a-3720-4dd0-9ebb-fa829fe03867

{
  "id": "7a500000-0000-4000-8000-000000000004",
  "projectId": "9a000000-0000-4000-8000-000000000001",
  "title": "Run the conformance script",
  "description": "All checks green on every backend.",
  "status": "todo",
  "priority": "medium",
  "assigneeId": null,
  "dueDate": "2027-02-19",
  "completedAt": null,
  "createdBy": "b0b00000-0000-4000-8000-000000000002",
  "version": 1,
  "createdAt": "2026-11-23T08:37:47.041142Z",
  "updatedAt": "2026-11-23T08:37:47.041142Z"
}
```
```text
python scripts/api.py --as alice GET /v1/tasks/7a500000-0000-4000-8000-000000000004 --if-none-match 1
```
```text
HTTP 304
etag: "1"
x-request-id: 202287d1-bd02-4242-bde6-152e17bed1c8
```
Now change it. First **without** `If-Match` (428), then with the right version (200, the ETag becomes `"2"`), then **again with the old version** (412 because somebody, here yourself, changed it meanwhile). `assigneeId:=null` is raw JSON `null`: it clears the assignee, and `dueDate=2027-03-15` sets a date.
```text
python scripts/api.py --as alice PATCH /v1/tasks/7a500000-0000-4000-8000-000000000004 priority=high
```
```text
HTTP 428
content-type: application/problem+json
x-request-id: 22f5d71a-fd63-48d0-b3cd-8491d35c983a

{
  "type": "https://code101.example/problems/precondition-required",
  "title": "Precondition required",
  "status": 428,
  "detail": "Send the ETag you last read in an If-Match header.",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000004",
  "traceId": "22f5d71a-fd63-48d0-b3cd-8491d35c983a"
}
```
```text
python scripts/api.py --as alice PATCH /v1/tasks/7a500000-0000-4000-8000-000000000004 --if-match 1 priority=high assigneeId:=null dueDate=2027-03-15
```
```text
HTTP 200
content-type: application/json
etag: "2"
x-request-id: b73b2bd5-f447-4b29-b996-888618e28fd1

{
  "id": "7a500000-0000-4000-8000-000000000004",
  "projectId": "9a000000-0000-4000-8000-000000000001",
  "title": "Run the conformance script",
  "description": "All checks green on every backend.",
  "status": "todo",
  "priority": "high",
  "assigneeId": null,
  "dueDate": "2027-03-15",
  "completedAt": null,
  "createdBy": "b0b00000-0000-4000-8000-000000000002",
  "version": 2,
  "createdAt": "2026-11-23T08:39:01.259458Z",
  "updatedAt": "2026-11-23T08:39:31.622306Z"
}
```
```text
python scripts/api.py --as alice PATCH /v1/tasks/7a500000-0000-4000-8000-000000000004 --if-match 1 priority=low
```
```text
HTTP 412
content-type: application/problem+json
x-request-id: a232dad7-f5e7-4b81-a295-8b0b7cfed7f9

{
  "type": "https://code101.example/problems/precondition-failed",
  "title": "Precondition failed",
  "status": 412,
  "detail": "The task changed since you read it (current version 2).",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000004",
  "traceId": "a232dad7-f5e7-4b81-a295-8b0b7cfed7f9"
}
```
An assignee who is not in the project's team is refused with a field error:
```text
python scripts/api.py --as alice PATCH /v1/tasks/7a500000-0000-4000-8000-000000000004 --if-match 2 assigneeId=11111111-1111-4111-8111-111111111111
```
```text
HTTP 422
content-type: application/problem+json
x-request-id: a9d0efe2-22af-4e37-80ab-839dd3ece560

{
  "type": "https://code101.example/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "One or more fields are invalid.",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000004",
  "traceId": "a9d0efe2-22af-4e37-80ab-839dd3ece560",
  "errors": [
    {
      "pointer": "/assigneeId",
      "detail": "must be a member of the project's team"
    }
  ]
}
```
Complete the task (this calls `complete_task`), then try to complete a cancelled task (`PATCH` its status to `cancelled` first), then reassign as a member (403, only leads reassign) and with a stale version (412 comes from the database function this time):
```text
python scripts/api.py --as alice POST /v1/tasks/7a500000-0000-4000-8000-000000000004/complete --if-match 2
```
```text
HTTP 200
content-type: application/json
etag: "3"
x-request-id: 26327f5c-440f-45b5-8743-8386abe05b7f

{
  "id": "7a500000-0000-4000-8000-000000000004",
  "projectId": "9a000000-0000-4000-8000-000000000001",
  "title": "Run the conformance script",
  "description": "All checks green on every backend.",
  "status": "done",
  "priority": "high",
  "assigneeId": null,
  "dueDate": "2027-03-15",
  "completedAt": "2026-11-23T08:39:32.150213Z",
  "createdBy": "b0b00000-0000-4000-8000-000000000002",
  "version": 3,
  "createdAt": "2026-11-23T08:39:01.259458Z",
  "updatedAt": "2026-11-23T08:39:32.150213Z"
}
```
```text
python scripts/api.py --as alice PATCH /v1/tasks/7a500000-0000-4000-8000-000000000005 --if-match 1 status=cancelled
python scripts/api.py --as alice POST /v1/tasks/7a500000-0000-4000-8000-000000000005/complete --if-match 2
```
```text
HTTP 409
content-type: application/problem+json
x-request-id: f07eeed7-ffae-4831-916e-170f3cccb4e5

{
  "type": "https://code101.example/problems/conflict",
  "title": "Conflict",
  "status": 409,
  "detail": "a cancelled task cannot be completed",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000005/complete",
  "traceId": "f07eeed7-ffae-4831-916e-170f3cccb4e5"
}
```
(The first command printed the updated task with status `cancelled`; it is cut here.) The text `a cancelled task cannot be completed` is the message of the SQL function, passed through. Reassign:
```text
python scripts/api.py --as bob POST /v1/tasks/7a500000-0000-4000-8000-000000000004/reassign --if-match 3 assigneeId=b0b00000-0000-4000-8000-000000000002
```
```text
HTTP 403
content-type: application/problem+json
x-request-id: ccbee108-ebb0-4e71-9af9-cbd596a2dc6c

{
  "type": "https://code101.example/problems/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "A team lead or an admin is required.",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000004/reassign",
  "traceId": "ccbee108-ebb0-4e71-9af9-cbd596a2dc6c"
}
```
```text
python scripts/api.py --as alice POST /v1/tasks/7a500000-0000-4000-8000-000000000006/reassign --if-match 9 assigneeId=b0b00000-0000-4000-8000-000000000002
```
```text
HTTP 412
content-type: application/problem+json
x-request-id: 3671c81d-7cf5-4684-95bf-64b9cd6a81fc

{
  "type": "https://code101.example/problems/precondition-failed",
  "title": "Precondition failed",
  "status": 412,
  "detail": "task changed (current version 1)",
  "instance": "/v1/tasks/7a500000-0000-4000-8000-000000000006/reassign",
  "traceId": "3671c81d-7cf5-4684-95bf-64b9cd6a81fc"
}
```
With `--if-match 1` instead the same request answers 200 with `"assigneeId": "b0b00000-0000-4000-8000-000000000002"` and the ETag `"2"`.

### 5. Idempotency, hidden teams and the audit trail
The same create three times: first creates (201), the second replays (same id, `idempotent-replayed: true`), the third has the same key but another title (422). Output shortened to the interesting lines:
```text
python scripts/api.py --as alice POST /v1/projects/9a000000-0000-4000-8000-000000000001/tasks -H "Idempotency-Key: demo-key-0001" title="Write the lesson" priority=high
```
```text
HTTP 201
content-type: application/json
location: http://localhost:8000/v1/tasks/9c630f4f-d5b1-4be6-991f-9decbbf96f62
etag: "1"
x-request-id: e71deb8e-da57-4536-a892-8ea10c4ebc79

{
  "assigneeId": null,
  "completedAt": null,
  "createdAt": "2026-11-23T08:39:33.346111Z",
  "createdBy": "a11ce000-0000-4000-8000-000000000001",
  "description": "",
  "dueDate": null,
  "id": "9c630f4f-d5b1-4be6-991f-9decbbf96f62",
  "priority": "high",
  "projectId": "9a000000-0000-4000-8000-000000000001",
  "status": "todo",
  "title": "Write the lesson",
  "updatedAt": "2026-11-23T08:39:33.346111Z",
  "version": 1
}
```
The replay is identical but carries `idempotent-replayed: true` next to `etag: "1"`, and the third call answers:
```text
HTTP 422
content-type: application/problem+json
x-request-id: 0902536f-8ae4-4ae8-9b5b-49fe25a4930e

{
  "type": "https://code101.example/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "This Idempotency-Key was already used with a different request.",
  "instance": "/v1/projects/9a000000-0000-4000-8000-000000000001/tasks",
  "traceId": "0902536f-8ae4-4ae8-9b5b-49fe25a4930e"
}
```
(The JSON keys of these two answers are in alphabetical order because they went through a `serde_json::Value`; clients do not care.) A team nobody but carol belongs to: alice (admin) creates it with carol as lead, and then **bob gets a 404**, not a 403:
```text
python scripts/api.py --as alice POST /v1/teams name="Secret Team" leadUserId=ca401000-0000-4000-8000-000000000003
python scripts/api.py --as bob GET /v1/teams/8cf8e34f-e91a-46da-b0e3-51716efd5c14
```
```text
HTTP 404
content-type: application/problem+json
x-request-id: a809da63-8c23-4b72-ae33-1a08c13ac7a4

{
  "type": "https://code101.example/problems/not-found",
  "title": "Not found",
  "status": 404,
  "detail": "The team does not exist.",
  "instance": "/v1/teams/8cf8e34f-e91a-46da-b0e3-51716efd5c14",
  "traceId": "a809da63-8c23-4b72-ae33-1a08c13ac7a4"
}
```
(Use the `id` your first command printed.) Creating the same team name again gives 409 `A record with the same name or key already exists.` (the unique index). The audit trail shows who did what, written by the database triggers with the actor you set in each transaction (details shortened):
```text
python scripts/api.py --as alice GET "/v1/audit-log?entityType=task&entityId=7a500000-0000-4000-8000-000000000004&limit=5"
```
```text
HTTP 200
content-type: application/json
x-request-id: 7dd4a3b2-6022-4c91-a4b6-e6cda09055c7

{
  "items": [
    {
      "id": 36,
      "occurredAt": "2026-11-23T08:39:32.150213Z",
      "actorId": "a11ce000-0000-4000-8000-000000000001",
      "action": "update",
      "entityType": "task",
      "entityId": "7a500000-0000-4000-8000-000000000004",
      "details": {
        "completed_at": "2026-11-23T08:39:32.150213+00:00",
        "status": "done"
      }
    },
    {
      "id": 35,
      "occurredAt": "2026-11-23T08:39:31.622306Z",
      "actorId": "a11ce000-0000-4000-8000-000000000001",
      "action": "update",
      "entityType": "task",
      "entityId": "7a500000-0000-4000-8000-000000000004",
      "details": {
        "due_date": "2027-03-15",
        "priority": "high"
      }
    },
    ... (the third entry is the seed insert of the task)
  ],
  "page": {
    "limit": 5,
    "nextCursor": null
  }
}
```
Every update lists only the columns that changed.

### 6. The unsafe part: a forged token
You can write a token yourself. The command below builds a token with the header `{"alg": "none"}`, **no signature**, and a payload that says: "I am bob, I have all scopes and the admin role". Run it in Terminal 2:

**Terminal 2 (folder: `tasks-api`), Windows PowerShell**
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
HTTP 200
content-type: application/json
x-request-id: b2dfc178-b0b3-4005-bbad-6d48e7e958ff

{
  "items": [
    {
      "id": 41,
      "occurredAt": "2026-11-23T08:39:33.883764Z",
      "actorId": "a11ce000-0000-4000-8000-000000000001",
      "action": "create",
      "entityType": "member",
      ... (the whole audit log of the system)
```
**The API gave the audit log, which is admin-only, to a request whose "token" nobody signed.** That is the vulnerability the next chapter closes. Remember how little it took: this is why OWASP lists broken authentication at number 2.

### 7. The conformance script
**Terminal 2 (folder: `tasks-api`)**
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
PASS  create team (201, Location and ETag set, team 2c9cd432-c026-4d6d-84cd-e4818640a7f4)
PASS  create project (201, project 45cc0e2b-2893-42e1-a143-b6b222928468)
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
17 of 18. The one failure is the `RateLimit-*` headers, delivered in chapter 05.

### 8. Stop and clean up
Press Ctrl+C in Terminal 1, then `docker compose -p backend down -v --remove-orphans` in the project folder. Because the volume is removed, the next start begins again with the seed data (every change of this chapter is gone).

## How it works
- **One request, many layers.** `PATCH /v1/tasks/ID` goes through: layers (request id, trace, problem renderer) -> router -> extractors in order (`State`, `AuthUser`, `Path`, `HeaderMap`, `ValidJson`) -> the handler: scope -> `load_task` (the task, then the team access: 404 for strangers) -> `require_if_match` (428) -> `Store::update_task`: begin a transaction as the user, run the `UPDATE ... WHERE version = $2`, commit -> the answer with a new ETag.
- **Who did it.** The API never writes audit rows. Each write transaction starts with `set_config('app.current_user_id', ..., true)`; the database triggers read that setting. The two stored functions set it themselves from their `p_actor_id` argument. So no code path can forget the actor, unless a write skips `begin_as`.
- **Concurrency without locks held across requests.** The ETag is the row `version`. Two clients that read version 1 and both write: the first `UPDATE` makes version 2, the second finds no row with version 1 and gets a 412. No lock stays open between requests.
- **SQL injection.** Every value reaches Postgres as a bind parameter. The only SQL text assembled at run time are column names and keywords chosen in our code. SQLx 0.9 enforces this for whole statements (`&'static str`).
- **New terms:** **pool** (shared database connections), **transaction** (all changes or none), **stored function**, **ETag** (version label of a resource), **optimistic concurrency**, **keyset pagination**, **idempotency key**, **merge patch**, **macro_rules** (a pattern-based code generator), **bind parameter**.

## Try it
Starter: `exercise/starter` (a tiny Cargo project, no dependencies). Implement `page`, the idea behind `PageRequest::fetch`, on a plain list: items sorted by id; return up to `limit` names whose id is greater than `after`, and the cursor (the id of the last returned item) **only** when more items remain. Run it with `cargo run`.

**File: `exercise/starter/src/main.rs`**
```rust
/// `items` is sorted by id. Return the names of up to `limit` items with an id greater than `after`,
/// and the cursor (the id of the last item returned) when more items are left. This is keyset paging.
fn page<'a>(items: &[(u32, &'a str)], after: Option<u32>, limit: usize) -> (Vec<&'a str>, Option<u32>) {
    todo!("filter by `after`, take `limit`, and decide the next cursor")
}

fn main() {
    let items = [(10, "ada"), (20, "bob"), (30, "cy"), (40, "dee"), (50, "eve"), (60, "fay"), (70, "gus")];
    let mut cursor = None;
    loop {
        let (names, next) = page(&items, cursor, 3);
        println!("{names:?} next={next:?}");
        if next.is_none() {
            break;
        }
        cursor = next;
    }
}
```
The starter folder also has a `Cargo.toml` like the one in the solution folder (`name = "keyset-page"`, `edition = "2024"`).

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.rs`**
```rust
/// `items` is sorted by id. Return the names of up to `limit` items with an id greater than `after`,
/// and the cursor (the id of the last item returned) when more items are left. This is keyset paging.
fn page<'a>(items: &[(u32, &'a str)], after: Option<u32>, limit: usize) -> (Vec<&'a str>, Option<u32>) {
    let rest: Vec<&(u32, &str)> = items.iter().filter(|(id, _)| after.is_none_or(|last| *id > last)).collect();
    let names = rest.iter().take(limit).map(|(_, name)| *name).collect();
    let next = if rest.len() > limit { rest.get(limit - 1).map(|(id, _)| *id) } else { None };
    (names, next)
}

fn main() {
    let items = [(10, "ada"), (20, "bob"), (30, "cy"), (40, "dee"), (50, "eve"), (60, "fay"), (70, "gus")];
    let mut cursor = None;
    loop {
        let (names, next) = page(&items, cursor, 3);
        println!("{names:?} next={next:?}");
        if next.is_none() {
            break;
        }
        cursor = next;
    }
}
```
Same trick as the real code: look at one row more than the limit (`rest.len() > limit`) to know whether a next page exists. Expected output:
```text
["ada", "bob", "cy"] next=Some(30)
["dee", "eve", "fay"] next=Some(60)
["gus"] next=None
```
</details>

## Check yourself
1. Why does the API answer 404, not 403, when bob asks for a team he does not belong to? <details><summary>Answer</summary>A 403 confirms that the team exists. With 404 a stranger cannot find out which ids are real (object level authorization, OWASP API1). A member who lacks the lead role is told 403, because he already knows the team.</details>
2. Two people open the same task (version 4) and both save. What happens to the second save and why? <details><summary>Answer</summary>The first `UPDATE ... WHERE version = 4` succeeds and the version becomes 5. The second finds no row with version 4, the store looks up the current version and returns 412 Precondition Failed. The second person must reload and decide.</details>
3. Why does `begin_as` run `set_config(..., true)` inside the transaction? <details><summary>Answer</summary>`true` makes the setting local to the transaction. A pooled connection is reused by other requests; a non-local setting would leak one user's id into the next request's audit rows.</details>
4. Why is `ValidJson` the last argument of a handler? <details><summary>Answer</summary>It consumes the request body, and a body can be read only once. Extractors that only read parts (headers, URL, state) must come before it. Axum checks this at compile time.</details>
5. What does the forged token show? <details><summary>Answer</summary>Reading a token is not validating it. The payload is plain JSON that anyone can write; only the signature, checked with the issuer's public key, proves who wrote it.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| ``error[E0277]: dynamic SQL strings should be audited for possible injections`` ... ``= note: this trait is only implemented for `&'static str`, not all `&str` like the compiler error may suggest`` | SQLx 0.9 accepts only literal SQL in `query` and `query_as`; a `format!` result is not a literal | Keep the SQL a literal. Use bind parameters for values, `QueryBuilder` for optional parts, and a `macro_rules!` plus `concat!` for a shared column list (see step 11b) |
| ``error[E0277]: the trait bound `fn(State<_>, _, Path<Uuid>, _, _) -> _ {update_team}: Handler<_, _>` is not satisfied`` ... ``Consider using `#[axum::debug_handler]` to improve the error message`` | A body extractor (`ValidJson`) is not the **last** argument of the handler (here it came before `HeaderMap`) | Move `ValidJson` to the end |
| ``thread 'main' panicked at src\app.rs:43:10:`` ``Path segments must not start with `:`. For capture groups, use `{capture}`. If you meant to literally match a segment starting with a colon, call `without_v07_checks` on the router.`` | A route written in the old Axum 0.7 style, `/v1/teams/:team_id`; the program exits with code 101 at start | Write `/v1/teams/{team_id}` |
| `Error: "DATABASE_URL is not set"` | No `.env` in the folder you run `cargo run` from, or the variable is missing in it | Copy `.env.example` to `.env` in the project folder |
| `Error: PoolTimedOut` (after about 5 seconds) | Postgres is not running or not reachable at the address in `DATABASE_URL` | `docker compose -p backend up -d --wait`, check `docker ps` |
| `HTTP 412` with `"detail": "The If-Match value is not a current ETag."` although you typed `-H 'If-Match: "1"'` | Windows PowerShell 5 removes the double quotes inside the single-quoted argument, so the header arrived as `If-Match: 1` | Use `--if-match 1`: the script adds the quotes |
| `HTTP 422` with pointer `""` and a text like ``unknown field `colour`, expected one of ...`` | The body has a member the contract does not allow (`deny_unknown_fields`) | Remove it, or fix the spelling (names are camelCase: `leadUserId`) |

The first three rows are real compiler and runtime output (shortened); to reproduce them, put `&format!("SELECT {} FROM teams t WHERE t.id = $1", "t.id")` into `Store::team`, swap the last two arguments of `update_team`, or change a route to `:team_id`, then run `cargo build` or `cargo run`.

## Best practice
Put every rule that must hold for all clients (version checks, who may do what to which row, who changed it) at the narrowest point where it can be enforced, and make the code path to it hard to skip: one `begin_as` for all writes, one `team_access` for all object access, bind parameters for all values. Source: OWASP API Security Top 10 2023, API1 Broken Object Level Authorization https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/

## Next lesson
03. Keycloak token validation: replace the unsafe `unverified_claims` with real validation (cached JWKS, `RS256` only, issuer, audience, expiry), and see the forged token from this chapter refused.
