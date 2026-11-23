---
track: python
level: 301
phase: 2
phase_name: performance-and-concurrency
lesson: '04'
title: "Concurrency models: GIL, threads, processes, asyncio and free-threaded builds"
time: "85 min"
prerequisites: [201.2.05, 301.1.03]
versions: { python: "3.14 or newer (an optional free-threaded build)", dependencies: "standard library only" }
verified: not yet run
source: source/python/301-super-hero-to-legendary/phase-2-performance-and-concurrency/04-concurrency-models/
assets: []
---

# 04. Concurrency models: GIL, threads, processes, asyncio and free-threaded builds

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain what the global interpreter lock (GIL) protects and what it does not, using a runnable race.
- Choose threads, processes, asyncio or a free-threaded build for a given workload, with the cost of each.
- Measure, on your own machine, whether a workload scales with threads or processes.
- Say precisely what changes and what stays the same in a free-threaded build.

## Recap
1. Python 201 lesson 05: what does `await` do to the event loop while the awaited operation waits?
   <details><summary>Answer</summary>It lets the loop run other ready tasks. That only helps if the awaited operation is genuinely non-blocking.</details>
2. Lesson 03: why does `create_v1` take a `threading.Lock`?
   <details><summary>Answer</summary>FastAPI runs sync handlers in a thread pool, so two requests can run the "look up key, then create" sequence at the same time.</details>

## Why it matters
"Python is single-threaded" and "just add threads" are both wrong, and both lead to production incidents: a service that stays at 100% of one core while others idle, a worker pool that doubles latency because a blocking call froze the event loop, a data race that appears only on a free-threaded build. The right model depends on the **kind of waiting** your code does. This lesson gives you the vocabulary, four small experiments, and a decision table.

## What you will build
Five small scripts, no dependencies:

| Script | Question it answers |
|---|---|
| `gil_check.py` | Which kind of interpreter am I running, and is the GIL on? |
| `race.py` | What does a data race look like, and what does a lock fix? |
| `bench.py` | Do threads or processes speed up my CPU-bound or I/O-bound work? |
| `loop_lag.py` | How badly does one blocking call hurt an asyncio loop? |
| `test_concurrency.py` | Do all models give the same answers? (Correctness first.) |

## Before you start
- **Prerequisites:** [Python 301 lesson 03, API design at scale](../phase-1-architecture/03-api-design-at-scale.md) and [Python 201 lesson 05, async and asyncio](../../201-hero-to-super-hero/phase-2-concurrency-and-packaging/05-async-and-asyncio.md).
- Time: 85 min including the measurements. Break after Step 5.
- Python **3.14 or newer**, standard library only. Windows `py -3.14`, macOS and Linux `python3.14`. A machine with at least 2 cores gives the more interesting results.
- Optional: a **free-threaded** build of the same version (`python3.14t`, on Windows `py -3.14t`) if your installer offers it. The official installers for macOS and Windows can install it; see the Python free-threading HOWTO linked at the end. Every step works without it.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/python/301-super-hero-to-legendary/phase-2-performance-and-concurrency/04-concurrency-models/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- Close heavy programs while measuring. Numbers from a busy laptop on battery are not comparable with numbers from an idle one.

## Steps
### Step 1. Create the workspace
**PowerShell - folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/python301/lesson04" -Force | Out-Null
Set-Location "$HOME/code101/python301/lesson04"
code .
```

**macOS/Linux - folder: anywhere**
```bash
mkdir -p ~/code101/python301/lesson04
cd ~/code101/python301/lesson04
code .
```
Create the files below in this folder (flat). If lost: `cd ~/code101/python301/lesson04`.

### Step 2. Two workloads that wait in different ways
**File: `workloads.py`**
```python
import time


def cpu_work(n: int) -> int:
    total = 0
    for i in range(n):
        total += i * i % 7
    return total


def io_work(seconds: float) -> float:
    time.sleep(seconds)
    return seconds
```
`cpu_work` keeps the processor busy running Python bytecode. `io_work` stands in for a network call or a disk wait: `time.sleep` releases the GIL while sleeping, exactly as a socket read does.

### Step 3. Which interpreter is this?
**File: `gil_check.py`**
```python
import sys
import sysconfig

free_threaded_build = bool(sysconfig.get_config_var("Py_GIL_DISABLED"))
gil_enabled = sys._is_gil_enabled() if hasattr(sys, "_is_gil_enabled") else True

