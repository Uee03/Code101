# Rust backend, phase 2: Data

The whole project with a database: a SQLx pool, a store module for every resource, the stored functions `create_team`, `complete_task` and `reassign_task`, the actor in every write transaction, ETag and `If-Match`, cursor pagination, filters and `Idempotency-Key`. All 27 operations of the contract exist. Status: **verified** on 2026-11-23: the conformance script passes **17 of 18**; only the `RateLimit-*` headers of `me` are missing (phase 5). Tokens are read **without** checking them in this phase (unsafe on purpose, replaced in phase 3).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `02-data-and-stored-functions` | Data and stored functions | create, read, patch with `If-Match`, complete, reassign, page and audit through Postgres |

## Prerequisites and extraction
- Phase 1 tools, plus the platform Postgres on port 5432.
- Extract `backend-rust-phase-2-data.zip` and open `02-data-and-stored-functions/code`. The pack holds the whole project at the end of phase 2.

## Run
**Terminal (folder: `02-data-and-stored-functions/code`)**
```text
cp .env.example .env            (Windows PowerShell: Copy-Item .env.example .env)
docker compose -p backend up -d --wait
cargo run
```
Second terminal: `python scripts/api.py --as alice GET /v1/teams`, then `python scripts/conformance.py` (expect `17 passed, 1 failed`).

## Exercise
`exercise/starter`: keyset paging over a sorted list (`page`). Solution in `exercise/solution`.

## Safety and cleanup
`docker compose -p backend down -v --remove-orphans`. The API connects as the limited role `tasks_app`.

## For maintainers
`verify.json` adds a seeded read and the conformance run (17 passed, 1 failed). Files unchanged since chapter 01, and files whose full text is in the chapter text of chapter 02 itself, are checked; the platform copies, `Cargo.lock` and unchanged chapter 01 files are in `skip_lesson_check`.
