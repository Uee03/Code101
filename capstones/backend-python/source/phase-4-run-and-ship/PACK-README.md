# Phase 4: Run and ship

Chapter 04 packages the API as a multi-stage, non-root container image on a pinned Python image (`python:3.14.10-slim-trixie`, chosen because every dependency ships a `cp314` wheel), excludes secrets and clutter with `.dockerignore`, and adds the service to the platform stack with `docker-compose.override.yml` (joins `tasksteams-net`, publishes `127.0.0.1:8000`, health check from the image). One command starts Postgres, Keycloak and the API. The application code is unchanged from chapter 03.

| Chapter | Lesson text | Folder |
|---------|-------------|--------|
| 04 Run and ship: a non-root image and one Compose command | `tutorials/phase-4-run-and-ship/04-run-and-ship.md` | `04-run-and-ship/` |

## Prerequisites
- Chapter 03 (or this pack, which holds the whole project at the end of chapter 04).
- Docker with Compose v2; free host ports 5432, 8180 and 8000 (stop any API started with Uvicorn).
- Python 3.12 or newer only for `scripts/` and the exercise; the API itself runs in the container.

## Folder layout
```text
04-run-and-ship/
  code/                  the whole project; new here: Dockerfile, .dockerignore, docker-compose.override.yml
  exercise/starter/      check_dockerfile.py with TODOs
  exercise/solution/     check_dockerfile.py finished (reads ../../code/Dockerfile)
  verify.json            what scripts/verify_labs.py runs
```

## Run it
```text
cd 04-run-and-ship/code
copy .env.example .env              (macOS and Linux: cp .env.example .env)
docker compose up -d --build --wait
python scripts/call.py GET /health
python scripts/conformance.py
docker compose down -v --remove-orphans --rmi local
```

## Conformance state
17 passed, 1 failed (`me`: the `RateLimit-*` headers arrive in phase 5).