print("python:", sys.version.split()[0])
print("free-threaded build:", free_threaded_build)
print("GIL enabled now:", gil_enabled)
```
`sysconfig.get_config_var("Py_GIL_DISABLED")` is `1` on a build that supports free threading, which is the documented way to test for it. `sys._is_gil_enabled()` reports whether the GIL is actually on in this process. A free-threaded build can re-enable the GIL at start-up (`PYTHON_GIL=1` or `-X gil=1`) or automatically when an incompatible extension module is imported, so the two answers can differ.

**PowerShell - folder: `~/code101/python301/lesson04`**
```powershell
py -3.14 gil_check.py
```

**macOS/Linux - folder: `~/code101/python301/lesson04`**
```bash
python3.14 gil_check.py
```
Expected output on a standard build, not yet run (the version number is whatever you have installed):
```text
python: 3.14.<patch>
free-threaded build: False
GIL enabled now: True
```
On a free-threaded build you expect `free-threaded build: True` and `GIL enabled now: False`, unless an extension re-enabled it.

### Step 4. A race, and the lock that fixes it
**File: `race.py`**
```python
import threading

THREADS = 4
PER_THREAD = 100_000


def count(use_lock: bool, threads: int = THREADS, per_thread: int = PER_THREAD) -> int:
    counter = 0
    lock = threading.Lock()

    def work() -> None:
        nonlocal counter
        for _ in range(per_thread):
            if use_lock:
                with lock:
                    counter += 1
            else:
                counter += 1

    workers = [threading.Thread(target=work) for _ in range(threads)]
    for worker in workers:
        worker.start()
    for worker in workers:
        worker.join()
    return counter


if __name__ == "__main__":
    expected = THREADS * PER_THREAD
    print("expected:", expected)
    print("with lock:", count(True))
    print("without lock never above expected:", count(False) <= expected)
```
`counter += 1` is **not atomic**: it reads the value, adds one, and writes it back. Two threads can read the same value and both write the same result, losing one increment. Predict first: will `count(False)` be exactly 400000 on your machine? (The honest answer: it may be, because the GIL makes a switch between those steps rare; it is **never guaranteed**, and on a free-threaded build losing updates is much easier to observe.)

**PowerShell - folder: `~/code101/python301/lesson04`**
```powershell
py -3.14 race.py
```

**macOS/Linux - folder: `~/code101/python301/lesson04`**
```bash
python3.14 race.py
```
Expected output, not yet run:
```text
expected: 400000
with lock: 400000
without lock never above expected: True
```
The script prints the *property that always holds* (never above expected), not the lost-update count, because the count differs on every run and the whole point is that it is not reliable. Edit the last line to print `count(False)` and run it a few times to see the variation on your machine.

### Step 5. Measure threads and processes
**File: `bench.py`**
```python
import os
import sys
import time
from collections.abc import Callable, Sequence
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor

from workloads import cpu_work, io_work

CPU_JOBS = [2_000_000] * 4
IO_JOBS = [0.5] * 4


def run_serial(fn: Callable, jobs: Sequence) -> list:
    return [fn(job) for job in jobs]


def run_threads(fn: Callable, jobs: Sequence) -> list:
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        return list(pool.map(fn, jobs))


def run_processes(fn: Callable, jobs: Sequence) -> list:
    with ProcessPoolExecutor(max_workers=len(jobs)) as pool:
        return list(pool.map(fn, jobs))


def timed(label: str, runner: Callable, fn: Callable, jobs: Sequence) -> list:
    start = time.perf_counter()
    results = runner(fn, jobs)
    elapsed = time.perf_counter() - start
    print(f"{label:<10}{elapsed:7.2f} s")
    return results


def main(kind: str) -> None:
    if kind not in ("cpu", "io"):
        raise SystemExit("usage: python bench.py cpu|io")
    fn, jobs = (cpu_work, CPU_JOBS) if kind == "cpu" else (io_work, IO_JOBS)
    print(f"{kind} workload, {len(jobs)} jobs, {os.cpu_count()} logical CPUs")
    serial = timed("serial", run_serial, fn, jobs)
    threads = timed("threads", run_threads, fn, jobs)
    processes = timed("processes", run_processes, fn, jobs)
    print("same results:", serial == threads == processes)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "cpu")
