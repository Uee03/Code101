---
track: python
level: 301
phase: 2
phase_name: performance-and-concurrency
lesson: '05'
title: "Profiling and optimisation: measure first, cache second"
time: "90 min"
prerequisites: [301.2.04, 201.1.03]
versions: { python: "3.14 or newer", redis-py: "8.2.0", redis-server: "8.8 (Docker image)", dependencies: "standard library, plus redis only for the optional Redis step" }
verified: not yet run
source: source/python/301-super-hero-to-legendary/phase-2-performance-and-concurrency/05-profiling-and-optimisation/
assets: []
---

# 05. Profiling and optimisation: measure first, cache second

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Follow a measure, profile, change one thing, re-measure loop and keep a test that proves behaviour did not change.
- Use `cProfile`, a sampling profiler (`py-spy`) and `tracemalloc` and say what each can and cannot tell you.
- Apply `functools.lru_cache` and a TTL cache-aside with Redis, and name the failure modes of each.
- Decide when not to cache.

## Recap
1. Lesson 04: why did four 0.5 s sleeps finish in about a quarter of the serial time with threads?
   <details><summary>Answer</summary>Sleeping releases the GIL, so the waits overlap.</details>
2. Python 201 lesson 03: why does a generator use less memory than a list?
   <details><summary>Answer</summary>It produces one item at a time instead of materialising all of them.</details>
3. Lesson 04: which tool reports whether the event loop is being blocked?
   <details><summary>Answer</summary>A heartbeat task that records the longest gap between wake-ups (`loop_lag.py`).</details>

## Why it matters
Most optimisation effort is wasted on code that was not the bottleneck, and most caches add a correctness bug in exchange for a speed-up nobody measured. The senior skill is not knowing tricks; it is knowing **where the time goes** and **what a change costs**. Everything in this lesson is a way of replacing an opinion with a measurement.

## What you will build
A deliberately slow function (`customers_slow`, a list membership test inside a loop), a profile that points at it, a faster version, and a benchmark that compares both on the same data. Then a `lru_cache` demo, a TTL cache with an injectable clock (so tests need no sleeping), and an optional Redis-backed store started with Docker Compose.

## Before you start
- **Prerequisites:** [Python 301 lesson 04, concurrency models](04-concurrency-models.md) and [Python 201 lesson 03, iterators and generators](../../201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-generators.md).
- Time: 90 min. Break after Step 7. The Redis part (Steps 9 to 11) is optional and needs Docker.
- Python **3.14 or newer**; Windows `py -3.14`, macOS and Linux `python3.14`. Steps 2 to 9 use the standard library only.
- Optional: Docker with Compose v2 for the Redis step, and `pip install py-spy==0.4.4` in a virtual environment for the sampling profiler.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/python/301-super-hero-to-legendary/phase-2-performance-and-concurrency/05-profiling-and-optimisation/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- Rule for the whole lesson: **every timing in your notes comes from your machine**. This lesson never states a speed-up; it shows how to get yours.

## Steps
### Step 1. Create the workspace
**PowerShell - folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/python301/lesson05" -Force | Out-Null
Set-Location "$HOME/code101/python301/lesson05"
code .
```

**macOS/Linux - folder: anywhere**
```bash
mkdir -p ~/code101/python301/lesson05
cd ~/code101/python301/lesson05
code .
```
Create the files below in this folder (flat). If lost: `cd ~/code101/python301/lesson05`.

### Step 2. The code under test, in two versions
**File: `report.py`**
```python
def make_rows(count: int) -> list[dict[str, object]]:
    return [{"id": n, "customer": f"c{n % 2000}", "amount": n % 97} for n in range(count)]


def customers_slow(rows: list[dict[str, object]]) -> list[str]:
    seen: list[str] = []
    for row in rows:
        customer = str(row["customer"])
        if customer not in seen:
            seen.append(customer)
    return seen


def customers_fast(rows: list[dict[str, object]]) -> list[str]:
    seen: dict[str, None] = {}
    for row in rows:
        seen.setdefault(str(row["customer"]), None)
    return list(seen)
