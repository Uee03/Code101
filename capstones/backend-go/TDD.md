# TDD: Backend Go (Tasks and Teams)

| Field | Value |
|-------|-------|
| Id | backend-go |
| Level | 201 |
| Status | Verified (all seven chapters run by `scripts/verify_labs.py`; the final phase passes `18 passed, 0 failed` on 2026-11-23) |
| Depends on | platform |
| Stack | Go 1.27.4 (`net/http` with the Go 1.22 `ServeMux` patterns, `log/slog`), pgx v5.13.0 (`pgxpool`), golang-jwt v5.3.1, Docker Engine 29.9.3, Compose 5.7.0, PostgreSQL 17 and Keycloak 26.8.2 from the platform. Image tags checked on Docker Hub and gcr.io on 2026-11-23: `golang:1.27.4-alpine3.24`, `gcr.io/distroless/static-debian13:nonroot`. Module versions checked on the Go module proxy and pkg.go.dev |
| Estimated learner time | 7 chapters, about 12 hours (90 + 120 + 120 + 60 + 120 + 90 + 120 minutes) |
| Last updated | 2026-11-23 |

## 1. Purpose and learning goals
`backend-go` implements the whole [platform contract](../platform/TDD.md) in Go: 27 operations, problem details, ETag and `If-Match`, cursor pagination, idempotency keys, Keycloak token validation with roles and scopes, rate limits and an audit trail written by the database. It is one of four interchangeable backends; the web clients work with it and so do the Flutter and Kotlin apps (the Rust backend is the one not taught for mobile).

Skills gained:
1. Structure a Go service in layers (`cmd`, `http`, `store`, `auth`, `problem`, `config`) with dependencies pointing one way.
2. Build an HTTP API with the standard library: `ServeMux` patterns, middleware, context, graceful shutdown.
3. Use `pgx` and `pgxpool` with parameterised SQL, transactions, generics for scanning, keyset pagination and stored functions.
4. Map database errors (`SQLSTATE` `TS404`, `TS409`, `TS412`, `TS422`, `23505`) to RFC 9457 problem details.
5. Validate JWT access tokens from Keycloak with a cached JWKS and apply role, scope and team-membership rules.
6. Ship a static binary in a multi-stage, non-root, healthchecked image and join the platform network.
7. Harden an API against the OWASP API Security Top 10 (2023): limits, headers, CORS, redacted logs.
8. Prove conformance with the platform's black-box script.

## 2. Scope
**In scope:** the Go service in `source/phase-5-hardening/07-hardening/code`, its Dockerfile and Compose override, seven chapters, an exercise per chapter and a `verify.json` per chapter.
**Out of scope:** unit and integration test suites (verification is a smoke test, see section 10), an ORM, code generation (`sqlc` is named as the next step, not used), TLS termination, Kubernetes, tracing backends, Authentik (an appendix mapping only, in the web and mobile capstones), changing the platform files.
**Assumptions:** Docker, Go 1.27, `curl` and Python 3.10+ are installed; the learner finished Go 101 and the platform capstone; the platform stack is started from this capstone's own folder (it holds byte-identical copies of the platform files).
**Constraints:** everything follows the platform contract exactly; the platform files are never edited; the API listens on host port 8000, Keycloak is 8180, Postgres is 5432 (all `127.0.0.1`); every password in the repository is fake and local.

## 3. Requirements
Platform ids (`P R-xx`) are from the [platform TDD](../platform/TDD.md).

