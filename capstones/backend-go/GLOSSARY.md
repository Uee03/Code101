# Glossary: Backend Go capstone

| Term | Meaning |
|------|---------|
| API | The set of URLs and rules a program offers to other programs |
| audit trail | A table that records who changed which row and when; here written by a database trigger |
| bearer token | A credential sent in the `Authorization: Bearer ...` header; whoever holds it is trusted |
| body limit | The largest request body the server accepts; here 1 MiB |
| build context | The files `docker build` sends to Docker; `.dockerignore` removes entries |
| capability (Linux) | One privilege of the root user, such as binding low ports; containers can drop them all |
| claim | One statement inside a token, for example `sub` (who) or `exp` (expiry) |
| clock skew | The difference between two computers' clocks; tokens are accepted with 30 seconds of it |
| connection pool | A set of open database connections shared by requests |
| context (Go) | A value passed down calls that carries request-scoped data and cancellation |
| CORS | The browser rule that decides which web pages may read answers of another origin |
| cursor | An opaque text that marks where the previous page ended |
| distroless | A minimal runtime image with no shell and no package manager |
| DTO | Data transfer object: the exact shape of a request or response body |
| ETag | A validator header, here the quoted version of a resource, for example `"3"` |
| fixed window | A rate-limit counter that restarts at the end of each time window |
| generics | Go functions and types with a type parameter, for example `collect[T any]` |
| graceful shutdown | Stop accepting new work and finish what is running before exiting |
| healthcheck | A command the container engine runs to learn whether the service works |
| idempotency key | A client-chosen value that makes a repeated `POST` return the first answer |
| If-Match | A request header that makes a change conditional on the current ETag |
| introspection | Asking the identity provider whether a token is still valid |
| JSON Merge Patch | A way to change a resource by sending only the changed fields; `null` clears a field |
| JSON Pointer | A path such as `/name` to a place inside a JSON document |
| JWKS | A JSON Web Key Set: the public keys that verify token signatures |
| JWT | A signed token made of header, payload and signature |
| keyset pagination | Paging by "rows after this sort value and id" instead of offsets |
| middleware | A function that wraps a handler and runs before or after it |
| module (Go) | A tree of packages with a `go.mod` file |
| multi-stage build | A Dockerfile with several `FROM` stages; only the last one is shipped |
| optimistic concurrency | Let everyone work, detect a conflict at write time (a stale version) |
| principal | The authenticated caller of a request |
| problem details | The RFC 9457 error document `application/problem+json` |
| rate limit | A cap on requests per time window per user or address |
| redaction | Replacing a secret in output, for example a password in a URL, with a placeholder |
| role | What a person may do (`admin`, `member`); comes from the identity provider |
| scope | What a client application may do for a person (`tasks:read`, `tasks:write`, `tasks:admin`) |
| SQLSTATE | A five-character error code of PostgreSQL; the schema defines `TS404`, `TS409`, `TS412`, `TS422` |
| static binary | A program file that needs no shared libraries |
| stored function | A function inside the database, called with `SELECT * FROM name(...)` |
| trace id | An id that ties a client's error, a response header and a log line together |
| transaction | A group of database changes that succeed or fail together |
