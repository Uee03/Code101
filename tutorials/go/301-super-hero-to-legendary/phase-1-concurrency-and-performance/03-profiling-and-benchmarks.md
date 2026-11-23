---
track: go
level: 301
phase: 1
phase_name: concurrency-and-performance
lesson: 03
title: "Profiling with pprof and benchmarks: measure first, then change one thing"
time: 75 min
prerequisites: [go-301.1.01, go-301.1.02]
versions: { go: "1.26.0 or newer" }
verified: not yet run
source: source/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/03-profiling-and-benchmarks/
assets: []
---

# 03. Profiling with pprof and benchmarks: measure first, then change one thing

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a benchmark with `testing.B.Loop` and read `ns/op`, `B/op` and `allocs/op`;
- collect a CPU profile and an allocation profile from a benchmark and from a running program, and read them with `go tool pprof`;
- compare two versions of code with `benchstat` instead of eyeballing one run;
- expose pprof safely, and write an optimisation log that records your own measurements.

This lesson contains **no performance numbers**. Speed depends on your CPU, your Go version and your load, so every number you will see is one you measured. The places where you record them are marked.

## Recap
1. Why can a race-detector build make a benchmark misleading? <details><summary>Answer</summary>Instrumentation slows execution by an amount that varies across code (the docs say 2 to 20 times), so relative costs change. Benchmark without `-race`.</details>
2. What does `errgroup.SetLimit` bound? <details><summary>Answer</summary>The number of goroutines running at once (lesson 01).</details>
3. What is a data race? <details><summary>Answer</summary>Concurrent access to one variable, at least one a write, with no happens-before ordering (lesson 02).</details>

## Why it matters
A doctor does not prescribe after one glance at the patient: she measures temperature, takes a blood test, compares with last month. Performance work done by intuition is the same as prescribing blind. The slow part of your service is rarely the part you suspect, and an "obvious" optimisation that you did not measure is as likely to add complexity as to remove time. Go ships the measuring tools in the standard toolchain: benchmarks, `pprof`, the execution tracer.

## What you will build
A module `l03` with a package `wordfreq` that counts words in two ways (a naive one that recompiles a regular expression on every call, and a faster one), tests that prove both return the same result, two benchmarks, and a `main.go` that can write profiles to files or serve live pprof endpoints on localhost.

## Before you start
- Lessons 01 and 02. Go 1.26.0 or newer.
- `benchstat` (optional but used): `go install golang.org/x/perf/cmd/benchstat@latest`. This installs a tool, not a dependency of your module; pin a version in CI (see lesson 08, "supply chain").
- Graphviz is **not** required: the pprof web UI and the `-top` and `-list` views work without it.
- Time: 75 minutes. Break after Step 4.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/03-profiling-and-benchmarks/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving and running.
- No dependencies: no `go.sum`.

## Steps

### Step 1. Folder and module
**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/go301/lesson03/wordfreq" | Out-Null
Set-Location "$HOME/code101/go301/lesson03"
```
```bash
mkdir -p ~/code101/go301/lesson03/wordfreq
cd ~/code101/go301/lesson03
```
Open `lesson03` in VS Code with a terminal in it. Recovery: `Set-Location "$HOME/code101/go301/lesson03"` or `cd ~/code101/go301/lesson03`.

**File: `go.mod`**
```text
module example.com/code101/go301/l03

go 1.26.0
```

### Step 2. The code to measure
**File: `wordfreq/wordfreq.go`**
```go
package wordfreq

import (
	"cmp"
	"regexp"
	"slices"
	"strings"
)

// Entry is one word and how often it occurs.
type Entry struct {
	Word  string
	Count int
}

// CountNaive recompiles its regular expression on every call, a common
// real-world mistake that a profile makes visible.
func CountNaive(text string) map[string]int {
	re := regexp.MustCompile(`[a-z']+`)
	counts := make(map[string]int)
	for _, w := range re.FindAllString(strings.ToLower(text), -1) {
		counts[w]++
	}
	return counts
}

