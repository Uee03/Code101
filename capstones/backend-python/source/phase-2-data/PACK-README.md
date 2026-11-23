# Phase 2: Data

Chapter 02 connects the skeleton to the platform Postgres: repositories with bound parameters, the stored functions `create_team`, `complete_task` and `reassign_task`, a transaction that tells the database who the caller is, ETag and `If-Match`, cursor pagination, filtering and sorting, idempotency keys, object-level authorization (non-members get 404) and the audit log. The caller is identified by a development **stand-in** that reads token claims without checking the signature; chapter 03 replaces it.

| Chapter | Lesson text | Folder |
|---------|-------------|--------|
| 02 Data: repositories, stored functions, ETag, cursors and idempotency | `tutorials/phase-2-data/02-data.md` | `02-data/` |

## Prerequisites
- Chapter 01 (or this pack, which holds the whole project at the end of chapter 02).
- Python 3.12 or newer, Docker with Compose v2, free host ports 5432, 8180 and 8000.
- The platform files `docker-compose.yml`, `db/`, `keycloak/` and `scripts/conformance.py` are **copied unchanged** from `capstones/platform` (final pack) into this project.

## Folder layout
```text
02-data/
  code/                  the whole project at the end of chapter 02
  exercise/starter/      cursor.py with TODOs
  exercise/solution/     cursor.py finished
  verify.json            what scripts/verify_labs.py runs
```

## Run it
```text
cd 02-data/code
copy .env.example .env              (macOS and Linux: cp .env.example .env)
docker compose up -d --wait
python -m venv .venv
.venv\Scripts\Activate.ps1          (macOS and Linux: source .venv/bin/activate)
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --port 8000
python scripts/conformance.py       (second terminal)
docker compose down -v              (when you are done)
```

## Conformance state
17 passed, 1 failed. The failing check is `me` (the `RateLimit-*` headers arrive in phase 5).
