# Backend ASP.NET Core, phase 5: Hardening

The OWASP API Security Top 10 walk-through made real: a fixed-window rate limiter with `RateLimit-*` headers and 429, security headers, request size and header limits, CORS for the two local web clients, JSON request logs without secrets, and warnings for rejected tokens and 403s. Status: **verified** on 2026-11-23: the conformance script prints **`18 passed, 0 failed`**.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `05-hardening` | OWASP walk-through, limits, headers, logging | all 18 checks pass; every OWASP risk maps to a file |

## Prerequisites and extraction
- Docker running in Linux-container mode; Python 3.10+; .NET SDK 11.0.100 or newer (only to build the exercise); host ports 5432, 8180, 8000 free.
- Extract the zip as in phase 1 and open `05-hardening/code`.

## Run
**Terminal (PowerShell; folder: `05-hardening/code`)**
```powershell
Copy-Item .env.example .env
docker compose -p backend up -d --build --wait
python scripts/conformance.py
```
Expected last line: `18 passed, 0 failed`.

## Exercise
`exercise/starter/src/TasksApi/Security/SecurityHeadersMiddleware.cs`: send a `Permissions-Policy` header. The solution must build.

## Safety and cleanup
```powershell
docker compose -p backend down -v --remove-orphans
docker image rm code101/tasksteams-backend-dotnet:1.0
```

## For maintainers
`verify.json` builds the image, runs the conformance script once (18 passed), checks the rate-limit, security and CORS headers and the JSON request log, builds the exercise solution and always cleans up. Chapter 05 is the final backend phase: `docker compose up` here must stay equal to the "How to run it" section of the capstone README.
