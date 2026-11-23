# Python 301 - Phase 2: Performance and concurrency

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Three lessons, about 265 minutes including measurements and exercises. Prerequisite: phase 1 and Python 3.14 or newer. Full lessons: https://github.com/Uee03/Code101/tree/main/tutorials/python/301-super-hero-to-legendary/phase-2-performance-and-concurrency . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open the extracted `python-301-phase-2-performance-and-concurrency` folder. Commands state their starting folder; Windows uses `py -3.14`, macOS and Linux `python3.14`. Work in a copy.

| Lesson | Focus | Time |
|---|---|---|
| 04 Concurrency models | GIL, threads, processes, asyncio, free-threaded builds; you measure your own ratios | 85 min |
| 05 Profiling and optimisation | cProfile, a sampling profiler, tracemalloc, lru_cache, TTL cache, optional Redis | 90 min |
| 06 Background work and queues | outbox, retries with backoff and jitter, dead letters, idempotent consumers | 90 min |

## 04, 05 (core) and 06 - standard library only
**PowerShell**
```powershell
Set-Location ./04-concurrency-models/code
py -3.14 gil_check.py
py -3.14 race.py
py -3.14 bench.py io
py -3.14 -m unittest -v
```
**macOS/Linux**
```bash
cd 04-concurrency-models/code
python3.14 gil_check.py
python3.14 race.py
python3.14 bench.py io
python3.14 -m unittest -v
```
Lesson 04's benchmark prints timings that differ on every machine; that is the point of the lesson (record your own table). Lesson 05 core scripts (`compare.py`, `profile_report.py`, `memory_peak.py`, `cache.py`) and lesson 06 (`main.py`, `-m unittest -v`) run the same way from their own `code` folders.

## 05 - the optional Redis step
Needs Docker with Compose v2 and a virtual environment with `redis`:
**PowerShell**
```powershell
Set-Location ./05-profiling-and-optimisation/code
py -3.14 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
docker compose up -d --wait
& ./.venv/Scripts/python.exe redis_demo.py
docker compose down -v --remove-orphans
```
**macOS/Linux**
```bash
cd 05-profiling-and-optimisation/code
python3.14 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
docker compose up -d --wait
.venv/bin/python redis_demo.py
docker compose down -v --remove-orphans
```
Redis is published on `127.0.0.1:6390` only, with persistence off and a memory limit. Stop and remove the container when you finish.

## Exercises and phase review
Copy the chosen `exercise/starter` folder itself and rename the copy `try04`, `try05` or `try06`. Answers are in `exercise/solution`. The phase review is the "Check yourself" set of lesson 06 together with the recap questions of each lesson; the lesson 04 and 05 measurement tables are the evidence you keep. Continue with phase 3 for observability, security and release.
