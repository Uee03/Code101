# Go 201: Hero to Super Hero

For developers who finished [Go 101](../101-zero-to-hero/phase-1-foundations/01-hello-go.md) and have written a little Go for a year or two. The level takes you from "I can write a console program" to "I can build, test and ship a small HTTP service": interfaces, concurrency, generics, `net/http`, JSON, configuration and logging, Postgres, token authentication, testing and a container image. Minimum **Go 1.22.0** (the standard-library router and per-iteration loop variables need it).

> **Status:** these lessons were written and reviewed by reading the code and the official documentation. They have not been run end to end yet (each lesson says so at the top). If your tool prints something different from a lesson, trust your tool and report it.

| Lesson | Read | Phase | You build |
|---|---|---|---|
| 01 | [Interfaces, embedding and small interfaces](phase-1-core-skills/01-interfaces-and-embedding.md) | core skills | a `Sender` seam, a wrapper by embedding, a fake in a test |
| 02 | [Goroutines and channels](phase-1-core-skills/02-goroutines-and-channels.md) | core skills | a worker pool and a pipeline |
| 03 | [sync, context and cancellation](phase-1-core-skills/03-sync-context-cancellation.md) | core skills | a safe counter, a timeout, a stoppable ticker |
| 04 | [Generics](phase-1-core-skills/04-generics.md) | core skills | `Map`, `Filter`, `Stack[T]`, `Set[T]` |
| 05 | [net/http server](phase-2-http-and-json/05-net-http-server.md) | HTTP and JSON | routes, handlers, middleware, an `http.Server` with timeouts |
| 06 | [JSON DTOs, validation and problem+json](phase-2-http-and-json/06-json-dtos-and-problems.md) | HTTP and JSON | a safe `POST` with RFC 9457 errors |
| 07 | [Configuration, slog and graceful shutdown](phase-2-http-and-json/07-config-slog-shutdown.md) | HTTP and JSON | environment config, structured logs, clean exit |
| 08 | [Postgres with pgx](phase-3-data-and-security/08-postgres-with-pgx.md) | data and security | Postgres in Compose, a pool, a transaction, a stored function |
| 09 | [Authentication middleware (JWT basics)](phase-3-data-and-security/09-auth-middleware-jwt.md) | data and security | a token verifier and role middleware |
| 10 | [Testing, and the notes API in a container](phase-4-quality-and-ship/10-testing-and-notes-api.md) | quality and ship | table-driven tests, a mini project, a non-root image |

The full production version of lessons 05 to 10 (all 27 operations, Keycloak, idempotency, hardening) is the capstone [`capstones/backend-go`](../../../capstones/backend-go/README.md); these lessons do not repeat it.

## How every 201 lesson works

Every lesson has the same shape: outcomes, a recap of earlier lessons, the idea and its diagram, numbered steps that show **every file in full**, a prediction step before the first run, "How it works", a "Why this, not that" table, a three-part exercise (guided, change, stretch), self-check questions, common mistakes and one sourced best practice. Phase 1 lessons print their results; phase 2 to 4 lessons start a server and call it with `curl`.

Tools: Go 1.22.0 or newer, a terminal, an editor (VS Code with the Go extension is used in 101), `curl` (in Windows PowerShell type **`curl.exe`**, because plain `curl` is an alias for another command), and from lesson 08 Docker with Compose v2.

### Get the optional source

Every file is shown in the lesson, so you can follow by typing. The finished code, the exercise starters and the solutions are in the course repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Each phase folder has a `PACK-README.md`.

### Working folder

Each lesson uses its own folder and module, outside the downloaded source. For lesson `NN` use the folder `$HOME/code101/go201/lessonNN` and the module name `example.com/code101/go201/lessonNN`.

**Windows PowerShell:**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/go201/lesson01" | Out-Null
Set-Location "$HOME/code101/go201/lesson01"
go mod init example.com/code101/go201/lesson01
```
**macOS and Linux:**
```bash
mkdir -p "$HOME/code101/go201/lesson01"
cd "$HOME/code101/go201/lesson01"
go mod init example.com/code101/go201/lesson01
```
Leave the `go` line that `go mod init` writes alone. If you use the supplied source, do not run `go mod init`: `go.mod` is already there (pinned to `go 1.22.0`). Every command in a lesson says which folder it runs in. Check with `Get-Location` (PowerShell) or `pwd`; if you are in the wrong folder, `cd` back into the lesson folder, and remember Go commands only work inside a module (`go: go.mod file not found...` means wrong folder).

Lessons 08 and 09 use libraries that are not in the standard library. Their `go.mod` lists them with a pinned version, and **you run `go mod tidy` once**: it downloads the libraries and creates `go.sum` (a checksum file). The supplied source does not contain `go.sum`, because `go mod tidy` makes it.

### Exercise folders

Every lesson ends with an exercise in three parts: guided, change and stretch. Two shapes exist.

- **Separate program** (lessons 01 to 07 and 10): copy the `exercise/starter` folder, **rename the copy** `tryNN` (for example `try03`), and open only that folder. The starter has its own `go.mod`, so do **not** run `go mod init`. Run the command the lesson gives (`go run .` or `go test ./...`). `starter` must not end up *inside* `tryNN`: `go.mod` has to be a direct child of `tryNN`.
- **Added to your lesson folder** (lessons 08 and 09): copy your finished `lessonNN` folder to `tryNN` and add the starter files into it, keeping their relative folders (for example `auth/roles.go`). Those lessons say so in "Try it".

The solution is in a `<details>` block under each exercise; try first, then compare. Solutions show what changed; where a file is replaced, the whole file is shown.

### Tests

From lesson 01 on, code ships with tests. Run them with `go test ./...` in the lesson folder; the last line starts with `ok`. Lessons 03 and 10 also use the race detector (`go test -race ./...`), which on some platforms needs a C compiler; if it is refused, run without it.
