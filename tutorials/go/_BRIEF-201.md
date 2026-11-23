# Go track brief - 201 Hero to Super Hero

## Learners and outcome
Developers who finished Go 101 (`101-zero-to-hero/`) and have written some Go for one or two years. Voice: assume 101, explain the why, a "Why this, not that" table in every lesson, Mermaid diagrams for structure, security by default in every example. Outcome: the learner can design small interfaces, write correct concurrent code, build a tested JSON HTTP service on the standard library, store data in Postgres with pgx, validate bearer tokens, and ship the service in a small non-root container. Not repeated here: the full production API, which is the capstone `capstones/backend-go` (Keycloak, idempotency, hardening, conformance); every lesson links to the matching chapter instead of duplicating it.

## Plan (10 lessons, four packs)
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 Core skills | 01 Interfaces, embedding and small interfaces | `Sender` seam, embedding wrapper, typed-nil trap / `io.Writer` decorators |
| 1 | 02 Goroutines and channels | worker pool, pipeline, buffered channels, `select` / order-preserving parallel squares, timeout |
| 1 | 03 sync, context and cancellation | mutex counter, timeouts, stoppable ticker / `RWMutex` cache, context-aware wait |
| 1 | 04 Generics | `Map`, `Filter`, `Reduce`, `Stack[T]`, `Set[T]`, constraints / `SortedKeys`, `GroupBy` |
| 2 HTTP and JSON | 05 net/http server | Go 1.22 `ServeMux` patterns, handlers, middleware chain, server timeouts / test-driven `/hello` service with a `nosniff` middleware |
| 2 | 06 JSON DTOs, validation and problem+json | request/response DTOs, strict decoding, 400 vs 422, RFC 9457 / sign-up validation and strict decode (library, tests) |
| 2 | 07 Configuration, slog and graceful shutdown | env config with injected `getenv`, `log/slog`, `NotifyContext` + `Shutdown` / settings loader and a quiet logger |
| 3 Data and security | 08 Postgres with pgx | Compose + `.env.example`, init SQL, `pgxpool`, queries, transaction, stored function, SQLSTATE mapping / `app.withdraw` (overlay files) |
| 3 | 09 Authentication middleware (JWT basics) | HS256 verify with pinned alg, expiry, iss, aud; bearer middleware; roles / `RequireAnyRole`, `RequireSelfOrRole` (overlay files) |
| 4 Quality and ship | 10 Testing and the notes API in a container | table-driven tests, `httptest`, fakes by embedding, multi-stage non-root Dockerfile, hardened Compose / slug tests, bug fix, fuzz |

## Versions and verification
Minimum Go **1.22.0** in every supplied `go.mod` (as in 101). Lessons 08 and 09 pin `github.com/jackc/pgx/v5 v5.7.2` (go 1.21) and `github.com/golang-jwt/jwt/v5 v5.3.1` (go 1.21); `go.sum` and the indirect requirements are produced by `go mod tidy` and are deliberately not shipped. Docker images: `postgres:17-alpine`, `golang:1.27.4-alpine3.24` and `gcr.io/distroless/static-debian13:nonroot` (the last two are the pins already used and verified in the Go capstone). Author toolchain on this machine: Go 1.27.4.

**Verification policy (user instruction 2026-11-23): written, not run.** No smoke tests, builds, servers or Docker were executed. Every lesson carries the draft notice under the title and `verified: not yet run`. Allowed check: `python scripts/verify_labs.py --static source/go/201-hero-to-super-hero` (lesson text must contain every code line and expected output). `verify.json` files exist so a later run can execute them; the later run sets `verified:` and removes the notice. Packs: `python scripts/build_packs.py go-201`. No art; `assets: []`.

## Sources (Tier 1)
- https://go.dev/doc/effective_go and https://google.github.io/styleguide/go/best-practices
- https://go.dev/wiki/CodeReviewComments, https://go.dev/blog/loopvar-preview, https://go.dev/blog/when-generics, https://go.dev/doc/tutorial/generics
- https://go.dev/blog/pipelines, https://go.dev/blog/context, https://go.dev/ref/mem, https://go.dev/doc/articles/race_detector
- https://go.dev/blog/routing-enhancements, https://pkg.go.dev/net/http, https://pkg.go.dev/net/http/httptest, https://go.dev/blog/slog, https://pkg.go.dev/log/slog
- https://www.rfc-editor.org/rfc/rfc9457, https://owasp.org/API-Security/ (API1, API2, API3 of 2023), https://12factor.net/config
- https://pkg.go.dev/github.com/jackc/pgx/v5 and /pgxpool, https://www.postgresql.org/docs/17/errcodes-appendix.html
- https://www.rfc-editor.org/rfc/rfc7519, https://www.rfc-editor.org/rfc/rfc8725, https://pkg.go.dev/github.com/golang-jwt/jwt/v5
- https://go.dev/wiki/TableDrivenTests, https://pkg.go.dev/testing, https://docs.docker.com/build/building/best-practices/

## Scope choices
- Standard library first (router, JSON, slog, testing); external modules only for Postgres (`pgx`) and JWT (`golang-jwt`). No router package, no ORM, no assertion or mocking library.
- Exercises are test-driven where a server would be awkward (05, 06, 07, 09, 10): the starter ships the tests and the learner makes them pass. Lessons 08 and 09 use "overlay" starters (files added to a copy of the lesson folder) because the exercise extends the lesson's code.
- Security is taught inside the code, not as a separate lesson: loopback binding, server timeouts, body limits, strict decoding, generic errors, parameterised SQL, constraint-backed rules, pinned JWT algorithms, non-root read-only containers. Identity providers (Keycloak) and RS256/JWKS are left to the capstone.
- Lesson 10 is the mini project (two sittings, break after Step 8) and doubles as the testing lesson; the store sits behind an interface so a pgx store from lesson 08 can replace the in-memory one (stretch).
- Each phase's last lesson (04, 07, 09, 10) ends with a mixed review.
