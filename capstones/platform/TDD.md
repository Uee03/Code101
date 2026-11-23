# TDD: Platform contract (Tasks and Teams)

| Field | Value |
|-------|-------|
| Id | platform |
| Level | 201 |
| Status | Verified (infrastructure smoke checks run on 2026-11-23; API checks wait for the first backend) |
| Depends on | none |
| Stack | OpenAPI 3.1.1, PostgreSQL 17 (`postgres:17-alpine`, 17.12), Keycloak 26.8.2 (`quay.io/keycloak/keycloak:26.8.2`, newest stable on 2026-11-19), Docker Engine 29.9.3, Compose 5.7.0, Python 3.10+ (standard library for scripts). Verified against the official docs on 2026-11-23 |
| Estimated learner time | 4 chapters, about 5 hours in total (60 + 75 + 90 + 75 minutes) |
| Last updated | 2026-11-23 |

## 1. Purpose and learning goals
The platform capstone is the **shared contract** of the "Tasks and Teams" capstones: one OpenAPI file, one Postgres schema with seed data, one Keycloak realm, one Compose file for the infrastructure and one conformance script. Four backends (Python, ASP.NET, Go, Rust), two web clients (Angular, React) and two mobile clients (Flutter, Kotlin) implement or consume it, so any web client works with any backend and the mobile clients work with the ASP.NET, Python and Go backends.

Skills gained:
1. Write a contract-first REST API description in OpenAPI 3.1 with reusable components.
2. Model a relational schema with constraints, indexes, triggers and stored functions.
3. Make writes atomic and auditable inside the database.
4. Apply RFC 9457 problem details, cursor pagination, ETag/If-Match and idempotency keys.
5. Configure Keycloak as code (realm import), with PKCE clients, roles and scopes.
6. Explain and verify bearer token validation and role plus scope authorization.
7. Run infrastructure in Docker Compose with health checks and loopback-only ports.
8. Prove conformance with a black-box script that every backend must pass.

## 2. Scope
**In scope:** `openapi.yaml`, `db/schema.sql`, `db/seed.sql`, `keycloak/realm-tasksteams.json`, `docker-compose.yml`, `.env.example`, `scripts/conformance.py`, the four chapters and the TDD.
**Out of scope:** any backend or client code, production hosting, e-mail and password reset, multi-realm tenancy, file attachments, notifications, search beyond a title filter. Authentik appears only as an appendix mapping in the backend capstones.
**Assumptions:** one Keycloak realm, one Postgres database, one API at a time on port 8000, learners on Windows, macOS or Linux with Docker.
**Constraints:** all passwords in the repository are fake and local; ports follow section 11; verification is a smoke test and Docker is temporary and cleaned up.

## 3. Requirements
| Id | Requirement | Priority | Acceptance check | Phase |
|----|-------------|----------|------------------|-------|
| R-01 | The API is described by a valid OpenAPI 3.1 file covering every endpoint and schema | Must | `python scripts/check_openapi.py` prints `OpenAPI 3.1.1 valid: 27 operations, 33 schemas` | 1 |
| R-02 | `GET /health` answers 200 without a token and reports the database state | Must | conformance check `health` | 4 |
| R-03 | `GET /v1/me` returns the caller, roles, scopes and teams; the user row is created on first use | Must | check `me` | 4 |
| R-04 | Teams: list, create (admin), read, update, delete (admin); memberships with roles `lead` and `member` | Must | checks `create team`, `cleanup` | 4 |
| R-05 | Projects belong to a team; keys are unique per team | Must | check `create project` | 4 |
| R-06 | Tasks have title, description, status, priority, assignee, due date; they can be completed and reassigned | Must | checks `create task`, `update with If-Match` | 4 |
| R-07 | Comments on tasks (list, create, delete by author, lead or admin) | Must | listed in the OpenAPI file; backend capstone tests | 1 |
| R-08 | Every write to teams, members, projects, tasks and comments is recorded in the audit trail; admins can read it | Must | check `audit log` | 2, 4 |
| R-09 | All errors are RFC 9457 problem details (`application/problem+json`) | Must | checks `problem details shape`, `401 without token` | 4 |
| R-10 | Lists use opaque cursor pagination (`limit`, `cursor`, `page.nextCursor`) | Must | check `cursor pagination` | 4 |
| R-11 | Task lists filter by status, priority, assignee, due date range and title text, and sort | Should | OpenAPI parameters; backend capstone tests | 1 |
| R-12 | Teams, projects and tasks use strong ETags and `If-Match`: 412 when stale, 428 when missing; `If-None-Match` gives 304 | Must | checks `get task with ETag`, `stale If-Match` | 4 |
| R-13 | Creates accept `Idempotency-Key`; a replay returns the first response with `Idempotent-Replayed: true` | Must | check `create task with Idempotency-Key` | 4 |
| R-14 | Responses carry `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`; excess requests get 429 with `Retry-After` | Should | check `me` (headers) | 4 |
| R-15 | The API is versioned with the `/v1` path prefix | Must | every path in the OpenAPI file | 1 |
| R-16 | The schema enforces constraints, foreign keys, indexes and `updated_at`/`version` triggers | Must | `try_procedures.sql` smoke run | 2 |
| R-17 | At least two stored functions (`complete_task`, `reassign_task`) change data atomically with row locking and a version check | Must | `try_procedures.sql` output | 2 |
| R-18 | Seed users match the Keycloak users (same ids) | Must | check `token for alice` (`sub`) | 2, 3 |
| R-19 | The Keycloak realm is imported from a file: clients `tasks-web`, `tasks-mobile`, `tasks-api`, `tasks-smoke`, roles, test users, PKCE S256, brute-force protection, token lifetimes | Must | check `keycloak discovery`, `token for alice` | 3 |
| R-20 | Backends validate bearer tokens (signature, `iss`, `aud`, `exp`) and require scope and role | Must | checks `401 without token`, `403 for member on admin route` | 4 |
| R-21 | Compose starts Postgres and Keycloak with health checks; ports bind to 127.0.0.1 | Must | `docker compose up -d --wait` | 2, 3 |
| R-22 | A standard-library conformance script runs ordered checks and has an `--infra-only` mode | Must | `python scripts/conformance.py --infra-only` | 3, 4 |
| R-23 | Backends use the limited role `tasks_app`, which cannot change the schema or the audit log | Should | `permission denied for table audit_log` | 2 |
| R-24 | Each chapter has a runnable pack, a `verify.json` and a lesson text that matches the code | Must | `python scripts/verify_labs.py capstones/platform` | 1-4 |

