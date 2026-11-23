# Backend Go, phase 5: Hardening

Rate limiting with `RateLimit-*` headers and 429, security headers, a CORS allow-list, a 1 MiB body limit (413), a redacted configuration log, a read-only container with no capabilities, the OWASP API Security Top 10 walk-through and a production checklist. Status: **verified** on 2026-11-23 (Windows 11, Docker 29.9.3, Compose 5.7.0, Python 3.15.2). Conformance: **18 passed, 0 failed**.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `07-hardening` | Hardening | `ratelimit.go`, `secure.go`, redacted `Config`, hardened Compose override, backup and restore |

## Prerequisites and extraction
- Docker (Linux containers); host ports 5432, 8000 and 8180 free. Python 3.10+. Go only for the exercise.
- Extract the zip and open `07-hardening/code`.

## Run
**Terminal (folder `07-hardening/code`)**
```bash
cp .env.example .env
docker compose -p tasksteams up -d --build --wait
python scripts/conformance.py
```
(PowerShell: `Copy-Item .env.example .env`.) The script prints `18 passed, 0 failed`. The chapter then shows the headers, a CORS preflight, a 413, a burst of requests that ends in 429, the container's hardening flags and a backup with a test restore. Clean up:
```bash
docker compose -p tasksteams down -v --remove-orphans --rmi local
```

## Exercise
`exercise/starter`: write the fixed-window `allow` function of the rate limiter and watch the decisions over time.

## For maintainers
`verify.json` builds and starts the stack under a throwaway project, runs the conformance script once and expects `18 passed, 0 failed`, checks the security headers and the container flags, and runs the exercise solution; `cleanup` always runs `docker compose -p {project} down -v --remove-orphans --rmi local`. It takes the exclusive lock `tasksteams`. The `Dockerfile` and `.dockerignore` are unchanged from phase 4 (shown in full in chapter 06).
