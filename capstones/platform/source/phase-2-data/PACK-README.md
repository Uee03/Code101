# Platform, phase 2: Data

Postgres 17 in Docker with the Tasks and Teams schema, triggers, stored functions and demo data. The pack holds the whole project so far: the contract from phase 1 plus `db/`, `docker-compose.yml` and `.env.example`. Status: **verified** on 2026-11-23 (stack healthy, seed counts, stored-function demo, least-privilege check, exercise solution).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `02-database-and-procedures` | The database and stored procedures | 8 tables, audit and version triggers, `complete_task`, `reassign_task`, `create_team`, 21 seed audit rows |

## Prerequisites and extraction
- Docker running in Linux-container mode. Author baseline: Docker 29.9.3, Compose 5.7.0, `postgres:17-alpine`.
- Host port **5432 must be free**; the Databases track labs use it too. Run one lab at a time.
- Extract the zip as in phase 1; open `02-database-and-procedures/code` and keep the `exercise` folder beside it.

## Run
**Terminal (PowerShell; folder: `02-database-and-procedures/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p platform up -d --wait
docker compose -p platform exec -T db psql -X -q -U tasks_admin -d tasksteams -f /scripts/try_procedures.sql
```
On macOS and Linux use `cp .env.example .env`; the Docker commands are identical.

## Exercise
`exercise/starter/exercise.sql` (open tasks per user); the solution is next to it. The chapter shows how to feed it to `psql`.

## Safety and cleanup
The passwords are public and fake; never reuse them. `down -v` deletes the data and the Compose network `tasksteams-net`.
```powershell
docker compose -p platform down -v --remove-orphans
```

## For maintainers
`verify.json` requires Docker, copies `.env.example` to `.env` in a temporary copy, starts a `code101-verify-*` project with `--wait` (retried because of image pulls), runs each smoke step once and always removes the project with `down -v --remove-orphans`. `openapi.yaml`, `requirements.txt` and `scripts/check_openapi.py` are unchanged from phase 1 and are in `skip_lesson_check`. No custom image is built, no art is used.