| Non-functional requirement | Target |
|----------------------------|--------|
| Infrastructure start (`up --wait`, images cached) | under 60 seconds on a 2020s laptop; the author run took 21 seconds |
| API response time (backend capstones) | p95 under 200 ms for list and read on the seed data, measured locally with 25 requests |
| Token lifetime | access token 5 minutes, SSO idle 30 minutes, SSO maximum 10 hours |
| Brute force | 5 failures, then wait 60 seconds growing to 15 minutes |
| Accessibility and i18n | not applicable to the contract; the client capstones own them. Text is UTF-8, timestamps are UTC ISO 8601 |
| Portability | Windows, macOS and Linux with Docker; scripts avoid shell-specific syntax |

## 4. Architecture
Context (C4 level 1):

```mermaid
C4Context
    title Tasks and Teams platform: system context
    Person(user, "Team member or admin", "Plans work in teams")
    System(platform, "Tasks and Teams platform", "Web and mobile clients, a backend API, a database")
    System_Ext(kc, "Keycloak", "Signs users in and issues tokens")
    Rel(user, platform, "Uses", "HTTPS")
    Rel(platform, kc, "Redirects to sign in, validates tokens with its keys", "OIDC")
```

Containers (C4 level 2). Exactly one web client and one backend run at a time; the table below the diagram lists the alternatives.

```mermaid
C4Container
    title Tasks and Teams platform: containers
    Person(user, "User", "Member or admin")
    System_Boundary(sys, "Tasks and Teams platform") {
        Container(web, "Web client", "Angular on 4200 or React on 5173", "Single-page app, PKCE")
        Container(mobile, "Mobile client", "Flutter or Kotlin", "Phone app, PKCE")
        Container(api, "Backend API", "Python, ASP.NET, Go or Rust on 8000", "Implements openapi.yaml")
        ContainerDb(db, "Database", "PostgreSQL 17 on 5432", "Tables, triggers, stored functions")
        Container(kc, "Keycloak", "Keycloak 26.8.2 on 8180", "Realm tasksteams")
    }
    Rel(user, web, "Uses")
    Rel(user, mobile, "Uses")
    Rel(web, kc, "Sign in", "OIDC code + PKCE")
    Rel(mobile, kc, "Sign in", "OIDC code + PKCE")
    Rel(web, api, "Calls", "JSON over HTTP, bearer token")
    Rel(mobile, api, "Calls", "JSON over HTTP, bearer token")
    Rel(api, db, "Reads and writes", "SQL as tasks_app")
    Rel(api, kc, "Fetches signing keys", "HTTP, JWKS")
```

| Component | Responsibility |
|-----------|----------------|
| `openapi.yaml` | The single description of paths, DTOs, errors and security. Clients are generated from it; backends are checked against it |
| Postgres | Source of truth. Constraints, `version` and `updated_at` triggers, the audit trigger and the functions `create_team`, `complete_task`, `reassign_task` |
| Keycloak | Users, passwords, roles, scopes, tokens. Backends never see a password |
| Backend | Validates tokens, authorizes by role, scope and team membership, maps requests to SQL, maps errors to problem details |
| Clients | Sign in with PKCE, call the API with the bearer token, show the data |

Decisions (ADR style):