```
Both return the distinct customers in first-seen order. `customer not in seen` on a **list** scans it from the start, so the cost grows with the number of distinct customers (up to 2000 here) for every row. A dict lookup is a hash lookup, and a dict keeps insertion order, so `list(seen)` gives the same order.

### Step 3. Profile before you touch anything
**File: `profile_report.py`**
```python
import cProfile
import pstats

from report import customers_slow, make_rows


def main() -> None:
    rows = make_rows(20_000)
    profiler = cProfile.Profile()
    profiler.enable()
    customers_slow(rows)
    profiler.disable()
    pstats.Stats(profiler).sort_stats("cumulative").print_stats(5)


if __name__ == "__main__":
    main()
```
`cProfile` is a **deterministic** profiler: it hooks every function call and return, so it gives exact call counts. That precision has a price: it slows Python code down and distorts the timing of very small functions. Only the section between `enable()` and `disable()` is measured, so setup is excluded.

**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 profile_report.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 profile_report.py
```
Expected output **shape**, not yet run (counts and times are yours):
```text
         <N> function calls in <seconds> seconds

   Ordered by: cumulative time
   List reduced from <M> to 5 due to restriction <5>

   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1  <t>      <t>      <t>      <t>     report.py:5(customers_slow)
        ...
```
Read it like this: the top line by cumulative time is `customers_slow`, with most of the time in its own `tottime` column. **Important limit:** the `in` operator is not a function call, so `cProfile` cannot show that the list scan is the cost. It only tells you *which function*. To find the *line* you need a line-level profiler or your own reasoning; the profile narrows the search, it does not finish it.

### Step 4. Benchmark both versions honestly
**File: `compare.py`**
```python
import statistics
import time
from collections.abc import Callable

from report import customers_fast, customers_slow, make_rows


def median_ms(fn: Callable, rows: list, repeats: int = 5) -> float:
    samples = []
    for _ in range(repeats):
        start = time.perf_counter()
        fn(rows)
        samples.append((time.perf_counter() - start) * 1000)
    return statistics.median(samples)


def main() -> None:
    rows = make_rows(20_000)
    print("same result:", customers_slow(rows) == customers_fast(rows))
    print(f"slow median: {median_ms(customers_slow, rows):.1f} ms")
    print(f"fast median: {median_ms(customers_fast, rows):.1f} ms")


if __name__ == "__main__":
    main()
```
Three habits are in these 20 lines. **Check equality first**: a faster wrong answer is a bug. **Use `time.perf_counter()`**, the clock meant for measuring intervals. **Report the median of several runs**, because one run is noise (the first may be slower because of caches warming up, and any run can be disturbed by another process). For micro-benchmarks of tiny snippets the standard library's `timeit` handles repetition for you.

Predict: which is faster, and by roughly what order of magnitude (2x, 10x, 100x)? Write the guess down, then run.

**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 compare.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 compare.py
```
Expected output shape, not yet run:
```text
same result: True
slow median: <number> ms
fast median: <number> ms
```
Record both numbers and the ratio in your notes, together with the Python version and the machine. Run it three times: if the medians vary by more than the effect you care about, your measurement is not trustworthy yet.

### Step 5. Measure memory
**File: `memory_peak.py`**
```python
import tracemalloc
from collections.abc import Callable


def peak_bytes(fn: Callable[[], int]) -> int:
    tracemalloc.start()
    fn()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    return peak


def with_list() -> int:
    return sum([n * n for n in range(200_000)])


def with_generator() -> int:
    return sum(n * n for n in range(200_000))


if __name__ == "__main__":
    list_peak = peak_bytes(with_list)
    generator_peak = peak_bytes(with_generator)
    print(f"list comprehension peak: {list_peak:,} bytes")
    print(f"generator peak: {generator_peak:,} bytes")
    print("generator peak is smaller:", generator_peak < list_peak)
```
`tracemalloc` records Python-level allocations while it is on. `get_traced_memory()` returns the current and the peak size; the peak is what decides whether a container hits its memory limit. Tracing slows the program down, so use it in a test or a staging run, not on every production request.

**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 memory_peak.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 memory_peak.py
```
Expected output shape, not yet run:
```text
list comprehension peak: <bytes> bytes
generator peak: <bytes> bytes
generator peak is smaller: True
```
The last line is the expected result; the byte counts are yours. For whole-process memory (including C extensions) and allocation call trees use the `memray` tool: `memray run -o out.bin script.py`, then `memray flamegraph out.bin`.

