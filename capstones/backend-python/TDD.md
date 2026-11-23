# TDD: Backend in Python (FastAPI)

| Field | Value |
|-------|-------|
| Id | backend-python |
| Level | 201 |
| Status | Verified (all five chapters pass `verify_labs.py`; the final pack passes 18 of 18 conformance checks, 2026-11-23) |
| Depends on | [platform](../platform/TDD.md) (contract, schema, realm, Compose, conformance script) |
| Stack | Python 3.12 or newer on your computer (author run: 3.15.2) and 3.14.10 in the container (`python:3.14.10-slim-trixie`); FastAPI 0.165.0, Starlette 1.10.0, Uvicorn 0.54.0, Pydantic 2.14.4, pydantic-settings 2.16.3, SQLAlchemy 2.1.9 (Core), psycopg 3.3.9, PyJWT 2.15.1 (with `cryptography` 50.0.2). Versions and APIs checked against the official docs and by running them on 2026-11-23 |
| Estimated learner time | 5 chapters, about 9 hours in total (90 + 180 + 90 + 60 + 75 minutes) |
| Last updated | 2026-11-23 |

## 1. Purpose and learning goals
This capstone is the **reference backend** of the "Tasks and Teams" family: a FastAPI service that implements the [platform contract](../platform/TDD.md) exactly and passes `python scripts/conformance.py` with `18 passed, 0 failed`. The Go, ASP.NET and Rust backends are written from the same contract, so every design decision here is also a choice the other three make differently.

Skills gained:
1. Lay out a Python web service (settings from the environment, JSON logs, layers, dependency direction).
2. Turn a contract into DTOs: validation, camelCase names, RFC 9457 problem details with JSON Pointers.
3. Talk to Postgres with SQLAlchemy Core and psycopg 3: bound parameters, transactions, stored functions, `set_config` for the audit actor.
4. Implement optimistic concurrency (ETag and `If-Match`), keyset pagination, filtering and idempotency keys.
5. Validate Keycloak access tokens (signature, `iss`, `aud`, `exp`, JWKS cache) and combine scopes, roles and team membership.
6. Package the service in a multi-stage, non-root image and run it with Compose next to the platform.
7. Harden it: rate limits, security headers, CORS, request size limit, security logging, OWASP API Top 10 mapping, backup and restore.

## 2. Scope
**In scope:** one FastAPI application with all 27 operations of `openapi.yaml`, its Dockerfile and Compose override, five phased chapters with packs, offline token-rule demo scripts.
**Out of scope:** Alembic migrations (the platform schema is the baseline; see decision D4), an ORM layer, background jobs, a cache server, TLS termination, a shared rate-limit store, async database access.
**Assumptions:** Docker with Compose v2, Python 3.12 or newer on the host, the platform stack from `capstones/platform` (copied into every pack), one backend on port 8000.
**Constraints:** SQL only through bound parameters; the API connects as the limited role `tasks_app`; no secrets in the repository (fake local values only); smoke verification only.

## 3. Requirements
`P R-nn` is a requirement of the [platform TDD](../platform/TDD.md). The acceptance check is a conformance check name or a shown command.