| Id | Requirement | Platform id | Priority | Acceptance check | Phase |
|----|-------------|-------------|----------|------------------|-------|
| R-01 | The service reads its settings from environment variables, fails at start-up on a bad value and shuts down gracefully on SIGINT or SIGTERM | P R-21 | Must | log lines `listening`, `shutting down`, `stopped` | 1 |
| R-02 | `GET /health` answers 200 without a token and reports the database; 503 and `degraded` when the database is down | P R-02 | Must | conformance `health`; chapter 02 "database down" run | 1, 2 |
| R-03 | `GET /v1/me` returns the caller with roles from the token, scopes and teams; the `users` row is created on first use | P R-03, P R-18 | Must | conformance `me` | 2, 5 |
| R-04 | All 27 operations of `openapi.yaml` exist with the contract's paths, methods, success and error statuses | P R-01, R-04 to R-07, R-11, R-15 | Must | conformance plus the curl runs of chapters 02 to 04 | 2, 3 |
| R-05 | Every error is `application/problem+json` with `type`, `title`, `status`, `instance` and `traceId`, including unknown paths (404) and wrong methods (405) | P R-09 | Must | conformance `problem details shape`, `401 without token` | 1 |
| R-06 | Request bodies are decoded strictly (unknown fields, wrong types, trailing data) and validated; errors name the field with a JSON Pointer | P R-09 | Must | conformance `problem details shape` (`/name`) | 1 |
| R-07 | All SQL is parameterised and lives in the `store` package; the API connects as `tasks_app` | P R-16, P R-23 | Must | code review of `internal/store`; the connection URL | 2 |
| R-08 | Every write runs in a transaction that sets `app.current_user_id`, so the audit trigger names the actor | P R-08 | Must | conformance `audit log` | 2 |
| R-09 | `create_team`, `complete_task`, `reassign_task` are called as stored functions; their SQLSTATEs map to 404, 409, 412, 422 | P R-17 | Must | chapter 03 curl runs (409 on a done task) | 3 |
| R-10 | Single resources carry a strong ETag (the version); `PATCH`, `complete`, `reassign` need `If-Match` (412 stale, 428 missing); `If-None-Match` gives 304 | P R-12 | Must | conformance `get task with ETag`, `stale If-Match gives 412` | 2, 3 |
| R-11 | Lists use opaque keyset cursors (`limit`, `cursor`, `page.nextCursor`); a bad cursor is 400 | P R-10 | Must | conformance `cursor pagination` | 2 |
| R-12 | Task lists filter by status, priority, assignee, due range and title text and sort by `createdAt`, `-createdAt` or `dueDate` (nulls last) | P R-11 | Should | chapter 03 curl runs | 3 |
| R-13 | `Idempotency-Key` on the four creates: replay with `Idempotent-Replayed: true`, 422 for another body, 409 while running | P R-13 | Must | conformance `create task with Idempotency-Key` | 4 |
| R-14 | Bearer tokens are validated: `RS256` only, exact `iss`, `aud` string or list containing `tasks-api`, `exp` required, 30 s skew, signature by cached JWKS | P R-20 | Must | conformance `401 without token`, the attack runs of chapter 05 | 5 |
| R-15 | Authorization is the intersection of scope and role; members see only their teams; strangers get 404; leads manage members, projects and reassignment; admins pass | P R-20 | Must | conformance `403 for member on admin route` | 5 |
| R-16 | The API sets `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` and answers 429 with `Retry-After` | P R-14 | Should | conformance `me` | 7 |
| R-17 | Responses carry security headers; CORS allows only `http://localhost:4200` and `http://localhost:5173`; bodies are limited to 1 MiB (413) | platform section 7 | Must | chapter 07 curl runs | 7 |
| R-18 | Logs are structured, carry a trace id and the user id, and never contain tokens, bodies, passwords or the database password | platform section 11 | Must | chapter 07 log excerpts | 1, 7 |
| R-19 | A multi-stage Dockerfile builds a static binary into a non-root distroless image; `docker-compose.override.yml` joins `tasksteams-net` and publishes `127.0.0.1:8000`; the container has a healthcheck | P R-21 | Must | `docker compose up -d --build --wait` | 6 |
| R-20 | The final phase passes all 18 checks of `scripts/conformance.py`; earlier phases document how many they pass | P R-22 | Must | `18 passed, 0 failed` | 7 |
| R-21 | Each chapter has a phase pack, a `verify.json` and a lesson whose text contains every line of the code | P R-24 | Must | `python scripts/verify_labs.py capstones/backend-go` | 1 to 7 |

| Non-functional requirement | Target and measurement |
|----------------------------|------------------------|
| Image size | under 30 MB; measured 23.3 MB (`docker image ls`) |
| Start-up | ready (healthy) within 5 s of the container start; measured 3 s in the Compose run |
| Latency | platform target p95 under 200 ms; the access log of the author runs shows 0.3 to 25 ms per request on the seed data (not a benchmark) |
| Resource limits | container memory 256 MB, 128 processes, database pool at most 10 connections |
| Dependencies | 2 direct modules (pgx, golang-jwt); everything else is the standard library |
| Portability | Windows, macOS, Linux; all commands are given for PowerShell and bash where they differ |

## 4. Architecture
System context:

```mermaid
flowchart LR
    C["Clients: Angular, React, Flutter, Kotlin, curl"]
    API["backend-go<br/>port 8000"]
    KC["Keycloak<br/>port 8180, realm tasksteams"]
    PG[("PostgreSQL 17<br/>schema, functions, seed")]
    C -->|"HTTPS in production, bearer token"| API
    C -.->|"sign in, PKCE"| KC
    API -->|"JWKS over the internal network"| KC
    API -->|"SQL as tasks_app"| PG
```

Inside the service (dependencies point downwards and to the right; nothing imports `cmd`):

```mermaid
flowchart TD
    MAIN["cmd/api: main, wiring, graceful shutdown, healthcheck"]
    HTTP["internal/http (package httpapi): routes, middleware, DTOs, handlers"]
    AUTH["internal/auth: Principal, JWT validator, JWKS cache"]
    STORE["internal/store: pgxpool, queries, keyset pages, error mapping"]
    PROB["internal/problem: RFC 9457 documents"]
    CFG["internal/config: environment to Config"]
    MAIN --> HTTP
    MAIN --> AUTH
    MAIN --> STORE
    MAIN --> CFG
    HTTP --> AUTH
    HTTP --> STORE
    HTTP --> PROB
```

| Component | Responsibility |
|-----------|----------------|
| `cmd/api` | Load configuration, build the logger, pool, validator and server, run until a signal arrives, then shut down; the `healthcheck` subcommand for the container |
| `internal/http` | Routing with `ServeMux`, the middleware chain, strict JSON decoding, validation, authorization decisions, mapping of store errors to problem details; no SQL |
| `internal/store` | Every SQL statement, transactions with the acting user, keyset pagination, mapping of `SQLSTATE` to `store.Error`; no HTTP |
| `internal/auth` | `Principal`, the `Authenticator` interface, the JWT validator and the JWKS cache |
| `internal/problem` | The one error document and the trace id context helpers |
| `internal/config` | Typed settings, defaults, validation, a redacted `LogValue` |

Middleware chain (first is outermost):

| Order | Middleware | Job |
|-------|-----------|-----|
| 1 | `withTrace` | W3C trace id or a new one, in the context and in `X-Trace-Id` |
| 2 | `accessLog` | one structured line per request, after it finished |
| 3 | `recoverer` | panic to logged 500 problem |
| 4 | `secureHeaders` | `nosniff`, `no-store`, CSP, referrer policy, HSTS over TLS |
| 5 | `cors` | allow-list, preflight answers |
| 6 | `authenticate` | soft: record the caller or the reason for refusal |
| 7 | `rateLimit` | per user or per address; `RateLimit-*` headers; 429 |
| 8 | `bodyLimit` | 1 MiB limit; 413 |
| route | `handle` | 401 without a caller, 403 without the scope; optional `idempotent` wrapper for the four creates |

Decisions (ADR style):

| Decision | Alternatives | Consequences |
|----------|--------------|--------------|
| Standard library router (Go 1.22 patterns) | chi, gin, echo | No router dependency; method and wildcard patterns are built in. Groups and middleware are written by hand (about 150 lines) |
| Hand-written SQL in `store` | sqlc, an ORM | No generator to run reproducibly; every query is readable; column lists are kept in step with structs by hand. sqlc is the named next step |
| `pgx` native interface and generics for scanning | `database/sql` | One scanning helper for every entity; code is tied to pgx |
| Keyset pagination with a signed-by-structure cursor (base64url JSON that includes the sort) | offset | Stable and fast; no page jumps |
| Business rules that must be atomic stay in Postgres functions | all logic in Go | One rule for four backends; Go only maps errors |
| Local JWT validation with a throttled JWKS cache | introspection per request | No network hop; revocation takes up to the 5 minute token life |
| `Authenticator` interface, a development stand-in in chapters 02 to 04 | Keycloak from the start | The authorization rules can be learned and tested early; the stand-in is deleted in chapter 05 |
| Fixed-window in-memory rate limiter | token bucket, Redis | Simple and exact for one process; not shared between processes |
| `distroless/static:nonroot` runtime | alpine, scratch | No shell, no package manager, CA certificates and time zones present; harder to debug |
| `log/slog` JSON in containers | zap, zerolog | Standard library; one line per event |

## 5. Domain and data model
The data model is the platform's ([platform TDD section 5](../platform/TDD.md)); this capstone copies `db/schema.sql` and `db/seed.sql` byte-identically and never edits them. Entities used by the code:

