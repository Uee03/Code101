---
track: capstone
level: 301
phase: 4
phase_name: run-and-ship
lesson: 04
title: "Docker image and Compose"
time: 75 min
prerequisites: [capstone-backend-rust-03, docker-101]
versions: { rust_image: "rust:1.100.0-slim-trixie", runtime_image: "gcr.io/distroless/cc-debian13:nonroot", docker: "29.9.3", compose: "5.7.0" }
verified: 2026-11-23 on Windows 11, Rust 1.100.0, Docker CLI/Engine 29.9.3, Compose 5.7.0, Python 3.15.2
source: capstones/backend-rust/source/phase-4-run-and-ship/04-docker-image-and-compose/
assets: []
---

# 04. Docker image and Compose

## Why it matters
A food truck is a kitchen packed into a van: it has everything it needs, nothing it does not, and it works the same in any car park. A container image is that van. A careless image is a van with a whole restaurant inside: gigabytes, a shell for intruders to use, the cooking tools left on board and the owner's keys in the glove box. This chapter packs the API into a small van: the compiler stays in the workshop, the van carries only the program, and it drives as a normal user, not as root.

## What you will build
A multi-stage `Dockerfile` (a build stage that compiles in release mode and a tiny runtime stage), a `.dockerignore`, a `healthcheck` mode inside the program (the image has no `curl`), and a `docker-compose.override.yml` that adds the API to the platform stack on the network `tasksteams-net` and publishes `127.0.0.1:8000`. One command starts Postgres, Keycloak and the Rust API; the conformance score stays at **17 of 18**.

## Before you start
- Chapter 03 done (or its pack unzipped). This chapter's pack is `backend-rust-phase-4-run-and-ship.zip`, folder `04-docker-image-and-compose/code`.
- Docker running in Linux-container mode, host ports 5432, 8000 and 8180 free. **Stop a `cargo run` of the API first** (it uses port 8000).
- Unchanged from earlier chapters, so not repeated here: `.env.example`, `.gitignore`, `rustfmt.toml`, `docker-compose.yml`, `db/`, `keycloak/`, `scripts/` and every file of `src/` except `main.rs`.
- Image tags checked on Docker Hub and the distroless registry on 2026-11-23: `rust:1.100.0-slim-trixie` (Rust 1.100.0 on Debian 13 "trixie", slim variant) and `gcr.io/distroless/cc-debian13:nonroot` (Debian 13 runtime libraries: glibc and nothing else, user `nonroot`). The build and the run image use the same Debian release, so the glibc of the compiled program matches the one it runs on.

## Steps
### Step 1. Why two stages
Compiling Rust needs the compiler, headers and several hundred megabytes. Running the result needs only the finished program and the C library. A *multi-stage build* uses one image to build and copies just the program into a second, minimal image: the final image has no compiler, no shell and no package manager, so there is little for an attacker to use and little to download.

### Step 2. The health check inside the program: `Cargo.toml`, `src/main.rs`
Docker and Compose need a way to ask "is the program healthy?". The usual answer is `curl http://localhost:8000/health`, but our runtime image has no `curl`, no `wget` and no shell. So the program itself gets a second job: when it is started as `tasks-api healthcheck` it makes one request to its own `/health` and exits with 0 (healthy) or 1.

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
tokio = { version = "1", features = ["io-util", "macros", "net", "rt-multi-thread", "signal", "time"] }
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
The only change: Tokio gets the features `io-util` (to read and write a TCP stream) and `time` (for `timeout`). The release profile of chapter 01 now matters: `cargo build --release` produces a smaller, faster program, and `strip = true` removes the debug symbols.

