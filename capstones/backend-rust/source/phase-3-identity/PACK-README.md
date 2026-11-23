# Rust backend, phase 3: Identity

Real token validation: a cached JWKS, `RS256` only, issuer, audience (a string or a list), expiry and not-before with 30 seconds of skew, roles from `realm_access`, scopes, and the rule that scope **and** role must both allow an action. Status: **verified** on 2026-11-23: the conformance script passes **17 of 18** (all identity checks `401 without token` and `403 for member on admin route` pass; only the `RateLimit-*` headers of `me` are missing).

| Folder | Chapter | Outcome |
|--------|---------|---------|
| `03-keycloak-token-validation` | Keycloak token validation | forged and tampered tokens get 401, real tokens work, members cannot reach admin routes |

## Prerequisites and extraction
- Phase 2 tools, plus Keycloak on port 8180 (platform capstone, started by the same Compose file).
- Extract `backend-rust-phase-3-identity.zip` and open `03-keycloak-token-validation/code`.

## Run
**Terminal (folder: `03-keycloak-token-validation/code`)**
```text
cp .env.example .env            (Windows PowerShell: Copy-Item .env.example .env)
docker compose -p backend up -d --wait
cargo run
```
Second terminal: `python scripts/api.py --as bob GET /v1/audit-log` (403), then `python scripts/conformance.py`.

## Exercise
`exercise/starter`: `audience_ok` (a string or a list) and `may_read_audit_log` (scope and role). Solution in `exercise/solution`.

## Safety and cleanup
`docker compose -p backend down -v --remove-orphans`. Tokens are never logged.

## For maintainers
`verify.json` also sends a forged token (401), a bob token (200) and bob on the audit log (403). Only the files that changed in this phase are checked against the chapter text; the rest are in `skip_lesson_check` and are shown in chapters 01 and 02.