func isWordRune(r rune) bool { return r >= 'a' && r <= 'z' || r == '\'' }

func isSeparator(r rune) bool { return !isWordRune(r) }

// Count returns the same result as CountNaive without a regular expression.
func Count(text string) map[string]int {
	counts := make(map[string]int)
	for _, w := range strings.FieldsFunc(strings.ToLower(text), isSeparator) {
		counts[w]++
	}
	return counts
}

// Top returns the n most frequent words, ties broken alphabetically.
func Top(counts map[string]int, n int) []Entry {
	entries := make([]Entry, 0, len(counts))
	for w, c := range counts {
		entries = append(entries, Entry{Word: w, Count: c})
	}
	slices.SortFunc(entries, func(a, b Entry) int {
		return cmp.Or(cmp.Compare(b.Count, a.Count), strings.Compare(a.Word, b.Word))
	})
	if len(entries) > n {
		entries = entries[:n]
	}
	return entries
}
```
`CountNaive` calls `regexp.MustCompile` inside the function, so every call parses and compiles the pattern again. That is a real mistake found in real services, and an excellent specimen: it is invisible when you read a call site and glaring in a profile. `Count` returns the same map using `strings.FieldsFunc`. `Top` sorts a copy of the entries with a total order (count descending, then word ascending) so its output is deterministic: Go randomises map iteration order on purpose.

### Step 3. Tests first, then benchmarks
Never optimise without a test that says the result did not change.

**File: `wordfreq/wordfreq_test.go`**
```go
package wordfreq

import (
	"maps"
	"slices"
	"strings"
	"testing"
)

func TestCountMatchesNaive(t *testing.T) {
	texts := []string{
		"",
		"   ",
		"The quick brown fox. Don't panic! The DOG, again...",
		"It's 42 o'clock; ÉCOLE école",
	}
	for _, text := range texts {
		got, want := Count(text), CountNaive(text)
		if !maps.Equal(got, want) {
			t.Fatalf("text %q: Count = %v, CountNaive = %v", text, got, want)
		}
	}
}

func TestTopBreaksTiesAlphabetically(t *testing.T) {
	got := Top(map[string]int{"b": 2, "a": 2, "c": 5}, 2)
	want := []Entry{{Word: "c", Count: 5}, {Word: "a", Count: 2}}
	if !slices.Equal(got, want) {
		t.Fatalf("got %v, want %v", got, want)
	}
}

var benchText = strings.Repeat("The quick brown fox jumps over the lazy dog. Don't panic! ", 200)

func BenchmarkCountNaive(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		CountNaive(benchText)
	}
}

func BenchmarkCount(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		Count(benchText)
	}
}
```
- `for b.Loop() { ... }` (Go 1.24 and newer) replaces the older `for i := 0; i < b.N; i++` loop. It runs the setup before the loop once, keeps the compiler from deleting a call whose result is unused, and handles the timer for you. Code **before** the loop is not timed.
- `b.ReportAllocs()` adds the `B/op` (bytes allocated per iteration) and `allocs/op` columns. Allocation counts often explain time.
- The benchmark text is built once, outside the timed loop, from a realistic sentence repeated 200 times. A benchmark input must look like production input: a three-word string measures something else.

### Step 4. The program with profiling switches
**File: `main.go`**
```go
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net/http"
	netpprof "net/http/pprof"
	"os"
	"os/signal"
	"runtime"
	"runtime/pprof"
	"strings"
	"time"

	"example.com/code101/go301/l03/wordfreq"
)

const sample = "The quick brown fox jumps over the lazy dog. The dog did not mind; the fox did."