**File: `src/main.rs`**
```rust
use std::{error::Error, sync::Arc, time::Duration};

use tasks_api::{app, config::Config, jwks::Authenticator, state::AppState, store::Store};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    signal,
    time::timeout,
};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    dotenvy::dotenv().ok();
    let config = Config::from_env()?;
    // `tasks-api healthcheck` is what Docker runs: the image has no shell, curl or wget.
    if std::env::args().nth(1).as_deref() == Some("healthcheck") {
        return healthcheck(&config).await.inspect_err(|err| eprintln!("unhealthy: {err}"));
    }
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let store = Store::connect(&config.database_url).await?;
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(address = %config.bind_addr, "listening");
    let state = AppState { store, auth: Arc::new(Authenticator::new(&config)), config: Arc::new(config) };
    axum::serve(listener, app::router(state)).with_graceful_shutdown(shutdown_signal()).await?;
    Ok(())
}

/// Asks the running server on this machine for `GET /health` and succeeds only on a 200.
async fn healthcheck(config: &Config) -> Result<(), Box<dyn Error>> {
    let limit = Duration::from_secs(3);
    let mut stream = timeout(limit, TcpStream::connect(("127.0.0.1", config.bind_addr.port()))).await??;
    stream.write_all(b"GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n").await?;
    let mut reply = String::new();
    timeout(limit, stream.read_to_string(&mut reply)).await??;
    match reply.lines().next() {
        Some(status) if status.starts_with("HTTP/1.1 200") => Ok(()),
        other => Err(format!("the server answered {}", other.unwrap_or("nothing")).into()),
    }
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
`healthcheck` opens a TCP connection to `127.0.0.1` on the port from `BIND_ADDR` (inside the container the program itself listens there), writes a minimal HTTP request by hand, reads the whole reply and checks that the status line begins `HTTP/1.1 200`. Both steps are wrapped in `timeout(3 s)`: a health check that can hang is worse than none. Because `/health` asks the database, a lost database also makes the container *unhealthy*. The error is printed with `eprintln!` and returned from `main`, so the exit code is 1. The configuration is read before the logger starts, so the health check prints nothing but its own message. (`?` after `.await?` appears twice because `timeout` itself returns a `Result`: the outer one means "timed out", the inner one is the I/O result.)

### Step 3. The `Dockerfile`
**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1

# ---- Stage 1: build ---------------------------------------------------------
FROM rust:1.100.0-slim-trixie AS build
WORKDIR /app

# Layer A: the dependencies only. A stub program lets Cargo compile every crate once.
# Docker reuses this layer as long as Cargo.toml and Cargo.lock do not change.
COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && touch src/lib.rs \
    && echo "fn main() {}" > src/main.rs \
    && cargo build --release --locked \
    && rm -rf src

# Layer B: our own code. Only this layer is rebuilt after an edit in src/.
# COPY keeps the old file times of your disk, which look older than the stub build above, so Cargo would
# call the stub "up to date" and ship it. `touch` gives the real files a new time and forces the rebuild.
COPY src ./src
RUN touch src/lib.rs src/main.rs \
    && cargo build --release --locked

# ---- Stage 2: run -----------------------------------------------------------
# distroless "cc" has glibc and nothing else: no shell, no package manager. "nonroot" is user 65532.
FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /app/target/release/tasks-api /usr/local/bin/tasks-api
USER nonroot:nonroot
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 CMD ["/usr/local/bin/tasks-api", "healthcheck"]
ENTRYPOINT ["/usr/local/bin/tasks-api"]
```
Line by line:
- `# syntax=docker/dockerfile:1` selects the current Dockerfile language (BuildKit).
- `FROM rust:1.100.0-slim-trixie AS build` starts stage 1 from an image with Rust 1.100.0. The tag is **pinned** to an exact version, so a build next year uses the same compiler (a floating tag such as `rust:latest` changes under you). `AS build` names the stage. `WORKDIR /app` sets the folder of all following commands.
- **Layer A, the dependency trick.** Docker caches every instruction; an instruction is rebuilt only when its inputs changed. Dependencies change rarely, our code often. So we first copy **only** `Cargo.toml` and `Cargo.lock`, create a stub `src/lib.rs` (empty) and a `src/main.rs` that does nothing, and build in release mode. Cargo downloads and compiles every crate (the slow part, about half a minute here, longer on a slow disk). `--locked` makes the build fail if `Cargo.lock` does not match `Cargo.toml`, instead of silently choosing other versions. Finally `rm -rf src` removes the stub. This layer is reused until `Cargo.toml` or `Cargo.lock` change.
- **Layer B.** `COPY src ./src` brings in the real code and `cargo build --release --locked` compiles **only our crate**; the dependencies are already built. The line `touch src/lib.rs src/main.rs` is essential: `COPY` keeps the *file times from your disk*, which are older than the stub build of layer A, so Cargo could decide the stub is "up to date" and ship it (see *Common mistakes*). `touch` gives the files the current time.
- **Stage 2.** `FROM gcr.io/distroless/cc-debian13:nonroot` starts a new, tiny image: the C runtime libraries and a non-root user, no shell, no `apt`. `COPY --from=build` takes just the one finished program out of stage 1; everything else of stage 1 (the compiler, the sources, `target/`) is thrown away. `USER nonroot:nonroot` makes the process run as user 65532, never as root. `EXPOSE 8000` documents the port. `HEALTHCHECK` tells Docker to run `tasks-api healthcheck` every 10 seconds (waiting at most 5, allowing a 5 second start-up, three failures make the container `unhealthy`). `ENTRYPOINT` is the program that starts; with the exec form (square brackets) the program is process 1 and receives `docker stop`'s SIGTERM directly, which is why graceful shutdown works.

