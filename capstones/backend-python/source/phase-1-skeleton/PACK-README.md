# Phase 1: Skeleton

Chapter 01 builds the whole project layout and the HTTP manners of the API: settings from the environment, JSON logs with a trace id, RFC 9457 problem details, validation DTOs for the entire contract, and three working endpoints (`GET /health`, a `GET /v1/me` stub and a `POST /v1/teams` stub). No database, no Docker.

| Chapter | Lesson text | Folder |
|---------|-------------|--------|
| 01 Skeleton: layout, problem details and DTOs | `tutorials/phase-1-skeleton/01-skeleton.md` | `01-skeleton/` |

## Prerequisites
- Python 3.12 or newer (the author run used 3.15.2).
- `curl` (Windows PowerShell: type `curl.exe`).
- The platform TDD sections 3 and 6.

## Folder layout
```text
01-skeleton/
  code/                  the finished project at the end of chapter 01 (copy it or follow the steps)
  exercise/starter/      problem.py with TODOs
  exercise/solution/     problem.py finished
  verify.json            what scripts/verify_labs.py runs
```

## Run it
```text
cd 01-skeleton/code
python -m venv .venv
.venv\Scripts\Activate.ps1          (macOS and Linux: source .venv/bin/activate)
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --port 8000
```
Then `curl -s http://127.0.0.1:8000/health` answers `{"status":"ok","version":"1.0.0"}`.

## Conformance state
The platform script needs Postgres and Keycloak, so it is first run in phase 2.
