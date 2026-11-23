---
track: databases
level: 201
phase: 2
phase_name: querying
lesson: 07
title: "Indexes in depth and reading EXPLAIN"
time: 60 min
prerequisites: [201.2.06]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain/
assets: []
---

# 07. Indexes in depth and reading EXPLAIN

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Match B-tree, partial, covering and GIN indexes to predicates.
- Read estimated versus actual rows, loops and buffer activity in EXPLAIN.
- Explain why a sequential scan can beat an eligible index.

## Recap
- Which JSONB index supports containment?
  <details><summary>Answer</summary>GIN with a suitable operator class; default jsonb_ops supports @>.</details>
- Does the order of returned rows follow the index automatically?
  <details><summary>Answer</summary>No. Request presentation order with ORDER BY.</details>

## Why it matters
Adding an index is a hypothesis, not a performance result. Its value depends on predicates, selectivity, row counts and write cost. Reading a plan lets you test the hypothesis instead of treating every sequential scan as a defect.

## What you will build
Four task rows, three illustrative indexes, deterministic query results and a separate plan-reading script with no invented plan output.

## Before you start
- Finished [Databases 101](../../101-zero-to-hero/phase-3-designing/12-library-project.md): Docker PostgreSQL, psql/IDE connections, joins, transactions and basic indexes. No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the same `postgres:17-alpine` image as 101. Docker/Compose versions above are the inherited authoring baseline, not a new runtime check. The tag pins major version/flavour, not a patch digest.
- Time: 60 minutes including reading, typing and exercise. Two sittings are reasonable: save the feature files before Step 5, then return for the run and exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-201-phase-2-querying.zip`.
- **One database lab at a time:** stop the previous 101/201 or capstone lab before using 127.0.0.1:5432. Do not stop unrelated services. These lessons are independent; do not carry a schema forward.
- All reset scripts/passwords are disposable local examples. Never aim them at work data. `learner` is the official image's initial administrative user, not an application login design.
- SQL, Docker, negative cases and IDE steps have not been run for this lesson. Result rows are derived by hand; variable tool output is described, not invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101` with your file manager. Obtain the source folder from the repository link above, or extract the phase ZIP: Windows **right-click > Extract All**; macOS double-click; Linux use your archive manager's **Extract Here**. Move `databases-201-phase-2-querying` into `code101`. Keep `07-indexes-and-explain/code` and its sibling `exercise` together.
2. Without a pack, create the same `databases-201-phase-2-querying/07-indexes-and-explain/code` structure and sibling `exercise/starter` and `exercise/solution` folders using **New Folder**. You will create every file shown below. Leave the finished solution unopened until you try the exercise.
3. Open a terminal (Windows: type `powershell` in File Explorer's address bar in the code folder; macOS/Linux: open Terminal). Do not type a prompt's `>` or `$`. The text before the prompt shows your current directory. Recover to this exact folder if needed:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-201-phase-2-querying\07-indexes-and-explain\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-201-phase-2-querying/07-indexes-and-explain/code"
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

This file is genuinely identical to [201 lesson 01, Step 2](../phase-1-schema-design/01-data-modeling-and-3nf.md#step-2-save-the-complete-compose-configuration). Repeat that step with only these differences: workspace `07-indexes-and-explain` instead of `01-data-modeling-and-3nf`, project `code101-db201-07` instead of `code101-db201-01`, and this lesson's SQL. **No YAML line changes.** Full configuration is repeated to keep this pack standalone.

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
A **B-tree** is an ordered index for equality, range and compatible ordering. A **partial index** contains only rows matching a predicate. A **covering index** stores all values needed for a query; INCLUDE adds payload values without making them search keys. The **heap** is the table storage; an index-only scan may still need heap visits to check row visibility.

The project_id here is only a scalar grouping label; the example omits a projects table so plan reading stays focused. In a real project model, give it a foreign key. **Selectivity** describes the fraction of rows a predicate matches; a selective predicate matches few rows. Four rows make correctness derivable, not performance representative.

| Workload | Candidate | Limitation |
|---|---|---|
| Project equality, due-date order | Composite B-tree (project_id, due_on, task_id) | Leftmost equalities are particularly useful in PostgreSQL 17 |
| Open-task queue | Same keys, WHERE state = open | Query must imply the predicate at planning time |
| Return title without extra payload lookup | INCLUDE (title) | Index-only benefit depends on visibility-map coverage |
| JSONB containment | GIN (metadata) | Does not serve arbitrary scalar sort order |

`ANALYZE` collects planner statistics. EXPLAIN shows estimates; EXPLAIN ANALYZE executes the query and adds measured work. Never use EXPLAIN ANALYZE casually on a write: it really performs it.

Read/save all files before running. SQL ends statements with semicolons. Backslash commands are **psql client commands**, not server SQL: ON_ERROR_STOP stops at the first unexpected error; `\ir` includes relative to its containing script; unaligned format uses `|` between columns; footer off removes row-count footers; the null setting displays SQL NULL as `(null)`. Use psql for whole scripts; in an IDE select server SQL, not the backslash commands. The entry script arranges setup automatically. Never execute sample reset files on valuable data.

Defines the isolated example and seed. DROP SCHEMA app CASCADE removes the sample schema and its dependent objects. Use a disposable database.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.tasks (
    task_id bigint GENERATED ALWAYS AS IDENTITY,
    project_id bigint NOT NULL,
    title text NOT NULL,
    state text NOT NULL,
    due_on date NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT pk_tasks PRIMARY KEY (task_id),
    CONSTRAINT ck_tasks_state CHECK (state IN ('open', 'done'))
);
INSERT INTO app.tasks (project_id, title, state, due_on, metadata) VALUES
    (1, 'Pack', 'open', DATE '2026-01-12', '{"priority":"high"}'),
    (1, 'Invoice', 'done', DATE '2026-01-10', '{}'),
    (1, 'Ship', 'open', DATE '2026-01-13', '{"priority":"high"}'),
    (2, 'Restock', 'open', DATE '2026-01-11', '{"priority":"low"}');
CREATE INDEX ix_tasks_project_due ON app.tasks (project_id, due_on, task_id) INCLUDE (title);
CREATE INDEX ix_tasks_open_due ON app.tasks (project_id, due_on, task_id)
    INCLUDE (title) WHERE state = 'open';
CREATE INDEX ix_tasks_metadata ON app.tasks USING gin (metadata);
ANALYZE app.tasks;
```

The entry script includes setup or the migration driver, then performs the worked example.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open'
ORDER BY due_on, task_id;
SELECT task_id FROM app.tasks
WHERE metadata @> '{"priority":"high"}'::jsonb ORDER BY task_id;
```

Separate plan inspection; unknown plan text is not part of the deterministic report.

**File: `code/plans.sql`**
```sql
\set ON_ERROR_STOP on
EXPLAIN (COSTS OFF)
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open' ORDER BY due_on, task_id;
EXPLAIN (ANALYZE, BUFFERS)
SELECT task_id, title, due_on FROM app.tasks
WHERE project_id = 1 AND state = 'open' ORDER BY due_on, task_id;
EXPLAIN (COSTS OFF)
SELECT task_id FROM app.tasks WHERE metadata @> '{"priority":"high"}'::jsonb;
```

### Step 5. Start and inspect PostgreSQL
From this code folder use project `code101-db201-07` consistently. `-p` isolates names/volumes, not the shared host port. Keep Docker Desktop running. `up -d --wait` starts the service and waits for readiness; an initial image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and db container, then reports healthy readiness. Progress order, IDs and timings vary; no startup transcript is claimed.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 logs --no-log-prefix --tail 10 db
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
| Display name | `Code101 DB201 07` |

- JetBrains: **Database / Database Explorer > + > Data Source > PostgreSQL**; enter General fields, **Download missing driver files** if offered, then **SSH/SSL** off for this local lab, **Test Connection > OK > New Query Console**. Run selected SQL with Ctrl+Enter (Cmd+Enter on macOS).
- VS Code: Microsoft's **PostgreSQL** extension (`ms-ossdata.vscode-pgsql`), **PostgreSQL > Connections > + / Add New Connection > Parameters**; enter fields, **Advanced** port/SSL, then **Test Connection > Save & Connect > New Query**. Run selected SQL with Ctrl+Shift+E (Cmd+Shift+E on macOS). UI labels may vary; 101 links the vendor directions.
- Visual Studio is not VS Code. Built-in SQL Server Object Explorer is not a PostgreSQL tool; Npgsql alone does not install a Server Explorer provider. Use the existing provider if available, or the terminal/IDE routes above.

Run only selected queries after setup; do not casually reapply destructive setup. A socket connection inside db does not prove a host-network password works. Require TLS for remote production connections; disabling SSL is only for local practice.

## Run it
**Predict first:** Predict the IDs of open project-1 tasks and high-priority documents. Then predict whether four rows guarantee an index scan (they do not).


From this code folder run the entry file. `exec -T` runs the container client without a pseudo-terminal; `-X` ignores psql startup customization; `-q` suppresses routine tags; ON_ERROR_STOP fails fast; `-U`/`-d` name role/database; `-f` is the container file path. Quiet mode does not hide server errors/notices on stderr.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run:**

```text
task_id|title|due_on
1|Pack|2026-01-12
3|Ship|2026-01-13
task_id
1
3
```

Project 1 open tasks are Pack on Jan 12 and Ship on Jan 13. Both have high-priority metadata; Invoice is done and Restock is project 2.

These are hand-derived unaligned result tables, not captured output. Missing-schema/dependency notices may appear on stderr; they are not data rows. An unexpected error means stop and inspect the first failing file/statement before continuing.

### Read your own plans, not a fabricated transcript
After Run it, from this code folder:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/plans.sql
```
Expected output, not yet run: PostgreSQL plan tables, whose exact nodes and numbers are intentionally not predicted. There is no captured plan in this lesson. **Typical shape, numbers vary:** a sequential scan with a filter and perhaps a sort is reasonable for this tiny seed; with representative selective data an index or bitmap path may become attractive. These are alternatives to look for, not literal plan text.

Compare the same SELECT in the first two plans: estimate versus actual, filter location, sort presence and buffers. For GIN, look for an index/bitmap path if justified by size, or explain why a scan is sensible. Do not disable sequential scans to manufacture a success. The plan script is separate from the deterministic report so unknown plan text is never asserted.

## How it works
The full project/due index and its partial counterpart intentionally overlap for teaching; do not blindly keep both in production. Equality on project_id narrows a leading B-tree key; due_on and task_id support the requested range/order. The partial index omits done rows. A general prepared predicate `state = $1` may not imply that partial predicate for all parameter values; do not assume eligibility.

**Why this, not that:** choose keys from the actual equality/range/order pattern rather than a universal most-selective-column slogan. Add INCLUDE only for a valuable read path: wider indexes cost disk and writes. GIN provides a different document search structure, not a substitute for B-tree ordering.

Read a plan bottom-up: identify scans, predicates and sorts, then the parent result. `cost` is an estimate in planner units, not milliseconds. Estimated rows describe output per execution of a node; compare with actual rows and loops, multiplying when reasoning about total work. Inspect rows removed by filters, shared buffer hits versus reads, and heap fetches on index-only scans. Buffer hits mean cached pages, not no work; buffer reads are not necessarily physical-disk reads because the OS can cache them. Large estimate errors suggest statistics or data-distribution issues before planner switches.

A sequential scan reads table pages and applies filters. An index scan finds matching entries then may visit scattered heap pages. A bitmap index/heap combination batches heap access. Reading four rows sequentially can be cheaper than setting up any lookup. No timing, cost, buffer count or speedup has been measured here.

## Try it
Keep db running after Run it. The starter resets the disposable schema, except lesson 03 which expects the already-applied migrations and rolls back its trial column.

1. **Guided:** Create a partial covering index for the done-task query using the TODO specification. The query result remains Invoice whether or not the planner chooses it.
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
\ir /scripts/setup.sql
-- TODO: create ix_tasks_done_due on (project_id, due_on, task_id).
-- TODO: include title and use a partial predicate for done rows.
SELECT title FROM app.tasks WHERE project_id = 1 AND state = 'done' ORDER BY due_on, task_id;
```

3. Fill the TODOs, save, then run your working file from this code folder.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target after completing the TODOs:

**Expected output, not yet run:**

```text
title
Invoice
```

The target is for the completed program, not the untouched starter, which deliberately may return no rows or an uncorrected value.

4. **Change:** Explain why the new done-only index is not useful for the open queue; inspect its predicate in your IDE.
5. **Stretch (optional):** On paper, choose which overlapping index to retain for a measured workload with many writes. State what evidence you would collect on representative data.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE INDEX ix_tasks_done_due ON app.tasks (project_id, due_on, task_id)
    INCLUDE (title) WHERE state = 'done';
SELECT title FROM app.tasks WHERE project_id = 1 AND state = 'done' ORDER BY due_on, task_id;
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
docker compose -p code101-db201-07 stop
docker compose -p code101-db201-07 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: variable stop progress, then:

```text
db exited
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 down -v --remove-orphans
```

Expected output, not yet run: Compose removes this project container/network and saved volume; exact progress text varies. **-v destroys saved database data**, including the restored target in lesson 11. It does not erase other projects or the host dump file. Never use it on valuable data.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-07 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: no service rows; port 5432 is no longer held by this project.

## Check yourself
1. Can INCLUDE(title) make title an efficient search key?
   <details><summary>Answer</summary>No. It is payload, not a B-tree search key.</details>
2. What is the difference between EXPLAIN and EXPLAIN ANALYZE?
   <details><summary>Answer</summary>The latter executes the statement and reports actual work; plain EXPLAIN plans it.</details>
3. Predict why this seed might use a sequential scan.
   <details><summary>Answer</summary>Four rows are cheap to read; the extra index/heap access can cost more.</details>

### Phase mixed review
Try without looking back; these connect this phase to earlier work.
- When does a CTE improve readability but not force storage?
  <details><summary>Answer</summary>A non-recursive, side-effect-free CTE referenced once can be folded into its parent in PostgreSQL 17.</details>
- Which window preserves one arbitrary but repeatable winner among ties?
  <details><summary>Answer</summary>row_number with an explicit unique tiebreaker.</details>
- Does a GIN on attributes replace foreign keys and all B-trees?
  <details><summary>Answer</summary>No. It accelerates supported document predicates, not relational integrity or every sort.</details>

## Common mistakes
No new error transcript has been captured. These are symptoms; wording marked typical message is illustrative, not observed output.

| Symptom | Cause | Fix |
|---|---|---|
| Compose cannot find its configuration (typical message) | Terminal is in the wrong folder | Recover to code using Step 1; keep code/exercise siblings. |
| Old behavior persists | Unsaved file, hidden .sql.txt extension or wrong project | Save, check filename extensions and use the exact -p name in every command. |
| Startup cannot claim 5432 (typical message) | Another lab owns the host port | Stop the previous lab from its own code folder; never kill unrelated processes. |
| An eligible index is not selected | Tiny data or a low-selectivity predicate makes a scan cheaper | Compare estimates and actual work on representative data; do not force a plan. |
| An index-only scan still has heap fetches | Some heap pages lack all-visible status | Understand visibility-map checks; INCLUDE is not a guarantee of zero heap work. |
| An IDE rejects a backslash line (typical message) | psql meta-commands were sent as SQL | Use psql for whole scripts; select only server SQL in an IDE. |

## Best practice
Treat index changes as workload hypotheses and validate with real plans before claiming a speedup. Source: [PostgreSQL 17: Using EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html).

## Going further
Official PostgreSQL **17** references checked for this draft:
- [PostgreSQL 17: Using EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html)
- [Index types](https://www.postgresql.org/docs/17/indexes-types.html)
- [Multicolumn indexes](https://www.postgresql.org/docs/17/indexes-multicolumn.html)
- [Partial indexes](https://www.postgresql.org/docs/17/indexes-partial.html)
- [Covering indexes](https://www.postgresql.org/docs/17/indexes-index-only-scans.html)

This returns in [lesson 11](../phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md): every schema/query/routine decision also needs a permission and recovery story.

## Summary
- You worked through how to match B-tree, partial, covering and GIN indexes to predicates.
- You worked through how to read estimated versus actual rows, loops and buffer activity in EXPLAIN.
- You worked through how to explain why a sequential scan can beat an eligible index.
- The code and derived output remain written but not run; the draft notice is intentional.

## Next lesson
[08. Views and materialized views](../phase-3-programmable-database/08-views-and-materialized-views.md): Expose a stable query interface using a view.