var workload = strings.Repeat(sample+" ", 200)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func run() error {
	cpuProfile := flag.String("cpuprofile", "", "write a CPU profile to this file")
	memProfile := flag.String("memprofile", "", "write an allocation profile to this file")
	rounds := flag.Int("n", 0, "count a larger text this many times (0 prints the top words once)")
	naive := flag.Bool("naive", false, "use the slow implementation")
	debugAddr := flag.String("debug-addr", "", "serve pprof here and run until Ctrl+C, for example 127.0.0.1:6060")
	flag.Parse()

	count := wordfreq.Count
	if *naive {
		count = wordfreq.CountNaive
	}

	if *cpuProfile != "" {
		f, err := os.Create(*cpuProfile)
		if err != nil {
			return err
		}
		defer f.Close()
		if err := pprof.StartCPUProfile(f); err != nil {
			return err
		}
		defer pprof.StopCPUProfile()
	}

	switch {
	case *debugAddr != "":
		return serveAndLoad(*debugAddr, count)
	case *rounds > 0:
		for range *rounds {
			count(workload)
		}
	default:
		for _, e := range wordfreq.Top(count(sample), 5) {
			fmt.Println(e.Word, e.Count)
		}
	}

	if *memProfile != "" {
		return writeAllocProfile(*memProfile)
	}
	return nil
}

func writeAllocProfile(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	runtime.GC() // bring the statistics up to date before writing
	return pprof.Lookup("allocs").WriteTo(f, 0)
}