| Decision | Alternatives | Consequences |
|----------|--------------|--------------|
| Contract first, one `openapi.yaml` | Code first; a file per resource | One truth for four backends; the file is long, so components are shared by `$ref` |
| OpenAPI 3.1.1 | 3.0.4, 3.2.1 | Full JSON Schema 2020-12 (`type: [string, 'null']`); generators for all four client stacks read 3.1 |
| Keep atomic rules in Postgres functions | All logic in each backend | The rule exists once; four backends only call it. Harder to unit test; changes need a migration |
| `text` plus `CHECK` instead of `enum` types | Postgres `enum` | Changing the allowed values is a plain migration; every ORM maps text |
| Strong ETag = quoted `version` | Hash of the body; `updated_at` | No hashing; the trigger guarantees monotonic versions |
| Cursor (keyset) pagination | Offset and limit | Stable under inserts and fast on the `(created_at, id)` indexes; no random page jump |
| Path versioning `/v1` | Header or media-type versioning | Visible in logs and easy to route; a breaking change means a parallel `/v2` |
| Local JWT validation with cached JWKS | Introspection call per request | No network hop per request; revocation takes up to the 5 minute token life |
| Keycloak realm file in Git | Click-ops in the console | Repeatable and reviewable; imported only once (change with the admin API in real systems) |
| Password grant only in `tasks-smoke` | Browser automation in the script | A script cannot type into a login page; the grant is deprecated for apps and limited to fake users |
| `users.id` equals the Keycloak `sub` | Own surrogate id | No lookup table; the seed must use the realm's user ids |

## 5. Domain and data model
```mermaid
erDiagram
    USERS ||--o{ TEAM_MEMBERS : "belongs to"
    TEAMS ||--o{ TEAM_MEMBERS : has
    TEAMS ||--o{ PROJECTS : owns
    PROJECTS ||--o{ TASKS : contains
    USERS |o--o{ TASKS : "assigned to"
    TASKS ||--o{ COMMENTS : has
    USERS ||--o{ COMMENTS : writes
```
`audit_log` and `idempotency_keys` have no foreign keys by design (an audit entry must outlive the row it describes).

| Table | Columns (type, constraints) | Indexes |
|-------|-----------------------------|---------|
| `users` | `id` uuid PK (Keycloak `sub`); `username` text, 1-100 chars; `email` text contains `@`; `display_name` text 1-120; `created_at`, `updated_at` timestamptz default now | unique `lower(username)`, unique `lower(email)` |
| `teams` | `id` uuid PK default `gen_random_uuid()`; `name` text 1-80; `description` text default '' max 500; `created_by` uuid FK users; `version` int default 1; `created_at`, `updated_at` | unique `lower(name)`; `(created_at DESC, id DESC)` |
| `team_members` | PK `(team_id, user_id)`; `team_id` FK teams cascade; `user_id` FK users cascade; `role` text in (`lead`, `member`) default `member`; `joined_at` | `(user_id)` |
| `projects` | `id` uuid PK; `team_id` FK teams cascade; `key` text matches `^[A-Z][A-Z0-9]{1,9}$`; `name` 1-120; `description` max 2000; `archived` bool default false; `created_by` FK; `version`; timestamps; UNIQUE `(team_id, key)` | `(team_id, created_at DESC, id DESC)` |
| `tasks` | `id` uuid PK; `project_id` FK projects cascade; `title` 1-200; `description` max 10000; `status` in (`todo`, `in_progress`, `blocked`, `done`, `cancelled`) default `todo`; `priority` in (`low`, `medium`, `high`, `urgent`) default `medium`; `assignee_id` FK users on delete set null; `due_date` date; `completed_at` timestamptz; `created_by` FK; `version`; timestamps; CHECK `(status = 'done') = (completed_at IS NOT NULL)` | `(project_id, created_at DESC, id DESC)`; `(project_id, status)`; partial `(project_id, due_date, id)` where due date not null; partial `(assignee_id)`; GIN trigram on `title` |
| `comments` | `id` uuid PK; `task_id` FK tasks cascade; `author_id` FK users; `body` 1-2000; `created_at` | `(task_id, created_at, id)` |
| `audit_log` | `id` bigint identity PK; `occurred_at` timestamptz; `actor_id` uuid null; `action` in (`create`, `update`, `delete`); `entity_type` in (`team`, `member`, `project`, `task`, `comment`); `entity_id` uuid; `details` jsonb | `(occurred_at DESC, id DESC)`; `(entity_type, entity_id)`; partial `(actor_id)` |
| `idempotency_keys` | PK `(user_id, key)`; `key` text 8-128; `request_hash` text; `status_code` int; `response_body` jsonb; `created_at`; `expires_at` default now + 24 hours | `(expires_at)` |

Triggers: `bump_version` (teams, projects, tasks; only on a real change), `set_updated_at` (users, teams, projects, tasks), `sync_completed_at` (tasks), `audit_row_change` (teams, team_members, projects, tasks, comments; actor from `app.current_user_id`). Functions: `create_team`, `complete_task`, `reassign_task`, `purge_expired_idempotency_keys`. Custom SQLSTATE codes: `TS404` not found, `TS409` rule violated, `TS412` stale version, `TS422` invalid input; the API maps them to 404, 409, 412 and 422, and `23505` (unique violation) to 409.