### Step 6. Profile a running process with a sampler
A **sampling profiler** looks at the program's call stack many times per second instead of hooking every call. It adds little overhead and can attach to a process that is already running, which is why it is the tool for production.

**PowerShell - folder: `~/code101/python301/lesson05`** (in a virtual environment where you ran `pip install py-spy==0.4.4`)
```powershell
py-spy record -o profile.svg -- python compare.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
py-spy record -o profile.svg -- python3.14 compare.py
```
Expected result, not yet run: py-spy runs the script, prints a short status message and writes `profile.svg`, a flame graph you open in a browser. Wide boxes are where time was spent. To look at a process that is already running: `py-spy top --pid <PID>` shows a live table and `py-spy dump --pid <PID>` prints each thread's current stack once.

Platform notes: on Linux, attaching to a process needs ptrace permission (inside a container you may need an explicit capability, and you must not grant it casually in production). On macOS, py-spy usually needs `sudo`. Check the supported Python versions in the project's README before relying on it for a new release. On Python 3.15 the standard library has its own sampling profiler in the `profiling.sampling` module; read https://docs.python.org/3/library/profiling.html for its commands if your interpreter has it.

### Step 7. `lru_cache`, a TTL cache and the tests
**File: `cache.py`**
```python
from collections.abc import Callable
from functools import lru_cache
from typing import Protocol

RATES = {"EU": 0.21, "US": 0.07}
CALLS = {"tax_rate": 0}


@lru_cache(maxsize=128)
def tax_rate(region: str) -> float:
    CALLS["tax_rate"] += 1
    return RATES[region]


class KeyValueStore(Protocol):
    def get(self, key: str) -> str | None: ...

    def set(self, key: str, value: str, ttl_seconds: int) -> None: ...


class InMemoryStore:
    def __init__(self, clock: Callable[[], float]) -> None:
        self._clock = clock
        self._data: dict[str, tuple[str, float]] = {}

    def get(self, key: str) -> str | None:
        entry = self._data.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if self._clock() >= expires_at:
            del self._data[key]
            return None
        return value

    def set(self, key: str, value: str, ttl_seconds: int) -> None:
        self._data[key] = (value, self._clock() + ttl_seconds)


def cached_lookup(
    store: KeyValueStore, key: str, load: Callable[[], str], ttl_seconds: int = 60
) -> str:
    cached = store.get(key)
    if cached is not None:
        return cached
    value = load()
    store.set(key, value, ttl_seconds)
    return value


def demo() -> None:
    for region in ["EU", "US", "EU", "EU"]:
        tax_rate(region)
    print(tax_rate.cache_info())
    print("underlying calls:", CALLS["tax_rate"])

    now = [0.0]
    store = InMemoryStore(lambda: now[0])
    loads: list[int] = []

    def load() -> str:
        loads.append(1)
        return "42"

    cached_lookup(store, "answer", load)
    cached_lookup(store, "answer", load)
    now[0] = 61.0
    cached_lookup(store, "answer", load)
    print("loads:", len(loads))


if __name__ == "__main__":
    demo()
```
Two different caches:
- **`lru_cache`** memoises a function **inside one process**, keyed by its arguments (which must be hashable). When `maxsize` is reached the least recently used entry is dropped. It has **no expiry**, so it is only for values that cannot become wrong (a pure function, or configuration read once). Exceptions are not cached.
- **Cache-aside with a TTL** (`cached_lookup`): look in the cache; on a miss, load from the source and store with a time-to-live. The clock is passed in (`lambda: now[0]`), so the test and the demo can move time by assigning a number instead of sleeping.

Predict before running: how many times does the function body of `tax_rate` run for the calls EU, US, EU, EU? And how many loads happen in `demo` when a 60-second TTL is used and the clock jumps to 61?

**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 cache.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 cache.py
```
Expected output, not yet run:
```text
CacheInfo(hits=2, misses=2, maxsize=128, currsize=2)
underlying calls: 2
loads: 2
```
Now the tests, which also prove the optimisation did not change behaviour.

**File: `test_cache.py`**
```python
import unittest