| Go type (`internal/store`) | Table | Notes |
|----------------------------|-------|-------|
| `User` | `users` | `id` is the Keycloak `sub`; created on first use by `EnsureUser` |
| `Team`, `TeamAccess`, `TeamFilter`, `TeamPatch` | `teams`, `team_members` | `memberCount` is a subquery; `TeamAccess` joins the caller's membership |
| `Member` | `team_members` joined with `users` | last-lead rule enforced under a row lock |
| `Project`, `ProjectPatch` | `projects` | unique `(team_id, key)` maps to 409 |
| `Task`, `TaskFilter`, `TaskInput`, `TaskPatch` | `tasks` | column order equals the table order, so `SELECT * FROM complete_task(...)` scans into it |
| `Comment` | `comments` joined with `users` | author profile embedded |
| `AuditEntry`, `AuditFilter` | `audit_log` | `details` passed through as JSON |
| `IdempotencyRecord` | `idempotency_keys` | claim, finish, release |

**Migration strategy.** The platform baseline (version 0001) is the schema. This backend adds no tables. When a later change is needed it is a numbered migration applied with a migration tool (golang-migrate is the usual choice); the baseline is never edited. **Seed data:** alice (admin), bob and carol as in the platform; the chapters use the seed ids in their curl runs.

## 6. API design
The contract is `openapi.yaml` of the platform capstone; this service implements all 27 operations with the same paths, DTO names, statuses and headers. Where the contract leaves room, the Go service decides as follows.