| Id | Requirement | Priority | Acceptance check | Platform | Phase |
|----|-------------|----------|------------------|----------|-------|
| R-01 | Settings come only from environment variables (and an ignored `.env`); one JSON log line per request with a `traceId` | Must | `GET /health` answers; log line shown | P R-21 | 1 |
| R-02 | Every error is `application/problem+json` with `type`, `title`, `status`, `detail`, `instance`, `traceId` | Must | checks `problem details shape`, `401 without token` | P R-09 | 1 |
| R-03 | Request DTOs reject unknown members and invalid values with a 422 and `errors[].pointer` | Must | check `problem details shape` | P R-09 | 1 |
| R-04 | `GET /health` is public and reports the database (200 `ok` or 503 `degraded`) | Must | check `health` | P R-02 | 2 |
| R-05 | `GET /v1/me` returns the caller and creates the `users` row on first use | Must | check `me` | P R-03 | 2 |
| R-06 | Teams, members, projects, tasks and comments implement every operation of the contract | Must | checks `create team`, `create project`, `create task ...`, `cleanup` | P R-04 to R-07 | 2 |
| R-07 | `complete`, `reassign` and team creation call the stored functions; `TS404`, `TS409`, `TS412`, `TS422` map to 404, 409, 412, 422 | Must | `complete` of a cancelled task gives 409 | P R-17 | 2 |
| R-08 | Each write transaction first runs `set_config('app.current_user_id', ...)`, so every audit row names the caller; admins read the trail | Must | check `audit log` | P R-08 | 2 |
| R-09 | Cursor pagination on every list; a bad cursor is a 400 | Must | check `cursor pagination` | P R-10 | 2 |
| R-10 | Task filters (`status`, `priority`, `assigneeId`, `dueBefore`, `dueAfter`, `q`) and sorts (`createdAt`, `-createdAt`, `dueDate`) | Should | filtered list shown in chapter 02 | P R-11 | 2 |
| R-11 | Strong ETag (quoted `version`) on single resources; `If-Match` gives 412 or 428; `If-None-Match` gives 304 | Must | checks `get task with ETag`, `stale If-Match gives 412` | P R-12 | 2 |
| R-12 | `Idempotency-Key` on creates: replay with `Idempotent-Replayed: true`, other body 422 | Must | check `create task with Idempotency-Key` | P R-13 | 2 |
| R-13 | A caller who is not in a team gets 404 for everything inside it; lacking the team role gives 403 | Must | probe shown in chapter 02 | P R-04 | 2 |
| R-14 | The API uses only the `tasks_app` role | Should | `DATABASE_URL` in `.env.example` | P R-23 | 2 |
| R-15 | Bearer tokens are verified: RS256 only, signature from a cached JWKS, exact `iss`, `aud` (string or list) contains `tasks-api`, `exp`, `nbf`, 30 s skew | Must | `scripts/token_rules.py`, forged token gives 401 | P R-20 | 3 |
| R-16 | Effective permission is scope AND role: `tasks:read`, `tasks:write`, `tasks:admin`; `admin` for admin routes | Must | check `403 for member on admin route` | P R-20 | 3 |
| R-17 | Multi-stage Dockerfile on a pinned Python image whose wheels exist, non-root user, health check | Must | `docker compose ps` shows `healthy`; `id` shows uid 10001 | P R-21 | 4 |
| R-18 | `docker-compose.override.yml` joins `tasksteams-net` and publishes `127.0.0.1:8000` only | Must | `docker compose ps` | P R-21 | 4 |
| R-19 | `RateLimit-*` headers on authenticated responses; 100 requests per 60 s per user, 30 per client address when anonymous; 429 with `Retry-After` | Should | check `me`; 429 demo | P R-14 | 5 |
| R-20 | Security headers, CORS allow-list, 1 MB body limit (413), docs off in the container | Must | header listing, 413 demo | P R-20 | 5 |
| R-21 | Refusals (401, 403, 429) are logged as security events without tokens, bodies or secrets | Should | log lines shown | - | 5 |
| R-22 | Read-only root file system, no capabilities, memory and process limits; backup and restore documented and run | Should | `touch` fails, restore count matches | P R-21 | 5 |
| R-23 | The finished pack passes all 18 conformance checks | Must | `python scripts/conformance.py` prints `18 passed, 0 failed` | P R-22, R-24 | 5 |
| R-24 | Every chapter has a pack, a `verify.json` and lesson text that matches the code | Must | `python scripts/verify_labs.py capstones/backend-python` | P R-24 | 1-5 |

| Non-functional requirement | Target |
|----------------------------|--------|
| Latency | p95 under 200 ms for list and read on the seed data with 25 sequential requests (measured result in chapter 05) |
| Start time | container healthy within 15 seconds of `up` once images are cached |
| Image | under 350 MB, no compiler, no pip cache |
| Robustness | database or Keycloak down gives 503 problem details, never a stack trace |
| Portability | commands shown for Windows PowerShell, macOS and Linux |

## 4. Architecture
Context and containers (the platform stack plus this API; one backend at a time):

```mermaid
flowchart LR
    client["Client: curl, web or mobile app"] -->|"HTTP + bearer token, port 8000"| api
    subgraph stack["Compose project, network tasksteams-net"]
        api["api: FastAPI + Uvicorn (this capstone)"]
        db[("db: PostgreSQL 17")]
        kc["keycloak: realm tasksteams"]
    end
    api -->|"SQL as tasks_app (psycopg 3)"| db
    api -->|"GET JWKS, cached 5 min"| kc
    client -->|"sign in, port 8180"| kc
```