from cache import CALLS, InMemoryStore, cached_lookup, tax_rate
from report import customers_fast, customers_slow, make_rows


class OptimisationKeepsBehaviourTests(unittest.TestCase):
    def test_fast_and_slow_agree_including_order(self) -> None:
        rows = make_rows(5_000)
        self.assertEqual(customers_fast(rows), customers_slow(rows))

    def test_first_seen_order_is_kept(self) -> None:
        self.assertEqual(customers_fast(make_rows(3)), ["c0", "c1", "c2"])


class LruCacheTests(unittest.TestCase):
    def setUp(self) -> None:
        tax_rate.cache_clear()
        CALLS["tax_rate"] = 0

    def test_repeated_arguments_hit_the_cache(self) -> None:
        for region in ["EU", "US", "EU", "EU"]:
            tax_rate(region)
        info = tax_rate.cache_info()
        self.assertEqual((info.hits, info.misses), (2, 2))
        self.assertEqual(CALLS["tax_rate"], 2)

    def test_exceptions_are_not_cached(self) -> None:
        for _ in range(2):
            with self.assertRaises(KeyError):
                tax_rate("MARS")
        self.assertEqual(CALLS["tax_rate"], 2)


class TtlCacheTests(unittest.TestCase):
    def setUp(self) -> None:
        self.now = [0.0]
        self.store = InMemoryStore(lambda: self.now[0])
        self.loads: list[int] = []

    def load(self) -> str:
        self.loads.append(1)
        return f"value-{len(self.loads)}"

    def test_a_fresh_entry_is_served_from_the_cache(self) -> None:
        cached_lookup(self.store, "k", self.load, ttl_seconds=60)
        self.now[0] = 59.0
        self.assertEqual(cached_lookup(self.store, "k", self.load, ttl_seconds=60), "value-1")
        self.assertEqual(len(self.loads), 1)

    def test_an_expired_entry_is_loaded_again(self) -> None:
        cached_lookup(self.store, "k", self.load, ttl_seconds=60)
        self.now[0] = 60.0
        self.assertEqual(cached_lookup(self.store, "k", self.load, ttl_seconds=60), "value-2")


if __name__ == "__main__":
    unittest.main()
```
**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 -m unittest -v
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 -m unittest -v
```
Expected output, not yet run: six tests ending in `ok`, then `Ran 6 tests in <time>s` and `OK`. Note the first test class: **an optimisation without an equivalence test is a rewrite with unknown risk.**

**Stop here for a break if you like.**

### Step 8. Why caching in front of a database needs care: the failure modes
Before the Redis code, read this list once. Each item is a way the cache you just wrote can hurt you:
- **Stale reads:** a TTL of 60 s means users can see data up to 60 s old. Decide per data type whether that is acceptable.
- **Stampede:** when a hot key expires, every request misses at once and all of them hit the database. Mitigations: add random jitter to TTLs, let one caller refresh while others get the stale value, or lock per key.
- **Unbounded memory:** `lru_cache(maxsize=None)` on a function with unbounded arguments is a memory leak. Redis needs `maxmemory` and an eviction policy.
- **Cache poisoning and leakage:** a key that omits the user or tenant can serve one user's data to another. Include every input that changes the answer in the key, plus a schema version (`v2:user:42:profile`).
- **Cache as a crutch:** a cache that hides a slow query makes the system fail only when the cache is cold, for example just after a restart or a deploy.
- **Per-process copies:** `lru_cache` lives in each worker process, so with 8 processes you have 8 caches and 8 different warm-up histories. Methods decorated with `lru_cache` also keep `self` alive.

### Step 9. The optional Redis store
Skip Steps 9 to 11 if you do not have Docker.

**File: `requirements.txt`**
```text
redis==8.2.0
```