// serveAndLoad exposes the pprof handlers on an explicit mux (not the default
// one) and keeps the program busy so there is something to profile.
func serveAndLoad(addr string, count func(string) map[string]int) error {
	mux := http.NewServeMux()
	mux.HandleFunc("/debug/pprof/", netpprof.Index)
	mux.HandleFunc("/debug/pprof/cmdline", netpprof.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", netpprof.Profile)
	mux.HandleFunc("/debug/pprof/symbol", netpprof.Symbol)
	mux.HandleFunc("/debug/pprof/trace", netpprof.Trace)

	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			fmt.Fprintln(os.Stderr, "debug server:", err)
		}
	}()
	defer srv.Close()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	fmt.Println("serving pprof on http://" + addr + "/debug/pprof/ ; press Ctrl+C to stop")
	for ctx.Err() == nil {
		count(workload)
	}
	return nil
}
```
Points to read carefully:
- Two packages are called `pprof`. `runtime/pprof` writes profiles to a file you give it; `net/http/pprof` serves them over HTTP. We import the second one with the alias `netpprof`.
- The common one-liner `import _ "net/http/pprof"` registers its handlers on `http.DefaultServeMux` as a **side effect**. If your service ever serves the default mux on a public port, you have just published your profiler. This program registers the handlers by hand on its **own** mux and binds it to the address you pass (use `127.0.0.1`).
- `defer pprof.StopCPUProfile()` runs **before** `defer f.Close()` (defers run last-in first-out), so the profile is flushed and then the file is closed. Calling `log.Fatal` or `os.Exit` would skip the defers and leave an empty profile; that is why `main` only calls `os.Exit` after `run` has returned.
- `runtime.GC()` before writing the allocation profile brings the statistics up to date, as the `runtime/pprof` documentation recommends.
- The CPU profiler samples the running goroutines about a hundred times per second, so a program that runs for a few milliseconds produces a profile with almost nothing in it. Run a workload long enough (seconds).

## Run it
**File: terminal (not a saved file)**
```text
go run .
```
Expected output (derived by reading the code; not yet run):
```text
the 4
did 2
dog 2
fox 2
brown 1
```
Run the tests:

**File: terminal (not a saved file)**
```text
go test ./...
```
Expected: `ok` followed by `example.com/code101/go301/l03/wordfreq` and a duration (the root package reports that it has no test files).

**Predict before you run the benchmarks.** Which of the two benchmarks will report more `allocs/op`, and which function in the standard library do you expect to dominate the naive one? Write it down.

### Benchmarks
**File: terminal (not a saved file)**
```text
go test -run '^$' -bench . -benchmem -count 10 ./wordfreq
```
`-run '^$'` runs no tests (the pattern matches nothing) so only benchmarks run; `-bench .` selects all benchmarks; `-benchmem` prints allocation columns (we already call `ReportAllocs`); `-count 10` repeats each benchmark ten times so you can see the noise. The output has this shape, one line per run (numbers are yours; none are given here):
```text
goos: <your os>
goarch: <your architecture>
pkg: example.com/code101/go301/l03/wordfreq
cpu: <your cpu>
BenchmarkCountNaive-<GOMAXPROCS>   <iterations>   <ns> ns/op   <bytes> B/op   <allocs> allocs/op
BenchmarkCount-<GOMAXPROCS>        <iterations>   <ns> ns/op   <bytes> B/op   <allocs> allocs/op
PASS
ok  	example.com/code101/go301/l03/wordfreq	<seconds>s
```
### Compare with benchstat
A single run is an anecdote. Save the results of each variant and let `benchstat` say whether a difference is larger than the noise:

**File: terminal (not a saved file)**
```text
go test -run '^$' -bench 'CountNaive' -benchmem -count 10 ./wordfreq > old.txt
go test -run '^$' -bench 'Count$' -benchmem -count 10 ./wordfreq > new.txt
benchstat old.txt new.txt
```
(The benchmark names differ, so `benchstat` shows them as separate rows; for a true before/after comparison keep the **same** benchmark name, change the code, and save `old.txt` before and `new.txt` after. This is the workflow to use on your own code.) `benchstat` prints the median of each metric with a confidence interval and a `p` value; a `~` means "no statistically significant difference".

### Profile the benchmark
**File: terminal (not a saved file)**
```text
go test -run '^$' -bench CountNaive -cpuprofile cpu.out -memprofile mem.out ./wordfreq
go tool pprof -top cpu.out
go tool pprof -sample_index=alloc_space -top mem.out
```
The profile flags work with a single package. `-top` prints the heaviest functions. Two columns matter: **flat** is the time spent in the function itself, **cum** (cumulative) includes everything it calls. A function with a small flat and a large cum is just a conduit; the one with a large flat is where the CPU is. For memory, `-sample_index` chooses `alloc_space` (bytes allocated in total), `alloc_objects` (number of allocations), `inuse_space` and `inuse_objects` (what is alive now, which is what you want for a leak). Expected: functions from `regexp` (for example compile and parse functions) should appear near the top for the naive version, because that is what the code does. If they do not, believe the profile, not this paragraph.

Look at one function line by line, then open the web UI:

**File: terminal (not a saved file)**
```text
go tool pprof -list 'CountNaive' cpu.out
go tool pprof -http=127.0.0.1:8081 cpu.out
```
In Go 1.26 the web UI opens on the **flame graph**: wide boxes are expensive, stacked boxes are callers above callees. The older graph is under **View > Graph**. Always bind the UI to `127.0.0.1`.

### A live program
**File: terminal (not a saved file)**
```text
go run . -naive -debug-addr 127.0.0.1:6060
```
In a second terminal, ask for ten seconds of CPU profile, then a goroutine dump and a heap snapshot:

**File: terminal (not a saved file)**
```text
go tool pprof -top "http://127.0.0.1:6060/debug/pprof/profile?seconds=10"
curl -s "http://127.0.0.1:6060/debug/pprof/goroutine?debug=2"
go tool pprof -top http://127.0.0.1:6060/debug/pprof/allocs
```
`goroutine?debug=2` prints every goroutine's stack as text: the first thing to look at when the goroutine count rises (lesson 01) or the service hangs. Press Ctrl+C in the first terminal to stop the program.

Two profiles are **off by default** because they cost something: the **mutex** profile (`runtime.SetMutexProfileFraction`) and the **block** profile (`runtime.SetBlockProfileRate`). Turn them on only while you investigate contention.

## How it works
- **A benchmark answers "how fast is this function on this machine?"** A **profile** answers "where does the time or memory go?" You need both: the benchmark gives a repeatable number, the profile tells you what to change, the benchmark confirms the change.
- **CPU profile:** the runtime interrupts the program many times per second and records the stack of what is running. Frequent stacks are expensive code. It sees only time on CPU, not time waiting for I/O or locks (use the block and mutex profiles, or the execution trace, for that).
- **Allocation profile:** the runtime records a sample of allocations with their stacks (by default roughly one per half a megabyte allocated), so small allocations are statistically represented. Fewer allocations means less garbage-collector work, which is often where "mysterious" time goes.
- **Execution trace** (`go tool trace`, `/debug/pprof/trace`): shows what each goroutine did over a few seconds, including scheduling delays and GC pauses. It is bigger and more expensive than a profile; use it for latency and concurrency questions, not for "which function is hot". Go 1.25 added `runtime/trace.FlightRecorder`, which keeps a rolling in-memory trace you can dump when something rare happens.
- **The garbage collector** is a tunable system: `GOGC` (how much the heap may grow before a collection) and `GOMEMLIMIT` (a soft limit on total memory, valuable in containers). `GODEBUG=gctrace=1` prints one line per collection. Release notes also matter: Go 1.25 made `GOMAXPROCS` aware of container CPU limits on Linux, and Go 1.26 made the "Green Tea" collector the default. **Re-run your benchmarks after every toolchain upgrade**; do not assume yesterday's tuning still holds.
- **Misconception to correct:** "a faster microbenchmark means a faster service." A microbenchmark has a warm cache, no contention and a clean heap. Confirm every win with an end-to-end test (a load test, lesson 07's latency histogram) before you celebrate.

## Decision record (ADR style)
**ADR-03: no optimisation merges without a before/after benchmark and a profile that motivated it.**
- Context: reviews were accepting "this should be faster" changes that added code and no evidence.
- Decision: a performance pull request must include (1) the profile or metric that showed the problem, (2) `benchstat` output before and after on the same machine, (3) a test proving the result is unchanged.
- Consequences: slower to propose, much cheaper to review and to revert; changes that cannot show a gain are dropped, which keeps the code simple.

**When not to optimise**
- The function is not in the top of a profile of the **real** workload. A 10x gain on 1% of the time is a 1% gain.
- The code is run once at start-up, or a few times per request, and the service is waiting on a database anyway: fix the query, not the loop.
- The optimisation makes the code harder to read and you have not measured a gain larger than the noise.

### Your optimisation log (fill in with your own measurements)
| Step | What I changed | Benchmark before (ns/op, B/op, allocs/op) | Benchmark after | benchstat p-value | Kept? |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |

## Failure modes
| Failure | Why it misleads | Prevention |
|---|---|---|
| Benchmark result discarded | the compiler removes dead code and you time nothing | `for b.Loop()`, or assign results to a package variable in older style |
| Input too small or too regular | caches and branch predictors make it unrealistically fast | use production-shaped data and sizes |
| Noisy machine (laptop on battery, other programs) | variance bigger than the effect | `-count 10`, `benchstat`, close other programs, same power mode |
| Profiling a short run | too few samples | run longer, or loop the workload |
| `pprof` exposed on a public port | anyone can read internals and trigger expensive profiles | localhost or an authenticated admin port; never the default mux on a public listener |
| Optimising allocations that GC handles cheaply | complexity for nothing | look at the profile and the GC share first |
| Comparing different machines or Go versions | not the same experiment | record `go version`, `GOOS`, `GOARCH`, CPU in the log |

## Measurements to take
1. For each benchmark: median `ns/op`, `B/op`, `allocs/op` with `-count 10` before and after, with the `benchstat` p-value.
2. For the service: p50, p95, p99 request latency and requests per second at a fixed load, before and after.
3. CPU profile top 10 by cumulative time, saved as an artefact so you can diff profiles later (`go tool pprof -base old.out new.out`).
4. Peak resident memory and GC share (`GODEBUG=gctrace=1` or runtime metrics) at the same load.

## Production checklist
- [ ] pprof endpoints exist, are reachable only from an operator network or localhost, and are not on the default mux of a public listener.
- [ ] You can capture CPU, heap, goroutine and (when needed) mutex/block profiles from a running instance without redeploying.
- [ ] `GOMEMLIMIT` is set for containers with a memory limit, and chosen from a measurement of the live heap.
- [ ] Benchmarks for hot paths live in the repository and run in CI on demand (not on every commit: they are noisy).
- [ ] A load test with a stable profile exists so a regression is visible before a release.
- [ ] Toolchain upgrades are followed by a benchmark re-run.

## Try it
Copy `exercise/starter` next to your lesson folder and rename the copy `try03` (it must directly contain `go.mod`, `main.go` and `join_test.go`).

**File: `exercise/starter/main.go`**
```go
package main

