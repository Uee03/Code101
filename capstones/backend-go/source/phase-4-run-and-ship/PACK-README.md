# Backend Go, phase 4: Run and ship

A multi-stage `Dockerfile` that builds a static binary and runs it as a non-root user in a distroless image (about 23 MB), a `.dockerignore`, a `docker-compose.override.yml` that adds the `api` service to the platform stack (network `tasksteams-net`, port `127.0.0.1:8000`) and a container healthcheck done by the binary itself. Status: **verified** on 2026-11-23 (Windows 11, Docker 29.9.3, Compose 5.7.0, Python 3.15.2). Conformance through Docker: 17 passed, 1 failed (`me`: `RateLimit-*` headers, phase 5).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `06-docker` | Run and ship | `Dockerfile`, `.dockerignore`, Compose override, `api healthcheck` |

## Prerequisites and extraction
- Docker (Linux containers); host ports 5432, 8000 and 8180 free (stop any `go run` server). Python 3.10+ for the conformance script. Go is only needed for the exercise.
- Image tags used: `golang:1.27.4-alpine3.24` (exists on Docker Hub, checked 2026-11-23) and `gcr.io/distroless/static-debian13:nonroot`.
- Extract the zip and open `06-docker/code`.

## Run
**Terminal (folder `06-docker/code`)**
```bash
cp .env.example .env
docker compose -p tasksteams up -d --build --wait
python scripts/conformance.py
```
(PowerShell: `Copy-Item .env.example .env`.) Clean up, including the image built here:
```bash
docker compose -p tasksteams down -v --remove-orphans --rmi local
```

## Exercise
`exercise/starter`: write `healthURL`, which turns a `LISTEN_ADDR` value into the URL the container healthcheck calls.

## For maintainers
`verify.json` builds and starts the whole stack under a throwaway project, checks that the container runs as `nonroot`, runs `api healthcheck` inside it and runs the conformance script once; `cleanup` always runs `docker compose -p {project} down -v --remove-orphans --rmi local`, which also removes the built image. It takes the exclusive lock `tasksteams`. `Dockerfile`, `.dockerignore` and `docker-compose.override.yml` are new in this chapter and shown in full in the lesson.