| Topic | Decision |
|-------|----------|
| Unknown path, wrong method | problem 404 `not-found`, problem 405 `method-not-allowed` (type not in the contract's table) with `Allow` |
| Malformed path id (not a UUID) | 404, as for an unknown id |
| Wrong `Content-Type` on a body | 400 `bad-request` (the contract lists no 415) |
| Unknown JSON field, wrong JSON type | 422 with a pointer such as `/foo` |
| Body over 1 MiB | 413 `payload-too-large` (type not in the contract's table) |
| Invalid `If-Match` syntax | 400; `*` means any version |
| Weak `If-None-Match` (`W/"3"`) | accepted for 304 |
| `archived=true` on the project list | includes archived projects next to active ones; the default hides them |
| Idempotent replay body | the stored `jsonb` document: same data, key order may differ |
| Header names | Go canonicalises them (`Etag`, `Ratelimit-Limit`); clients must compare case-insensitively |

SQLSTATE to problem mapping (done once, in `store.mapError` and `httpapi.storeProblem`):

| SQLSTATE | Meaning | `store.Kind` | HTTP | Problem type |
|----------|---------|--------------|------|--------------|
| `TS404` | not found | `KindNotFound` | 404 | `not-found` |
| `TS409` | business rule violated | `KindConflict` | 409 | `conflict` |
| `TS412` | stale version | `KindStale` | 412 | `precondition-failed` |
| `TS422` | invalid input | `KindInvalid` | 422 | `validation-error` |
| `23505` | unique violation | `KindConflict` | 409 | `conflict` (named per constraint) |
| `23503` | foreign key violation | `KindInvalid` | 422 | `validation-error` |
| `23514` | check violation | `KindInvalid` | 422 | `validation-error` |
| bad cursor (Go) | undecodable cursor | `KindBadCursor` | 400 | `bad-request` |
| anything else | unexpected | none | 500 | `internal-error` (no details; cause logged with the trace id) |

Order of checks in a handler: scope (401, 403) then team access (404, 403) then `If-Match` presence (428) then decode (400, 422) then validation (422) then the store (409, 412, 422). Rate limiting (429) and the body limit (413) run before all of them.

## 7. Identity and security design
Token flow in this service (the sign-in itself belongs to the clients, see the platform TDD):

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant A as backend-go
    participant K as Keycloak JWKS
    C->>A: request with Authorization Bearer
    A->>A: header present and Bearer, else anonymous
    A->>K: key by kid, only when unknown, at most every 10 s
    A->>A: RS256, iss, aud, exp, nbf with 30 s skew
    A->>A: ensure users row, build Principal
    A->>A: rate limit by user id or address
    A->>A: route: scope, then team access, then handler
    A-->>C: result or problem details
```

| Rule | Implementation |
|------|----------------|
| Accepted algorithm | `RS256` only (`jwt.WithValidMethods`); `none` and HMAC tokens are refused |
| Issuer | must equal `KEYCLOAK_ISSUER` exactly (`http://localhost:8180/realms/tasksteams`) |
| Audience | `aud` string or list must contain `KEYCLOAK_AUDIENCE` (`tasks-api`) |
| Lifetime | `exp` required; 30 seconds of leeway for `exp` and `nbf` |
| Keys | downloaded from `KEYCLOAK_JWKS_URL`, cached by `kid`, refreshed for an unknown `kid` at most every 10 seconds |
| Roles | `realm_access.roles`; only `admin` and `member` are returned by `/v1/me` |
| Scopes | space separated `scope` claim; each route declares the scope it needs |
| Effective permission | scope AND role AND team membership (admins pass team checks) |
| Strangers | 404 for every object of a team the caller is not in |
| Secrets | none in code except the disposable local defaults; production values come from the environment; `Config.LogValue` redacts the database password |

| Role or team level | May |
|--------------------|-----|
| anonymous | `GET /health` |
| any signed-in user with `tasks:read` | `GET /v1/me`, `GET /v1/users`, the lists and reads of their own teams |
| team member (`tasks:write`) | create tasks and comments, update and complete tasks, delete own comments |
| team lead | manage members, projects, reassign and delete tasks, delete any comment of the team, update the team |
| realm role `admin` (`tasks:write` or `tasks:admin`) | everything above in every team, create teams, delete teams and read the audit log (the last two need `tasks:admin`) |

OWASP API Security Top 10 (2023) mapping (the code-level table is in chapter 07):

| Risk | Mitigation here |
|------|-----------------|
| API1 Broken object level authorization | `authorize` on every object; 404 for strangers; UUID path ids |
| API2 Broken authentication | the JWT policy above; no development authentication in the final build |
| API3 Broken object property level authorization | strict DTOs, unknown fields rejected, store types never serialised, no e-mail in user lists |
| API4 Unrestricted resource consumption | `limit` at most 100, 1 MiB body, 64 KiB headers, timeouts, rate limits, small pool, container limits |
| API5 Broken function level authorization | scope per route, `requireAdmin`, team levels |
| API6 Unrestricted access to sensitive business flows | admin-only team creation, idempotency keys, per-user budget |
| API7 Server side request forgery | the only outgoing request is the JWKS download from a configured URL |
| API8 Security misconfiguration | security headers, CORS allow-list, no wildcard accepted, loopback ports, read-only non-root container |
| API9 Improper inventory management | one contract file, `/v1` prefix, uniform 404 for the rest |
| API10 Unsafe consumption of APIs | tokens only from the configured issuer, size and time limits on the key download, parameterised SQL |

Threat model summary. **Assets:** identities and tokens, task data, the audit trail. **Entry points:** port 8000, the token header, request bodies, query strings, the JWKS URL setting, the container. **Top threats and answers:** forged or foreign tokens (policy above); algorithm confusion (algorithm allow-list); object enumeration (404 for strangers); mass assignment (strict DTOs); lost updates (ETag and row locks); duplicate creates (idempotency keys); flooding (rate limits, body limit, timeouts); secret leakage (redaction, no tokens in logs); post-exploit movement (non-root, read-only, no capabilities, no shell).

## 8. Project structure
```text
capstones/backend-go/
  README.md  TDD.md  GLOSSARY.md
  tutorials/phase-N-slug/NN-slug.md              seven chapters
  source/phase-N-slug/PACK-README.md
  source/phase-N-slug/NN-slug/{code, exercise/{starter,solution}, verify.json}
  source/phase-5-hardening/07-hardening/code/    the finished project
    cmd/api/main.go
    internal/config/config.go
    internal/problem/problem.go
    internal/auth/{principal.go, jwks.go, jwt.go}
    internal/store/{store.go, errors.go, page.go, users.go, registry.go, teams.go, members.go, projects.go, tasks.go, comments.go, audit.go, idempotency.go}
    internal/http/{server.go, middleware.go, authz.go, errors.go, request.go, respond.go, validate.go, etag.go, optional.go, idempotency.go, ratelimit.go, secure.go, health.go, me.go, users.go, teams.go, members.go, projects.go, tasks.go, comments.go, audit.go}
    requests/*.json, requests/*.txt              request bodies and header files for curl
    Dockerfile  .dockerignore  docker-compose.override.yml
    docker-compose.yml  .env.example  db/  keycloak/  scripts/conformance.py    platform copies, byte-identical
    go.mod  go.sum
```
Layering rules: `store` imports nothing from `http`; `http` never contains SQL; handlers are methods of `*Server` and reach collaborators through it, not through globals; the only package-level state is immutable (regular expressions, tables). Naming: JSON members `camelCase`, database columns `snake_case`, Go exported names `CamelCase`, one resource per file.

| Variable | Default | Used by |
|----------|---------|---------|
| `LISTEN_ADDR` | `127.0.0.1:8000` (`0.0.0.0:8000` in the image) | server, healthcheck |
| `DATABASE_URL` | `postgres://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams` | store |
| `PUBLIC_URL` | `http://localhost:8000` | `Location` headers |
| `KEYCLOAK_ISSUER` | `http://localhost:8180/realms/tasksteams` | JWT validator |
| `KEYCLOAK_AUDIENCE` | `tasks-api` | JWT validator |
| `KEYCLOAK_JWKS_URL` | `http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs` (`http://keycloak:8080/...` in Compose) | JWKS cache |
| `CORS_ORIGINS` | `http://localhost:4200,http://localhost:5173` | CORS middleware |
| `RATE_LIMIT_PER_MINUTE`, `RATE_LIMIT_ANONYMOUS_PER_MINUTE` | `100`, `30` | rate limiter |
| `MAX_BODY_BYTES` | `1048576` | body limit |
| `LOG_LEVEL`, `LOG_FORMAT` | `info`, `text` (`json` in the image) | logger |

## 9. Delivery plan (phases)
| Phase | Title | Chapters | Requirement ids | Exit check (smoke) | Conformance | Source pack |
|-------|-------|----------|-----------------|--------------------|-------------|-------------|
| 1 | Skeleton | 01 The skeleton | R-01, R-05, R-06, R-18, R-21 | `curl /health` 200; invalid body gives 422 with `/name` | 6 passed, 12 failed | `backend-go-phase-1-skeleton.zip` |
| 2 | Data | 02 Store and teams; 03 Tasks and stored functions; 04 Idempotency | R-02, R-03, R-04, R-07 to R-13, R-21 | `/health` reports `database: up`; curl runs with the development stand-in | 6 passed, 12 failed (every token check fails) | `backend-go-phase-2-data.zip` |
| 3 | Identity | 05 JWT and roles | R-14, R-15, R-03 | conformance with real tokens | 17 passed, 1 failed (`me`: no `RateLimit-*` headers) | `backend-go-phase-3-identity.zip` |
| 4 | Run and ship | 06 Docker | R-19 | `docker compose up -d --build --wait` healthy | 17 passed, 1 failed (same) | `backend-go-phase-4-run-and-ship.zip` |
| 5 | Hardening | 07 Hardening | R-16, R-17, R-18, R-20 | conformance, headers, 429, 413, preflight | **18 passed, 0 failed** | `backend-go-phase-5-hardening.zip` |

Each phase pack holds the whole project at the end of that phase, so a learner can start at any phase. The conformance numbers in the table are real runs against that phase's code.

## 10. Verification plan
Smoke only, Docker temporary, never left behind. `python scripts/verify_labs.py capstones/backend-go` runs, per chapter, in a clean copy and under the exclusive lock `tasksteams` (host ports 8000, 8180 and 5432 are shared by all backends):
- chapter 01: `go build ./...`, `go run ./cmd/api` in the background, five `curl` probes, the exercise solution;
- chapters 02 to 04: start only the database (`docker compose -p {project} up -d --wait db`), run the API on the host and probe it with `curl` (create, ETag, `If-Match`, stored functions, filters, audit, idempotent replay), run the exercise solution;
- chapter 05: start the database and Keycloak, run the API on the host, probe 401, run `scripts/conformance.py` once (`17 passed, 1 failed` is the expected, documented result);
- chapters 06 and 07: `docker compose -p {project} up -d --build --wait` (database, Keycloak and the API container), run the conformance script once (chapter 06: `17 passed, 1 failed`; chapter 07: `18 passed, 0 failed`) and probe the image and container properties.
`cleanup` always runs `docker compose -p {project} down -v --remove-orphans --rmi local`, which also removes the image built for the check. Afterwards `docker ps -a`, `docker volume ls` and `docker network ls` show nothing of this capstone. There are no `go test` runs and no unit tests. The lesson text must contain every line of every file in `code/` except the listed unchanged files, the platform copies and the generated `go.sum`.

## 11. Deployment and operations
| Host port | Used by | Notes |
|-----------|---------|-------|
| 8000 | the API container (`127.0.0.1` only) | one backend at a time |
| 8180 | Keycloak | from the platform file |
| 5432 | Postgres | from the platform file |

Files: `docker-compose.yml` and `.env.example` (platform copies), `docker-compose.override.yml` (the `api` service), `Dockerfile`, `.dockerignore`. The override makes `docker compose up` start the whole stack; the service joins the platform network `tasksteams-net`. Logs: JSON lines on stdout (`docker compose -p tasksteams logs -f api`), each with `trace_id` and, when known, `user_id`. Health: `GET /health` for load balancers; `api healthcheck` inside the container. Shutdown: `docker stop` sends SIGTERM and the service finishes running requests (10 s limit). Backup: `pg_dump -Fc` and a restore into a scratch database (chapter 07 shows both). Releases: build the image with a pinned tag or digest; rebuild when the base image has security updates.

## 12. Risks, open questions, decisions
| Risk or question | Impact | Mitigation / decision |
|------------------|--------|-----------------------|
| The development stand-in (`X-Dev-User`) is a backdoor if it ships | Anyone can claim any identity | Used only in chapters 02 to 04, logs a loud warning, deleted in chapter 05; the final phase pack does not contain it |
| In-memory rate limits and idempotency waits are per process | Several replicas multiply the budget | Documented; a shared store or gateway limits is the production answer |
| Header canonicalisation (`Etag`, `Ratelimit-Limit`) | A client that compares case-sensitively fails | Contract section 6 note; the conformance script compares case-insensitively |
| `jsonb` normalises replayed idempotent responses | Replay is not byte-identical | Documented in chapter 04; acceptable because clients parse JSON |
| `tasks-smoke` holds all scopes | A scope refusal cannot be shown with a real token | The refusal is shown with the development stand-in in chapter 02; web and mobile clients request `tasks:admin` on demand |
| Image tags move | A rebuild may change the base | Tags are pinned to the patch version; digests are recommended for releases |
| Open: sqlc | Less hand-maintained column lists | Not used because generating code reproducibly in every learner environment is out of scope; named as the next step |
| Contract note: no 415, 413, 405 | The API adds three problem types | They are additive and follow RFC 9110; reported to the platform owners |

## 13. References
- Go `net/http` `ServeMux` patterns: https://pkg.go.dev/net/http#ServeMux and the routing enhancements post https://go.dev/blog/routing-enhancements
- `log/slog`: https://pkg.go.dev/log/slog
- pgx v5 and pgxpool: https://pkg.go.dev/github.com/jackc/pgx/v5
- golang-jwt v5: https://pkg.go.dev/github.com/golang-jwt/jwt/v5
- RFC 9457 Problem Details https://www.rfc-editor.org/info/rfc9457, RFC 7396 JSON Merge Patch https://www.rfc-editor.org/info/rfc7396, RFC 9110 HTTP Semantics https://www.rfc-editor.org/info/rfc9110, RFC 6585 https://www.rfc-editor.org/info/rfc6585
- RFC 7517 JSON Web Key https://www.rfc-editor.org/info/rfc7517, RFC 8725 JWT Best Current Practices https://www.rfc-editor.org/info/rfc8725, RFC 9068 JWT profile for access tokens https://www.rfc-editor.org/info/rfc9068, RFC 6750 Bearer tokens https://www.rfc-editor.org/info/rfc6750
- Keycloak documentation https://www.keycloak.org/documentation
- PostgreSQL 17 documentation https://www.postgresql.org/docs/17/
- Docker multi-stage builds https://docs.docker.com/build/building/multi-stage/, build best practices https://docs.docker.com/build/building/best-practices/, Compose merge https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/
- Distroless images https://github.com/GoogleContainerTools/distroless
- OWASP API Security Top 10 2023 https://owasp.org/API-Security/editions/2023/en/0x11-t10/ and the REST Security Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
- IETF drafts: RateLimit header fields https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/ and Idempotency-Key https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/
- Docker Hub `golang` tags and gcr.io `distroless/static-debian13` tags, checked 2026-11-23.
