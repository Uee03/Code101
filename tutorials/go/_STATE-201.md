# Go track state - 201 Hero to Super Hero

Last updated: 2026-11-23. Written under the "no smoke tests" policy: nothing was executed (no `go build`, `go test`, `go run`, `docker`).

## 201 Hero to Super Hero

Minimum Go 1.22.0 in supplied modules. 10 lessons, four phases. Status `written (not run)` means: lesson, source pack and `verify.json` exist and pass the static text check; the code and expected outputs were derived by reading and checking official documentation, and have never been executed.

| Lesson | Phase | Time | Status |
|---|---|---|---|
| 01-interfaces-and-embedding | phase-1-core-skills | 40 min | written (not run) |
| 02-goroutines-and-channels | phase-1-core-skills | 45 min | written (not run) |
| 03-sync-context-cancellation | phase-1-core-skills | 45 min | written (not run) |
| 04-generics | phase-1-core-skills | 40 min | written (not run) |
| 05-net-http-server | phase-2-http-and-json | 50 min | written (not run) |
| 06-json-dtos-and-problems | phase-2-http-and-json | 50 min | written (not run) |
| 07-config-slog-shutdown | phase-2-http-and-json | 50 min | written (not run) |
| 08-postgres-with-pgx | phase-3-data-and-security | 60 min | written (not run) |
| 09-auth-middleware-jwt | phase-3-data-and-security | 55 min | written (not run) |
| 10-testing-and-notes-api | phase-4-quality-and-ship | 90 min, two sittings | written (not run) |

## Evidence (static only)

- `python scripts/verify_labs.py --static source/go/201-hero-to-super-hero`: 10 static-checked, 0 failed. Every non-blank line of every `code/` file (except `go.mod`, listed in `skip_lesson_check`) and every `expect_stdout` appear in the lesson text; the lesson text is generated from the source files, not retyped.
- Draft notice verbatim under each H1; front matter `verified: not yet run`.
- Manual audit (reading, no compiler): unused imports in every `.go` file, relative links and anchors in the lessons, UTF-8 without BOM, LF line endings.
- Pack build: `python scripts/build_packs.py go-201` (zips only, nothing executed).

## What the first real run must check (open risks)

Derived, not observed. Run `python scripts/verify_labs.py source/go/201-hero-to-super-hero` (needs Go 1.22+, internet for `go mod tidy`, curl, Docker with Compose v2; port 8080 and 5433 free) and compare:
- 01 to 04: the printed outputs in the lessons (especially timing-based 03: tick order and `ticker stopped`).
- 05, 06, 10: curl bodies and statuses; the 405 body text for `POST /books` is the standard status text (not verified).
- 06: `%header{location}` in curl needs curl 7.84 or newer.
- 07: `go run` prints `exit status 2` after the configuration error; duration formats in text vs JSON logs (JSON writes nanoseconds).
- 08: pgx v5.7.2 with `go mod tidy` on Go 1.22 to 1.27 (needs no go directive bump); `RowsAffected()` on a `SELECT ... FOR UPDATE` `Exec`; scanning `integer` into `int`; psql table text and Compose status text are marked "typical".
- 09: `golang-jwt` v5.3.1 option names (`WithExpirationRequired`, `WithTimeFunc`, `WithLeeway`, `WithIssuer`, `WithAudience`, `WithValidMethods`), `UnsafeAllowNoneSignatureType`; token header prefix `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`.
- 10: the image build runs `go vet` and `go test` inside the build stage; `docker inspect` user `nonroot:nonroot` and exit code 0 after `docker compose stop`.
- Error texts in "Common mistakes" are marked "typical message" unless they come from the lesson's own code or the Go runtime (`fatal error: all goroutines are asleep - deadlock!`, `panic: send on closed channel`, `fatal error: concurrent map writes`).
- `go test -race` may need a C compiler on Windows; the lessons say to run without it if refused.

## Decisions and deviations

- Exercises 08 and 09 are "overlay" starters (files added to a copy of the finished lesson folder); the pack READMEs and the level README say so. All other starters are standalone modules (`try0N`).
- Lesson 06 and 07 duplicate small pieces (`statusRecorder`, server settings) from lesson 05 on purpose, because each lesson is an independent module and every file must be shown in full. Lesson 10 repeats them once more in compact form.
- `go.sum` is not shipped (task rule); every lesson that needs it says `go mod tidy` creates it.
- Indirect requirements of `pgx` and `golang-jwt` are not listed in `go.mod`; `go mod tidy` adds them.
- `tutorials/go/201-hero-to-super-hero/README.md` holds the shared guide (working folder, exercise folders, tests), as the 101 README does.
- `CONTEXT.md` was not edited (task limited edits to `tutorials/go/` and `source/go/201-hero-to-super-hero/`); the coordinator should add one line for Go 201.

## Packs

Command: `python scripts/build_packs.py go-201`. Outputs go to `dist/packs/` (git-ignored): `go-201-phase-1-core-skills.zip`, `go-201-phase-2-http-and-json.zip`, `go-201-phase-3-data-and-security.zip`, `go-201-phase-4-quality-and-ship.zip`, `go-201-all.zip`.
