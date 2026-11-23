---
track: go
level: 301
phase: 1
phase_name: concurrency-and-performance
lesson: 02
title: "The memory model, data races and the race detector"
time: 60 min
prerequisites: [go-301.1.01]
versions: { go: "1.26.0 or newer" }
verified: not yet run
source: source/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/02-memory-model-and-race-detector/
assets: []
---

# 02. The memory model, data races and the race detector

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain what a data race is and what "happens before" means in the Go memory model;
- run a program and its tests with `-race`, and read a race report line by line;
- fix a race with a mutex, an atomic value, a channel or `sync.Once`, and say why you chose it;
- state what the race detector cannot tell you, and where it belongs in CI.

## Recap
1. In lesson 01, why is `results[i] = v` in `fetchAll` safe when each goroutine has its own `i`? <details><summary>Answer</summary>Different goroutines write different memory locations, and `g.Wait` orders all the writes before the read of the slice.</details>
2. Who may close a channel? <details><summary>Answer</summary>Its single owner on the sending side.</details>
3. What does `wg.Go(f)` do compared with `go f()`? <details><summary>Answer</summary>It also adds one to the WaitGroup and calls `Done` when `f` returns.</details>

## Why it matters
Two cooks write on the same recipe card at the same time. One card, two pens, no rule about who goes first: the card ends up as a mix of both, or one change vanishes. A **data race** is exactly that, and it is the most expensive kind of concurrency bug because the program usually seems to work in tests, and fails under production load, on other hardware, or after an unrelated compiler upgrade.

## What you will build
A module `l02` that runs, side by side, a **racy** and a **safe** version of four everyday situations: a shared counter, publishing a value to another goroutine, a shared map, and lazy initialisation. You will run the racy ones under the race detector and read what it reports.

## Before you start
- Lesson 01 done (WaitGroup, `wg.Go`, goroutines, channels), and the mutex and `context` basics from [Go 201 lesson 03](../../201-hero-to-super-hero/phase-1-core-skills/03-sync-context-cancellation.md).
- Go 1.26.0 or newer. **The race detector needs cgo and a C compiler** on every system except macOS. Check with `go env CGO_ENABLED` (it must print `1`) and `gcc --version` (or `cc --version`).
  - Linux (and WSL): install your distribution's C toolchain, for example `sudo apt install build-essential` on Ubuntu/Debian.
  - macOS: the Xcode command line tools are enough (`xcode-select --install`); no extra compiler is needed for `-race` according to the official requirements.
  - Windows: you need a mingw-w64 based `gcc` whose runtime is version 8 or newer; the Go documentation explains how to test your compiler (see "Going further"). The simplest route is to run this lesson inside WSL2 Ubuntu.
  - Without a compiler you can still read the lesson, run every "safe" command and write the fixes; only the `-race` commands are blocked.
- Time: 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/301-super-hero-to-legendary/phase-1-concurrency-and-performance/02-memory-model-and-race-detector/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving and running.
- This module has no dependencies, so there is no `go.sum` and no download.

## Steps

### Step 1. Create the folder and `go.mod`
**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/go301/lesson02" | Out-Null
Set-Location "$HOME/code101/go301/lesson02"
```
```bash
mkdir -p ~/code101/go301/lesson02
cd ~/code101/go301/lesson02
```
Open only this folder in VS Code and a terminal in it. Recovery: `Set-Location "$HOME/code101/go301/lesson02"` or `cd ~/code101/go301/lesson02`.

**File: `go.mod`**
```text
module example.com/code101/go301/l02

go 1.26.0
```
There is no `require` line, so nothing to download and no `go mod tidy` is needed.

### Step 2. Three counters: racy, mutex, atomic
**File: `counter.go`**
```go
package main

import (
	"sync"
	"sync/atomic"
)

type counter interface {
	Inc()
	Value() int
}

// RacyCounter has a data race: Inc is not synchronised.
type RacyCounter struct{ n int }

func (c *RacyCounter) Inc()       { c.n++ }
func (c *RacyCounter) Value() int { return c.n }

// MutexCounter protects n with a mutex; every access takes the lock.
type MutexCounter struct {
	mu sync.Mutex
	n  int
}

func (c *MutexCounter) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.n++
}

func (c *MutexCounter) Value() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.n
}