**Migration strategy.** `db/schema.sql` is the baseline (version 0001). Each backend capstone adopts it with its own tool (Alembic, EF Core migrations, golang-migrate, SQLx migrate) and adds later changes as numbered migrations; the baseline is never edited after a backend ships. In this capstone Compose runs it once on an empty data volume.
**Seed data** (`db/seed.sql`): users alice (admin), bob and carol (members); teams Platform Team (alice lead) and Mobile Team (carol lead); projects PLAT, DOCS, MOB; 8 tasks in all statuses but `cancelled`; 3 comments. 21 audit rows are written by the seed itself.

## 6. API design
Machine-readable: [openapi.yaml](source/phase-4-conformance/04-conformance-script/code/openapi.yaml). Base URL `http://localhost:8000`. Access values: `public`; `auth` (any signed-in user); `member` (team member or admin); `lead` (team lead or admin); `admin` (realm role admin). Every operation also needs its scope: `tasks:read` for GET, `tasks:write` for changes, `tasks:admin` for the admin-only deletes and the audit log.

| Resource | Method and path | Access | Request DTO | Response DTO | Success | Errors |
|----------|-----------------|--------|-------------|--------------|---------|--------|
| Health | `GET /health` | public | none | `Health` | 200 | 503 |
| Me | `GET /v1/me` | auth | none | `Me` | 200 | 401, 429 |
| Users | `GET /v1/users?q&limit&cursor` | auth | none | `UserPage` | 200 | 400, 401 |
| Teams | `GET /v1/teams?q&sort&limit&cursor` | auth | none | `TeamPage` | 200 | 400, 401 |
| Teams | `POST /v1/teams` | admin | `TeamCreate` | `Team` + `Location`, `ETag` | 201 | 400, 401, 403, 409, 422 |
| Teams | `GET /v1/teams/{teamId}` | member | none | `Team` + `ETag` | 200 | 401, 403, 404 |
| Teams | `PATCH /v1/teams/{teamId}` | lead | `TeamUpdate` + `If-Match` | `Team` | 200 | 400, 401, 403, 404, 409, 412, 422, 428 |
| Teams | `DELETE /v1/teams/{teamId}` | admin | none | none | 204 | 401, 403, 404 |
| Members | `GET /v1/teams/{teamId}/members` | member | none | `MemberPage` | 200 | 400, 401, 403, 404 |
| Members | `PUT /v1/teams/{teamId}/members/{userId}` | lead | `MemberPut` | `Member` | 200 or 201 | 400, 401, 403, 404, 422 |
| Members | `DELETE /v1/teams/{teamId}/members/{userId}` | lead | none | none | 204 | 401, 403, 404, 409 (last lead) |
| Projects | `GET /v1/teams/{teamId}/projects?archived&sort` | member | none | `ProjectPage` | 200 | 400, 401, 403, 404 |
| Projects | `POST /v1/teams/{teamId}/projects` | lead | `ProjectCreate` | `Project` | 201 | 400, 401, 403, 404, 409, 422 |
| Projects | `GET /v1/projects/{projectId}` | member | none | `Project` + `ETag` | 200 | 401, 403, 404 |
| Projects | `PATCH /v1/projects/{projectId}` | lead | `ProjectUpdate` + `If-Match` | `Project` | 200 | 400, 401, 403, 404, 412, 422, 428 |
| Projects | `DELETE /v1/projects/{projectId}` | lead | none | none | 204 | 401, 403, 404 |
| Tasks | `GET /v1/projects/{projectId}/tasks?status&priority&assigneeId&dueBefore&dueAfter&q&sort` | member | none | `TaskPage` | 200 | 400, 401, 403, 404 |
| Tasks | `POST /v1/projects/{projectId}/tasks` | member | `TaskCreate` | `Task` | 201 | 400, 401, 403, 404, 409, 422 |
| Tasks | `GET /v1/tasks/{taskId}` | member | `If-None-Match` | `Task` + `ETag` | 200, 304 | 401, 403, 404 |
| Tasks | `PATCH /v1/tasks/{taskId}` | member | `TaskUpdate` + `If-Match` | `Task` | 200 | 400, 401, 403, 404, 412, 422, 428 |
| Tasks | `DELETE /v1/tasks/{taskId}` | lead | optional `If-Match` | none | 204 | 401, 403, 404, 412 |
| Tasks | `POST /v1/tasks/{taskId}/complete` | member | `If-Match` | `Task` | 200 | 401, 403, 404, 409, 412, 428 |
| Tasks | `POST /v1/tasks/{taskId}/reassign` | lead | `ReassignRequest` + `If-Match` | `Task` | 200 | 400, 401, 403, 404, 409, 412, 422, 428 |
| Comments | `GET /v1/tasks/{taskId}/comments` | member | none | `CommentPage` | 200 | 400, 401, 403, 404 |
| Comments | `POST /v1/tasks/{taskId}/comments` | member | `CommentCreate` | `Comment` | 201 | 400, 401, 403, 404, 409, 422 |
| Comments | `DELETE /v1/comments/{commentId}` | author, lead or admin | none | none | 204 | 401, 403, 404 |
| Audit | `GET /v1/audit-log?entityType&entityId&actorId&from&to` | admin | none | `AuditPage` | 200 | 400, 401, 403 |

Visibility rule: a user who is not a member of a team gets **404** (not 403) for that team's objects, so ids cannot be probed; 403 is for known resources the caller may not change.