Modules and the direction of dependencies (arrows point at what a module uses; nothing in a lower layer imports an upper one):

```mermaid
flowchart TB
    subgraph http["HTTP layer"]
        main["main.py: app factory, lifespan"]
        mw["middleware.py"]
        routers["routers/*: one file per resource"]
        schemas["schemas.py: DTOs"]
        errors["errors.py, db_errors.py"]
        httpx["http.py, pagination.py"]
    end
    subgraph policy["Policy layer"]
        auth["auth.py: Principal, authenticate"]
        tokens["tokens.py: TokenVerifier, JwksKeys"]
        access["access.py: team access"]
        idem["idempotency.py"]
        rate["ratelimit.py"]
    end
    subgraph data["Data layer"]
        db["db.py: Database, transaction"]
        repos["repositories/*: SQL"]
    end
    main --> mw
    main --> routers
    routers --> schemas
    routers --> httpx
    routers --> auth
    routers --> access
    routers --> idem
    auth --> tokens
    auth --> rate
    access --> repos
    idem --> db
    repos --> db
    routers --> repos
    errors --> schemas
```

Main types:

```mermaid
classDiagram
    class Principal {
        +UUID user_id
        +str username
        +frozenset roles
        +frozenset scopes
        +is_admin() bool
    }
    class Access {
        +UUID team_id
        +str level
        +can_manage() bool
        +require_manage(action)
    }
    class TokenVerifier {
        +str issuer
        +str audience
        +verify(token) dict
    }
    class JwksKeys {
        +call(token) key
    }
    class Database {
        +transaction(actor_id) Connection
        +ping() bool
    }
    class FixedWindowLimiter {
        +hit(key, limit) Decision
    }
    class ProblemError {
        +int status
        +str detail
        +str code
        +list errors
    }
    TokenVerifier --> JwksKeys : key_for
    Principal ..> TokenVerifier : built from verified claims
    Access ..> Principal : decided for
    Database ..> ProblemError : errors become problems
```

Decisions (ADR style):

| Id | Decision | Alternatives | Consequences |
|----|----------|--------------|--------------|
| D1 | FastAPI with **synchronous** route functions | `async def` with SQLAlchemy async | FastAPI runs sync routes in a thread pool, so blocking psycopg and PyJWT calls never stall the event loop; the code reads top to bottom. Throughput is bounded by the pool (10 + 10 connections), not by coroutines |
| D2 | SQLAlchemy **Core** with `text()` and bound parameters | ORM models; raw psycopg | The SQL stays visible and reviewable, the stored functions are called directly; there is no object graph to keep in step with the schema. Rows are dictionaries |
| D3 | Stored functions for `create_team`, `complete_task`, `reassign_task` | The same rules in Python | One implementation for four backends. The API maps `TS...` errors; changes need a migration |
| D4 | No Alembic in this capstone | Alembic baseline plus revisions | The platform `db/schema.sql` runs once from `docker-entrypoint-initdb.d`; adopting it with `alembic stamp` and adding numbered revisions later is the production path (chapter 04 note). Fewer moving parts for learners |
| D5 | PyJWT with `PyJWKClient` | Authlib; python-jose | Small, maintained, one call per rule; `PyJWKClient` caches the JWK Set and throttles refetches on unknown `kid` |
| D6 | Pydantic v2 DTOs with `extra="forbid"` | Hand-written validation | The contract's `additionalProperties: false` is one line; errors carry a location we turn into a JSON Pointer |
| D7 | Pure ASGI middleware | `BaseHTTPMiddleware` | Less overhead, can add headers to every response including errors |
| D8 | In-process fixed-window rate limiter | Redis; token bucket | No extra service; counts per process, so a second replica doubles the allowance (documented risk) |
| D9 | Python 3.14 slim image, venv copied between stages | Alpine; distroless; 3.15 | Every dependency ships a `cp314` manylinux wheel (checked on 2026-11-23); musl (Alpine) would compile or fail. 3.15 is newer than the wheels of some libraries |
| D10 | Keyset cursors are unsigned base64url JSON | Signed cursors | A forged cursor can only move the position inside rows the query already allows; every query repeats the authorization filter |