// AtomicCounter uses a lock-free atomic integer.
type AtomicCounter struct{ n atomic.Int64 }

func (c *AtomicCounter) Inc()       { c.n.Add(1) }
func (c *AtomicCounter) Value() int { return int(c.n.Load()) }

// hammer calls Inc perWorker times from each of workers goroutines and waits.
func hammer(c counter, workers, perWorker int) int {
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range perWorker {
				c.Inc()
			}
		})
	}
	wg.Wait()
	return c.Value()
}
```
`c.n++` looks like one step but is three: read `n`, add one, write `n`. Two goroutines can both read 41 and both write 42, so one increment is lost. The `MutexCounter` makes the three steps one critical section; the `AtomicCounter` makes the whole increment one indivisible hardware operation. The `Value` call after `wg.Wait()` is safe even in `RacyCounter` because `Wait` returning is ordered after every `Done`; the race is between the concurrent `Inc` calls.

### Step 3. Publishing a value to another goroutine
**File: `publish.go`**
```go
package main

import "time"

// racyPublish hands a message to another goroutine through two plain
// variables. Nothing orders the write of msg before the read of msg, so this
// is a data race on both variables. The loop is bounded so it cannot hang.
func racyPublish() string {
	var msg string
	var ready bool
	go func() {
		msg = "hello"
		ready = true
	}()
	for i := 0; i < 1000 && !ready; i++ {
		time.Sleep(time.Millisecond)
	}
	return msg
}

// safePublish closes a channel after writing msg. The close happens before
// the receive that observes it, so the read of msg is ordered after the write.
func safePublish() string {
	var msg string
	done := make(chan struct{})
	go func() {
		msg = "hello"
		close(done)
	}()
	<-done
	return msg
}
```
`racyPublish` is the classic "spin on a flag" mistake. It often seems to work, because on many machines the flag does become visible. But the Go memory model gives **no promise** that when the reader sees `ready == true` it also sees `msg == "hello"`: the compiler or the CPU may reorder the two writes, and a `string` is two words (pointer and length) that can be observed half-written. `safePublish` uses the one thing the memory model does promise: closing a channel happens before a receive that returns because of the close.

### Step 4. A shared map and lazy initialisation
**File: `cache.go`**
```go
package main

import "sync"

// SafeCache guards a map with a read-write mutex: many readers or one writer.
type SafeCache struct {
	mu sync.RWMutex
	m  map[string]string
}

func NewSafeCache() *SafeCache {
	return &SafeCache{m: make(map[string]string)}
}

func (c *SafeCache) Set(key, value string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.m[key] = value
}

func (c *SafeCache) Get(key string) (string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	v, ok := c.m[key]
	return v, ok
}

// config is built once, on first use, by exactly one goroutine. Every later
// call observes the finished map, and nobody writes to it afterwards.
var config = sync.OnceValue(func() map[string]string {
	return map[string]string{"region": "eu-1"}
})

// racyMapWrites writes to one plain map from four goroutines. The Go runtime
// often detects this itself and stops the program with a fatal error.
func racyMapWrites() {
	m := make(map[int]int)
	var wg sync.WaitGroup
	for w := range 4 {
		wg.Go(func() {
			for i := range 1000 {
				m[w*1000+i] = i
			}
		})
	}
	wg.Wait()
}
```
- Maps are **not** safe for concurrent writes, nor for a write concurrent with a read. The runtime has a cheap built-in check that can stop the program with a message like `fatal error: concurrent map writes` (typical message). That check is best effort, and a fatal error is not recoverable with `recover`.
- `sync.RWMutex` lets many readers in at once. It is not automatically faster than `sync.Mutex`: for short critical sections the bookkeeping can cost more than it saves. Measure (lesson 03) before choosing it.
- `sync.OnceValue` runs the function once, even when many goroutines call at once, and every caller sees the finished result. The map is then **read-only**: concurrent reads without writes are fine.

### Step 5. The program and the tests
**File: `main.go`**
```go
package main

import (
	"fmt"
	"os"
)

