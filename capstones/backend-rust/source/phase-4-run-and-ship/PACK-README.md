# Rust backend, phase 4: Run and ship

A multi-stage `Dockerfile` (dependency layer, then your code), a distroless non-root runtime image, `.dockerignore`, a `healthcheck` subcommand in the binary and `docker-compose.override.yml`, which adds the API to the platform stack on the network `tasksteams-net` and publishes `127.0.0.1:8000`. Status: **verified** on 2026-11-23: `docker compose up -d --build --wait` makes all three containers healthy and the conformance script passes **17 of 18** (the `RateLimit-*` headers wait for phase 5).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `04-docker-image-and-compose` | Docker image and Compose | one command starts Postgres, Keycloak and the Rust API; the image is about 13 MB and runs as `nonroot` |

## Prerequisites and extraction
- Docker running in Linux-container mode, Python 3.10+, host ports 5432, 8000 and 8180 free. Rust is only needed for the exercise.
- Extract `backend-rust-phase-4-run-and-ship.zip` and open `04-docker-image-and-compose/code`.

## Run
**Terminal (folder: `04-docker-image-and-compose/code`)**
```text
cp .env.example .env            (Windows PowerShell: Copy-Item .env.example .env)
docker compose -p backend up -d --build --wait
docker compose -p backend ps
python scripts/conformance.py
```

## Exercise
`exercise/starter`: `is_healthy`, the check behind the `healthcheck` subcommand. Solution in `exercise/solution`.

## Safety and cleanup
```text
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasks-api-rust:local
```

## For maintainers
`verify.json` runs `up -d --build --wait` (timeout 900 seconds), probes `/health`, checks the image user, runs the conformance script once and cleans up, including `docker image rm`. Only the new and changed files (`Dockerfile`, `.dockerignore`, `docker-compose.override.yml`, `Cargo.toml`, `src/main.rs`) are checked against the chapter text.
