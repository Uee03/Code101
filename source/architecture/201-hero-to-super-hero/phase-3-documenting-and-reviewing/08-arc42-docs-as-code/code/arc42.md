# arc42 summary: Tasks and Teams platform

Source of every statement: capstones/platform/TDD.md. Sections that later lessons complete say so.

## 1. Introduction and goals
Tasks and Teams is a shared contract for a task-planning product: one API description, one database schema, one identity realm. Four backends and four clients implement or consume it. Top goals: interchangeable backends, correct access control, safe concurrent edits.

## 2. Architecture constraints
- One OpenAPI 3.1 file describes the API, versioned with the /v1 path prefix.
- PostgreSQL is the source of truth and Keycloak issues the tokens.
- The local stack publishes its ports on 127.0.0.1 only.

## 3. Context and scope
People use web and mobile clients. Clients call one backend API and sign in at Keycloak. See diagrams/context.mmd and diagrams/containers.mmd.

## 4. Solution strategy
- Contract first: clients and backends are checked against the same file.
- Atomic business rules live in Postgres functions, so four backends share one implementation.
- Strong ETags from a version column, cursor pagination and idempotency keys keep clients safe.

## 5. Building block view
Web client, mobile client, backend API, PostgreSQL and Keycloak. The backend has an HTTP layer, an application layer and a data layer; diagrams/components-backend.mmd shows them.

## 6. Runtime view
Sign-in with PKCE, token validation and an idempotent create. See diagrams/signin-pkce.mmd and the sequences in the architecture lessons.

## 7. Deployment view
The local stack runs Postgres and Keycloak in Docker Compose and the backend and web client as host processes. See diagrams/deployment.drawio.

## 8. Crosscutting concepts
- Errors are RFC 9457 problem details.
- Every write to teams, members, projects, tasks and comments is recorded in an audit trail by database triggers.
- Responses carry rate-limit headers; timestamps are UTC ISO 8601.

## 9. Architecture decisions
See adr/0001-keep-rest.md and adr/0002-local-token-validation.md. The TDD section 4 table lists more decisions that can become ADRs.

## 10. Quality requirements
TODO: quality scenarios, written in lesson 09 as quality/scenarios.md.

## 11. Risks and technical debt
TODO: risk register, written in lesson 09 as quality/risks.md.

## 12. Glossary
ETag: a version marker for one record. Idempotency key: a client-chosen value that makes a repeated create safe. Scope: what a token may be used for. Team: the unit that owns projects and tasks.