func main() {
	mode := "safe"
	if len(os.Args) > 1 {
		mode = os.Args[1]
	}

	switch mode {
	case "safe":
		fmt.Println("mutex counter:", hammer(&MutexCounter{}, 8, 1000))
		fmt.Println("atomic counter:", hammer(&AtomicCounter{}, 8, 1000))
		fmt.Println("safe publish:", safePublish())

		cache := NewSafeCache()
		cache.Set("region", "eu-1")
		v, ok := cache.Get("region")
		fmt.Println("cache:", v, ok)
		fmt.Println("lazy config:", config()["region"])
	case "racy-counter":
		fmt.Println("racy counter:", hammer(&RacyCounter{}, 8, 1000), "(a correct counter would print 8000)")
	case "racy-publish":
		fmt.Printf("racy publish: %q\n", racyPublish())
	case "racy-map":
		racyMapWrites()
		fmt.Println("racy map: finished without a crash this time")
	default:
		fmt.Fprintf(os.Stderr, "unknown mode %q: use safe, racy-counter, racy-publish or racy-map\n", mode)
		os.Exit(2)
	}
}
```
**File: `race_test.go`**
```go
package main

import (
	"fmt"
	"sync"
	"testing"
)

func TestSafeCountersReachTotal(t *testing.T) {
	counters := map[string]counter{
		"mutex":  &MutexCounter{},
		"atomic": &AtomicCounter{},
	}
	for name, c := range counters {
		t.Run(name, func(t *testing.T) {
			if got := hammer(c, 8, 1000); got != 8000 {
				t.Fatalf("got %d, want 8000", got)
			}
		})
	}
}

func TestSafePublish(t *testing.T) {
	if got := safePublish(); got != "hello" {
		t.Fatalf("got %q, want %q", got, "hello")
	}
}

func TestSafeCacheConcurrentWrites(t *testing.T) {
	cache := NewSafeCache()
	var wg sync.WaitGroup
	for w := range 4 {
		wg.Go(func() {
			for i := range 100 {
				cache.Set(fmt.Sprintf("k-%d-%d", w, i), "v")
			}
		})
	}
	wg.Wait()
	if _, ok := cache.Get("k-3-99"); !ok {
		t.Fatal("expected key k-3-99 to exist")
	}
}
```
The tests contain only the **safe** versions on purpose: a test that races fails under `-race`, which would break your CI. The racy code exists to be run by hand.

### Step 6. Predict, then run the safe mode
**Predict before you run.** What does `go run .` print for the two counters? Then guess what `go run . racy-counter` prints: the number 8000, more than 8000, or less? Write the answer down before you run it.

## Run it
**File: terminal (not a saved file)**
```text
go run .
```
Expected output (derived by reading the code; not yet run):
```text
mutex counter: 8000
atomic counter: 8000
safe publish: hello
cache: eu-1 true
lazy config: eu-1
```
Run the racy counter **without** the detector first, a few times:

**File: terminal (not a saved file)**
```text
go run . racy-counter
```
Typical result: a number **below** 8000 that changes from run to run (increments were lost). On a machine or load where the goroutines happen not to overlap it may print 8000: absence of a visible symptom proves nothing. That is why we need a detector.

Now with the race detector:

**File: terminal (not a saved file)**
```text
go run -race . racy-counter
```
Typical shape of the report (**not exact**: addresses, goroutine numbers, line numbers, paths and offsets differ on every machine and run; the `...` lines stand for stack frames):
```text
==================
WARNING: DATA RACE
Write at 0x00c000012345 by goroutine 8:
  main.(*RacyCounter).Inc()
      /home/you/code101/go301/lesson02/counter.go:21 +0x...
  main.hammer.func1()
      /home/you/code101/go301/lesson02/counter.go:...
  ...

Previous write at 0x00c000012345 by goroutine 7:
  main.(*RacyCounter).Inc()
      /home/you/code101/go301/lesson02/counter.go:21 +0x...
  ...

Goroutine 8 (running) created at:
  main.hammer()
      /home/you/code101/go301/lesson02/counter.go:...
  ...
