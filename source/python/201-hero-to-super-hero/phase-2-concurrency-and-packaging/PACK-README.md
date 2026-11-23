# Python 201 - Phase 2: Concurrency and packaging

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Three independent lessons, 210 minutes including typing/exercises. Prerequisites: phase 1 and Python 3.12. Full lessons: https://github.com/Uee03/Code101/tree/main/tutorials/python/201-hero-to-super-hero/phase-2-concurrency-and-packaging . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open the extracted `python-201-phase-2-concurrency-and-packaging` folder. In the all-level ZIP it is inside `python-201`. Every command below states its starting folder. Programs, tests, builds and dependency resolution have not been run by the author.

| Lesson | Focus | Time |
|---|---|---|
| 05 async and asyncio | TaskGroup, timeout, cancellation and ordered collection | 65 min |
| 06 Packaging with uv | src layout, pyproject, local manager, entry point and real lock resolution | 75 min; break before Step 5 |
| 07 Logging, configuration and secrets | pydantic-settings, dotenv, safe logging and isolated tests | 70 min |

## 05 - from the phase root
**PowerShell**
```powershell
Set-Location ./05-async-and-asyncio/code
py -3.12 main.py
py -3.12 -m unittest -v
```
**macOS/Linux**
```bash
cd 05-async-and-asyncio/code
python3.12 main.py
python3.12 -m unittest -v
```
Expected application output, not yet run: `['note-2', 'note-1', 'note-3']`. There is no benchmark or external server.

## 06 - use a fresh terminal at the phase root
**PowerShell**
```powershell
Set-Location ./06-packaging-with-uv/code
py -3.12 -m venv .uv-tool
& ./.uv-tool/Scripts/python.exe -m pip install uv==0.6.14
& ./.uv-tool/Scripts/uv.exe sync --python 3.12
& ./.uv-tool/Scripts/uv.exe run --locked note-words
& ./.venv/Scripts/python.exe -m unittest discover -s tests -v
```
**macOS/Linux**
```bash
cd 06-packaging-with-uv/code
python3.12 -m venv .uv-tool
.uv-tool/bin/python -m pip install uv==0.6.14
.uv-tool/bin/uv sync --python 3.12
.uv-tool/bin/uv run --locked note-words
.venv/bin/python -m unittest discover -s tests -v
```
Expected application output, not yet run: `words: 3`. The first real sync creates `.venv` and `uv.lock`; retain/review the generated lock. It is intentionally not fabricated in this draft. `--locked` is for after that first successful resolution. uv is local in `.uv-tool`, separate from the managed project. Use the lesson for optional distribution-build commands and exact configuration explanations. Nothing is published or globally installed.

## 07 - use a fresh terminal at the phase root
**PowerShell**
```powershell
Set-Location ./07-logging-configuration-and-secrets/code
py -3.12 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
& ./.venv/Scripts/python.exe configure.py
& ./.venv/Scripts/python.exe main.py
& ./.venv/Scripts/python.exe -m unittest -v
```
**macOS/Linux**
```bash
cd 07-logging-configuration-and-secrets/code
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python configure.py
.venv/bin/python main.py
.venv/bin/python -m unittest -v
```
`configure.py` exclusively creates a private `.env`; do not rerun it to overwrite an existing secret. Expected report, not yet run: INFO startup with batch_size=10 and a masked key. Overrides already present in your environment take precedence. Commit/share `.env.example`, never the generated `.env`. Pins are direct teaching snapshots, not a full transitive lock or production-security claim.

## Exercises and phase review
Copy the chosen `exercise/starter` folder itself and rename the copy `try05`, `try06` or `try07` in your own lesson workspace. Do not nest `starter` inside that folder. Each lesson supplies exact commands and completed expected output. Exercise 06 imports the installed package, so use its project `.venv` interpreter after synchronization; exercise 07 needs that lesson's Pydantic environment. Answers are in `exercise/solution`.

Phase mixed review is in lesson 07. Continue with phase 3 for DTOs, persistent data and bearer identity boundaries.
