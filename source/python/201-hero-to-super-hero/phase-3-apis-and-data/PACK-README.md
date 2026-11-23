# Python 201 - Phase 3: APIs and data

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Three independent labs, 295 minutes including typing/exercises; each is suitable for two sittings. Prerequisites: phases 1-2 and Python 3.12. Lesson 09 additionally needs Databases 101 and Docker 101 setup with a running Linux-container engine/Compose v2. Full lessons: https://github.com/Uee03/Code101/tree/main/tutorials/python/201-hero-to-super-hero/phase-3-apis-and-data . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md . No art is used.

Extract ZIP first: Windows **Extract All > Extract**, macOS double-click, Linux archive-manager **Extract**. Open `python-201-phase-3-apis-and-data`; in an all-level ZIP find it inside `python-201`. Every lesson owns `code`, standalone exercise folders and a future verification specification. Authoring did not install dependencies, start services or execute tests.

| Lesson | Main program, from its code folder | Boundary | Time |
|---|---|---|---|
| 08 First FastAPI service | `probe.py` | in-process DTO/routing tests; optional Uvicorn at 8008 | 90 min; break before Step 5 |
| 09 SQLAlchemy and stored procedures | `main.py` | real PostgreSQL CALL, transaction and ORM read; database at 5542 | 105 min; break before Step 6 |
| 10 Authentication basics | `probe.py` | Argon2 and JWT checks; optional local bearer route at 8010 | 100 min; break before Step 6 |

## Common environment setup
Start with 08 from the phase root:

**PowerShell**
```powershell
Set-Location ./08-your-first-fastapi-service/code
py -3.12 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
& ./.venv/Scripts/python.exe probe.py
& ./.venv/Scripts/python.exe -m unittest -v
```
**macOS/Linux**
```bash
cd 08-your-first-fastapi-service/code
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python probe.py
.venv/bin/python -m unittest -v
```
Expected application observations, not yet run: create=201 with public fields only, missing=404 and invalid input=422. No Uvicorn listener is created by the probe/tests. The full lesson separately shows how to start, use and stop one.

For 10, use a fresh terminal at the phase root and repeat exactly that setup, changing only the directory to `10-authentication-basics/code`. The script remains `probe.py` and tests remain `-m unittest -v`. It uses ephemeral demo secrets in process. To serve the manual route, follow lesson 10's private-config and trusted local issuance steps. There is deliberately no public password grant, registration or refresh flow.

## 09 - real PostgreSQL, separate lifecycle
Use a fresh terminal at the phase root. Create its environment as above with the directory changed to `09-sqlalchemy-and-stored-procedures/code`; do not run the probe command because this lab uses `main.py`. Before running it, generate `.env` with this lesson's `.venv` interpreter and start its database as described below.

**PowerShell - folder: `09-sqlalchemy-and-stored-procedures/code`**
```powershell
& ./.venv/Scripts/python.exe configure.py
```
**macOS/Linux - same folder**
```bash
.venv/bin/python configure.py
```
Expected output, not yet run: `Created .env; keep it private.` The full lesson prints every template/configuration file and explains every Compose line. Never share the generated password or confuse host port 5542 with container port 5432.

**PowerShell or macOS/Linux - same code folder**
```shell
docker compose -p python201-data up -d --wait
docker compose -p python201-data ps
docker compose -p python201-data logs --tail 20 db
```
Expected service state, not yet run: one healthy database, with variable startup/log output. Then run `.venv` Python with `main.py`, followed by `-m unittest -v`, using the matching OS interpreter form above. Expected main output, not yet run: `saved: True`. Every run inserts a new sample note; integration tests roll back their own writes.

Finish only this lab:

**PowerShell or macOS/Linux - same code folder**
```shell
docker compose -p python201-data stop
docker compose -p python201-data down -v --remove-orphans
```
`stop` preserves data; `down -v` **deletes this lab's data volume**. Omit `-v` to retain it. Initialization SQL runs only for an empty volume, not as a migration. Production schema evolution and least-privilege roles need a different design; see the linked capstone.

## Exercises and review
Copy `exercise/starter` itself into your own lesson workspace and rename it `try08`, `try09` or `try10`; do not create an extra nested starter folder. Use the corresponding lesson's `.venv` interpreter and exact exercise command. The SQLite bound-parameter exercise in 09 deliberately does not replace the real PostgreSQL procedure test. Solutions answer the guided rung.

Phase mixed review is in lesson 10. Phase 4 combines these boundaries in a small owner-scoped notes API. For Keycloak and the full app, use https://github.com/Uee03/Code101/tree/main/capstones/backend-python instead of treating local HS256 issuance as production identity.
