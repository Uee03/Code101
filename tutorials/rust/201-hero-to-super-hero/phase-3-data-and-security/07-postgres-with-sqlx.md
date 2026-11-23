---
track: rust
level: 201
phase: 3
phase_name: data-and-security
lesson: "07"
title: "Postgres with SQLx"
time: "65-85 min"
prerequisites: ["rust-201-06"]
versions: { rust: "1.100.0 (target)", cargo: "1.100.0 (target)", edition: "2024" }
verified: not yet run
source: source/rust/201-hero-to-super-hero/phase-3-data-and-security/07-postgres-with-sqlx/
assets: []
---

# 07. Postgres with SQLx

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Bind values in runtime SQL without a compile-time database.
- Use a bounded pool and a transaction with explicit rollback.
- Configure disposable Postgres without committing secrets.

## Recap
1. Why not expose database columns automatically as a request DTO?
   <details><summary>Answer</summary>Storage may contain fields clients must not read or write.</details>

2. Does ? log a database error?
   <details><summary>Answer</summary>No. It propagates; the boundary chooses logging and response behavior.</details>

## Why it matters
Persistence introduces an external system and its own failures. Runtime SQLx queries teach typed row mapping without requiring a live database at compile time. Parameter binding keeps data separate from SQL syntax.

## What you will build
Insert Rust, read it inside a transaction, and roll it back. The normal runtime path needs a disposable database; --describe prints the SQL and exits without opening a connection.

## Before you start
- Audience: finished [Rust 101](../../101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md), with 1-2 years of practice. Finish lesson 06 first.
- Target Rust/Cargo 1.100.0, edition 2024. Reuse the Rust 101 installation and editor. No tools were installed for this draft. Exact direct crate versions/features are in the full manifest, checked in official documentation; this is not a claim they are the latest releases.
- Time: 65-85 min. Allow extra time for the first future dependency download.
- Docker/Compose is optional for the later database walk-through, not compilation or --describe. Docker 101 covers installation; nothing is installed or started for this draft.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/201-hero-to-super-hero/phase-3-data-and-security/07-postgres-with-sqlx/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Extract a ZIP: Windows right-click **Extract All**; macOS double-click; Linux use your file manager's **Extract** action. Open the source path above. If copying instead of typing, copy code directly into `$HOME/code101/rust201`, rename the copy lesson07, and do not nest it inside an already-created destination.
- Save as UTF-8. On Windows enable **View, Show, File name extensions** so main.rs does not become main.rs.txt. Save every editor tab; a dot marks unsaved edits. Commands below are future learner instructions, not observed results.
- No Cargo.lock is supplied: Cargo creates it on the first build. Keep/review the generated application lock. Exact direct pins alone do not lock transitive dependencies.

## Steps
### Step 1. Create your project folders
Use the typed route below or the optional copy route, not both. Start in any terminal folder; these home-relative absolute paths recover from the wrong working directory. `$HOME` is your user home on all platforms.

**File: `terminal in any folder (Windows)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust201/lesson07/src"
Set-Location "$HOME/code101/rust201/lesson07"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust201/lesson07/src"
cd "$HOME/code101/rust201/lesson07"
```

Expected result: the prompt ends in lesson07; src and the listed subfolders exist. PowerShell may print directory tables, not program output. Do not overwrite existing work; choose a different local folder name if needed.

### Step 2. Create the complete manifest
In the project root create Cargo.toml in your editor.

**File: `Cargo.toml`**
```toml
[package]
name = "postgres_notes"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "=1.0.100"
sqlx = { version = "=0.8.6", default-features = false, features = ["runtime-tokio", "tls-rustls", "postgres"] }
tokio = { version = "=1.48.0", features = ["macros", "rt-multi-thread"] }
```

[package] names the package; 0.1.0 is its learning-project version and edition 2024 selects language rules. Cargo discovers src/lib.rs as the library and src/main.rs as the binary. [dependencies] lists external crates; an empty table uses std only. Exact = versions pin direct crates and features enable capabilities. No cargo add command is needed.