==================
racy counter: <a number> (a correct counter would print 8000)
Found 1 data race(s)
exit status 66
```
`exit status 66` is the race detector's default exit code (set with `GORACE="exitcode=..."`). Now the other two, and the safe mode and the tests under the detector:

**File: terminal (not a saved file)**
```text
go run -race . racy-publish
go run -race . racy-map
go run -race .
go test -race ./...
```
Expected: the first two print `WARNING: DATA RACE` reports (the map one may instead stop with the runtime's own fatal error before the detector prints); the last two print no warning, and `go test` ends with a line starting `ok` followed by the module path and a duration.

## How it works
### The memory model in five sentences
1. A **data race** is two goroutines accessing the same variable concurrently, at least one of them writing, with no synchronisation between them. (This is the definition in the official race detector article.)
2. The Go memory model defines **happens before**: if event A happens before event B, then B is guaranteed to observe A's effects. Without such an ordering, B may observe the old value, the new one, or (for multi-word values) a torn mix.
3. Ordering comes only from **synchronisation events**: a `go` statement happens before the new goroutine starts; a send on a channel happens before the matching receive completes; closing a channel happens before a receive that returns because of the close; `Unlock` happens before the next `Lock`; `Once` completion happens before any `Do` returns; `WaitGroup.Done` happens before the `Wait` it releases; operations in `sync/atomic` behave as sequentially consistent.
4. Goroutine **exit** is *not* a synchronisation event: nothing orders the end of a goroutine before anything else unless you use one of the above.
5. If a program has no data races, it behaves as if its goroutines were interleaved one step at a time, which is the model your intuition already has. If it has a race, the specification says much less: a compiler optimisation or CPU reordering you did not expect becomes allowed. Races on values that fit in one machine word cannot create values nobody wrote, but races on strings, slices and interface values can corrupt memory, because those are several words written one after another.

The authoritative text is [The Go Memory Model](https://go.dev/ref/mem). Read it once, slowly.

### How the detector works, and what it cannot do
`-race` rebuilds your program with extra instrumentation: every memory access and every synchronisation event is recorded, and the runtime library checks whether two accesses to one location are ordered by happens-before. When they are not, it prints the report.
- It reports a race only when it **observes** one in this run. It cannot find races on code paths your tests or workload never execute, nor races that this particular scheduling happened to avoid. **No report is not a proof of safety.**
- A report is a real unordered pair of accesses, not a guess, which is why a report must never be dismissed as "benign". Even races on a plain `bool` or `int` interact with compiler optimisation and CPU ordering, as the official documentation says.
- It has a **cost**. The official documentation says that for a typical program memory usage may increase by 5 to 10 times and execution time by 2 to 20 times. So: tests and staging load tests, yes; the default production binary, normally no.
- It needs cgo and a C compiler (see Before you start) and supports a limited list of platform pairs (among them `linux/amd64`, `linux/arm64`, `darwin/arm64` and `windows/amd64`).

### Reading a report
1. The first stack, labelled `Write at` or `Read at`, is the access the detector caught **now**; the second, `Previous write at` (or read), is the earlier conflicting access. Both addresses are the same: the same variable.
2. Read each stack **from the top**: the first frame is the exact line of the conflicting access. The frames below show who called it.
3. `Goroutine N (running) created at:` tells you **which `go` statement** started each goroutine; that is how you find the code that must add the synchronisation.
4. The program keeps running unless you set `GORACE="halt_on_error=1"`; at exit the status is 66 (so CI fails), after `Found N data race(s)`.
Other useful `GORACE` options from the official list: `log_path` (write reports to a file, for example in CI artefacts), `strip_path_prefix` (shorter paths), `history_size` (raise it if a report says it "failed to restore the stack").

### Which fix? A decision table
| Situation | Prefer | Why | Trade-off |
|---|---|---|---|
| Several fields must change together (invariant) | `sync.Mutex` | one critical section protects the whole invariant | contention; hold the lock briefly; never call out to unknown code while holding it |
| A single counter or flag | `sync/atomic` types (`atomic.Int64`, `atomic.Bool`) | lock-free, no lock to forget | cannot protect two related values; easy to misuse beyond one variable |
| Read-mostly shared map | `sync.RWMutex`, or copy-on-write behind an `atomic.Pointer` | readers do not block each other | measure: RWMutex can be slower than Mutex for short sections |
| Handing ownership of data from one goroutine to another | channel | transfer of ownership is the synchronisation | channels have overhead; a closed channel cannot be reused |
| One-time initialisation | `sync.Once` / `sync.OnceValue` | exactly once, and the result is published safely | the initialiser's error handling is on you (`OnceValues` for `(T, error)`) |
| Each goroutine writes its own slot | indexed slice (lesson 01) | no sharing at all | requires known size |
Rule of thumb: share memory by **communicating** when ownership moves, and protect shared memory with a **mutex** when many goroutines legitimately touch the same state.

## Decision record (ADR style)
**ADR-02: run the race detector in CI on every change; do not ship race builds by default.**
- Context: the team has had two production incidents from unsynchronised maps; the test suite is fast enough to run twice.
- Decision: CI runs `go test -race ./...` on the main platforms; a nightly job runs integration tests against a `-race` binary under a recorded workload; production images are built without `-race`.
- Consequences: CI time and memory increase (record both before and after, do not guess); data races found in CI are fixed, never skipped with build tags unless an issue is filed; a canary instance with `-race` is allowed if you have measured that its slowdown is acceptable.
- Rejected: "only run it before release" (races are cheapest to fix on the commit that introduced them).

**When not to reach for `-race` first**
- You suspect a *logic* error, not a race: the detector will say nothing. Use tests and logs.
- The bug is a **deadlock** or a **leak**: use a goroutine profile (lesson 03) or `GOTRACEBACK=all` and a stack dump (send `SIGQUIT` on Linux/macOS).
- You are checking for lock-ordering mistakes: the detector finds races, not deadlocks.

## Failure modes
| Failure | Symptom | Prevention |
|---|---|---|
| "Benign" race on a flag or counter | works for months, then loses counts or hangs after a compiler upgrade | no race is benign; use atomics |
| Copying a `sync.Mutex` by value | the copy has its own lock, so nothing is protected | pass pointers; `go vet` has a `copylocks` check |
| Lock held while calling unknown code | deadlock or long stalls | copy the data out, release the lock, then call |
| Locking some accesses but not all | race on the one that forgot | make the field unexported and reach it only through methods |
| Skipping flaky `-race` tests | the race ships | fix it; track exclusions with an issue number |
| Reading a map while another goroutine writes | `fatal error: concurrent map read and map write` (typical message) | `RWMutex`, or `sync.Map` for the narrow cases it was designed for (append-only or disjoint keys) |

## Measurements to take
1. Time and peak memory of your test suite with and without `-race`, on your CI runner. Report both; the official ratios (2 to 20 times time, 5 to 10 times memory) are only a warning to budget for.
2. How many races the detector finds when you run your service under a **realistic** workload for 10 minutes (an hour is better) in a staging environment. Zero in unit tests does not mean zero here.
3. Lock contention: `go test -bench` with `-cpu 1,2,4,8` for the shared structure, or the **mutex profile** (lesson 03). If adding CPUs does not add throughput, the lock is the bottleneck.

## Production checklist
- [ ] `go test -race ./...` is a required CI check on Linux (and where you support others).
- [ ] No test is excluded with `//go:build !race` without a linked issue.
- [ ] Every exported type that holds shared state documents its concurrency rule ("safe for concurrent use" or "not safe").
- [ ] `go vet ./...` runs in CI (it finds copied locks and misplaced `WaitGroup.Add`).
- [ ] Maps and slices shared across goroutines are behind a lock, a channel or an atomic pointer.
- [ ] A long-running soak or load test runs a `-race` binary at least before major releases.