**Problem details (RFC 9457).** Media type `application/problem+json`. Members: `type` (URI), `title`, `status`, `detail`, `instance` (request path), extensions `traceId` and optional `code`; validation problems add `errors[]` with `pointer` (JSON Pointer) and `detail`.

| `type` (under `https://code101.example/problems/`) | Status | When |
|------|--------|------|
| `bad-request` | 400 | malformed JSON, bad query parameter, bad cursor |
| `unauthorized` | 401 | no, expired or invalid token; `WWW-Authenticate: Bearer` |
| `forbidden` | 403 | role, scope or team permission missing |
| `not-found` | 404 | unknown id, or not visible to the caller |
| `conflict` | 409 | duplicate name or key, rule violated (cancelled task, last lead), idempotency key in progress |
| `precondition-failed` | 412 | `If-Match` does not match the current version |
| `validation-error` | 422 | field invalid (`errors[]`), idempotency key reused with another body |
| `precondition-required` | 428 | `If-Match` missing |
| `rate-limited` | 429 | too many requests; `Retry-After` set |
| `internal-error` | 500 | unexpected failure; the detail never leaks internals |

**Pagination.** `limit` 1 to 100 (default 25). The response is `{ "items": [...], "page": { "limit": n, "nextCursor": "..." | null } }`. The cursor is an opaque base64url string that encodes the sort values and the id of the last item (keyset); clients never build or parse it. A bad cursor is a 400. Default order `-createdAt`; `createdAt` ascending and, for tasks, `dueDate` (nulls last) are also allowed. Ties break on `id`.
**Filtering.** Repeatable `status` and `priority`; `assigneeId`; `dueBefore` and `dueAfter` (dates, inclusive); `q` (case-insensitive substring of the title); lists of teams and users accept `q` as a prefix.
**Concurrency.** `ETag` is the quoted `version` (`"3"`). `PATCH`, `complete` and `reassign` require `If-Match` (428 if absent, 412 if stale); task `DELETE` accepts it; `If-None-Match` on a task `GET` gives 304. `PATCH` is JSON Merge Patch (RFC 7396): absent fields stay, `null` clears `assigneeId` and `dueDate`.
**Idempotency.** `Idempotency-Key` (8 to 128 characters, usually a UUID) on `POST` creates. Scope: caller plus key, kept 24 hours in `idempotency_keys`. Same key and body: replay of the stored status and body with `Idempotent-Replayed: true`. Same key, different body: 422. First request still running: 409.
**Rate limits.** 100 requests per 60 seconds per user (per client address when anonymous: 30). Headers `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (seconds) on every response, plus `Retry-After` on 429. The IETF draft is moving to structured `RateLimit` and `RateLimit-Policy` fields; this contract uses the widely deployed three-header form until the draft is final.
**Versioning.** `/v1` in the path. Additive changes (new optional fields, new endpoints) stay in v1; removing or changing a field starts `/v2`, with `Deprecation` and `Sunset` headers on v1 for at least 6 months.

## 7. Identity and security design
Keycloak realm `tasksteams` at `http://localhost:8180`. Issuer: `http://localhost:8180/realms/tasksteams`. Test users (fake passwords): alice (role `admin`, password `alice-local-fake`), bob (`member`, `bob-local-fake`), carol (`member`, `carol-local-fake`).

Sign-in from the browser (web clients `tasks-web`):

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant W as Web app on 4200 or 5173
    participant K as Keycloak
    participant A as Backend API on 8000
    W->>W: random code_verifier, code_challenge = S256 of it, state
    W->>K: redirect to /auth with client_id tasks-web, redirect_uri, scope, state, code_challenge
    K->>U: login page, password check, brute-force protection
    U->>K: username and password
    K->>W: redirect to redirect_uri with code and state
    W->>W: compare state
    W->>K: POST /token with code, code_verifier, client_id
    K->>W: access token 5 min, refresh token with rotation
    W->>A: API calls with Authorization Bearer
    A->>K: GET JWKS once, then cached
    A->>A: verify signature, iss, aud, exp, scope and role
    A->>W: 200 or problem details
```

Sign-in from a phone (`tasks-mobile`, the same code flow in the system browser):

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant M as Mobile app
    participant B as System browser tab
    participant K as Keycloak
    participant A as Backend API
    M->>M: code_verifier, code_challenge S256, state
    M->>B: open /auth with client_id tasks-mobile and redirect_uri com.code101.tasks:/oauth2redirect
    B->>K: GET /auth
    U->>K: username and password in the browser, never in the app
    K->>B: redirect to com.code101.tasks:/oauth2redirect with code
    B->>M: the OS hands the URL to the app
    M->>K: POST /token with code and code_verifier
    K->>M: tokens, stored in Keychain or Keystore
    M->>A: API calls with Authorization Bearer
```

Bearer token validation in the API (every backend implements the same steps):

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant A as Backend API
    participant K as Keycloak JWKS
    C->>A: request with Authorization Bearer token
    A->>A: no header or not Bearer then 401
    A->>K: key by kid, only when not cached
    A->>A: signature RS256, iss, aud contains tasks-api, exp and nbf with 30 s skew
    A->>A: required scope present, else 403
    A->>A: role from realm_access.roles and team membership, else 403 or 404
    A->>C: handler runs, user id is sub