**Predict before you run:** Which of query_as and query_as! needs compile-time schema metadata? After rollback, should find_note return Some or None for the new id?

Tests below use assert_eq for exact values, assert for conditions and matches for enum patterns. #[cfg(test)] includes a child test module for tests only; #[test] marks a normal test; #[tokio::test] supplies an async runtime where used. These are taught, not executed here. Lesson 09 explains unit, documentation and integration boundaries.

### Step 3. Create `src/lib.rs`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `src/lib.rs`**
```rust
use sqlx::{PgPool, Postgres, Transaction};

pub const FIND_NOTE: &str = "SELECT id, title FROM notes WHERE id = $1";

pub fn valid_title(title: &str) -> bool {
    (1..=80).contains(&title.trim().chars().count())
}

pub async fn insert_note(
    tx: &mut Transaction<'_, Postgres>,
    title: &str,
) -> Result<(i64, String), sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(
        "INSERT INTO notes (title) VALUES ($1) RETURNING id, title",
    ).bind(title).fetch_one(&mut **tx).await
}

pub async fn find_note(pool: &PgPool, id: i64) -> Result<Option<(i64, String)>, sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(FIND_NOTE)
        .bind(id).fetch_optional(pool).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_before_io() {
        assert!(valid_title(" Rust "));
        assert!(!valid_title(" "));
        assert!(!valid_title(&"a".repeat(81)));
    }
}
```

query_as::<_, (i64, String)> is a runtime function, not the query_as! macro. BIGINT maps to i64 and TEXT to String. Tuples implement FromRow without a derive feature, so query macros are unnecessary. A runtime row mismatch remains a runtime error; later database integration checks still matter.

A **parameter placeholder** such as $1 separates query text from a bound value. bind prevents the value from changing SQL syntax. Bind values, not table or column names; identifiers require trusted query construction. fetch_optional distinguishes no row (None) from query failure (Err).

A **transaction** groups operations until commit or rollback. The library receives &mut Transaction, so &mut **tx borrows the underlying connection. main owns its transaction and uses &mut *tx. Neither moves the transaction away.

--describe returns before reading DATABASE_URL or creating a pool. Normal startup bounds the pool at five connections and connection acquisition at five seconds; that is not a timeout for every statement. include_str embeds SQL at compile time without contacting Postgres. The pure title-policy test needs no database.

For the exercise, chars yields characters; any checks whether a predicate matches at least one, and char::is_control identifies controls such as newlines and tabs.

### Step 4. Create `src/main.rs`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `src/main.rs`**
```rust
use anyhow::{ensure, Context, Result};
use postgres_notes::{find_note, insert_note, valid_title, FIND_NOTE};
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().any(|arg| arg == "--describe") {
        println!("runtime SQL: {FIND_NOTE}");
        println!("no database connection opened");
        return Ok(());
    }
    let url = std::env::var("DATABASE_URL").context("set DATABASE_URL in this terminal")?;
    let pool = PgPoolOptions::new().max_connections(5)
        .acquire_timeout(Duration::from_secs(5)).connect(&url).await?;
    sqlx::query(include_str!("../schema.sql")).execute(&pool).await?;
    let title = "Rust";
    ensure!(valid_title(title), "invalid title");
    let mut tx = pool.begin().await?;
    let (id, stored) = insert_note(&mut tx, title).await?;
    let selected: (i64, String) = sqlx::query_as(FIND_NOTE)
        .bind(id).fetch_one(&mut *tx).await?;
    assert_eq!(selected.1, stored);
    println!("stored title: {stored}");
    tx.rollback().await?;
    ensure!(find_note(&pool, id).await?.is_none(), "rollback failed");
    println!("rolled back: true");
    pool.close().await;
    Ok(())
}
```

The binary imports the library using its package name. It owns startup, demonstration output and top-level errors at the application boundary.

### Step 5. Create `schema.sql`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `schema.sql`**
```sql
CREATE TABLE IF NOT EXISTS notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 80)
);
```