```
Four identical jobs run three ways. The `if __name__ == "__main__":` guard is **mandatory** here: on Windows and macOS (and on Linux from Python 3.14, where the default start method is no longer `fork`; check the `multiprocessing` documentation for your version) child processes import this file, and without the guard each child would start more children.

Before you run: for `cpu`, predict the ranking of the three timings on a standard build. For `io`, predict it again. Write your guesses down.

**PowerShell - folder: `~/code101/python301/lesson04`**
```powershell
py -3.14 bench.py cpu
py -3.14 bench.py io
```

**macOS/Linux - folder: `~/code101/python301/lesson04`**
```bash
python3.14 bench.py cpu
python3.14 bench.py io
```
Expected output **shape**, not yet run. The numbers are yours to record; the shape is what to check:
```text
cpu workload, 4 jobs, <N> logical CPUs
serial       <seconds> s
threads      <seconds> s
processes    <seconds> s
same results: True
```
The last line is always `same results: True`; correctness does not depend on the model. Copy this table into your notes and fill it from your two runs:

| Workload | serial | threads | processes | Ratio threads / serial | Ratio processes / serial |
|---|---|---|---|---|---|
| cpu | | | | | |
| io | | | | | |

What to expect to **see** (the pattern, not the values): on a standard build the `cpu` threads row is close to the serial row because only one thread runs bytecode at a time, while the processes row drops if you have several free cores; the `io` threads row is about a quarter of serial because sleeping threads do not hold the GIL. Process start-up and result pickling mean processes lose on tiny jobs: re-run `cpu` with `CPU_JOBS = [20_000] * 4` to find your own crossover.

Run the same two commands on a free-threaded interpreter if you have one (`py -3.14t bench.py cpu`). The question to answer from your own numbers: do the threads now beat serial for CPU-bound work?

**Stop here for a break if you like.**

### Step 6. Block an event loop, then fix it
**File: `loop_lag.py`**
```python
import asyncio
import time
from collections.abc import Awaitable, Callable


def blocking_call() -> None:
    time.sleep(0.3)


async def ticker(stop: asyncio.Event) -> float:
    worst = 0.0
    last = time.perf_counter()
    while not stop.is_set():
        await asyncio.sleep(0.01)
        now = time.perf_counter()
        worst = max(worst, now - last)
        last = now
    return worst


async def blocks_the_loop() -> None:
    blocking_call()


async def offloaded_to_a_thread() -> None:
    await asyncio.to_thread(blocking_call)


async def measure(label: str, work: Callable[[], Awaitable[None]]) -> None:
    stop = asyncio.Event()
    watcher = asyncio.create_task(ticker(stop))
    await asyncio.sleep(0.05)
    await work()
    stop.set()
    worst = await watcher
    print(f"{label}: loop stalled for more than 0.2 s: {worst > 0.2}")


async def main() -> None:
    await measure("blocking call in a coroutine", blocks_the_loop)
    await measure("asyncio.to_thread", offloaded_to_a_thread)


if __name__ == "__main__":
    asyncio.run(main())
```
`ticker` is a heartbeat: it wakes every 10 ms and records the longest gap between wake-ups. In a healthy loop the gap stays near 10 ms. In `blocks_the_loop` the coroutine never yields while `time.sleep` runs, so *every other task on the loop*, including the heartbeat, waits 0.3 s. `asyncio.to_thread` runs the blocking call in a worker thread and awaits it, so the loop stays responsive.

**PowerShell - folder: `~/code101/python301/lesson04`**
```powershell
py -3.14 loop_lag.py
```

**macOS/Linux - folder: `~/code101/python301/lesson04`**
```bash
python3.14 loop_lag.py
```
Expected output, not yet run:
```text
blocking call in a coroutine: loop stalled for more than 0.2 s: True
asyncio.to_thread: loop stalled for more than 0.2 s: False
```
The first line is guaranteed (the call blocks for 0.3 s). The second is the typical result; a machine so loaded that the heartbeat is delayed by 0.2 s would print `True`, which is itself a useful reading.

### Step 7. Correctness tests
**File: `test_concurrency.py`**
```python
import unittest

from bench import run_processes, run_serial, run_threads
from race import count
from workloads import cpu_work, io_work


class WorkloadTests(unittest.TestCase):
    def test_cpu_work_is_deterministic(self) -> None:
        self.assertEqual(cpu_work(10), 19)

    def test_io_work_returns_what_it_slept(self) -> None:
        self.assertEqual(io_work(0.01), 0.01)


class RunnerTests(unittest.TestCase):
    JOBS = [10, 20, 30]

    def test_every_model_returns_the_same_results_in_the_same_order(self) -> None:
        expected = run_serial(cpu_work, self.JOBS)
        self.assertEqual(run_threads(cpu_work, self.JOBS), expected)
        self.assertEqual(run_processes(cpu_work, self.JOBS), expected)