**File: `compose.yml`**
```yaml
name: code101-lesson05

services:
  redis:
    image: redis:8.8-alpine
    command: ["redis-server", "--save", "", "--appendonly", "no", "--maxmemory", "64mb", "--maxmemory-policy", "allkeys-lru"]
    ports:
      - "127.0.0.1:6390:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
```
Line by line:
- `name:` sets the Compose project name, so containers are grouped as `code101-lesson05` and do not collide with another project.
- `image: redis:8.8-alpine` pins a minor version of the official image; the Alpine variant is small. Floating tags such as `latest` change underneath you.
- `command:` overrides the server start-up. `--save ""` and `--appendonly no` turn off persistence (this is a cache; losing it on restart is acceptable and expected). `--maxmemory 64mb` with `--maxmemory-policy allkeys-lru` makes Redis evict the least recently used keys instead of growing or refusing writes.
- `ports: "127.0.0.1:6390:6379"` publishes the container's 6379 on **loopback only** and on host port 6390 (to avoid clashing with a Redis you may already run). Never publish an unauthenticated Redis on `0.0.0.0`: by default it has no password, and exposed Redis servers are a classic way to be compromised. In production use a private network plus authentication (ACLs) and TLS.
- `healthcheck:` runs `redis-cli ping` every 5 s; `docker compose up --wait` blocks until it passes.

**File: `redis_store.py`**
```python
import logging

import redis

logger = logging.getLogger(__name__)


class RedisStore:
    def __init__(self, url: str) -> None:
        self._client = redis.Redis.from_url(
            url, decode_responses=True, socket_connect_timeout=0.5, socket_timeout=0.5
        )

    def get(self, key: str) -> str | None:
        try:
            value = self._client.get(key)
        except redis.RedisError:
            logger.warning("cache read failed, falling back to the source", exc_info=True)
            return None
        return value if isinstance(value, str) else None

    def set(self, key: str, value: str, ttl_seconds: int) -> None:
        try:
            self._client.set(key, value, ex=ttl_seconds)
        except redis.RedisError:
            logger.warning("cache write failed, continuing without the cache", exc_info=True)
```
Two design decisions: **short timeouts** (a slow cache is worse than no cache) and **fail open** (any Redis error is logged and treated as a miss, so an outage degrades speed, not correctness). Fail open is right for a cache; it is wrong for a rate limiter or a lock, where silence changes behaviour. It satisfies the same `KeyValueStore` protocol as `InMemoryStore`, so `cached_lookup` does not change.

**File: `redis_demo.py`**
```python
import os
import uuid

from cache import cached_lookup
from redis_store import RedisStore

loads: list[int] = []


def load() -> str:
    loads.append(1)
    return "expensive result"


def main() -> None:
    store = RedisStore(os.environ.get("REDIS_URL", "redis://127.0.0.1:6390/0"))
    key = f"demo:lesson05:{uuid.uuid4()}"
    cached_lookup(store, key, load, ttl_seconds=30)
    print("first call loaded:", len(loads) == 1)
    cached_lookup(store, key, load, ttl_seconds=30)
    print("second call loaded:", len(loads) == 2)


if __name__ == "__main__":
    main()
```
The key contains a random UUID so reruns never find an old entry.

### Step 10. Start Redis and run the demo
**PowerShell - folder: `~/code101/python301/lesson05`**
```powershell
py -3.14 -m venv .venv
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
docker compose up -d --wait
docker compose ps
& .\.venv\Scripts\python.exe redis_demo.py
```

**macOS/Linux - folder: `~/code101/python301/lesson05`**
```bash
python3.14 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
docker compose up -d --wait
docker compose ps
.venv/bin/python redis_demo.py
```
Expected result, not yet run: `docker compose ps` lists one service `redis` with status `Up ... (healthy)` and the port mapping `127.0.0.1:6390->6379/tcp`. The demo prints:
```text
first call loaded: True
second call loaded: False
```
Now test the failure mode. Stop Redis and run the demo again:
```powershell
docker compose stop
& .\.venv\Scripts\python.exe redis_demo.py
```
(macOS and Linux: `.venv/bin/python redis_demo.py`.) Expected: warnings (with tracebacks, because `exc_info=True`) are logged for each failed read and write, and the output is `first call loaded: True` and `second call loaded: True`. The program still works, only without the speed-up. That is fail-open in action.

### Step 11. Clean up
**PowerShell or bash - folder: `~/code101/python301/lesson05`**
```text
docker compose down -v --remove-orphans
```
Expected: the container and its network are removed. `-v` also removes volumes (this setup creates none you need).