This statement gives rows a generated BIGINT primary key and enforces a non-null title with trimmed length 1-80. Changing this file does not migrate an existing table: IF NOT EXISTS leaves the old definition in place. Use a fresh disposable database, not personal data.

### Step 6. Create `.env.example`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `.env.example`**
```dotenv
# Local disposable database only. Replace the value in your private .env.
POSTGRES_PASSWORD=
```

This is the complete reference template, not a credential. Blank values are intentional. Never commit a private .env. Rust does not load it automatically.

### Step 7. Create `.gitignore`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `.gitignore`**
```text
/target/
.env
```

/target/ excludes generated Rust artifacts at the root; .env excludes local private configuration. Cargo.lock is not ignored by Git: Cargo creates it on first build, and applications should normally retain the reviewed generated lock.

### Step 8. Create `compose.yaml`
Create this exact file under $HOME/code101/rust201/lesson07; save the entire content, not a fragment.

**File: `compose.yaml`**
```yaml
services:
  db:
    image: postgres:17.12-alpine3.23
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}
      POSTGRES_DB: notes201
    ports:
      - "127.0.0.1:5547:5432"
    volumes:
      - notes-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d notes201"]
      interval: 2s
      timeout: 3s
      retries: 20
volumes:
  notes-data:
```

services defines one database. image selects the checked Postgres 17 tag. environment provides bootstrap user postgres, a required private password and database notes201. ports binds host 5547 only on loopback and forwards to container 5432. The named volume preserves cluster data at the Postgres 17 data directory. healthcheck runs pg_isready every two seconds, gives probes three seconds and allows twenty failures; readiness is not proof every query works. The top-level volumes entry declares that storage. Removing ports prevents host Rust access; changing the password does not rewrite an initialized database. Use the same Compose project name in startup and cleanup.

## Run it
Save every file. This command runs in the project root on Windows/macOS/Linux. It is for a future walk-through; no author runtime result is claimed.

**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
cargo run --quiet -- --describe
```

Expected output, not yet run (derived from source; Cargo download/build messages omitted):

**File: `terminal standard output`**
```text
runtime SQL: SELECT id, title FROM notes WHERE id = $1
no database connection opened
```

--describe reads no environment variable and opens no connection. It does not validate the SQL against a schema.

### Check the supplied feature tests later
From this same project root, on all platforms:

**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
cargo test
```

Expected result, not yet run: the finished example's assertions pass. Harness paths, timings and test order are not assumed. No test suite was run while authoring.

### Optional database walk-through
These are instructions for a later learner run, not actions performed during authoring. Use only a disposable database. Compose uses an official image, so no Dockerfile is needed. No IDE plugin is required: the client below runs inside the database container.

1. In this project's root, copy .env.example to .env; do not overwrite existing private work. Windows:
**File: `terminal in $HOME/code101/rust201/lesson07 (Windows)`**
```powershell
Copy-Item .env.example .env
```
**File: `terminal in $HOME/code101/rust201/lesson07 (macOS/Linux)`**
```bash
cp .env.example .env
```
Expected result: a private .env appears. Open it in your editor. Set POSTGRES_PASSWORD to a unique disposable ASCII letters/digits value, at least 24 characters. Do not copy a real service password or paste it into this lesson. Save. The Compose required-value expression rejects an empty password; .gitignore is not a secrets vault.

2. In the same terminal set DATABASE_URL with that identical private value. Replace the placeholder inside the quotes before pressing Enter; do not use the literal placeholder. Shell history may store commands, so keep this value disposable. Windows:
**File: `terminal in $HOME/code101/rust201/lesson07 (Windows)`**
```powershell
$env:DATABASE_URL = "postgres://postgres:REPLACE_WITH_YOUR_LOCAL_VALUE@127.0.0.1:5547/notes201?sslmode=disable"
```
**File: `terminal in $HOME/code101/rust201/lesson07 (macOS/Linux)`**
```bash
export DATABASE_URL="postgres://postgres:REPLACE_WITH_YOUR_LOCAL_VALUE@127.0.0.1:5547/notes201?sslmode=disable"
```
The user is postgres, database notes201 and host port 5547. sslmode=disable is for this local disposable loopback setup only. Rust does not load .env. Expected result: assignment sets the variable in this shell and prints no value. Do not echo it into a screenshot/log.