```

| Role | Meaning |
|------|---------|
| `admin` | all operations on every team; create and delete teams; read the audit log |
| `member` | only teams where the user has a membership; inside a team the team role applies (`lead` manages members, projects and reassignment) |

| Scope | Granted to | Allows |
|-------|-----------|--------|
| `tasks:read` | web, mobile (default), smoke | every GET |
| `tasks:write` | web, mobile (default), smoke | POST, PUT, PATCH, DELETE except admin-only |
| `tasks:admin` | web, mobile (optional, requested on demand), smoke | `DELETE /v1/teams/{id}`, `GET /v1/audit-log` |

Effective permission is the **intersection** of scope and role: bob holding `tasks:admin` is still refused (check `403 for member on admin route`).

Token rules: accept only `RS256`; reject `alg: none`; `iss` must equal the configured issuer exactly; `aud` is a string or a list and must contain `tasks-api`; allow 30 seconds of clock skew; cache the JWKS and refetch on an unknown `kid`; never log tokens. Secrets: `.env` is ignored by Git, `.env.example` holds fake values, production values come from a secret store. CORS: allow only `http://localhost:4200` and `http://localhost:5173`, methods GET, POST, PUT, PATCH, DELETE, headers `Authorization`, `Content-Type`, `If-Match`, `If-None-Match`, `Idempotency-Key`; expose `ETag`, `Location`, `RateLimit-*`, `Retry-After`, `Idempotent-Replayed`. Data protection: TLS terminates in front of the API in production; Postgres is bound to loopback; the `tasks_app` role cannot alter the schema or the audit log; request bodies are validated against the OpenAPI limits; no personal data in logs beyond the user id.

OWASP API Security Top 10 (2023) mapping:

| Risk | Mitigation in this platform |
|------|------------------------------|
| API1 Broken object level authorization | Every object read or write checks team membership; non-members get 404; ids are UUIDs |
| API2 Broken authentication | Keycloak with PKCE, brute-force protection, 5 minute tokens, refresh rotation; APIs verify signature, `iss`, `aud`, `exp` |
| API3 Broken object property level authorization | DTOs list the writable fields (`additionalProperties: false`); `id`, `version`, timestamps, `createdBy` are read-only; `role` only changes through `PUT members` by a lead |
| API4 Unrestricted resource consumption | `limit` maximum 100, field length limits, rate limits with 429, body size limit 1 MB |
| API5 Broken function level authorization | `x-access` per operation; admin-only routes need role and scope (test: bob gets 403) |
| API6 Unrestricted access to sensitive business flows | `Idempotency-Key` stops duplicate creates; team creation is admin-only |
| API7 Server-side request forgery | The API makes no outgoing calls except the JWKS fetch from a configured URL; no user-supplied URLs |
| API8 Security misconfiguration | Pinned images, loopback ports, no wildcard CORS, redirect URIs exact, problem details without stack traces, `sslRequired` and `start-dev` documented as development only |
| API9 Improper inventory management | One OpenAPI file with a `/v1` prefix; `Deprecation` and `Sunset` headers; the checker counts operations |
| API10 Unsafe consumption of APIs | Tokens and keys come only from the configured Keycloak issuer; JSON is validated before use |

Threat model summary. **Assets:** user identities and tokens, task data, the audit trail. **Entry points:** the API port 8000, Keycloak 8180, the database 5432 (loopback only), the realm file and `.env`, the clients' token storage. **Top threats and answers:** stolen authorization code (PKCE S256, exact redirect URIs, 60 second code life); token theft (short life, refresh rotation, mobile Keychain or Keystore, no tokens in `localStorage` for production web apps: keep them in memory); privilege escalation (role and scope intersection, DB constraints); lost update (ETag and row locks); replay of creates (idempotency keys); audit tampering (no UPDATE or DELETE right for `tasks_app`); credential stuffing (brute-force protection, rate limiting); SQL injection (parameterised queries only, stored functions with typed arguments).

## 8. Project structure
```text
capstones/platform/
  README.md  TDD.md
  tutorials/phase-N-slug/NN-slug.md          four chapters
  source/phase-N-slug/PACK-README.md
  source/phase-N-slug/NN-slug/{code, exercise/{starter,solution}, verify.json}
  source/phase-4-conformance/04-conformance-script/code/    the finished platform
    openapi.yaml  requirements.txt  docker-compose.yml  .env.example
    db/{schema.sql, seed.sql, try_procedures.sql}
    keycloak/realm-tasksteams.json
    scripts/{check_openapi.py, conformance.py}
```
Each phase pack holds the whole project at that point. Backend and client capstones copy the final folder's contract files into their own repository folder (`contract/`) or reference them by relative path, and never edit them: a change to the contract is a change to this capstone. Naming: JSON members `camelCase`, database columns `snake_case`, URLs plural `kebab` nouns, enums lowercase with underscores. Layering for backends is defined in each backend TDD (HTTP layer, application layer, data layer; dependencies point inwards).

