# Go 301, Phase 2: Architecture and Services

Source pack for lessons 04 to 06 of **Go 301 (Super Hero to Legendary)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/301-super-hero-to-legendary/phase-2-architecture-and-services/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open **one** lesson `code` folder at a time.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `04-clean-architecture` | Clean architecture in Go | tasks API in `domain`, `app`, `adapters`; fakes; an architecture test / invert a wrong dependency |
| `05-grpc-services` | gRPC services | an `InventoryService` with unary, server, client and bidirectional streaming, `buf`, `bufconn` tests / add `DeleteItem` (overlay) |
| `06-resilience` | Resilience | retry with backoff and jitter, circuit breaker, per-key rate limiter, idempotency keys / parse `Retry-After` |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with `go.mod`. |
| `exercise/starter/` | Starting point with TODO markers (lesson 05: an **overlay**, see below). |
| `exercise/solution/` | Complete answer. Try the exercise first. |
| `verify.json` | Maintainer check steps. Learners can ignore this file. |

## How to run

1. Go **1.26.0 or newer**.
2. Lesson 04: standard library only. `go test ./...`, then `go run ./cmd/tasks` and the `curl` commands in the lesson.
3. Lesson 05 needs three tools installed with `go install` (versions in the lesson) and **generated code**: run `buf lint` and `buf generate` in `code/`, then `go mod tidy`, then `go test ./...`. The folder `gen/` is **not shipped** because it is produced by `buf generate`; `go.sum` is produced by `go mod tidy`. Start the server with `go run ./cmd/server` and the client with `go run ./cmd/client` in two terminals.
4. Lesson 06: run `go mod tidy` once (it adds `golang.org/x/time`), then `go run .` and `go test ./...` (the tests also work with `-race`).
5. Exercises: copy `starter` and rename the copy `try04`, `try06`. **Lesson 05's exercise is an overlay**: copy the lesson's whole `code` folder to `try05`, then add the files in `exercise/starter/` on top (read `TODO.txt` and `delete.go`).

## Needs

Go 1.26.0 or newer. Lesson 05: `buf`, `protoc-gen-go`, `protoc-gen-go-grpc` on `PATH`. Lessons 05 and 06 need internet access once for `go mod tidy`.
Lesson text: `tutorials/go/301-super-hero-to-legendary/phase-2-architecture-and-services/` in the repository.
Status: all three lessons are **written (not run)**.