## 5. Domain and data model
The data model is owned by the platform ([section 5](../platform/TDD.md)); this API never changes the schema. Mapping used here:

| Table | Written by | Notes |
|-------|-----------|-------|
| `users` | `ensure_user` on first authenticated request | `INSERT ... ON CONFLICT DO NOTHING`; the seed already holds alice, bob, carol |
| `teams`, `team_members` | `create_team()` function; `PUT`/`DELETE` members; plain `UPDATE`/`DELETE` for teams | `lock_leads` protects the last-lead rule |
| `projects`, `tasks`, `comments` | repositories (`INSERT ... RETURNING`, `UPDATE` of allow-listed columns, `DELETE`) | `lock_and_check` locks the row and compares `version` |
| `tasks` status changes | `complete_task()`, `reassign_task()` | row lock, version check and rules inside Postgres |
| `audit_log` | triggers only | the API sets `app.current_user_id` first; `tasks_app` cannot update or delete audit rows |
| `idempotency_keys` | `run_idempotent` in the same transaction as the create | replay returns the stored body |

DTO names are camelCase (`dueDate`), columns snake_case (`due_date`); `PatchModel.model_dump(exclude_unset=True)` yields exactly the column names. Seed data and users come from the platform seed.

## 6. API design
The 27 operations, paths, DTOs, status codes and error format are those of the platform ([section 6](../platform/TDD.md), `openapi.yaml`). Implementation details that the contract leaves open:

| Topic | Decision in this backend |
|-------|--------------------------|
| Route order of checks | token (401) then rate limit (429) then scope (403) then body validation (400, 422) then handler: header presence (428), team access (404 or 403), version (412), rules (409) |
| 400 versus 422 | malformed JSON, bad query/path/header value, bad cursor: 400. A bad body field or an assignee outside the team: 422 with `errors[]` |
| `Location` | `PUBLIC_BASE_URL` + `/v1/<resource>/<id>`, never the `Host` header |
| `PATCH` | JSON Merge Patch: only sent fields change; `null` allowed for `assigneeId` and `dueDate`; empty body is 422 |
| `If-Match` | one strong ETag like `"3"`; anything else is 400; `*` and weak tags are not accepted |
| Members | `PUT` answers 201 when the member is new, 200 when only the role changed; the last lead cannot be demoted or removed (409, `code: last_lead`) |
| Idempotency | key row and resource are written in one transaction; a second request waits on the unique index and then replays; failed creates leave no key |

SQLSTATE to problem mapping (`app/db_errors.py`):

| SQLSTATE | Raised by | Status | Problem `type` suffix | Detail shown |
|----------|-----------|--------|-----------------------|--------------|
| `TS404` | stored functions: not found | 404 | `not-found` | the function's message |
| `TS409` | rule violated (cancelled task, last lead) | 409 | `conflict` | the function's message |
| `TS412` | stale `p_expected_version` | 412 | `precondition-failed` | the function's message |
| `TS422` | invalid input (assignee not in team, unknown lead) | 422 | `validation-error` | the function's message |
| `23505` | unique violation (team name, project key) | 409 | `conflict`, `code: duplicate` | fixed text, no constraint name |
| `23503`, `23514` | foreign key, check constraint | 422 | `validation-error` | fixed text |
| `22P02` | bad text representation | 400 | `bad-request` | fixed text |
| class `08`, `53`, `57` or none | database unreachable or overloaded | 503 | `service-unavailable` | fixed text, `Retry-After: 5` |
| anything else | unexpected | 500 | `internal-error` | fixed text; details only in the log |

## 7. Identity and security design
Flows: the browser and mobile sign-in sequences and the bearer validation sequence are in the [platform TDD, section 7](../platform/TDD.md). This backend implements the last one:

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant M as Middleware
    participant A as authenticate()
    participant V as TokenVerifier
    participant K as Keycloak JWKS
    participant H as Route handler
    participant D as Postgres
    C->>M: request with Authorization Bearer
    M->>A: trace id set, body size checked
    A->>V: verify(token)
    V->>V: alg must be RS256
    V->>K: key for kid, only when not cached
    V->>V: signature, iss, aud, exp, nbf with 30 s skew
    V-->>A: claims or TokenRejected
    A->>A: rate limit per user, then scopes
    A-->>H: Principal (user id is sub)
    H->>D: BEGIN, set_config(actor), team access, SQL
    D-->>H: rows or SQLSTATE
    H-->>C: 2xx with ETag, or problem+json