| Variable | Default | Used by |
|----------|---------|---------|
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | `tasksteams`, `tasks_admin`, `tasks_admin_local_only` | Compose, administration |
| `POSTGRES_PORT` | `5432` | Compose, script |
| `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`, `KEYCLOAK_PORT` | `kcadmin`, `kcadmin_local_only`, `8180` | Compose |
| `TASKS_NETWORK` | `tasksteams-net` | Compose; backends join it as an external network |
| `BASE_URL`, `KEYCLOAK_URL`, `TOKEN_ISSUER`, `SMOKE_ALICE_PASSWORD`, `SMOKE_BOB_PASSWORD` | `http://127.0.0.1:8000`, `http://127.0.0.1:8180`, `http://localhost:8180/realms/tasksteams`, fake passwords | `conformance.py` |
| `DATABASE_URL` (backend) | `postgresql://tasks_app:tasks_app_local_only@127.0.0.1:5432/tasksteams`, in Docker host `db` | backends |

## 9. Delivery plan (phases)
| Phase | Title | Chapters | Requirement ids | Exit check (smoke) | Source pack |
|-------|-------|----------|-----------------|--------------------|-------------|
| 0 | Primers | 01 Git and GitHub, 02 HTTP and REST, 03 Reading an OpenAPI file, 04 OAuth 2, OIDC and Keycloak | none (background for R-01 to R-24) | none: reading plus four small labs, written but not yet run | `platform-phase-0-primers.zip` |
| 1 | Contract | 01 The OpenAPI contract | R-01, R-07, R-11, R-15 | `check_openapi.py` prints 27 operations, 33 schemas | `platform-phase-1-contract.zip` |
| 2 | Data | 02 The database and stored procedures | R-08, R-16, R-17, R-18, R-21, R-23 | Compose up healthy; `try_procedures.sql`; `permission denied` for `tasks_app` | `platform-phase-2-data.zip` |
| 3 | Identity | 03 Identity with Keycloak | R-18, R-19, R-21, R-22 | `conformance.py --infra-only` 4 passed | `platform-phase-3-identity.zip` |
| 4 | Conformance | 04 The conformance script | R-02 to R-06, R-09, R-10, R-12 to R-14, R-20, R-22, R-24 | `--infra-only` 4 passed; the 14 API checks run in each backend capstone | `platform-phase-4-conformance.zip` |

How each capstone consumes the platform:

| Capstone | Takes from the platform | Its own phases use it for |
|----------|-------------------------|---------------------------|
| `backend-python`, `backend-dotnet`, `backend-go`, `backend-rust` | the final `code` folder: schema, seed, realm, Compose, script, `openapi.yaml` | 1 Skeleton: routes from the contract and `/health`; 2 Data: functions and the `tasks_app` role, ETag, idempotency, cursors; 3 Identity: token validation with `aud` and role checks; 4 Run and ship: join `tasksteams-net`, publish 8000; 5 Hardening: the OWASP table, rate limits. Exit: `conformance.py` 18 passed |
| `web-angular`, `web-react` | `openapi.yaml` (generated client), realm client `tasks-web`, any backend on 8000 | 1 Setup and generated client; 2 PKCE sign-in; 3 Screens; 4 Errors (problem details, 412 reload, 429 retry), offline and polish |
| `mobile-flutter`, `mobile-kotlin` | `openapi.yaml`, realm client `tasks-mobile`, the ASP.NET, Python or Go backend (not Rust) | the same four client phases; the redirect scheme `com.code101.tasks:/oauth2redirect`; the Android emulator reaches the host with `adb reverse tcp:8180 tcp:8180` and `adb reverse tcp:8000 tcp:8000`, so `localhost` and the issuer stay identical |

## 10. Verification plan
Smoke only, Docker temporary. Per chapter (`python scripts/verify_labs.py capstones/platform`): 1 installs the two Python packages into a throwaway folder and validates the contract (exit 0, expected line); 2 starts Postgres under `docker compose -p {project} up -d --wait`, counts the seed rows, runs `try_procedures.sql`, shows the permission error, runs the exercise solution; 3 starts Postgres and Keycloak, runs `conformance.py --infra-only` (with retries for the slow first start), runs the exercise solution; 4 repeats the infrastructure run and `--help`. `cleanup` always runs `docker compose -p {project} down -v --remove-orphans`. The 14 API checks are not run here (no backend); every backend capstone runs them once. Conformance with this contract: a backend is conformant when `python scripts/conformance.py` prints `18 passed, 0 failed`.

## 11. Deployment and operations
| Host port | Used by | Notes |
|-----------|---------|-------|
| 5432 | Postgres (`127.0.0.1` only) | shared with the Databases track labs: one at a time |
| 8000 | Backend API (any of the four) | one backend at a time |
| 8180 | Keycloak (`127.0.0.1` only) | container port 8080; the management port 9000 is not published |
| 4200 | Angular dev server | |
| 5173 | React (Vite) dev server | |
| not used | 8080, 8081, 11434 | Docker 101 labs and Ollama |