## How it works
1. **Measure, profile, change one thing, measure again.** The profile (Step 3) located the function; reasoning located the line; the benchmark (Step 4) proved the effect; the test (Step 7) proved equivalence.
2. **Algorithmic fixes beat micro-tuning.** Replacing a list scan with a hash lookup changed the cost from proportional to distinct customers per row to roughly constant. No interpreter flag or `lru_cache` can match that.
3. **Deterministic versus sampling.** Use a deterministic profiler (`cProfile`) to understand a small reproducible case; use a sampler (`py-spy`) on the real system.
4. **Caches turn latency problems into consistency problems.** Every cache needs an owner for freshness, size and failure behaviour.

**Misconception to correct:** "Caching is the first optimisation." It is the last one: first remove unnecessary work (the algorithm, the query, the N+1 pattern), then cache what is left.

## Decision record (ADR-005)
| | |
|---|---|
| **Context** | A read-heavy endpoint calls a slow, rarely changing lookup. |
| **Decision** | Fix the algorithm or query first. Then use cache-aside with Redis, TTL with jitter, keys that include tenant and schema version, short client timeouts and fail-open reads. Use `lru_cache` only for pure functions and process-wide configuration. |
| **Consequences** | Lower median latency and database load; stale data up to the TTL; one more component to monitor; a cold-cache scenario that must be load-tested. |
| **Alternatives rejected** | A larger database instance (treats the symptom; recurring cost). Write-through caching (stronger freshness, more coupling and failure paths in the write path). A distributed lock around every refresh (correct, but adds latency and a new failure mode for a first version). |

## When not to cache or optimise
- **When nobody measured a problem.** No requirement, no profile, no optimisation. Readable code is also a performance feature for the next engineer.
- **When the data must always be current** (balances, permissions, inventory at checkout) unless you have a precise invalidation story.
- **When the hit rate will be low.** A cache with a 5% hit rate adds latency on 95% of requests.
- **When the computation is already cheaper than a network round trip to Redis.**
- **When you cannot afford the cold start.** If the system cannot survive an empty cache, you have a dependency, not a cache.

## What to measure
- Request latency percentiles (50th, 95th, 99th) and throughput before and after, with the same load shape.
- Cache hit ratio (hits / (hits + misses)); in Redis, `INFO stats` reports `keyspace_hits`, `keyspace_misses` and `evicted_keys`. Rising evictions mean the memory limit is too small for the working set.
- Time to recover after a deploy with an empty cache.
- Memory per process, via `tracemalloc` snapshots in staging or `memray`.
- The share of wall time in your own code versus in libraries, from a flame graph.

## Production checklist
- [ ] A written performance goal (for example a percentile target) that the change is judged against.
- [ ] A benchmark script in the repository, with the machine and version recorded next to its results.
- [ ] An equivalence test for every optimised function.
- [ ] Profilers used in production are sampling ones, with the permission model reviewed.
- [ ] Every cache has: a maximum size, a TTL or invalidation rule, keys including all inputs, a fail-open or fail-closed decision, and a hit-ratio metric.
- [ ] Redis is on a private network, authenticated, with TLS where it crosses hosts, and is not exposed on a public interface.
- [ ] A load test with a cold cache has been run.

## Try it
Starter: `exercise/starter/exercise.py`. Copy the `starter` folder itself and rename the copy `try05`, then work in `try05`.
1. **Guided:** implement `top_words_fast` with `collections.Counter` so it returns exactly what `top_words_slow` returns, including the alphabetical order of ties.
2. **Change:** write a `benchmark.py` that builds a list of 200,000 random-looking words (use a fixed seed so runs are comparable), times both functions with the median-of-5 helper from Step 4 and prints the ratio. Record your result.
3. **Stretch (no single answer):** `top_words_fast` is called with the same large input on every request. Design the cache: what is the key, what is the TTL, who invalidates it, and what happens on a stampede? Write the four answers down before you write any code.