```

Token validation rules (all in `app/tokens.py`):

| Rule | Implementation | Failure |
|------|----------------|---------|
| Algorithm | header `alg` must equal `RS256` before any key lookup (blocks `none` and HS256 key confusion) | 401 |
| Signature | key by `kid` from the cached JWK Set (5 minutes); unknown `kid` allows one refetch per 30 seconds | 401 |
| Issuer | exact string `TOKEN_ISSUER` | 401 |
| Audience | claim string or list must contain `TOKEN_AUDIENCE` (`tasks-api`) | 401 |
| Lifetime | `exp` required, `nbf` honoured, 30 seconds skew | 401 (`The access token has expired.` for `exp`) |
| Required claims | `exp`, `iss`, `aud`, `sub` | 401 |
| Keys unreachable | no cached key and Keycloak down | 503 with `Retry-After` |

| Check | Source | Effect |
|-------|--------|--------|
| Scope | claim `scope`, space separated | missing scope: 403 |
| Role | `realm_access.roles` filtered to `admin`, `member` | admin routes: 403 for others |
| Team access | `team_members` row; admin sees every team | not a member: 404; member without lead role on a manage action: 403 |
| Comment delete | author, team lead or admin | otherwise 403 |

Secrets: only `.env` (ignored) and Compose `environment`; the repository holds fake local values. The token is never logged; refusals log `event`, `status`, `path`, `userId`, `detail`.

OWASP API Security Top 10 (2023) mapping (every row is walked through with code in chapter 05):

| Risk | Where this backend answers it |
|------|-------------------------------|
| API1 Broken object level authorization | `access.py`: every object resolves to a team; non-members get 404 |
| API2 Broken authentication | `tokens.py`: RS256, exact issuer, audience, expiry, cached JWKS; anonymous rate limit |
| API3 Broken object property level authorization | DTOs with `extra="forbid"`; `update_columns` allow-lists columns; read-only fields never bound |
| API4 Unrestricted resource consumption | `limit` max 100, `MAX_BODY_BYTES`, rate limits, pool timeout and container limits |
| API5 Broken function level authorization | `require_admin` plus scope per route (`Reader`, `Writer`, `AdminWriter`, `AdminOnly`) |
| API6 Sensitive business flows | admin-only team creation, idempotency keys, last-lead rule |
| API7 Server-side request forgery | the only outgoing call is the JWKS fetch from `JWKS_URL`; redirects are refused by PyJWT |
| API8 Security misconfiguration | pinned image, non-root, read-only file system, loopback ports, CORS allow-list, docs off, no stack traces |
| API9 Improper inventory management | one contract, `/v1` prefix, `/docs` only in development |
| API10 Unsafe consumption of APIs | JWKS parsed by PyJWT; token claims treated as input and type-checked |

Threat model summary. **Assets:** tokens, task data, audit trail. **Entry points:** port 8000, `JWKS_URL`, the database credentials in the environment. **Top threats:** forged or replayed tokens (verification, short lifetime), IDOR (404 on non-members), SQL injection (bound parameters; the only formatted SQL uses literal table names and allow-listed columns), abuse (limits), container escape or tampering (non-root, read-only, no capabilities).

## 8. Project structure
```text
capstones/backend-python/
  README.md  TDD.md
  tutorials/phase-N-slug/NN-slug.md                        five chapters
  source/phase-N-slug/PACK-README.md
  source/phase-N-slug/NN-slug/{code, exercise/{starter,solution}, verify.json}
    code/
      pyproject.toml  requirements.txt  .env.example  .gitignore
      Dockerfile  .dockerignore  docker-compose.override.yml      (phase 4)
      docker-compose.yml  db/  keycloak/  scripts/conformance.py  (copied from the platform, unchanged)
      app/
        main.py  config.py  logging_config.py  middleware.py  errors.py  db_errors.py
        schemas.py  http.py  pagination.py  idempotency.py  ratelimit.py
        auth.py  tokens.py  access.py  db.py  dependencies.py
        repositories/{sql,users,teams,members,projects,tasks,comments,audit}.py
        routers/{health,me,users,teams,members,projects,tasks,comments,audit}.py
      scripts/{get_token,forge_token,token_rules}.py  requests/*.json
```
Layering rules: routers may import everything below them; `repositories` import only `sql.py` helpers and SQLAlchemy; `schemas.py` and `errors.py` import nothing from the application. Names: Python `snake_case`, JSON `camelCase`, one router module per resource, one repository module per table family. Settings (environment variables, defaults in `app/config.py`):

| Variable | Default / example | Phase |
|----------|-------------------|-------|
| `DATABASE_URL` | `postgresql+psycopg://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams` (host `db` in Compose) | 2 |
| `TOKEN_ISSUER`, `TOKEN_AUDIENCE`, `JWKS_URL`, `TOKEN_LEEWAY_SECONDS` | `http://localhost:8180/realms/tasksteams`, `tasks-api`, Keycloak `.../protocol/openid-connect/certs`, `30` | 3 |
| `PUBLIC_BASE_URL`, `LOG_LEVEL`, `ENABLE_DOCS` | `http://localhost:8000`, `INFO`, `true` (`false` in Compose) | 1 |
| `RATE_LIMIT_USER`, `RATE_LIMIT_ANONYMOUS`, `RATE_LIMIT_WINDOW_SECONDS` | `100`, `30`, `60` | 5 |
| `MAX_BODY_BYTES`, `CORS_ORIGINS`, `ENABLE_HSTS` | `1048576`, `http://localhost:4200,http://localhost:5173`, `false` | 5 |

## 9. Delivery plan (phases)
| Phase | Title | Chapter | Requirement ids | Exit check (smoke) | Source pack |
|-------|-------|---------|-----------------|--------------------|-------------|
| 1 | Skeleton | 01 Project layout, problem details, DTOs | R-01, R-02, R-03 | `/health` answers; invalid team body gives a 422 problem | `backend-python-phase-1-skeleton.zip` |
| 2 | Data | 02 Repositories, stored functions, ETag, cursors, idempotency | R-04 to R-14 | conformance: 17 passed, 1 failed (`me` lacks RateLimit headers) | `backend-python-phase-2-data.zip` |
| 3 | Identity | 03 Keycloak token validation, scopes and roles | R-15, R-16 | token rules script; forged token gives 401; conformance 17 and 1 | `backend-python-phase-3-identity.zip` |
| 4 | Run and ship | 04 Dockerfile, Compose override, health check | R-17, R-18 | `docker compose up --build --wait`, conformance 17 and 1 | `backend-python-phase-4-run-and-ship.zip` |
| 5 | Hardening | 05 Limits, headers, logging, OWASP walk-through, backup | R-19 to R-23 | conformance `18 passed, 0 failed` | `backend-python-phase-5-hardening.zip` |

Chapter 01 needs no Docker. Chapters 02 and 03 run Postgres and Keycloak in Compose and the API on the host; chapters 04 and 05 run all three in Compose.

## 10. Verification plan
Smoke only, Docker temporary, `"exclusive": "tasksteams"` (ports 8000, 8180, 5432 are shared with the other backends). Per chapter, `python scripts/verify_labs.py capstones/backend-python`:
1. **01**: install the four packages into a throwaway folder, start Uvicorn, `GET /health`, `POST` an invalid team (422), run the exercise solution. No Docker.
2. **02, 03**: `docker compose -p {project} up -d --wait` (Postgres, Keycloak), start the API on the host, run `scripts/conformance.py` once and compare the pass and fail lines (chapter 03 also runs `token_rules.py` and a forged-token request).
3. **04, 05**: `docker compose -p {project} up -d --build --wait` (adds the API container), run the conformance script (chapter 05 also checks headers, 429, a backup and restore).
4. Every chapter: `cleanup` runs `docker compose -p {project} down -v --remove-orphans --rmi local` and removes the image it built. No unit-test suite is run.
Conformance with the contract: chapter 05 prints `18 passed, 0 failed`; chapters 02 to 04 print `17 passed, 1 failed` and the one failure is named in the text.

## 11. Deployment and operations
| Item | Value |
|------|-------|
| Compose files | `docker-compose.yml` (platform, unchanged) plus `docker-compose.override.yml` (service `api`), merged automatically |
| Ports | `127.0.0.1:8000` API, `127.0.0.1:8180` Keycloak, `127.0.0.1:5432` Postgres (platform port table) |
| Network | `tasksteams-net`, service names `db` and `keycloak` |
| Health | image `HEALTHCHECK` calls `GET /health` every 10 seconds; Compose `--wait` waits for it |
| Logs | JSON lines on stdout: `docker compose logs -f api`; fields `time`, `level`, `logger`, `message`, `traceId`, plus `method`, `path`, `status`, `durationMs`, `userId` |
| Backup | `docker compose exec -T db pg_dump -U tasks_admin --no-owner tasksteams > backup.sql`; restore into an empty database with `psql -f -` (chapter 05) |
| Scaling | stateless except the rate limiter; with more replicas use a shared limiter |
| Upgrades | rebuild the image (`up -d --build`); schema changes are numbered SQL migrations applied before the new image starts |

## 12. Risks, open questions, decisions
| Risk or question | Impact | Mitigation / decision |
|------------------|--------|-----------------------|
| Newest library majors (FastAPI 0.165, Starlette 1.x, SQLAlchemy 2.1) change quickly | Learners on other versions see different messages | Everything is pinned in `requirements.txt`; the chapter says which versions were run |
| In-memory rate limiter per process | Two replicas allow twice the traffic | Documented in `ratelimit.py` and chapter 05; Redis is the next step |
| `ensure_user` cannot cure a username or e-mail clash with another id | A later insert fails with a foreign key error | Platform seed ids equal Keycloak ids; a clash is a data problem (500 is logged) |
| JWKS refetch cooldown of 30 s | A freshly rotated key is unknown for up to 30 s | Acceptable for the 5 minute token life; shown in chapter 03 |
| `tasks_app` password is in the schema file | Fine for local practice only | Chapter 04 says to create the role from a secret store in real systems |
| Windows and Linux differ in the venv path and quoting | Copy-paste mistakes | Every command is shown in both forms; JSON bodies are sent from files |
| Platform defects (reported, not edited) | The conformance script's `PASSWORDS` has no `carol`, and `openapi.yaml` declares no `413` (although the platform TDD sets a 1 MB body limit) and no `503` for `/v1` routes when the database is down | Worked around: our probes add carol's password; the API answers 413 and 503 as problem details anyway. The platform owner should add both responses to the contract |

## 13. References
- FastAPI documentation (security scopes, dependencies, lifespan): https://fastapi.tiangolo.com/
- Starlette middleware (pure ASGI): https://www.starlette.io/middleware/
- Pydantic 2 (models, validators, settings): https://docs.pydantic.dev/ and https://docs.pydantic.dev/latest/concepts/pydantic_settings/
- SQLAlchemy 2.1 (Core, `text()`, psycopg dialect): https://docs.sqlalchemy.org/en/21/ and https://docs.sqlalchemy.org/en/21/dialects/postgresql.html#module-sqlalchemy.dialects.postgresql.psycopg
- psycopg 3: https://www.psycopg.org/psycopg3/docs/
- PyJWT (decode options, `PyJWKClient`): https://pyjwt.readthedocs.io/
- RFC 9457 Problem Details, RFC 7396 JSON Merge Patch, RFC 9110 (ETag, If-Match), RFC 6750 (Bearer): https://www.rfc-editor.org/
- RFC 8725 JWT Best Current Practices, RFC 9068 JWT access tokens: https://www.rfc-editor.org/info/rfc8725
- OWASP API Security Top 10 2023: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- Docker: multi-stage builds https://docs.docker.com/build/building/multi-stage/ ; Dockerfile best practices https://docs.docker.com/build/building/best-practices/ ; Compose merge https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/
- PostgreSQL 17 `pg_dump` and `psql`: https://www.postgresql.org/docs/17/app-pgdump.html
- Python Docker image tags and wheel availability checked on 2026-11-23: https://hub.docker.com/_/python and https://pypi.org/