### Step 4. `.dockerignore`
**File: `.dockerignore`**
```text
*
!Cargo.toml
!Cargo.lock
!src/
```
The *build context* is the folder Docker sends to the builder. `*` excludes everything, and the three `!` lines let back in only what the image needs. This is an *allow-list*: your `.env` (with settings), `target/` (gigabytes), `.git` and the `db/` folder can never end up in the image or its cache, even if you add files later. Remove the `*` approach and a copied `.env` would be baked into a layer that anyone who gets the image can read.

### Step 5. The Compose override: `docker-compose.override.yml`
Compose automatically merges `docker-compose.override.yml` into `docker-compose.yml` when both are in the folder. The platform file stays untouched and we only add one service.

**File: `docker-compose.override.yml`**
```yaml
# Compose merges this file into docker-compose.yml (the platform file) automatically.
# It adds the API as a third service on the same network as Postgres and Keycloak.
services:
  api:
    build: .
    image: code101/tasks-api-rust:local
    depends_on:
      db:
        condition: service_healthy
      keycloak:
        condition: service_healthy
    environment:
      BIND_ADDR: 0.0.0.0:8000
      PUBLIC_BASE_URL: http://localhost:8000
      DATABASE_URL: postgres://tasks_app:tasks_app_local_only@db:5432/${POSTGRES_DB:-tasksteams}
      TOKEN_ISSUER: http://localhost:${KEYCLOAK_PORT:-8180}/realms/tasksteams
      TOKEN_AUDIENCE: tasks-api
      JWKS_URL: http://keycloak:8080/realms/tasksteams/protocol/openid-connect/certs
      RUST_LOG: info
    ports:
      - "127.0.0.1:8000:8000"
    healthcheck:
      test: ["CMD", "/usr/local/bin/tasks-api", "healthcheck"]
      interval: 5s
      timeout: 5s
      retries: 12
      start_period: 3s
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    networks:
      - tasksteams
```
- `build: .` builds the image from the `Dockerfile` in this folder; `image:` names the result `code101/tasks-api-rust:local` so you can find and remove it later.
- `depends_on` with `condition: service_healthy` starts the API only after Postgres and Keycloak report healthy; `up --wait` also waits for the API itself.
- `environment`: inside the container the program listens on `0.0.0.0:8000` (all addresses *of the container*); `DATABASE_URL` uses the **service name** `db` as host name (Compose gives every service a DNS name on the shared network); `TOKEN_ISSUER` stays `localhost:8180`, because that is the host name inside the tokens (set by `KC_HOSTNAME` in the platform file); `JWKS_URL` uses the **Docker-internal** address `keycloak:8080`, where the keys are fetched. This is why chapter 03 kept issuer and JWKS URL apart. The `${NAME:-default}` parts read your `.env`, with a default.
- `ports: "127.0.0.1:8000:8000"` publishes the container port on **loopback only**: only your own machine can call the API. Writing `"8000:8000"` would expose it on every network interface.
- `healthcheck` repeats the check for Compose (5 second interval, up to 12 tries); `read_only: true` makes the container's root file system read-only (the API writes no files); `cap_drop: [ALL]` removes every Linux capability; `no-new-privileges` stops the process from gaining rights. None of them changes behaviour; each removes something an attacker could use.
- `networks: [tasksteams]` joins the network defined in the platform file (`tasksteams-net`), which is how the API reaches `db` and `keycloak`.

