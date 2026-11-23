# Python 301 - Phase 1: Architecture

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Three lessons, about 245 minutes including typing and exercises. Prerequisite: Python 201 (especially lessons 02, 08 and 11) and Python 3.14 or newer. Full lessons: https://github.com/Uee03/Code101/tree/main/tutorials/python/301-super-hero-to-legendary/phase-1-architecture . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open the extracted `python-301-phase-1-architecture` folder (inside `python-301` in the all-level ZIP). Every command below states its starting folder. Windows commands use `py -3.14`; macOS and Linux use `python3.14`. Work in a copy, not inside the ZIP.

| Lesson | Focus | Time |
|---|---|---|
| 01 Clean and hexagonal architecture | ports as Protocols, adapters, dependency rule enforced by an AST test | 75 min |
| 02 Domain modeling and SOLID | entities, value objects, aggregate, unit of work, contract tests | 80 min |
| 03 API design at scale | versioning, cursor pagination, idempotency keys, contract tests (FastAPI) | 90 min |

## 01 and 02 - standard library only
**PowerShell**
```powershell
Set-Location ./01-clean-and-hexagonal-architecture/code
py -3.14 main.py
py -3.14 check_dependency_rule.py
py -3.14 -m unittest -v
```
**macOS/Linux**
```bash
cd 01-clean-and-hexagonal-architecture/code
python3.14 main.py
python3.14 check_dependency_rule.py
python3.14 -m unittest -v
```
Lesson 02 is the same from `02-domain-modeling-and-solid/code` (`main.py` and `-m unittest -v`). Expected output is in each lesson, marked not yet run.

## 03 - needs a virtual environment (network once)
**PowerShell**
```powershell
Set-Location ./03-api-design-at-scale/code
py -3.14 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
& ./.venv/Scripts/python.exe -m unittest -v
```
**macOS/Linux**
```bash
cd 03-api-design-at-scale/code
python3.14 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m unittest -v
```
The lesson also starts the server on `127.0.0.1:8000` and calls it with `curl`. Pins are direct teaching snapshots, not a complete transitive lock: resolve and review a lock before deploying anything.

## Exercises and phase review
Copy the chosen `exercise/starter` folder itself and rename the copy `try01`, `try02` or `try03` in your own lesson workspace. Answers are in `exercise/solution`. The phase review is the set of "Check yourself" questions of lesson 03 plus the recap questions that open each lesson; the architecture test from lesson 01 is worth running against your own project. Continue with phase 2 for concurrency, profiling and queues.