import "fmt"

// JoinNaive builds the result with +=: every step allocates and copies a new string.
func JoinNaive(parts []string, sep string) string {
	out := ""
	for i, p := range parts {
		if i > 0 {
			out += sep
		}
		out += p
	}
	return out
}

// JoinBuilder must return exactly what JoinNaive returns.
// TODO 1: implement it with strings.Builder (add the import) and call Grow once
// with the exact final size, computed from len(sep) and the length of each part.
func JoinBuilder(parts []string, sep string) string {
	return ""
}

func main() {
	parts := []string{"a", "b", "c"}
	fmt.Println(JoinNaive(parts, ","))
	fmt.Println(JoinBuilder(parts, ","))
}
```
**File: `exercise/starter/join_test.go`**
```go
package main

import (
	"strings"
	"testing"
)

func TestJoinBuilderMatchesNaive(t *testing.T) {
	cases := [][]string{nil, {"a"}, {"a", "b", "c"}, {"", "x", ""}}
	for _, parts := range cases {
		if got, want := JoinBuilder(parts, ", "), JoinNaive(parts, ", "); got != want {
			t.Fatalf("parts %q: got %q, want %q", parts, got, want)
		}
	}
}

var parts = strings.Split(strings.Repeat("word,", 1000), ",")

// TODO 2: write BenchmarkJoinNaive and BenchmarkJoinBuilder.
// Use b.ReportAllocs() and `for b.Loop() { ... }`, and join `parts` with ",".
```
1. **Guided.** Run `go test ./...` in `try03`: the test fails, because `JoinBuilder` returns an empty string. Implement `JoinBuilder` (TODO 1) until it passes, then `go run .` must print `a,b,c` twice.
2. **Change.** Write the two benchmarks (TODO 2). Run them with `-benchmem -count 10`, save the results in `join.txt`, and record the medians in your optimisation log. Then change the input to 10 parts and measure again. Does the winner change? Write one sentence about what that means for "always use a builder".
3. **Stretch (no single answer).** Take the `Count` function from `wordfreq` and find, with a CPU profile of `go run . -n 20000 -cpuprofile cpu.out`, the next most expensive function. Decide whether a further change is worth its complexity, and write the decision as a two-line ADR.

<details><summary>Solution</summary>

**File: `exercise/solution/main.go` (changed region)**
```go
import (
	"fmt"
	"strings"
)