3. Start, inspect status, read logs and check readiness (all platforms, project root):
**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
docker compose -p rust201-sqlx up -d --wait
docker compose -p rust201-sqlx ps
docker compose -p rust201-sqlx logs --tail 20 db
docker compose -p rust201-sqlx exec -T db pg_isready -U postgres -d notes201
```
Expected output, not yet run: up finishes after health succeeds; ps lists db as running/healthy at host port 5547; logs show database startup. Ids, timings and exact log text vary and are deliberately not invented. pg_isready should report that connections are accepted; trust its real message and exit status rather than an assumed transcript.

4. Run the normal application, still in the shell with DATABASE_URL:
**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
cargo run --quiet
```

Expected output, not yet run (derived from source; build messages omitted):

**File: `terminal standard output`**
```text
stored title: Rust
rolled back: true
```
5. Inspect the remaining count with the included container client:
**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
docker compose -p rust201-sqlx exec -T db psql -U postgres -d notes201 -Atc "SELECT count(*) FROM notes;"
```

Expected output, not yet run (derived from source; build messages omitted):

**File: `terminal standard output`**
```text
0
```
Zero assumes a fresh volume and no other writers; existing data can change it. The program itself checks only its own rolled-back id and never assumes that id is 1. Identity sequences can advance despite rollback.

6. Stop/remove this lesson's container, network and volume. -v destroys this disposable database; never use it for data you need:
**File: `terminal in $HOME/code101/rust201/lesson07`**
```powershell
docker compose -p rust201-sqlx down -v --remove-orphans
```
Expected output, not yet run: Compose reports removal of this project's resources; names/progress vary. The downloaded image is a local cache, not a running service. Clear the variable afterward. Windows:
**File: `terminal in $HOME/code101/rust201/lesson07 (Windows)`**
```powershell
Remove-Item Env:DATABASE_URL
```
**File: `terminal in $HOME/code101/rust201/lesson07 (macOS/Linux)`**
```bash
unset DATABASE_URL
```
Expected result: the variable is absent in this shell. If finished, delete the private .env through your editor/file manager. No actual password or connection-string file ships in this pack. Docker 101 covers Docker Desktop/Compose installation; no installation or startup was performed for this draft.

## How it works
A **connection pool** shares a bounded set of connections. Startup creates the teaching table with one SQL statement; the CHECK also protects nonempty/length invariants from direct SQL writers. After application validation, insert and select share one transaction, followed by explicit rollback. SQLx also rolls back uncommitted transactions on drop; explicit rollback makes this example's intent clear. The pool query then finds no row.

The table remains until its disposable volume is removed. Identity sequences are not rolled back; id gaps are normal. CREATE TABLE IF NOT EXISTS is a lesson convenience, not a migration system or a schema upgrade mechanism.

**Why this, not that:** runtime functions remove compile-time schema coupling. query! and query_as! offer compile-time checks with a live database or prepared metadata; neither is used here. Parameter binding is required in both styles. Never format untrusted input into SQL text.

The Docker postgres superuser is a bootstrap account for this throwaway exercise only. Remote databases need verified TLS and a least-privilege application role; use the capstone data chapter. A local sslmode=disable URL is only for this loopback setup. Rust does not load .env automatically; Compose's environment is separate from the host application's.

**Structure:**

**File: `lesson architecture diagram`**
```mermaid
flowchart LR
    A[application] --> P[pool: max 5]
    P --> T[transaction]
    T --> I[INSERT bind title]
    I --> S[SELECT bind id]
    S --> R[rollback]
    R --> N[find returns None]
