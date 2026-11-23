# Go track state - 301 Super Hero to Legendary

Last updated: 2026-11-23. Written under the "no smoke tests" policy: nothing was executed (no `go build`, `go test`, `go run`, `buf`, `docker`).

## 301 Super Hero to Legendary

`go 1.26.0` in supplied modules. 9 lessons, three phases. Status `written (not run)` means: lesson, source pack and `verify.json` exist and pass the static text check; the code and expected outputs were derived by reading the code and checking official documentation and module metadata, and have never been executed.

| Lesson | Phase | Time | Status |
|---|---|---|---|
| 01-concurrency-patterns | phase-1-concurrency-and-performance | 70 min | written (not run) |
| 02-memory-model-and-race-detector | phase-1-concurrency-and-performance | 60 min | written (not run) |
| 03-profiling-and-benchmarks | phase-1-concurrency-and-performance | 75 min | written (not run) |
| 04-clean-architecture | phase-2-architecture-and-services | 80 min | written (not run) |
| 05-grpc-services | phase-2-architecture-and-services | 90 min | written (not run) |
| 06-resilience | phase-2-architecture-and-services | 90 min | written (not run) |
| 07-observability | phase-3-production | 100 min | written (not run) |
| 08-security-and-supply-chain | phase-3-production | 110 min | written (not run) |
| 09-release-engineering | phase-3-production | 120 min | written (not run) |

## Evidence (static only)

- `python scripts/verify_labs.py --static go/301`: 9 static-checked, 0 failed. Every non-blank line of every text file in each `code/` folder and every `expect_stdout` / `expect_contains` appear in the lesson text. Files that cannot be exact because they are generated are not in `code/`: `go.sum` (by `go mod tidy`) and `gen/` (by `buf generate`).
- Draft notice verbatim under each H1; front matter `verified: not yet run`.
- Manual audit while writing (reading, no compiler): imports used in every `.go` file, gofmt-style import grouping, relative links to Go 201 lessons and capstone chapters, UTF-8 without BOM.
- Pack build: `python scripts/build_packs.py go-301` (zips only, nothing executed).
- Module and tool versions were looked up on the Go module proxy (`proxy.golang.org`) and Docker Hub on 2026-11-23; every dependency's `go` directive is at most 1.26.0.

## What the first real run must check (open risks, in order of likelihood)

1. **Lesson 05:** `buf generate` with `paths=source_relative` and the `go_package` option writes to `gen/inventory/v1/`; generated names (`Sku`, `MinQuantity`, `grpc.ServerStreamingServer[...]`) match what the code uses with `protoc-gen-go-grpc v1.6.2`; `buf lint` STANDARD passes (no unexpected rule); `grpc.NewClient("passthrough:///bufnet", ...)` with `bufconn`.
2. **Lesson 07:** `go mod tidy` resolves the OpenTelemetry module set (`otelhttp v0.72.0` against `otel v1.47.0`); the exact JSON key order of the log lines (`service`, then record attributes, then `trace_id`, `span_id`); the metric line order in `/metrics`; `docker compose` read-only container with `distroless` and the `prom/prometheus:v3.16.0` config mount.
3. **Lesson 06:** `rate.Limiter.ReserveN` + `CancelAt` restore the token so the one-second-later call is allowed; the idempotency concurrency test (`201` or `409` only).
4. **Lesson 08:** error classification of `jwt` v5 for `kid` lookup failure (`ErrTokenUnverifiable`) and for a disallowed algorithm; the mTLS demo with TLS 1.3 (client without certificate fails on `Get`); `http.MaxBytesError` returned unwrapped by `json.Decoder`.
5. **Lesson 01 and 02:** timing-based leak counts (`1` then `0`); race-detector commands need a C compiler (the Windows author machine has MSVC only).
6. **Lesson 03:** `b.Loop` with `-benchmem`; `-cpuprofile` with a single package; pprof web UI flame-graph default described from the Go 1.26 notes.
7. **Lesson 09:** two clean builds with `-trimpath -buildvcs=false` give identical hashes on the author's Windows machine and on Linux; the `-X` linker flag form in PowerShell; Docker `--mount=type=cache` and `--platform=$BUILDPLATFORM` with Compose build.
8. Every `Common mistakes` row marked "typical message" must be replaced with the captured text once the lesson is run; rows are written from official documentation or experience, not captured.

## Source and pacing decisions

- Go 201 covers goroutines, channels, sync, context, slog basics, JWT with HS256 and a small container; 301 links to those lessons and goes deeper (leaks and ownership, memory model, asymmetric keys and rotation, release engineering).
- The idempotency store of lesson 06 is in memory by design and says so; the database-backed version is capstone chapter 04.
- The review exercise (lesson 09) has no code to run; its solution is `REVIEW.md` with 24 findings and a fixed `main.go`.
- Repository edits limited to `tutorials/go/` and `source/go/301-super-hero-to-legendary/`; the pack builder writes ignored `dist/packs` outputs.

## Packs

Command: `python scripts/build_packs.py go-301` (zips only, nothing executed). Result:

```text
built go-301-phase-1-concurrency-and-performance.zip (35 files)
built go-301-phase-2-architecture-and-services.zip (51 files)
built go-301-phase-3-production.zip (48 files)
built go-301-all.zip (3 phases)
```
Static check result: `0 passed, 9 static-checked (not run), 0 failed, 0 unverified`.
