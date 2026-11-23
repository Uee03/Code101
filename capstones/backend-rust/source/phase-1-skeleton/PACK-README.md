# Rust backend, phase 1: Skeleton

The Axum project from nothing: `Cargo.toml`, configuration, a router, `/health`, a stub `/v1/me`, RFC 9457 problem details and a body validator. Status: **verified** on 2026-11-23 (Windows 11, Rust 1.100.0, Docker 29.9.3): the program compiles, answers `/health` and the validation error, and the conformance script passes **6 of 18** checks (the 4 infrastructure checks, `health` and `problem details shape`). The other 12 need the database (phase 2), real tokens (phase 3) and rate limiting (phase 5).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `01-skeleton` | Skeleton and problem details | `cargo run` serves `/health`; every error is `application/problem+json` |

## Prerequisites and extraction
- Rust 1.100 or newer (`rustc --version`), Python 3.10+, Docker running (Postgres and Keycloak come from the platform capstone), host ports 5432, 8000 and 8180 free.
- Extract `backend-rust-phase-1-skeleton.zip` (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip`) and open `01-skeleton/code`.
- `db/`, `keycloak/`, `docker-compose.yml` and `scripts/conformance.py` are byte-identical copies from the **platform** capstone (phase 4); do not edit them.

## Run
**Terminal (folder: `01-skeleton/code`)**
```text
cp .env.example .env            (Windows PowerShell: Copy-Item .env.example .env)
docker compose -p backend up -d --wait
cargo run
```
In a second terminal: `python scripts/api.py GET /health`. Stop the API with Ctrl+C.

## Exercise
`exercise/starter`: write `problem_slug` (status to problem type). The solution is in `exercise/solution`. Run with `cargo run` inside the folder.

## Safety and cleanup
Fake local passwords only. When you are done: `docker compose -p backend down -v --remove-orphans`.

## For maintainers
`verify.json` starts a throwaway Compose project, compiles and runs the API, probes it, runs the conformance script once (6 passed, 12 failed is the expected phase 1 result), runs the exercise solution and always cleans up. `Cargo.lock`, the platform copies and `conformance.py` are in `skip_lesson_check`.
