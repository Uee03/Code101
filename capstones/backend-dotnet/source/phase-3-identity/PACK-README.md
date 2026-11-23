# Backend ASP.NET Core, phase 3: Identity

Real Keycloak sign-in checks: the stand-in identity is gone; the API validates bearer tokens (signature, issuer, audience, expiry, RS256 only), requires a scope and a realm role per operation, and answers 401, 403 and 404 as the contract says. Status: **verified** on 2026-11-23: the conformance script prints `17 passed, 1 failed` (the rate-limit headers arrive in chapter 5).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `03-identity` | Keycloak tokens, scopes and roles | 401 without a token, 403 for bob on admin routes, 404 for non-members |

## Prerequisites and extraction
- Docker running in Linux-container mode; Python 3.10+; .NET SDK 11.0.100 or newer; host ports 5432, 8180, 8000 free.
- Extract the zip as in phase 1 and open `03-identity/code`.

## Run
**Terminal (PowerShell; folder: `03-identity/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p bdn up -d --wait
cd src/TasksApi
dotnet run
```
In a second terminal in `03-identity/code`: `python scripts/conformance.py` (expected last line `17 passed, 1 failed`), `python scripts/show_token.py bob`, `python scripts/call.py --as bob GET /v1/audit-log`.

## Exercise
`exercise/starter/src/TasksApi/Features/Platform/PermissionsEndpoint.cs`: answer what the caller's token allows. The solution must build.

## Safety and cleanup
Fake local passwords only. `docker compose -p bdn down -v --remove-orphans` removes the stack.

## For maintainers
`verify.json` starts Postgres and Keycloak, runs the API on the host and the conformance script once, checks a 401, a 403 and the claims of a token, builds the exercise solution and always cleans up. Files unchanged from chapter 02 are in `skip_lesson_check`.
