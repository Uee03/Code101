# Backend Go, phase 3: Identity

Keycloak access-token validation (`RS256`, issuer, audience, expiry, signature with a cached and throttled JWKS), roles from `realm_access`, scopes, the user row created on first use, and the removal of the development stand-in. Status: **verified** on 2026-11-23 (Windows 11, Go 1.27.4, Docker 29.9.3, Compose 5.7.0, Python 3.15.2). Conformance: **17 passed, 1 failed**; the only failure is `me`, which wants the `RateLimit-*` headers of phase 5.

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `05-jwt-and-roles` | Identity | `auth.JWKS`, `auth.JWT`, `EnsureUser`, member versus admin, scope and role intersection |

## Prerequisites and extraction
- Go 1.27, `curl`, Python 3.10+, Docker (Linux containers); host ports 5432, 8000 and 8180 free.
- Extract the zip as before and open `05-jwt-and-roles/code`.

## Run
**Terminal (folder `05-jwt-and-roles/code`)**
```bash
cp .env.example .env
docker compose -p tasksteams up -d --wait db keycloak
go run ./cmd/api
```
In a second terminal: `python scripts/conformance.py` prints `17 passed, 1 failed`. The chapter shows how to fetch a token for alice or bob and call the API with it. Clean up:
```bash
docker compose -p tasksteams down -v --remove-orphans
```

## Exercise
`exercise/starter`: write `payloadOf`, which reads the claims of a JWT without verifying it, and learn why that is never enough.

## For maintainers
`verify.json` starts the database and Keycloak under a throwaway project, runs the API in the background, checks 401 answers and runs `scripts/conformance.py` (with retries for the slow first Keycloak start), expecting exit code 1 and the line `17 passed, 1 failed`. It takes the exclusive lock `tasksteams`.