class RaceTests(unittest.TestCase):
    def test_a_lock_makes_the_count_exact(self) -> None:
        self.assertEqual(count(True, threads=4, per_thread=10_000), 40_000)

    def test_without_a_lock_the_count_is_never_above_expected(self) -> None:
        self.assertLessEqual(count(False, threads=4, per_thread=10_000), 40_000)


if __name__ == "__main__":
    unittest.main()
```
`cpu_work(10)` is 19: the squares 0, 1, 4, 9, 16, 25, 36, 49, 64, 81 modulo 7 are 0, 1, 4, 2, 2, 4, 1, 0, 1, 4, which add up to 19. Notice what the tests deliberately do **not** assert: they never assert that a race *loses* updates, because a test that depends on a race is flaky.

**PowerShell - folder: `~/code101/python301/lesson04`**
```powershell
py -3.14 -m unittest -v
```

**macOS/Linux - folder: `~/code101/python301/lesson04`**
```bash
python3.14 -m unittest -v
```
Expected output, not yet run: five tests ending in `ok`, then `Ran 5 tests in <time>s` and `OK`.

## How it works
### What each model is
| Model | What runs in parallel | Cost | Good for | Bad for |
|---|---|---|---|---|
| **Threads** (`threading`, `ThreadPoolExecutor`) | OS threads; on a standard build only one runs Python bytecode at a time, but threads overlap while blocked in I/O or in C code that releases the GIL | Low start-up, shared memory, needs locks for shared mutable state | Blocking I/O with libraries that are not async, a handful of concurrent calls | CPU-bound Python on a standard build |
| **Processes** (`multiprocessing`, `ProcessPoolExecutor`) | Separate interpreters, real parallelism | Start-up time, arguments and results are pickled, memory is duplicated, no shared state | CPU-bound work, isolation from crashes and leaks | Many tiny jobs, large objects passed back and forth |
| **asyncio** | One thread, many tasks that cooperatively yield at `await` | Everything on the path must be async-aware; one blocking call stalls all tasks | Thousands of concurrent sockets; the typical API gateway | CPU-bound work; code that uses blocking libraries |
| **Free-threaded build** | Threads run Python bytecode in parallel | Extra per-thread bookkeeping, extension modules must opt in, you must now reason about races | CPU-bound work that is awkward to split into processes (large shared in-memory data) | Code and dependencies that assume the GIL protects them |

### What the GIL is, exactly
The **global interpreter lock** is a lock inside the CPython interpreter. It makes the interpreter's internal data structures, in particular reference counts, safe without a lock on every object. It means that on a standard build only one thread executes Python bytecode at any instant. It does **not** make your code thread-safe: the interpreter can switch threads between the read and the write of `counter += 1`. A single bytecode instruction is the unit that is not interrupted, not a line of your code.

### What changes in a free-threaded build (and what does not)
The Python documentation describes free threading as available since 3.13 (experimental) and made *officially supported but still optional* by [PEP 779](https://peps.python.org/pep-0779/) for 3.14. Read the current free-threading HOWTO for your exact version, because the details move.

| Aspect | Standard build | Free-threaded build |
|---|---|---|
| Parallel Python threads | No | Yes |
| Built-in `dict`, `list`, `set` | Safe for single operations | Still protected by internal locks, per the docs; compound operations (`check then update`) are still your problem |
| `counter += 1` from two threads | Racy, rarely visible | Racy, easier to see |
| Single-thread speed | Baseline | Extra overhead. The docs state the overhead on the pyperformance suite averages about 1% on macOS aarch64 to 8% on x86-64 Linux; **measure your workload** |
| C extensions | Work | Must declare support, otherwise the interpreter turns the GIL back on for the process with a warning |
| Sharing one iterator between threads | Possible but unsafe | Documented as unsafe; threads may see duplicate or missing items |
| Context variables in new threads | Thread starts with an empty context by default | `thread_inherit_context` is on by default, so a new `threading.Thread` starts with a copy of the creator's context (this changes behaviour of code that relies on empty contexts) |
| `asyncio` | One loop, one thread | Same model. Free threading does not make a coroutine run faster; it lets *several loops or threads* run in parallel |
| Multiple processes | Unchanged | Unchanged. A web server with several worker processes still isolates faults and memory |

The *what does not change* column matters most: your data-race bugs, your blocking-in-async bugs and your need for locks exist today. A free-threaded build mostly turns rare races into frequent ones.

**Sub-interpreters.** Python 3.14 also adds `concurrent.interpreters` and `concurrent.futures.InterpreterPoolExecutor`: several interpreters, each with its own state, in one process. Treat them as a newer option to evaluate, not a default.

### Misconception to correct
"asyncio makes my code parallel." It does not. It interleaves tasks on **one thread**. It scales waiting, not computing.

## Decision record (ADR-004)
| | |
|---|---|
| **Context** | An API service mixes I/O waits (database, partner APIs) with occasional CPU work (report generation, image resizing). |
| **Decision** | Run N worker **processes** (one per core as a first guess) each running an **asyncio** server. Use async drivers for I/O. Send blocking library calls to a bounded thread pool (`asyncio.to_thread` or `run_in_executor`). Send CPU-heavy jobs to a queue and a separate worker pool (lesson 06). Do not adopt a free-threaded interpreter in production until every dependency in the lock file has been tested on it. |
| **Consequences** | Predictable failure isolation and scaling. Memory is per process. Total database connections = processes x pool size, so the pool must be sized accordingly. |
| **Alternatives rejected** | Threads only (hits the GIL for the CPU work and the per-thread memory of many sockets). One big process on a free-threaded build (promising, but ecosystem support and operational experience are the open cost today). |

## When not to use each
- **Do not use processes** for jobs shorter than a few milliseconds, or when each job needs a large object: pickling costs more than the work.
- **Do not use threads** to speed up pure-Python loops on a standard build.
- **Do not use asyncio** for a service whose I/O libraries are blocking only and whose concurrency is a dozen requests: a thread pool is simpler and has less to get wrong.
- **Do not use a free-threaded build** when a dependency lacks support, or when single-thread latency is your main metric and you have not measured the overhead.
- **Do not use `fork` in a process that already has threads.** Forking a multi-threaded process can copy a held lock into the child and deadlock it; this is part of why default start methods have been changing.

## What to measure
- CPU utilisation per core while a load test runs. One core at 100% and the rest idle on a standard build means you are GIL-bound.
- Event-loop lag: the same heartbeat idea as `loop_lag.py`, exported as a metric (lesson 07). A rising p99 lag means something blocks the loop.
- The size of each pool compared to the number of database connections it can open.
- For any proposed move (threads to processes, standard to free-threaded): the same load test before and after, with your real dependencies, recording median and 95th-percentile latency and throughput. Do not publish a claim without the numbers from your own hardware.

## Production checklist
- [ ] Every blocking call inside `async def` is found (tools: asyncio debug mode and a lag metric) and offloaded or replaced.
- [ ] Thread pools and process pools have explicit maximum sizes; unbounded pools turn load spikes into outages.
- [ ] Shared mutable state is either avoided, protected by a lock, or owned by one task.
- [ ] Worker processes handle `SIGTERM` and drain in-flight work.
- [ ] Database pool size x processes is below the database's connection limit.
- [ ] Anything started with `multiprocessing` is protected by `if __name__ == "__main__":`.
- [ ] A free-threaded trial, if any, ran the full test suite and a soak test, and recorded which packages re-enabled the GIL.

## Try it
Starter: `exercise/starter/exercise.py`. Copy the `starter` folder itself and rename the copy `try04`, then work in `try04`.
1. **Guided:** implement `parallel_map` so that `"io"` uses threads, `"cpu"` uses processes and anything else raises `ValueError`.
2. **Change:** add a `max_workers` parameter with a default of `4` and make `parallel_map` refuse (raise `ValueError`) a non-positive value. Why is a default cap safer than `os.cpu_count()` inside a container?
3. **Stretch (no single answer):** your service calls a blocking partner SDK (about 200 ms per call) from 50 concurrent requests. Compare `asyncio.to_thread` with the default executor, a dedicated `ThreadPoolExecutor(max_workers=16)` and an async rewrite of the SDK. For each, say what limits throughput and how you would observe that limit.

**File: `exercise/starter/exercise.py`**
```python
import time
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor


def square(n: int) -> int:
    return n * n


def slow_upper(text: str) -> str:
    time.sleep(0.01)
    return text.upper()


def parallel_map(fn, items, kind: str) -> list:
    # TODO 1: for kind == "io" use a ThreadPoolExecutor
    # TODO 2: for kind == "cpu" use a ProcessPoolExecutor
    # TODO 3: for any other kind raise ValueError(f"unknown kind: {kind}")
    # Return list(pool.map(fn, items)) so the results keep the input order.
    raise NotImplementedError


if __name__ == "__main__":
    print("cpu", parallel_map(square, [1, 2, 3], "cpu"))
    print("io", parallel_map(slow_upper, ["a", "b"], "io"))
    try:
        parallel_map(square, [1], "gpu")
    except ValueError as error:
        print(error)
```
Expected output once complete:
```text
cpu [1, 4, 9]
io ['A', 'B']
unknown kind: gpu
```

<details><summary>Solution</summary>

**File: `exercise/solution/exercise.py`** (only `parallel_map` differs)
```python
def parallel_map(fn, items, kind: str) -> list:
    if kind == "io":
        pool_class = ThreadPoolExecutor
    elif kind == "cpu":
        pool_class = ProcessPoolExecutor
    else:
        raise ValueError(f"unknown kind: {kind}")
    with pool_class() as pool:
        return list(pool.map(fn, items))