**File: `exercise/starter/exercise.py`**
```python
from collections import Counter


def top_words_slow(words: list[str], n: int) -> list[tuple[str, int]]:
    counts = {word: words.count(word) for word in set(words)}
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]


def top_words_fast(words: list[str], n: int) -> list[tuple[str, int]]:
    # TODO 1: count the words once with Counter(words)
    # TODO 2: sort by highest count first, ties alphabetical (most_common does NOT break ties alphabetically)
    # TODO 3: return the first n items
    raise NotImplementedError


if __name__ == "__main__":
    words = "to be or not to be that is the question to be".split()
    slow = top_words_slow(words, 3)
    fast = top_words_fast(words, 3)
    print(fast)
    print("same result:", slow == fast)
```
Expected output once complete:
```text
[('be', 3), ('to', 3), ('is', 1)]
same result: True
```

<details><summary>Solution</summary>

**File: `exercise/solution/exercise.py`** (only `top_words_fast` differs)
```python
def top_words_fast(words: list[str], n: int) -> list[tuple[str, int]]:
    counts = Counter(words)
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]
```
`words.count(word)` inside the dict comprehension rescans the whole list for every distinct word. `Counter` reads the list once. The sort key `(-count, word)` gives a total order, so the result is deterministic.

</details>

## Check yourself
1. Why can `cProfile` not point at the exact line that is slow in `customers_slow`?
   <details><summary>Answer</summary>It records function calls. The `in` check is bytecode inside the function, not a call, so its time is attributed to `customers_slow` as a whole.</details>
2. Predict: you call `tax_rate("MARS")` twice. How many times does the function body run?
   <details><summary>Answer</summary>Twice. It raises `KeyError` both times and `lru_cache` does not cache exceptions.</details>
3. Redis is down. With `RedisStore` as written, what does `cached_lookup` do?
   <details><summary>Answer</summary>`get` logs a warning and returns `None`, so it treats the call as a miss and loads from the source. `set` logs and continues. The caller gets the correct value, slower.</details>
4. Give two reasons a median of five runs is better than one run.
   <details><summary>Answer</summary>One run can include warm-up and interference from other processes. The median ignores a single outlier. Several samples also show how noisy the measurement is.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'redis'` | The demo ran with the system Python instead of the `.venv` interpreter | Use `.venv/bin/python` or `.\.venv\Scripts\python.exe` |
| `redis.exceptions.ConnectionError ...` printed as a traceback (typical message) | Code that calls the client directly, without the `RedisStore` wrapper, while Redis is down | Go through `RedisStore`, which logs and falls back |
| `Bind for 127.0.0.1:6390 failed: port is already allocated` (typical message) | Another container or program uses host port 6390 | Change the left-hand port in `compose.yml` and `REDIS_URL` |
| Timings change a lot between runs | Background load, power saving, a short benchmark | Close other programs, increase `repeats`, keep the median |
| `py-spy: error ... Permission denied` (typical message) | Not allowed to read another process's memory | Follow py-spy's permission notes for your OS; do not weaken production security to get a flame graph |
| `TypeError: unhashable type: 'list'` | A list was passed to an `lru_cache` function | Pass a tuple or another hashable value |

## Best practice
Never optimise without a measurement before and after, and never cache without an owner for freshness, size and failure. Source: Python profilers (`cProfile`, `pstats`) https://docs.python.org/3/library/profile.html ; `functools.lru_cache` https://docs.python.org/3/library/functools.html#functools.lru_cache ; `tracemalloc` https://docs.python.org/3/library/tracemalloc.html ; `timeit` https://docs.python.org/3/library/timeit.html

## Going further
- The capstone measures its own latency with a script and records median and maximum: read the "latency" part of [chapter 05](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-5-hardening/05-hardening.md).
- Run `explain analyze` on your slowest SQL query before adding any cache; lesson 07 shows how traces reveal slow queries in a running service.

## Summary
- You profiled a slow function, fixed the algorithm, proved equivalence with a test and recorded your own before and after numbers.
- You used `tracemalloc` for memory and learned when to use a sampling profiler.
- You applied `lru_cache` and a TTL cache-aside, with an injectable clock for tests.
- You ran a Redis cache that fails open and listed when not to cache.

## Next lesson
06. Background work and queues: moving slow or unreliable work out of the request, with the outbox pattern, retries and idempotent workers.
