# Backend Go, phase 2: Data

The store layer on `pgxpool`, teams, members, projects, tasks, comments, the audit trail, stored functions, ETag and `If-Match`, keyset pagination, filtering and idempotency keys. Sign-in is a **development stand-in** (`X-Dev-User` headers) in this phase; Keycloak arrives in phase 3. Status: **verified** on 2026-11-23 (Windows 11, Go 1.27.4, Docker 29.9.3, Compose 5.7.0). Conformance in every chapter of this phase: 6 passed, 12 failed, because the stand-in does not understand bearer tokens.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `02-store-and-teams` | The data layer | pool, `WithUser` transactions, teams, members, projects, users, `/v1/me`, cursors, ETag |
| `03-tasks-and-procedures` | Tasks and stored functions | tasks with filters and sorting, `complete_task`, `reassign_task`, comments, audit trail |
| `04-idempotency` | Idempotency keys | safe retries for the four creates |

## Prerequisites and extraction
- Go 1.27, `curl`, Docker running in Linux-container mode; host port 5432 free (and 8000 for the API).
- Extract the zip as in phase 1 and open the chapter's `code` folder. Each folder holds the whole project at that point, including byte-identical copies of the platform files (`docker-compose.yml`, `.env.example`, `db/`, `keycloak/`, `scripts/conformance.py`).

## Run
**Terminal (folder `0N-.../code`)**
```bash
cp .env.example .env
docker compose -p tasksteams up -d --wait db
go run ./cmd/api
```
(PowerShell: `Copy-Item .env.example .env`.) The API warns that the stand-in is active. Call it with `curl -H "X-Dev-User: a11ce000-0000-4000-8000-000000000001" -H "X-Dev-Roles: admin" http://127.0.0.1:8000/v1/me`. Clean up: Ctrl+C, then
```bash
docker compose -p tasksteams down -v --remove-orphans
```

## Exercises
Chapter 02: `likePrefix` (escape LIKE wildcards). Chapter 03: `etagMatches` (the `If-None-Match` comparison). Chapter 04: `requestHash` (identify a request for the idempotency check). Starters and solutions are in each chapter's `exercise` folder.

## For maintainers
`verify.json` of each chapter starts only the database under a throwaway Compose project, builds and starts the API in the background, probes it with `curl` and runs the exercise solution; `cleanup` always runs `docker compose -p {project} down -v --remove-orphans --rmi local`. All chapters take the exclusive lock `tasksteams`. Platform copies, files unchanged since the previous chapter (shown there in full) and the generated `go.sum` are listed in `skip_lesson_check`.