## Try it
Copy `exercise/starter` next to your lesson folder and rename the copy `try02` (the folder `try02` must directly contain `go.mod` and `main.go`).

**File: `exercise/starter/main.go`**
```go
package main

import (
	"fmt"
	"sync"
)

type Account struct {
	balance int
}

// TODO 1: add a sync.Mutex field and use it in both methods so that the
// balance printed by main is always 4000 and `go run -race .` reports nothing.
func (a *Account) Deposit(n int) { a.balance += n }
func (a *Account) Balance() int  { return a.balance }

func main() {
	acc := &Account{}
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			for range 500 {
				acc.Deposit(1)
			}
		})
	}
	wg.Wait()
	fmt.Println("balance:", acc.Balance())
}
```
1. **Guided.** First run `go run -race .` on the unchanged starter and find the two conflicting lines in the report (you should see `Deposit` in both stacks). Then fix it with a mutex. Goal output, and no warning with `-race`:
```text
balance: 4000
```
2. **Change.** Replace the mutex with `atomic.Int64`. Which method no longer needs a lock, and what would you lose if the account also had an `owner` string that must change together with the balance?
3. **Stretch (design).** Add `Transfer(from, to *Account, n int)` that locks both accounts. Two goroutines call `Transfer(a, b, 1)` and `Transfer(b, a, 1)` at the same time. Describe how it can deadlock and one rule (for example "always lock the account with the lower id first") that prevents it. Which tool in this lesson would **not** reveal the deadlock?