Files: `docker-compose.yml` (services `db`, `keycloak`; network `tasksteams-net`; volume `pg_data`), `.env.example`. Logs: `docker compose -p platform logs -f keycloak`; backends log JSON lines with `traceId`. Health: `pg_isready -h 127.0.0.1` for Postgres; `/health/ready` on port 9000 for Keycloak; `GET /health` for the API. Backup (Postgres): `docker compose -p platform exec -T db pg_dump -U tasks_admin tasksteams > backup.sql`. Realm export for changes: stop Keycloak and run `kc.sh export` (see the Keycloak import and export guide); this lab keeps the realm file in Git instead.

## 12. Risks, open questions, decisions
| Risk or question | Impact | Mitigation / decision |
|------------------|--------|-----------------------|
| `start-dev` is not for production | Learners copy it | The lessons say so; production needs HTTPS, a real database and a hostname |
| The realm is imported only once | Edits to the JSON seem ignored | Lessons and Common mistakes say `down -v` |
| `aud` is a string for one audience | Backends that expect an array fail | The contract says "string or list"; the script normalises it |
| The IETF RateLimit and Idempotency-Key drafts may change | Header names could change | The contract pins the current forms and lists them as drafts |
| Android emulator cannot reach `localhost` | Sign-in fails on the issuer | Use `adb reverse`; documented in the mobile capstones |
| Fixed network name `tasksteams-net` | Two stacks collide | One platform stack at a time; documented |
| Password grant in `tasks-smoke` | Misuse in apps | Named and described as smoke-only; realm file comments say so |
| Open: Authentik appendix depth | Scope of backend chapters | Default: a mapping table per backend, no extra lessons |

### 12.1 Contract v1.1 backlog (found by the four backends on 2026-11-23, all four pass conformance 18 of 18 with these workarounds)

The backends agreed on the behaviour below; the platform files still say less. One consolidated edit (openapi.yaml, conformance.py, `.env.example`, byte-identical copies in the
backends, rebuilt zips) is planned after the client capstones have also reported defects. Until then every backend implements the **Decision** column.

| Gap in the v1 files | Decision all backends follow |
|---------------------|------------------------------|
| No 413 response, no `payload-too-large` problem type | Body over 1 MiB gives 413 `application/problem+json` (`type` ends `payload-too-large`) |
| No 405 or 415 problem types | Wrong method gives 405 with `Allow` header; wrong content type gives 415 or 400 (document which in the backend TDD) |
| No 503 on `/v1` routes | A database outage gives 503 problem+json with `Retry-After` |
| Malformed path or query values and unknown JSON fields unspecified | 400 problem+json with `errors[].pointer` |
| `If-None-Match` on teams and projects in the TDD but only on tasks in `openapi.yaml` | Tasks only until v1.1 decides; clients must not rely on it elsewhere |
| `PUT` member demoting the last lead unspecified (delete is specified) | 409 `last_lead` |
| `RateLimit-*` "on every response" includes `/health` | `/health` counts against the budget; clients ignore the headers there |
| `conformance.py` `PASSWORDS` has no `carol` | Add carol to the script (not used by any check today) |
| `.env.example` has no variable for the `tasks_app` password | Backends read it from their own `.env`; add the variable in v1.1 |
| `tasks-smoke` holds all three scopes | A 403 for a missing scope cannot be shown with a real token; the lessons use a stand-in or say so |
| Header names are case-insensitive (`Etag`, `Ratelimit-Limit` in Go) | Clients must compare header names case-insensitively |
| Replayed idempotent responses come from `jsonb` | JSON key order may differ from the first response; compare as JSON, not text |

## 13. References
- OpenAPI Specification 3.1.1: https://spec.openapis.org/oas/v3.1.1.html (versions: https://spec.openapis.org/oas/)
- RFC 9457 Problem Details for HTTP APIs: https://www.rfc-editor.org/info/rfc9457
- RFC 7396 JSON Merge Patch: https://www.rfc-editor.org/info/rfc7396
- RFC 9110 HTTP Semantics (ETag, If-Match, 412, 304) and RFC 6585 (428, 429): https://www.rfc-editor.org/info/rfc9110, https://www.rfc-editor.org/info/rfc6585
- RFC 7636 PKCE, RFC 8252 OAuth for native apps, RFC 9700 OAuth 2.0 Security BCP: https://www.rfc-editor.org/info/rfc7636, https://www.rfc-editor.org/info/rfc8252, https://www.rfc-editor.org/info/rfc9700
- RFC 9068 JWT profile for access tokens and RFC 8725 JWT best practices: https://www.rfc-editor.org/info/rfc9068, https://www.rfc-editor.org/info/rfc8725
- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0.html
- Keycloak documentation (hostname, containers, import and export, securing applications): https://www.keycloak.org/documentation, https://www.keycloak.org/server/hostname, https://www.keycloak.org/server/importExport
- IETF drafts: RateLimit header fields https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/ and Idempotency-Key https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/
- OWASP API Security Top 10 2023: https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- PostgreSQL 17 documentation (privileges, triggers, PL/pgSQL): https://www.postgresql.org/docs/17/
- Docker Hub `postgres` and quay.io `keycloak/keycloak` tags, checked 2026-11-23.