## Run it
**Terminal (folder: `tasks-api`; stop other stacks and `cargo run` first)**
```text
docker compose -p backend up -d --build --wait
```
The first build compiles everything and takes a minute or three. The end of the output:
```text
 Container devrust-db-1 Healthy 
 Container devrust-keycloak-1 Healthy 
 Container devrust-api-1 Healthy 
```
(The container names start with the project name you gave with `-p`; with `-p backend` they read `backend-api-1` and so on.)
```text
docker compose -p backend ps
```
```text
NAME                 IMAGE                              COMMAND                  SERVICE    CREATED          STATUS                    PORTS
devrust-api-1        code101/tasks-api-rust:local       "/usr/local/bin/task…"   api        29 seconds ago   Up 3 seconds (healthy)    127.0.0.1:8000->8000/tcp
devrust-db-1         postgres:17-alpine                 "docker-entrypoint.s…"   db         29 seconds ago   Up 29 seconds (healthy)   127.0.0.1:5432->5432/tcp
devrust-keycloak-1   quay.io/keycloak/keycloak:26.8.2   "/opt/keycloak/bin/k…"   keycloak   29 seconds ago   Up 29 seconds (healthy)   127.0.0.1:8180->8080/tcp
```
Read the log and ask the API for its health (the first log line is the JSON line you know):
```text
docker compose -p backend logs api
```
```text
api-1  | {"timestamp":"2026-11-23T08:28:17.443695Z","level":"INFO","fields":{"message":"listening","address":"0.0.0.0:8000"},"target":"tasks_api"}
```
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
The size and the user of the image:
```text
docker image ls code101/tasks-api-rust
docker inspect --format "{{.Config.User}}" code101/tasks-api-rust:local
```
```text
IMAGE                          ID             DISK USAGE   CONTENT SIZE   EXTRA
code101/tasks-api-rust:local   803095dd43ca   51.6MB         13.4MB   U    
```
```text
nonroot:nonroot
```
About 13 MB of content: the program plus the C library. There is **no shell** in it; trying to open one fails:
```text
docker compose -p backend exec api id
```
```text
OCI runtime exec failed: exec failed: unable to start container process: exec: "id": executable file not found in $PATH
```
Starting the image without settings shows the configuration check at work:
```text
docker run --rm code101/tasks-api-rust:local
```
```text
Error: "DATABASE_URL is not set"
```
Now the conformance script against the container:
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
PASS  create team (201, Location and ETag set, team cf48cef8-dc45-43e9-8613-1e3c3da5760f)
PASS  create project (201, project e9294c5c-6cc9-4e84-8214-58420a4f3f18)
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
Same 17 as before: the code did not change, only where it runs. **The cache at work.** Edit any line of a file in `src/` (a comment is enough) and build again; the dependency layer is reused, only layer B runs. This is the output filtered for the interesting lines (`CACHED` means reused), and it took 25 seconds instead of the full build:
```text
#3 CACHED
#10 CACHED
#11 CACHED
#12 CACHED
#14 0.360    Compiling tasks-api v1.0.0 (/app)
#14 22.38     Finished `release` profile [optimized] target(s) in 22.18s
#15 CACHED
#16 naming to docker.io/code101/tasks-api-rust:dbg done
```
Clean up (stops and removes the containers, the network and the volume, then the image):
```text
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasks-api-rust:local
```
Expected result: `docker ps -a`, `docker volume ls` and `docker network ls` show nothing of yours. The base images (`rust`, `distroless`, `postgres`, `keycloak`) stay in Docker's cache; remove them with `docker image rm` if you want the disk space back.

