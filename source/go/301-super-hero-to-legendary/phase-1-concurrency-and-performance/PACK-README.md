# Go 301, Phase 1: Concurrency and Performance

Source pack for lessons 01 to 03 of **Go 301 (Super Hero to Legendary)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons. Open **one** lesson `code` folder at a time, never the parent that holds all modules.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-concurrency-patterns` | Concurrency patterns | worker pool, pipeline, fan-out and fan-in, errgroup, a counted goroutine leak / `processAll` with errgroup |
| `02-memory-model-and-race-detector` | Memory model, data races and the race detector | racy and safe counters, publication, maps, `sync.OnceValue` / fix a racy `Account` |
| `03-profiling-and-benchmarks` | Profiling with pprof and benchmarks | benchmarks with `testing.B.Loop`, CPU and allocation profiles, live pprof on localhost / `strings.Builder` join |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson; its own module with `go.mod`. |
| `exercise/starter/` | Starting point with TODO markers; copy the whole folder and rename the copy. |
| `exercise/solution/` | Complete answer. Try the exercise first. |
| `verify.json` | Maintainer check steps. Learners can ignore this file. |

## How to run

1. Install Go **1.26.0 or newer** (`go version`). Lesson text and code assume `go 1.26.0` in `go.mod`.
2. In a lesson's `code` folder run `go mod tidy` **only for lesson 01** (it needs `golang.org/x/sync`; the command downloads it and creates `go.sum`, which is not shipped). Lessons 02 and 03 use only the standard library.
3. Run `go run .` and `go test ./...` there. Lesson 02 also uses `go test -race ./...`; the race detector needs cgo and a C compiler (see lesson 02, "Before you start"). Lesson 03 uses `go test -run '^$' -bench . -benchmem -count 10 ./wordfreq` and `go tool pprof`.
4. Exercises: copy the `starter` folder and rename the copy `try01`, `try02`, `try03`. The renamed folder must directly contain `go.mod` and `main.go`.

## Needs

Go 1.26.0 or newer. Lesson 01 needs internet access once, for `go mod tidy`. Optional: `benchstat` (`go install golang.org/x/perf/cmd/benchstat@latest`).
Complete Go 201 first (goroutines, channels, sync, context); terms continue in lesson order and are collected in `tutorials/go/GLOSSARY.md`.
Lesson text: `tutorials/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/` in the repository.
Status: all three lessons are **written (not run)**: the code and outputs were derived by reading, not executed.
