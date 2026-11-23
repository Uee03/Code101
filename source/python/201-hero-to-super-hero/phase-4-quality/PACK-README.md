# Python 201 - Phase 4: Quality and a notes mini-project

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Lesson 11 integrates lessons 08-10 while teaching pytest fixtures, parametrization and TestClient. Allow 180 minutes in three sittings: pause before tests (Step 5), then before container setup (Step 9). Prerequisites: phases 1-3, Python 3.12, Databases 101/Docker 101 setup for the optional PostgreSQL/container workflow. Full lesson: https://github.com/Uee03/Code101/blob/main/tutorials/python/201-hero-to-super-hero/phase-4-quality/11-testing-and-notes-api.md . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open the extracted `python-201-phase-4-quality` folder (inside `python-201` for an all-level ZIP). Work in your own copy. This pack contains unexecuted source and test specifications, not a passing-test certificate.

## Fast application workflow - starting at the phase root
**PowerShell**
```powershell
Set-Location ./11-testing-and-notes-api/code
py -3.12 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements-dev.txt
& ./.venv/Scripts/python.exe probe.py
& ./.venv/Scripts/python.exe -m pytest -q
```
**macOS/Linux**
```bash
cd 11-testing-and-notes-api/code
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python probe.py
.venv/bin/python -m pytest -q
```
Expected probe output, not yet run: create=201, owner=200, other owner=404, anonymous=401. The source specifies 16 pytest cases using fresh SQLite files and ephemeral signing keys. No real `.env`, PostgreSQL, Docker or Uvicorn listener is needed for those checks. This does not prove PostgreSQL schema/locking or real identity-provider behavior. Exact pytest timings/warnings are not predicted.

`requirements-dev.txt` includes runtime requirements plus HTTPX/pytest. The runtime image installs only `requirements.txt`. Dependency pins are direct teaching snapshots; review supported versions and a real transitive lock before deployment.

## Separate local container workflow - from the same code folder
Generate private configuration once:

**PowerShell**
```powershell
& ./.venv/Scripts/python.exe configure.py
```
**macOS/Linux**
```bash
.venv/bin/python configure.py
```
Expected output, not yet run: `Created .env; keep it private.` It refuses to overwrite an existing file. Share `.env.example`, never `.env`. Full Dockerfile, Compose, ignore files, initialization SQL and all configuration explanations appear in the lesson.

**PowerShell or macOS/Linux - same code folder**
```shell
docker compose -p python201-notes up -d --build --wait
docker compose -p python201-notes ps
docker compose -p python201-notes logs --tail 20 api db
docker compose -p python201-notes exec -T api python issue.py ada
```
Expected state, not yet run: both services healthy. The final command prints a private five-minute learning JWT; do not capture it in shared logs. Container build/start/log output is variable and unobserved by the author. API: http://127.0.0.1:8011/docs ; host database port: 5543, container database hostname/port: db:5432. Follow the lesson's precise Authorize/create/read/Bob-denied workflow and use actual returned note IDs on a reused volume.

The local issuer is privileged tooling, not password login or production identity. The API derives owner from validated tokens, never from caller JSON. Use https://github.com/Uee03/Code101/tree/main/capstones/backend-python for Keycloak, migrations and the full application.

Finish only this lab:

**PowerShell or macOS/Linux - same code folder**
```shell
docker compose -p python201-notes stop
docker compose -p python201-notes down -v --remove-orphans
```
`down -v` **deletes this project's notes volume**. Omit `-v` to retain it. Restarting only the API does not delete database data. Initialization SQL is first-start provisioning, not a migration mechanism. The cached image may remain after cleanup; it is not a running server.

## Three-rung exercise
`exercise/starter` and `exercise/solution` each contain the full project. Their support files are identical to `code`; each additionally contains `tests/test_exercise.py`. Copy `starter` itself into your own lesson workspace and rename it `try11`, not `try11/starter`. Complete the ownership assertions, then parametrize two titles, then design a safely isolated PostgreSQL fixture as the optional stretch. All steps and the guided solution appear in the lesson.

Use the parent project's already prepared environment. From your own `lesson11/try11` folder: PowerShell `& ../.venv/Scripts/python.exe -m pytest -q`; macOS/Linux `../.venv/bin/python -m pytest -q`. The completed guided project specifies 17 cases. Do not copy real dotenv files or installed environments into the exercise.

The phase mixed review closes lesson 11. The level is complete as an authored draft, not runtime-verified.