<details><summary>Solution</summary>

**File: `exercise/solution/main.go` (changed region: the type and its methods)**
```go
type Account struct {
	mu      sync.Mutex
	balance int
}

func (a *Account) Deposit(n int) {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.balance += n
}

func (a *Account) Balance() int {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.balance
}
```
`main` is unchanged. For rung 2, `Deposit` becomes `a.balance.Add(int64(n))` and `Balance` becomes `int(a.balance.Load())`, with no mutex. With an `owner` field that must change together with the balance you would need a mutex again, because two atomics are not one atomic operation. For rung 3, with `Transfer(a, b)` locking `a` then `b` while the other goroutine locks `b` then `a`, each holds one lock and waits for the other: a deadlock. A global lock order breaks the cycle. The race detector does not report deadlocks.
</details>

## Check yourself
1. Name the three steps hidden inside `c.n++` and say how two goroutines lose an increment. <details><summary>Answer</summary>Read, add, write. Both read 41, both write 42.</details>
2. In `safePublish`, which single operation makes the read of `msg` safe? <details><summary>Answer</summary>`close(done)` followed by the receive `<-done`: the close happens before the receive that observes it.</details>
3. The detector prints nothing on your test run. What can you conclude? <details><summary>Answer</summary>Only that this run observed no race. Code paths not executed, or schedules that did not occur, are unchecked.</details>
4. Predict: what exit status does `go run -race .` give if a race is reported, and how do you change it? <details><summary>Answer</summary>The program exits with status 66 (shown by `go run` as `exit status 66`); `GORACE="exitcode=N"` changes it.</details>
5. Why does the lesson's test file contain no racy test? <details><summary>Answer</summary>A racy test fails under `-race`, and `-race` is a required CI check.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: -race requires cgo; enable cgo by setting CGO_ENABLED=1` (typical message) | cgo is off or there is no C compiler | install a C compiler; set `CGO_ENABLED=1` (PowerShell `$env:CGO_ENABLED = "1"`; bash `export CGO_ENABLED=1`) |
| `-race` fails to link on Windows | the C compiler's mingw-w64 runtime is older than version 8 | install a newer mingw-w64 gcc, or use WSL2 |
| `go run -race .` is much slower | expected: instrumentation overhead | measure it; use `-race` for tests, not for benchmarks |
| The race report shows only runtime frames | the race is in a library you did not write | read downward to the first frame in your code and check how you share the object |
| `fatal error: concurrent map writes` (typical message) | plain map written by two goroutines | guard with a mutex |
| Test passes with `-race` but the service still has a race | the path was not exercised | run the `-race` binary under a realistic workload |
| `unknown mode "x": use safe, racy-counter, racy-publish or racy-map` | a mode name was mistyped | use one of the four names |

## Best practice
Treat every data-race report as a bug to fix, run `go test -race` in CI, and never rely on a "benign" race. Source: Data Race Detector, https://go.dev/doc/articles/race_detector

## Going further
- The Go Memory Model: https://go.dev/ref/mem
- Data Race Detector (requirements, options, typical races): https://go.dev/doc/articles/race_detector
- `sync/atomic` and `sync` package reference: https://pkg.go.dev/sync/atomic and https://pkg.go.dev/sync
- Go 1.25 added `testing/synctest` for testing time-dependent concurrent code without real sleeps: https://pkg.go.dev/testing/synctest
- Where the capstone protects shared state: [Go backend capstone, chapter 05 (JWKS cache)](../../../../capstones/backend-go/tutorials/phase-3-identity/05-jwt-and-roles.md).

## Summary
- You defined a data race and used happens-before to explain which versions are safe.
- You ran racy code under `-race` and read the report: the two accesses, the two goroutine creation points and the exit status 66.
- You fixed races with a mutex, an atomic, a channel close, `RWMutex` and `OnceValue`, and chose between them with a table.
- You can state what the detector cannot prove, what it costs and where it belongs in CI.

## Next lesson
03. Profiling with pprof and benchmarks: how to find where time and memory go, with measurements you take yourself.
