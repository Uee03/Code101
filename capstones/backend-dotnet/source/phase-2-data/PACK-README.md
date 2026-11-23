# Backend ASP.NET Core, phase 2: Data

All 27 operations of the contract on EF Core 11 and Npgsql, with the platform's stored functions, ETag and `If-Match`, keyset cursors, task filters, JSON Merge Patch and `Idempotency-Key`. A stand-in identity treats every caller as alice. Status: **verified** on 2026-11-23: the conformance script prints `15 passed, 3 failed` (the three failures need sign-in and rate-limit headers, chapters 3 and 5).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `02-data-access` | Data access with EF Core and stored functions | the log says `Registered 27 endpoints`; 15 of 18 conformance checks pass |

## Prerequisites and extraction
- Docker running in Linux-container mode; Python 3.10+; .NET SDK 11.0.100 or newer.
- Host ports 5432, 8180 and 8000 free.
- Extract the zip as in phase 1 and open `02-data-access/code`. It holds the whole project plus the platform files (`db/`, `keycloak/`, `docker-compose.yml`, `scripts/conformance.py`, `openapi.yaml`, `.env.example`), copied unchanged from the platform capstone.

## Run
**Terminal (PowerShell; folder: `02-data-access/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p bdn up -d --wait
cd src/TasksApi
dotnet run
```
In a second terminal in `02-data-access/code`: `python scripts/conformance.py` (expected last line `15 passed, 3 failed`) and `python scripts/call.py GET /v1/teams`.

## Exercise
`exercise/starter/src/TasksApi/Features/Teams/TeamStatsEndpoint.cs`: count a team's tasks per status with one `GROUP BY` query. The solution must build.

## Safety and cleanup
Fake local passwords only. Stop the API with Ctrl+C and remove the stack including the database volume:
```powershell
docker compose -p bdn down -v --remove-orphans
```

## For maintainers
`verify.json` starts a throwaway project (`-p {project}`), builds, runs the API on the host, runs `scripts/conformance.py` once (retries for slow Keycloak) and expects exactly the partial result above, builds the exercise solution and always runs `down -v --remove-orphans`. Platform files and files shown in chapter 01 are in `skip_lesson_check`. Never run it while another capstone lab uses the ports: it sets `"exclusive": "tasksteams"`.