```
The kind is checked **before** any pool is created, so a bad value costs nothing. `pool.map` returns results in input order even when jobs finish out of order.

</details>

## Check yourself
1. Does the GIL make `counter += 1` safe? Why or why not?
   <details><summary>Answer</summary>No. The statement is several bytecode steps (read, add, write) and the interpreter may switch threads between them. The GIL protects interpreter internals, not your logic.</details>
2. For four 0.5 s `time.sleep` jobs, which finishes fastest on a standard build, serial, threads or processes, and why are threads enough?
   <details><summary>Answer</summary>Threads and processes both take about a quarter of serial time. Sleeping releases the GIL, so threads overlap. Threads are cheaper.</details>
3. Predict: one coroutine calls `requests.get(...)` (a blocking call) inside an asyncio server. What happens to other requests during the call?
   <details><summary>Answer</summary>They wait. The loop cannot run any other task until the call returns, exactly like `blocks_the_loop`.</details>
4. Name two things that do not change on a free-threaded build.
   <details><summary>Answer</summary>The need for locks around compound operations, and the asyncio single-thread-per-loop model. Also: blocking calls in coroutines still stall that loop.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `RuntimeError: An attempt has been made to start a new process before the current process has finished its bootstrapping phase.` (typical message) | `multiprocessing` code without the `if __name__ == "__main__":` guard | Put the entry point under the guard |
| `ModuleNotFoundError: No module named 'workloads'` | The terminal is not in `lesson04` | `cd ~/code101/python301/lesson04` |
| `AttributeError: Can't get local object ...` or `Can't pickle local object ...` (typical message) | A lambda or nested function was passed to a process pool | Use a function defined at module level |
| The `cpu` threads timing equals the serial timing | You are on a standard build; expected | Use processes, or try a free-threaded build |
| `processes` is slower than `serial` | The jobs are too small to pay for start-up and pickling | Make the jobs larger, or use threads |
| `RuntimeWarning: coroutine '...' was never awaited` | A coroutine was called without `await` or a task | Await it or schedule it with `asyncio.create_task` |

## Best practice
Choose the model by the kind of waiting, bound every pool, never block an event loop, and verify every claim with a measurement from your own hardware. Source: Python free-threading HOWTO https://docs.python.org/3/howto/free-threading-python.html ; `concurrent.futures` https://docs.python.org/3/library/concurrent.futures.html ; asyncio, running blocking code https://docs.python.org/3/library/asyncio-dev.html#running-blocking-code ; PEP 703 https://peps.python.org/pep-0703/ and PEP 779 https://peps.python.org/pep-0779/

## Going further
- Turn on asyncio debug mode (`PYTHONASYNCIODEBUG=1` or `asyncio.run(main(), debug=True)`) and read how it reports slow callbacks.
- Check which of your dependencies support free threading at https://py-free-threading.github.io/tracking/ (a community tracker linked from the official HOWTO).
- The capstone runs Uvicorn in a container; compare its worker settings in [chapter 04](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-4-run-and-ship/04-run-and-ship.md).

## Summary
- You showed with a race and a lock what the GIL does and does not protect.
- You measured serial, thread and process timings for CPU-bound and I/O-bound work and recorded your own ratios.
- You demonstrated that a blocking call stalls an event loop and that `asyncio.to_thread` fixes it.
- You listed precisely what a free-threaded build changes and what it leaves alone.

## Next lesson
05. Profiling and optimisation: measure before optimising, with cProfile, a sampling profiler, memory profiling and caching with `lru_cache` and Redis.