```

## Try it
### Rung 1. Guided practice
Reject control characters anywhere in the original title, even when trim would remove them. Keep length validation and ordinary spaces. The starter adds tests for a newline and tab. Do not change SQL construction or pretend pure tests validate SQL.

Work separately in `$HOME/code101/rust201/try07`. Optional download route: from `source/rust/201-hero-to-super-hero/phase-3-data-and-security/07-postgres-with-sqlx/exercise`, copy starter directly into `$HOME/code101/rust201`, then rename the copied folder try07. Do not first create try07 and put starter inside it. Use this route only if the destination does not exist.

Typed route without a download: create the exact directories below, then every starter file shown. Start in any terminal folder.

**File: `terminal in any folder (Windows)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust201/try07/src"
Set-Location "$HOME/code101/rust201/try07"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust201/try07/src"
cd "$HOME/code101/rust201/try07"
```

Expected result: a separate exercise root, not a nested starter directory.

**File: `try07/Cargo.toml (starter)`**
```toml
[package]
name = "postgres_notes"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "=1.0.100"
sqlx = { version = "=0.8.6", default-features = false, features = ["runtime-tokio", "tls-rustls", "postgres"] }
tokio = { version = "=1.48.0", features = ["macros", "rt-multi-thread"] }
```

**File: `try07/src/lib.rs (starter)`**
```rust
use sqlx::{PgPool, Postgres, Transaction};

pub const FIND_NOTE: &str = "SELECT id, title FROM notes WHERE id = $1";

pub fn valid_title(title: &str) -> bool {
    // TODO: also reject control characters in the original title.
    (1..=80).contains(&title.trim().chars().count())
}

pub async fn insert_note(
    tx: &mut Transaction<'_, Postgres>,
    title: &str,
) -> Result<(i64, String), sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(
        "INSERT INTO notes (title) VALUES ($1) RETURNING id, title",
    ).bind(title).fetch_one(&mut **tx).await
}

pub async fn find_note(pool: &PgPool, id: i64) -> Result<Option<(i64, String)>, sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(FIND_NOTE)
        .bind(id).fetch_optional(pool).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_before_io() {
        assert!(valid_title(" Rust "));
        assert!(!valid_title(" "));
        assert!(!valid_title("two\nlines"));
        assert!(!valid_title("tab\tstop"));
        assert!(!valid_title(&"a".repeat(81)));
    }
}
```

**File: `try07/src/main.rs (starter)`**
```rust
use anyhow::{ensure, Context, Result};
use postgres_notes::{find_note, insert_note, valid_title, FIND_NOTE};
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().any(|arg| arg == "--describe") {
        println!("runtime SQL: {FIND_NOTE}");
        println!("no database connection opened");
        return Ok(());
    }
    let url = std::env::var("DATABASE_URL").context("set DATABASE_URL in this terminal")?;
    let pool = PgPoolOptions::new().max_connections(5)
        .acquire_timeout(Duration::from_secs(5)).connect(&url).await?;
    sqlx::query(include_str!("../schema.sql")).execute(&pool).await?;
    let title = "Rust";
    ensure!(valid_title(title), "invalid title");
    let mut tx = pool.begin().await?;
    let (id, stored) = insert_note(&mut tx, title).await?;
    let selected: (i64, String) = sqlx::query_as(FIND_NOTE)
        .bind(id).fetch_one(&mut *tx).await?;
    assert_eq!(selected.1, stored);
    println!("stored title: {stored}");
    tx.rollback().await?;
    ensure!(find_note(&pool, id).await?.is_none(), "rollback failed");
    println!("rolled back: true");
    pool.close().await;
    Ok(())
}
```

**File: `try07/schema.sql (starter)`**
```sql
CREATE TABLE IF NOT EXISTS notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 80)
);
```

**File: `try07/.env.example (starter)`**
```dotenv
# Local disposable database only. Replace the value in your private .env.
POSTGRES_PASSWORD=
```

**File: `try07/.gitignore (starter)`**
```text
/target/
.env
```

**File: `try07/compose.yaml (starter)`**
```yaml
services:
  db:
    image: postgres:17.12-alpine3.23
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}
      POSTGRES_DB: notes201
    ports:
      - "127.0.0.1:5547:5432"
    volumes:
      - notes-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d notes201"]
      interval: 2s
      timeout: 3s
      retries: 20