// JoinBuilder returns exactly what JoinNaive returns, with one allocation for the result.
func JoinBuilder(parts []string, sep string) string {
	if len(parts) == 0 {
		return ""
	}
	size := len(sep) * (len(parts) - 1)
	for _, p := range parts {
		size += len(p)
	}
	var b strings.Builder
	b.Grow(size)
	for i, p := range parts {
		if i > 0 {
			b.WriteString(sep)
		}
		b.WriteString(p)
	}
	return b.String()
}
```
**File: `exercise/solution/join_test.go` (the two benchmarks added below `parts`)**
```go
func BenchmarkJoinNaive(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		JoinNaive(parts, ",")
	}
}

func BenchmarkJoinBuilder(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		JoinBuilder(parts, ",")
	}
}
```
Expected output of `go run .` in the solution (derived by reading the code):
```text
a,b,c
a,b,c
```
For rung 2 the exact numbers are yours to measure. Expect `JoinNaive` to report far more `allocs/op` as the number of parts grows (every `+=` allocates a new string), and the difference to become small for a handful of parts. (The standard library's `strings.Join` already does what `JoinBuilder` does; in real code use it.)
</details>

## Check yourself
1. What is the difference between `flat` and `cum` in a pprof listing? <details><summary>Answer</summary>`flat` is time in the function itself; `cum` includes the functions it calls.</details>
2. Why does `main.go` register the pprof handlers on its own mux instead of importing `net/http/pprof` for its side effect? <details><summary>Answer</summary>The side-effect import registers them on `http.DefaultServeMux`, which might later be served on a public listener. An explicit mux on a localhost address keeps the profiler private.</details>
3. A colleague says "the new version is 5% faster" after one run. What do you ask for? <details><summary>Answer</summary>Repeated runs (`-count 10`) and a `benchstat` comparison on the same machine, to separate the effect from noise.</details>
4. Predict: you profile a program that spends most of its time waiting on the network. What will the CPU profile show? <details><summary>Answer</summary>Very little: waiting is not CPU time. Use the block profile, the execution trace or tracing spans (lesson 07).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `go test -bench` prints `PASS` but no benchmark lines | `-bench` not given, or the pattern matched nothing | `-bench .` (a regular expression) |
| Benchmarks run the tests too | tests are selected by default | add `-run '^$'` |
| `cannot use -cpuprofile flag with multiple packages` (typical message) | the profile flags work for one package | name the package: `./wordfreq` |
| `pprof` shows only a handful of samples | run too short | loop the workload or run longer |
| Empty profile file | the program ended through `os.Exit` or `log.Fatal` before `StopCPUProfile` | return from `main` normally; keep `os.Exit` outside the code that holds defers |
| `benchstat` is not recognized, or `command not found` (typical message) | the Go bin folder is not on `PATH` | add `$(go env GOPATH)/bin` to `PATH` and open a new terminal |
| `bind: address already in use` (typical message) | another program uses port 6060 or 8081 | choose another port |

## Best practice
Measure with a repeatable benchmark, locate the cost with a profile, change one thing, and confirm with `benchstat`; keep pprof off public interfaces. Source: Diagnostics, https://go.dev/doc/diagnostics and Profiling Go Programs, https://go.dev/blog/pprof

## Going further
- `testing.B.Loop`: https://pkg.go.dev/testing#B.Loop
- `runtime/pprof` and `net/http/pprof`: https://pkg.go.dev/runtime/pprof and https://pkg.go.dev/net/http/pprof
- pprof command: https://pkg.go.dev/cmd/pprof and the profile viewer https://github.com/google/pprof
- A guide to the Go garbage collector (`GOGC`, `GOMEMLIMIT`): https://go.dev/doc/gc-guide
- Go 1.26 release notes (pprof web UI default view, the new garbage collector): https://go.dev/doc/go1.26

## Summary
- You wrote benchmarks with `b.Loop` and `ReportAllocs` and read the three result columns.
- You collected CPU and allocation profiles from a benchmark and from a running program, and read `flat` against `cum`.
- You compared versions with `benchstat` and recorded your own numbers in an optimisation log.
- You exposed pprof on localhost with an explicit mux and listed the profiles that are off by default.

## Next lesson
04. Clean architecture in Go: packages, interfaces at the consumer and the direction of dependencies.