## How it works
1. `docker compose up --build` reads `docker-compose.yml` and merges `docker-compose.override.yml` over it. It builds the `api` image (stage 1 compiles, stage 2 copies the program into the distroless image), creates the network and the volume, and starts `db` and `keycloak` first because `api` depends on their health.
2. Inside the container the program reads its settings from the `environment:` list (there is no `.env`: the `.dockerignore` keeps it out, and the program ignores a missing file), connects to `db:5432`, starts listening on `0.0.0.0:8000` and Docker publishes that port on `127.0.0.1:8000` of your machine.
3. Every 5 seconds Compose runs `tasks-api healthcheck` *inside* the container: a second process, the same binary, that calls `/health`. `up --wait` returns when the status is `healthy`.
4. Image size and attack surface: the final image contains the program and glibc. No shell means an attacker who finds a code-execution bug cannot simply `sh` around; `read_only`, no capabilities and a non-root user limit what they could do anyway.
New terms: **image**, **container**, **multi-stage build**, **layer** and **build cache**, **build context**, **distroless**, **health check**, **override file**, **service name** (the host name of a container on a Compose network).

## Try it
Starter: `exercise/starter` (a tiny Cargo project, no dependencies). The health check of this chapter reads the first line of the raw HTTP reply. Write `is_healthy`: true only when the first line starts with `HTTP/1.1 200` **followed by a space** (so `HTTP/1.1 2000 Odd` and an empty reply are not healthy). Make `cargo run` print `true false false false`, one per line.

**File: `exercise/starter/src/main.rs`**
```rust
/// The Docker health check reads the raw reply of the server. Healthy means: the first line is
/// `HTTP/1.1 200` followed by a space and a reason phrase. `HTTP/1.1 2000 Odd` and an empty reply are not healthy.
fn is_healthy(reply: &str) -> bool {
    todo!("look at the first line only")
}

fn main() {
    let replies = [
        "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\n\r\n{\"status\":\"ok\"}",
        "HTTP/1.1 503 Service Unavailable\r\n\r\n",
        "HTTP/1.1 2000 Odd\r\n\r\n",
        "",
    ];
    for reply in replies {
        println!("{}", is_healthy(reply));
    }
}
```
The starter folder also holds a `Cargo.toml` (`name = "health-reply"`, `edition = "2024"`).

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.rs`**
```rust
/// The Docker health check reads the raw reply of the server. Healthy means: the first line is
/// `HTTP/1.1 200` followed by a space and a reason phrase. `HTTP/1.1 2000 Odd` and an empty reply are not healthy.
fn is_healthy(reply: &str) -> bool {
    reply.lines().next().is_some_and(|line| line.starts_with("HTTP/1.1 200 "))
}

