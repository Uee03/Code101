---
track: databases
level: 201
phase: 1
phase_name: schema-design
lesson: 03
title: "Migrations with plain SQL and a small runner"
time: 60 min
prerequisites: [201.1.02]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/201-hero-to-super-hero/phase-1-schema-design/03-plain-sql-migrations/
assets: []
---

# 03. Migrations with plain SQL and a small runner

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Apply ordered migrations using a ledger and transactional runner.
- Distinguish repeatable runner behavior from blindly idempotent DDL.
- Choose a safe correction or rollback strategy for a deployed change.

## Recap
- What protects writes from clients that skip validation?
  <details><summary>Answer</summary>Database constraints.</details>
- Does ROLLBACK undo committed work?
  <details><summary>Answer</summary>No. It cancels the current uncommitted transaction; restoring committed data requires another strategy.</details>

## Why it matters
A schema is a versioned dependency of application code. Ad hoc ALTER commands cannot tell a teammate what changed or whether it already ran. A tiny explicit runner makes that history visible before you adopt a larger migration tool.

## What you will build
Two numbered SQL migrations, an applied-version ledger, a container shell entry point, a repeat-run check and an explicit destructive teaching rollback.

## Before you start
- Finished [Databases 101](../../101-zero-to-hero/phase-3-designing/12-library-project.md): Docker PostgreSQL, psql/IDE connections, joins, transactions and basic indexes. No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the same `postgres:17-alpine` image as 101. Docker/Compose versions above are the inherited authoring baseline, not a new runtime check. The tag pins major version/flavour, not a patch digest.
- Time: 60 minutes including reading, typing and exercise. Two sittings are reasonable: save the feature files before Step 5, then return for the run and exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/201-hero-to-super-hero/phase-1-schema-design/03-plain-sql-migrations/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-201-phase-1-schema-design.zip`.
- **One database lab at a time:** stop the previous 101/201 or capstone lab before using 127.0.0.1:5432. Do not stop unrelated services. These lessons are independent; do not carry a schema forward.
- All reset scripts/passwords are disposable local examples. Never aim them at work data. `learner` is the official image's initial administrative user, not an application login design.
- SQL, Docker, negative cases and IDE steps have not been run for this lesson. Result rows are derived by hand; variable tool output is described, not invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101` with your file manager. Obtain the source folder from the repository link above, or extract the phase ZIP: Windows **right-click > Extract All**; macOS double-click; Linux use your archive manager's **Extract Here**. Move `databases-201-phase-1-schema-design` into `code101`. Keep `03-plain-sql-migrations/code` and its sibling `exercise` together.
2. Without a pack, create the same `databases-201-phase-1-schema-design/03-plain-sql-migrations/code` structure and sibling `exercise/starter` and `exercise/solution` folders using **New Folder**. You will create every file shown below. Leave the finished solution unopened until you try the exercise.
3. Open a terminal (Windows: type `powershell` in File Explorer's address bar in the code folder; macOS/Linux: open Terminal). Do not type a prompt's `>` or `$`. The text before the prompt shows your current directory. Recover to this exact folder if needed:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-201-phase-1-schema-design\03-plain-sql-migrations\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-201-phase-1-schema-design/03-plain-sql-migrations/code"
```

Expected result, not yet run: the prompt is in this lesson code folder; Set-Location/cd normally print no text. Using the repository directly is also fine: open its matching source code folder and use the same subsequent relative commands.

4. Open that folder in your editor. For each file caption choose **File > New File > Save As** at the shown path relative to the lesson root (`code/` is where your terminal is). If supplied, open and compare instead of creating duplicates. Create displayed subfolders first. Save as UTF-8 without BOM; use LF for shell files. On Windows enable **View > Show > File name extensions** so `.sql.txt` cannot hide. Save with Ctrl+S (Cmd+S on macOS); an editor-tab dot often means unsaved changes.

### Step 2. Save the complete Compose configuration
**File: `code/docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATABASE: ${POSTGRES_DB}
      PGUSER: ${POSTGRES_USER}
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - .:/scripts:ro
      - ../exercise:/exercises:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 2s
      timeout: 3s
      retries: 30
      start_period: 5s
volumes:
  pg_data:
```

This file is genuinely identical to [201 lesson 01, Step 2](../phase-1-schema-design/01-data-modeling-and-3nf.md#step-2-save-the-complete-compose-configuration). Repeat that step with only these differences: workspace `03-plain-sql-migrations` instead of `01-data-modeling-and-3nf`, project `code101-db201-03` instead of `code101-db201-01`, and this lesson's SQL. **No YAML line changes.** Full configuration is repeated to keep this pack standalone.

| Configuration line(s) | Meaning and consequence of changing it |
|---|---|
| `services:`, `db:` | Define one service named db; commands below must use that name. |
| `image: postgres:17-alpine` | Use the unchanged official image. A different major version changes the data-directory compatibility contract. |
| `environment:` and POSTGRES_DB/USER/PASSWORD | Initialize the database/admin/password from .env only when the data volume is empty. |
| `PGDATABASE`, `PGUSER` | Set container-client defaults; commands also name user/database explicitly for clarity. |
| `ports:` with `127.0.0.1:5432:5432` | Publish only IPv4 loopback on host port 5432, not every host interface. Host tools use 127.0.0.1; another Compose service would use db. |
| `volumes:` and `pg_data:/var/lib/postgresql/data` | Keep data in this project's named volume. Removing the container alone does not erase it. |
| `.:/scripts:ro` | Mount this code folder read-only; saved host edits are visible to psql. It is not a writable backup location. |
| `../exercise:/exercises:ro` | Mount the sibling exercise folder read-only. Flattening the pack breaks the path. |
| `healthcheck:` and `test:` | Run pg_isready inside db. `$$` defers variable expansion to its shell, not Compose. Readiness is not a password/security test. |
| `interval: 2s`, `timeout: 3s` | Check every two seconds, allowing three seconds per probe. |
| `retries: 30`, `start_period: 5s` | Allow startup time before declaring failure; --wait uses health status. |
| Final `volumes:`, `pg_data:` | Declare the volume, scoped by the explicit project name. |

Indent with spaces. No Dockerfile/.dockerignore: nothing is built. No art is used (`assets: []`).

### Step 3. Create the local environment file
**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

The comment marks local-only credentials. POSTGRES_DB names the initial database, POSTGRES_USER its administrator, and POSTGRES_PASSWORD its disposable password. Compose substitutes `${...}` in YAML using a file named exactly `.env`.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: a successful copy prints no text. The complete generated local file is:

**File: `code/.env`** (local copy, not shipped)
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

**File: `code/.gitignore`**
```gitignore
.env
*.dump
```

These patterns exclude .env and dump archives from Git; they do not encrypt them or remove already tracked files. Editing .env later does not change an initialized database password. Reset only this disposable volume if reinitializing.

### Step 4. Model the feature, then save its files
A **migration** is a versioned schema/data change. A **ledger** records which versions committed. **Idempotency** means repeating an operation has the same final effect as applying it once. Our runner is repeatable because it skips recorded files; the files themselves deliberately use strict CREATE/ALTER so **schema drift** (an unexpected difference between intended and actual schema) fails visibly.

Create the migrations subfolder before saving its files. Save migrate.sh with LF (Unix) line endings; running it with `sh` means no chmod or host shell installation is needed. The container already has sh and psql.

The driver lists 001 then 002 explicitly. It does not scan filenames. A new numbered file is not applied until you also add its conditional include and ledger insert. Never edit an applied file: write 003 for a correction. Only one migrator should initialize an empty database. The ledger lock serializes subsequent batches, but this is not a production deployment orchestrator.

Read/save all files before running. SQL ends statements with semicolons. Backslash commands are **psql client commands**, not server SQL: ON_ERROR_STOP stops at the first unexpected error; `\ir` includes relative to its containing script; unaligned format uses `|` between columns; footer off removes row-count footers; the null setting displays SQL NULL as `(null)`. Use psql for whole scripts; in an IDE select server SQL, not the backslash commands. The entry script arranges setup automatically. Never execute sample reset files on valuable data.

This numbered migration contains one logical change; the driver includes it in order.

**File: `code/migrations/001_create_tasks.sql`**
```sql
CREATE TABLE app.tasks (
    task_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    CONSTRAINT pk_tasks PRIMARY KEY (task_id)
);
INSERT INTO app.tasks (title) VALUES ('Pack order');
```

This numbered migration contains one logical change; the driver includes it in order.

**File: `code/migrations/002_add_priority.sql`**
```sql
ALTER TABLE app.tasks ADD COLUMN priority integer NOT NULL DEFAULT 1;
ALTER TABLE app.tasks ADD CONSTRAINT ck_tasks_priority CHECK (priority BETWEEN 1 AND 3);
```

The psql driver records successful versions in one transaction. It is an explicit list, not directory discovery.

**File: `code/migrate.sql`**
```sql
\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA IF NOT EXISTS app;
CREATE TABLE IF NOT EXISTS app.schema_migrations (
    version text,
    CONSTRAINT pk_schema_migrations PRIMARY KEY (version)
);
LOCK TABLE app.schema_migrations IN EXCLUSIVE MODE;
SELECT NOT EXISTS (SELECT 1 FROM app.schema_migrations WHERE version = '001') AS apply_001
\gset
\if :apply_001
    \ir migrations/001_create_tasks.sql
    INSERT INTO app.schema_migrations (version) VALUES ('001');
\endif
SELECT NOT EXISTS (SELECT 1 FROM app.schema_migrations WHERE version = '002') AS apply_002
\gset
\if :apply_002
    \ir migrations/002_add_priority.sql
    INSERT INTO app.schema_migrations (version) VALUES ('002');
\endif
COMMIT;
```

The container-shell entry point replaces itself with psql and returns its exit status. Save with LF endings.

**File: `code/migrate.sh`**
```bash
#!/bin/sh
set -eu
exec psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/migrate.sql
```

An explicit destructive local rollback, not part of the normal run.

**File: `code/rollback_002.sql`**
```sql
\set ON_ERROR_STOP on
BEGIN;
LOCK TABLE app.schema_migrations IN EXCLUSIVE MODE;
ALTER TABLE app.tasks DROP CONSTRAINT ck_tasks_priority;
ALTER TABLE app.tasks DROP COLUMN priority;
DELETE FROM app.schema_migrations WHERE version = '002';
COMMIT;
```

The entry script includes setup or the migration driver, then performs the worked example.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir migrate.sql
\ir migrate.sql
SELECT version FROM app.schema_migrations ORDER BY version;
SELECT task_id, title, priority FROM app.tasks ORDER BY task_id;
```

### Step 5. Start and inspect PostgreSQL
From this code folder use project `code101-db201-03` consistently. `-p` isolates names/volumes, not the shared host port. Keep Docker Desktop running. `up -d --wait` starts the service and waits for readiness; an initial image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and db container, then reports healthy readiness. Progress order, IDs and timings vary; no startup transcript is claimed.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 logs --no-log-prefix --tail 10 db
```

Expected output, not yet run: timestamped PostgreSQL log lines indicating readiness to accept connections. Exact timestamps/process IDs are unpredictable. Read real logs if startup fails.

### Step 6. Connect using the existing 101 IDE pattern (optional)
The psql command below is sufficient. Repeat [101 lesson 02's IDE steps](../../101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool.md) with these fields; the differences are this lesson workspace and display name. No server install or Azure sign-in is needed for local access.

| Field | Value |
|---|---|
| Host / Server | `127.0.0.1` (IPv4 localhost) |
| Port | `5432` |
| Database | `code101` |
| User | `learner` |
| Password | `learn_local_only` (local only) |
| Authentication | Password / User & Password |
| SSL mode | Disable, only for this loopback lab |
| SSH tunnel | off |
| Display name | `Code101 DB201 03` |

- JetBrains: **Database / Database Explorer > + > Data Source > PostgreSQL**; enter General fields, **Download missing driver files** if offered, then **SSH/SSL** off for this local lab, **Test Connection > OK > New Query Console**. Run selected SQL with Ctrl+Enter (Cmd+Enter on macOS).
- VS Code: Microsoft's **PostgreSQL** extension (`ms-ossdata.vscode-pgsql`), **PostgreSQL > Connections > + / Add New Connection > Parameters**; enter fields, **Advanced** port/SSL, then **Test Connection > Save & Connect > New Query**. Run selected SQL with Ctrl+Shift+E (Cmd+Shift+E on macOS). UI labels may vary; 101 links the vendor directions.
- Visual Studio is not VS Code. Built-in SQL Server Object Explorer is not a PostgreSQL tool; Npgsql alone does not install a Server Explorer provider. Use the existing provider if available, or the terminal/IDE routes above.

Run only selected queries after setup; do not casually reapply destructive setup. A socket connection inside db does not prove a host-network password works. Require TLS for remote production connections; disabling SSL is only for local practice.

## Run it
**Predict first:** Predict how many task rows remain after including migrate.sql twice. Which insert is skipped on the second pass?


From this code folder run the entry file. `exec -T` runs the container client without a pseudo-terminal; `-X` ignores psql startup customization; `-q` suppresses routine tags; ON_ERROR_STOP fails fast; `-U`/`-d` name role/database; `-f` is the container file path. Quiet mode does not hide server errors/notices on stderr.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run:**

```text
version
001
002
task_id|title|priority
1|Pack order|1
```

The first include records 001 and 002 and inserts Pack order once. The second sees both versions, so it changes no tasks. The constant default gives the existing row priority 1.

These are hand-derived unaligned result tables, not captured output. Missing-schema/dependency notices may appear on stderr; they are not data rows. An unexpected error means stop and inspect the first failing file/statement before continuing.

### Try the shell runner and the explicit rollback (optional, local data only)
After Run it, from this lesson code folder:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 exec -T db sh /scripts/migrate.sh
docker compose -p code101-db201-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/rollback_002.sql
docker compose -p code101-db201-03 exec -T db sh /scripts/migrate.sh
```
Expected output, not yet run: no query rows; repeat-run notices may appear on stderr. These commands apply, remove, then reapply 002. Run lesson.sql again to inspect the two ledger versions and the single priority-1 task. Do not use this down script after collecting real priority values: the column values would be lost.

## How it works
`BEGIN` makes this small batch atomic. If any SQL fails, ON_ERROR_STOP terminates psql; closing that connection rolls back the uncommitted batch, including ledger inserts. The exclusive lock lasts until commit. `SELECT ... \gset` sends one Boolean row into a psql variable instead of printing it; `\if :apply_001` consumes that variable. `\ir` paths are relative to the driver, not your host folder.

**Why this, not that:** a ledger is safer than putting IF NOT EXISTS on every object, which can hide an incompatible pre-existing table. This teaching runner has no checksum validation, automatic discovery, lock timeout or partial-batch recovery. Use a maintained migration tool for concurrent deployment teams. Never put CREATE INDEX CONCURRENTLY inside this transaction; it requires a different execution path.

**Rollback strategy:** before commit, rollback is lossless for this batch. After commit, prefer a forward corrective migration, backed by a tested backup. The supplied down script removes priority data permanently; it is only for this disposable seed before other versions depend on 002. For live changes use expand (add compatible shape), backfill, migrate application readers/writers, then contract (remove old shape) across deployments.

## Try it
Keep db running after Run it. The starter resets the disposable schema, except lesson 03 which expects the already-applied migrations and rolls back its trial column.

1. **Guided:** In a transaction, add nullable due_on and select title plus whether it starts NULL. Roll back. This rehearses an expand step without altering the ledger.
2. Copy the single starter file into your code folder. This is a file copy, not a folder copy; setup includes use the absolute container /scripts path. Without a pack create the file from the complete starter listing. Edit only your working copy and save it.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

Expected output, not yet run: no text after a successful copy.

**File: `exercise/starter/exercise.sql`** (copy to `code/exercise.sql`)
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
-- Prerequisite: Run it has applied migrations 001 and 002.
BEGIN;
-- TODO: add nullable due_on date to app.tasks.
-- TODO: return title and due_on IS NULL AS starts_empty.
ROLLBACK;
```

3. Fill the TODOs, save, then run your working file from this code folder.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target after completing the TODOs:

**Expected output, not yet run:**

```text
title|starts_empty
Pack order|t
```

The target is for the completed program, not the untouched starter, which deliberately may return no rows or an uncorrected value.

4. **Change:** Design migration 003 for due_on on paper: list the new file, driver branch and ledger value that must ship together. Do not edit 001 or 002.
5. **Stretch (optional):** Describe how checksum validation would detect someone editing 001 after it was applied.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
BEGIN;
ALTER TABLE app.tasks ADD COLUMN due_on date;
SELECT title, due_on IS NULL AS starts_empty FROM app.tasks ORDER BY task_id;
ROLLBACK;
```

The solution implements the guided TODOs using the worked example's constructs. Compare its rows with the target above. To compare in your workspace, repeat the starter-copy step with only the source directory changed from starter to solution, then run the exact exercise command above:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\solution\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/solution/exercise.sql ./exercise.sql
```

</details>

### Stop and clean up before the next lab
Close IDE connections first. These commands apply only to this named disposable project.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 stop
docker compose -p code101-db201-03 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: variable stop progress, then:

```text
db exited
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 down -v --remove-orphans
```

Expected output, not yet run: Compose removes this project container/network and saved volume; exact progress text varies. **-v destroys saved database data**, including the restored target in lesson 11. It does not erase other projects or the host dump file. Never use it on valuable data.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-03 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: no service rows; port 5432 is no longer held by this project.

## Check yourself
1. Why is there only one Pack order after two passes?
   <details><summary>Answer</summary>001 is skipped once its ledger entry exists; the seed insert is inside that branch.</details>
2. Find the bug: a teammate changed 002 in Git after deployment.
   <details><summary>Answer</summary>The runner will skip 002 on deployed databases. Use a new version, not a historical edit.</details>
3. Can rollback_002 recover existing priority values?
   <details><summary>Answer</summary>No. Dropping the column loses them. Use a backup or a forward correction when preservation matters.</details>

### Phase mixed review
Try without looking back; these connect this phase to earlier work.
- A customer changes email; which table changes?
  <details><summary>Answer</summary>customers only, unless a separate historical contact snapshot is a stated business requirement.</details>
- Which is better for business-managed shipping states: enum or lookup?
  <details><summary>Answer</summary>A lookup table supports metadata and controlled retirement.</details>
- A migration fails before commit. Should its ledger version remain?
  <details><summary>Answer</summary>No: DDL and ledger writes belong to the same transaction.</details>

## Common mistakes
No new error transcript has been captured. These are symptoms; wording marked typical message is illustrative, not observed output.

| Symptom | Cause | Fix |
|---|---|---|
| Compose cannot find its configuration (typical message) | Terminal is in the wrong folder | Recover to code using Step 1; keep code/exercise siblings. |
| Old behavior persists | Unsaved file, hidden .sql.txt extension or wrong project | Save, check filename extensions and use the exact -p name in every command. |
| Startup cannot claim 5432 (typical message) | Another lab owns the host port | Stop the previous lab from its own code folder; never kill unrelated processes. |
| A new numbered file is ignored | The driver has no automatic discovery | Add a matching conditional include and ledger insert to migrate.sql. |
| The shell runner reports an option problem (typical message) | migrate.sh was saved with CRLF line endings | Save the shell file as LF and run with sh, not the host shell. |
| An IDE rejects a backslash line (typical message) | psql meta-commands were sent as SQL | Use psql for whole scripts; select only server SQL in an IDE. |

## Best practice
Review ALTER TABLE changes for locking and data-loss consequences, and separate incompatible deployment steps. Source: [PostgreSQL 17: modifying tables](https://www.postgresql.org/docs/17/ddl-alter.html).

## Going further
Official PostgreSQL **17** references checked for this draft:
- [PostgreSQL 17: modifying tables](https://www.postgresql.org/docs/17/ddl-alter.html)
- [psql conditionals and includes](https://www.postgresql.org/docs/17/app-psql.html)
- [LOCK](https://www.postgresql.org/docs/17/sql-lock.html)

This returns in [lesson 11](../phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md): every schema/query/routine decision also needs a permission and recovery story.

## Summary
- You worked through how to apply ordered migrations using a ledger and transactional runner.
- You worked through how to distinguish repeatable runner behavior from blindly idempotent DDL.
- You worked through how to choose a safe correction or rollback strategy for a deployed change.
- The code and derived output remain written but not run; the draft notice is intentional.

## Next lesson
[04. CTEs and recursive queries](../phase-2-querying/04-ctes-and-recursive-queries.md): Factor an aggregate query into a named CTE.