volumes:
  notes-data:
```

Save the TODO changes, then use these commands in the exercise root (all platforms):

**File: `terminal in $HOME/code101/rust201/try07`**
```powershell
cargo run --quiet -- --describe
cargo test
```

Expected output, not yet run (derived from source; Cargo download/build messages omitted):

**File: `terminal standard output`**
```text
runtime SQL: SELECT id, title FROM notes WHERE id = $1
no database connection opened
```

This is the completed guided target, not a claim the untouched starter satisfies it. The supplied assertions identify the policy to complete; do not delete them to get a green result.

### Rung 2. Change the behavior or coverage
Experiment with commit in a separate disposable database. Read the committed note through find_note, then remove that database. Explain why repeating the rollback demo cannot prove commit behavior.

### Rung 3. Stretch (optional)
Design migrations and a least-privilege role instead of startup CREATE TABLE. Follow the capstone rather than copying its full schema.

<details><summary>Solution: complete guided project</summary>

These files solve Rung 1 only. Compare after attempting the TODO. Supporting files are included so no download is required. Rung 2 and the optional design question remain your work.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "postgres_notes"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "=1.0.100"
sqlx = { version = "=0.8.6", default-features = false, features = ["runtime-tokio", "tls-rustls", "postgres"] }
tokio = { version = "=1.48.0", features = ["macros", "rt-multi-thread"] }
```

**File: `exercise/solution/src/lib.rs`**
```rust
use sqlx::{PgPool, Postgres, Transaction};

pub const FIND_NOTE: &str = "SELECT id, title FROM notes WHERE id = $1";

pub fn valid_title(title: &str) -> bool {
    (1..=80).contains(&title.trim().chars().count())
        && !title.chars().any(|ch| ch.is_control())
}

pub async fn insert_note(
    tx: &mut Transaction<'_, Postgres>,
    title: &str,
) -> Result<(i64, String), sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(
        "INSERT INTO notes (title) VALUES ($1) RETURNING id, title",
    ).bind(title).fetch_one(&mut **tx).await
}

pub async fn find_note(pool: &PgPool, id: i64) -> Result<Option<(i64, String)>, sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(FIND_NOTE)
        .bind(id).fetch_optional(pool).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_before_io() {
        assert!(valid_title(" Rust "));
        assert!(!valid_title(" "));
        assert!(!valid_title("two\nlines"));
        assert!(!valid_title("tab\tstop"));
        assert!(!valid_title(&"a".repeat(81)));
    }
}
```

**File: `exercise/solution/src/main.rs`**
```rust
use anyhow::{ensure, Context, Result};
use postgres_notes::{find_note, insert_note, valid_title, FIND_NOTE};
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().any(|arg| arg == "--describe") {
        println!("runtime SQL: {FIND_NOTE}");
        println!("no database connection opened");
        return Ok(());
    }
    let url = std::env::var("DATABASE_URL").context("set DATABASE_URL in this terminal")?;
    let pool = PgPoolOptions::new().max_connections(5)
        .acquire_timeout(Duration::from_secs(5)).connect(&url).await?;
    sqlx::query(include_str!("../schema.sql")).execute(&pool).await?;
    let title = "Rust";
    ensure!(valid_title(title), "invalid title");
    let mut tx = pool.begin().await?;
    let (id, stored) = insert_note(&mut tx, title).await?;
    let selected: (i64, String) = sqlx::query_as(FIND_NOTE)
        .bind(id).fetch_one(&mut *tx).await?;
    assert_eq!(selected.1, stored);
    println!("stored title: {stored}");
    tx.rollback().await?;
    ensure!(find_note(&pool, id).await?.is_none(), "rollback failed");
    println!("rolled back: true");
    pool.close().await;
    Ok(())
}
```