fn main() {
    let replies = [
        "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\n\r\n{\"status\":\"ok\"}",
        "HTTP/1.1 503 Service Unavailable\r\n\r\n",
        "HTTP/1.1 2000 Odd\r\n\r\n",
        "",
    ];
    for reply in replies {
        println!("{}", is_healthy(reply));
    }
}
```
`lines().next()` is `None` for an empty reply, and `is_some_and` turns that into `false`. Expected output:
```text
true
false
false
false
```
</details>

(The program in the chapter checks `starts_with("HTTP/1.1 200")` without the trailing space; the exercise is stricter. Both are fine for a server that always sends a reason phrase.)

## Check yourself
1. Why copy `Cargo.toml` and `Cargo.lock` and build before copying `src/`? <details><summary>Answer</summary>Docker rebuilds a layer only when its inputs change. Dependencies change rarely and take long to compile; our code changes often. Building the dependencies in their own layer means an edit of `src/` reuses them.</details>
2. What goes wrong if the `touch` line is removed? <details><summary>Answer</summary>`COPY` keeps the file times from your disk, which are older than the stub build of the dependency layer. Cargo may judge the build up to date and the image would contain the do-nothing stub: the container starts and exits with code 0 at once.</details>
3. Why does the API container use `keycloak:8080` for the JWKS but `localhost:8180` as the issuer? <details><summary>Answer</summary>The issuer is just the text inside the token, set by Keycloak's configured host name (`localhost:8180`, what browsers use). The JWKS is a real request from container to container, so it must use the service name on the Docker network.</details>
4. Why publish `127.0.0.1:8000:8000` and not `8000:8000`? <details><summary>Answer</summary>The first publishes only on loopback, reachable from this machine; the second on every network interface, so other computers on the network could call the API.</details>
5. How can the health check work in an image without `curl`? <details><summary>Answer</summary>The program implements it: `tasks-api healthcheck` opens a TCP connection to itself, sends `GET /health` and exits 0 or 1.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| ``container devrust-api-1 exited (0)`` right after `up --wait`, and `docker compose logs api` shows nothing | The image contains the **stub** `fn main() {}` of the dependency layer: Cargo did not rebuild after `COPY src`, because the copied files looked older than the stub build (Cargo 1.100 moved its build files into `target/release/build/<package>/`, so tricks that delete old fingerprints silently stop working) | Keep `RUN touch src/lib.rs src/main.rs && cargo build ...` after `COPY src ./src` |
| `Error response from daemon: failed to set up container networking: ...` and ``Bind for 127.0.0.1:8000 failed: port is already allocated`` | Another program or container already listens on port 8000 (an old `cargo run`, another backend) | Stop it (`docker ps`, `docker rm -f NAME`, or Ctrl+C in its terminal) and run `up` again |
| ``Error: "DATABASE_URL is not set"`` when you start the image with `docker run` | The image has no `.env` (on purpose) and you passed no `-e` settings | Start it through Compose, which sets the environment |
| `OCI runtime exec failed: ... exec: "id": executable file not found in $PATH` | There is no shell or tool in a distroless image | That is the point. To debug, read the logs (`docker compose logs api`) or build a temporary image from `debian:trixie-slim` |
| `error: cannot update the lock file ...\Cargo.lock because --locked was passed to prevent this` (the Docker build prints `/app/Cargo.lock`) | `Cargo.toml` changed (here a new dependency) but `Cargo.lock` was not updated and committed | Run `cargo build` on your machine, commit the new `Cargo.lock`, build the image again |

The rows are real output of this chapter's setup (shortened); the first was a real bug of the first version of this Dockerfile, the port message appears when you start another container with `-p 127.0.0.1:8000:80` first, and the last one when a dependency is added to `Cargo.toml` without updating the lock file.

## Best practice
Build in one stage, run in another, pin every image tag, run as a non-root user with a read-only file system and no capabilities, keep secrets out of the image (an allow-list `.dockerignore`) and make the health check part of the image. Source: Docker documentation, Multi-stage builds https://docs.docker.com/build/building/multi-stage/ and Best practices for building images https://docs.docker.com/build/building/best-practices/

## Next lesson
05. Hardening and OWASP: rate limits with `RateLimit-*` headers and 429, CORS for the web clients, security headers, body and time limits, security logging, and the OWASP API Top 10 walk-through. The conformance score reaches 18 of 18.