**File: `exercise/solution/schema.sql`**
```sql
CREATE TABLE IF NOT EXISTS notes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL CHECK (char_length(btrim(title)) BETWEEN 1 AND 80)
);
```

**File: `exercise/solution/.env.example`**
```dotenv
# Local disposable database only. Replace the value in your private .env.
POSTGRES_PASSWORD=
```

**File: `exercise/solution/.gitignore`**
```text
/target/
.env
```

**File: `exercise/solution/compose.yaml`**
```yaml
services:
  db:
    image: postgres:17.12-alpine3.23
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in .env}
      POSTGRES_DB: notes201
    ports:
      - "127.0.0.1:5547:5432"
    volumes:
      - notes-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d notes201"]
      interval: 2s
      timeout: 3s
      retries: 20
volumes:
  notes-data:
```

</details>

## Check yourself
1. Why can the crate compile without DATABASE_URL?
   <details><summary>Answer</summary>It uses runtime query functions and embedded SQL text, not compile-time query macros.</details>

2. How do None and Err differ from find_note?
   <details><summary>Answer</summary>None means a successful query found no row. Err means a query or connection failure.</details>

3. Does .env.example configure the Rust process?
   <details><summary>Answer</summary>No. Compose reads its input file; the host process needs DATABASE_URL set in its own shell.</details>

## Common mistakes
These are symptoms and fixes, not fabricated compiler transcripts. Read your tool's actual diagnostic and file/line first.

| Symptom | Cause | Fix |
|---|---|---|
| Wrong project runs or no manifest is found. | Terminal is outside this project. | Return to `$HOME/code101/rust201/lesson07`, next to Cargo.toml. |
| Your edit changes nothing. | The buffer was not saved. | Save all tabs, then run from the project root. |
| DATABASE_URL is unavailable. | It exists in a file or another shell, not this environment. | Set it in the same terminal before cargo run. |
| Changing POSTGRES_PASSWORD does not fix an old volume. | That variable initializes a fresh cluster; it does not rewrite an existing role. | For disposable lesson data only, remove its volume and recreate it; never erase real data to fix credentials. |
| A runtime query fails after a schema edit. | No compile-time SQL check was claimed. | Read the actual database error, compare column types and later run database integration checks. |

## Best practice
Bind untrusted values and keep connection limits and transaction boundaries explicit. Source: [SQLx 0.8.6 runtime and TLS features](https://docs.rs/sqlx/0.8.6/sqlx/); [SQLx query_as and tuple mapping](https://docs.rs/sqlx/0.8.6/sqlx/fn.query_as.html); [SQLx transactions](https://docs.rs/sqlx/0.8.6/sqlx/struct.Transaction.html); [Postgres official image](https://hub.docker.com/_/postgres).

## Going further
- [SQLx 0.8.6 runtime and TLS features](https://docs.rs/sqlx/0.8.6/sqlx/) (official; version checked where applicable).
- [SQLx query_as and tuple mapping](https://docs.rs/sqlx/0.8.6/sqlx/fn.query_as.html) (official; version checked where applicable).
- [SQLx transactions](https://docs.rs/sqlx/0.8.6/sqlx/struct.Transaction.html) (official; version checked where applicable).
- [Postgres official image](https://hub.docker.com/_/postgres) (official; version checked where applicable).
- [Rust backend capstone](../../../../capstones/backend-rust/README.md): data, identity and API hardening rather than a duplicate capstone inside this level.
## Summary
- You practiced how to bind values in runtime SQL without a compile-time database.
- You practiced how to use a bounded pool and a transaction with explicit rollback.
- You practiced how to configure disposable Postgres without committing secrets.
- You distinguished expected draft behavior from observed runtime evidence.

## Next lesson
[08. Authentication middleware with Tower](08-authentication-middleware-with-tower.md): establish identity before protected requests perform work.
