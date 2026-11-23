---
track: databases
level: 201
phase: 2
phase_name: querying
lesson: 05
title: "Window functions"
time: 45 min
prerequisites: [201.2.04]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/201-hero-to-super-hero/phase-2-querying/05-window-functions/
assets: []
---

# 05. Window functions

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Rank detail rows per partition with deliberate tie behavior.
- Calculate a deterministic running total and previous-row value.
- Filter window results in an outer query.

## Recap
- Does GROUP BY retain one output row per sale?
  <details><summary>Answer</summary>No. It collapses rows into groups.</details>
- How long does a CTE name exist?
  <details><summary>Answer</summary>One statement; it can feed an outer SELECT in that statement.</details>

## Why it matters
A team report often needs both every sale and a comparison with neighboring sales. GROUP BY removes detail. A window calculation retains each row while looking across a related set.

## What you will build
A four-sale leaderboard with tied ranks, running amounts and a deterministic winner per team.

## Before you start
- Finished [Databases 101](../../101-zero-to-hero/phase-3-designing/12-library-project.md): Docker PostgreSQL, psql/IDE connections, joins, transactions and basic indexes. No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the same `postgres:17-alpine` image as 101. Docker/Compose versions above are the inherited authoring baseline, not a new runtime check. The tag pins major version/flavour, not a patch digest.
- Time: 45 minutes including reading, typing and exercise. Allow extra time if retyping files.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/201-hero-to-super-hero/phase-2-querying/05-window-functions/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-201-phase-2-querying.zip`.
- **One database lab at a time:** stop the previous 101/201 or capstone lab before using 127.0.0.1:5432. Do not stop unrelated services. These lessons are independent; do not carry a schema forward.
- All reset scripts/passwords are disposable local examples. Never aim them at work data. `learner` is the official image's initial administrative user, not an application login design.
- SQL, Docker, negative cases and IDE steps have not been run for this lesson. Result rows are derived by hand; variable tool output is described, not invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101` with your file manager. Obtain the source folder from the repository link above, or extract the phase ZIP: Windows **right-click > Extract All**; macOS double-click; Linux use your archive manager's **Extract Here**. Move `databases-201-phase-2-querying` into `code101`. Keep `05-window-functions/code` and its sibling `exercise` together.
2. Without a pack, create the same `databases-201-phase-2-querying/05-window-functions/code` structure and sibling `exercise/starter` and `exercise/solution` folders using **New Folder**. You will create every file shown below. Leave the finished solution unopened until you try the exercise.
3. Open a terminal (Windows: type `powershell` in File Explorer's address bar in the code folder; macOS/Linux: open Terminal). Do not type a prompt's `>` or `$`. The text before the prompt shows your current directory. Recover to this exact folder if needed:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-201-phase-2-querying\05-window-functions\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-201-phase-2-querying/05-window-functions/code"
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

This file is genuinely identical to [201 lesson 01, Step 2](../phase-1-schema-design/01-data-modeling-and-3nf.md#step-2-save-the-complete-compose-configuration). Repeat that step with only these differences: workspace `05-window-functions` instead of `01-data-modeling-and-3nf`, project `code101-db201-05` instead of `code101-db201-01`, and this lesson's SQL. **No YAML line changes.** Full configuration is repeated to keep this pack standalone.

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
A **window function** computes across related rows while retaining detail rows. Its OVER clause defines a **partition** (rows with the same team), an order and, for frame-sensitive operations, a **frame** (the subset considered for this row).

row_number assigns distinct positions. rank gives ties the same place and leaves gaps; dense_rank leaves no gaps. Here only row_number includes sale_id as a tiebreaker. Adding it to rank would destroy the intended amount ties.

The explicit ROWS frame means physical positions in the sorted partition, from the first row through the current one. The default ordered frame includes peers (equal sort keys), which can make a running sum jump over ties if you order only by sold_on. lag reads a previous partition row regardless of that aggregate frame; its third argument supplies 0 when there is no previous row.

Read/save all files before running. SQL ends statements with semicolons. Backslash commands are **psql client commands**, not server SQL: ON_ERROR_STOP stops at the first unexpected error; `\ir` includes relative to its containing script; unaligned format uses `|` between columns; footer off removes row-count footers; the null setting displays SQL NULL as `(null)`. Use psql for whole scripts; in an IDE select server SQL, not the backslash commands. The entry script arranges setup automatically. Never execute sample reset files on valuable data.

Defines the isolated example and seed. DROP SCHEMA app CASCADE removes the sample schema and its dependent objects. Use a disposable database.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.sales (
    sale_id bigint GENERATED ALWAYS AS IDENTITY,
    team text NOT NULL,
    rep text NOT NULL,
    sold_on date NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (sale_id),
    CONSTRAINT ck_sales_amount CHECK (amount > 0)
);
INSERT INTO app.sales (team, rep, sold_on, amount) VALUES
    ('North', 'Ava', DATE '2026-01-10', 100),
    ('North', 'Ben', DATE '2026-01-10', 100),
    ('North', 'Cora', DATE '2026-01-11', 60),
    ('South', 'Dan', DATE '2026-01-10', 80);
```

The entry script includes setup or the migration driver, then performs the worked example.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT team, rep, amount,
       row_number() OVER (PARTITION BY team ORDER BY amount DESC, sale_id) AS position,
       rank() OVER (PARTITION BY team ORDER BY amount DESC) AS place,
       dense_rank() OVER (PARTITION BY team ORDER BY amount DESC) AS dense_place,
       SUM(amount) OVER (
           PARTITION BY team ORDER BY sold_on, sale_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_amount,
       lag(amount, 1, 0) OVER (PARTITION BY team ORDER BY sold_on, sale_id) AS previous_amount
FROM app.sales ORDER BY team, sold_on, sale_id;
```

### Step 5. Start and inspect PostgreSQL
From this code folder use project `code101-db201-05` consistently. `-p` isolates names/volumes, not the shared host port. Keep Docker Desktop running. `up -d --wait` starts the service and waits for readiness; an initial image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and db container, then reports healthy readiness. Progress order, IDs and timings vary; no startup transcript is claimed.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 logs --no-log-prefix --tail 10 db
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
| Display name | `Code101 DB201 05` |

- JetBrains: **Database / Database Explorer > + > Data Source > PostgreSQL**; enter General fields, **Download missing driver files** if offered, then **SSH/SSL** off for this local lab, **Test Connection > OK > New Query Console**. Run selected SQL with Ctrl+Enter (Cmd+Enter on macOS).
- VS Code: Microsoft's **PostgreSQL** extension (`ms-ossdata.vscode-pgsql`), **PostgreSQL > Connections > + / Add New Connection > Parameters**; enter fields, **Advanced** port/SSL, then **Test Connection > Save & Connect > New Query**. Run selected SQL with Ctrl+Shift+E (Cmd+Shift+E on macOS). UI labels may vary; 101 links the vendor directions.
- Visual Studio is not VS Code. Built-in SQL Server Object Explorer is not a PostgreSQL tool; Npgsql alone does not install a Server Explorer provider. Use the existing provider if available, or the terminal/IDE routes above.

Run only selected queries after setup; do not casually reapply destructive setup. A socket connection inside db does not prove a host-network password works. Require TLS for remote production connections; disabling SSL is only for local practice.

## Run it
**Predict first:** Predict Cora place versus dense_place, and Ben running_amount. Why is Ava chosen over Ben for a single winner?


From this code folder run the entry file. `exec -T` runs the container client without a pseudo-terminal; `-X` ignores psql startup customization; `-q` suppresses routine tags; ON_ERROR_STOP fails fast; `-U`/`-d` name role/database; `-f` is the container file path. Quiet mode does not hide server errors/notices on stderr.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run:**

```text
team|rep|amount|position|place|dense_place|running_amount|previous_amount
North|Ava|100|1|1|1|100|0
North|Ben|100|2|1|1|200|100
North|Cora|60|3|3|2|260|100
South|Dan|80|1|1|1|80|0
```

North amounts sort 100, 100, 60: rank is 1,1,3; dense_rank is 1,1,2. Running amounts in date/ID order are 100,200,260. South starts a fresh partition at 80, with lag default 0.

These are hand-derived unaligned result tables, not captured output. Missing-schema/dependency notices may appear on stderr; they are not data rows. An unexpected error means stop and inspect the first failing file/statement before continuing.

## How it works
The input has four rows, and the window SELECT still has four. The ordered windows calculate different facts: leaderboard order is amount descending, while running/previous values use chronological order plus sale_id. The final ORDER BY controls presentation independently of the window order.

**Why this, not that:** use a window when detail plus context belongs in one result, not a join to an accidentally multiplying aggregate. Use GROUP BY when you really want just one row per team. Windows see rows after WHERE and grouping, so filtering on a window result in that same WHERE is not allowed. The exercise computes position in a CTE, then filters the resulting column outside.

The amount is an integer count of whole currency units to keep arithmetic visible; fractional real-world amounts need an exact numeric type. A zero lag default is a reporting choice and is not evidence that a previous sale existed.

## Try it
Keep db running after Run it. The starter resets the disposable schema, except lesson 03 which expects the already-applied migrations and rolls back its trial column.

1. **Guided:** Return exactly one highest sale per team. Break amount ties by the smaller sale_id. Fill the window and outer filter TODOs.
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
WITH ranked AS (
    SELECT team, rep, amount,
           -- TODO: number each team's rows by amount descending, then sale_id.
           0 AS position
    FROM app.sales
)
-- TODO: keep position 1 and order by team.
SELECT team, rep, amount FROM ranked WHERE false ORDER BY team;
```

3. Fill the TODOs, save, then run your working file from this code folder.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target after completing the TODOs:

**Expected output, not yet run:**

```text
team|rep|amount
North|Ava|100
South|Dan|80
```

The target is for the completed program, not the untouched starter, which deliberately may return no rows or an uncorrected value.

4. **Change:** Return all tied highest sales by switching to rank over amount only. Predict North will now have two rows, while South keeps one.
5. **Stretch (optional):** Decide whether a business leaderboard should rank sales or aggregate per representative first; describe how the meaning changes.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
WITH ranked AS (
    SELECT team, rep, amount,
           row_number() OVER (PARTITION BY team ORDER BY amount DESC, sale_id) AS position
    FROM app.sales
)
SELECT team, rep, amount FROM ranked WHERE position = 1 ORDER BY team;
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
docker compose -p code101-db201-05 stop
docker compose -p code101-db201-05 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: variable stop progress, then:

```text
db exited
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 down -v --remove-orphans
```

Expected output, not yet run: Compose removes this project container/network and saved volume; exact progress text varies. **-v destroys saved database data**, including the restored target in lesson 11. It does not erase other projects or the host dump file. Never use it on valuable data.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-05 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: no service rows; port 5432 is no longer held by this project.

## Check yourself
1. Predict rank and dense_rank for Cora.
   <details><summary>Answer</summary>3 and 2. Ava and Ben share first place; rank leaves the gap.</details>
2. What makes Ben running_amount exactly 200?
   <details><summary>Answer</summary>The ROWS frame and the unique chronological sort (sold_on, sale_id).</details>
3. Why is the winner filter outside ranked?
   <details><summary>Answer</summary>Window results are not available in the WHERE of the same query level.</details>

## Common mistakes
No new error transcript has been captured. These are symptoms; wording marked typical message is illustrative, not observed output.

| Symptom | Cause | Fix |
|---|---|---|
| Compose cannot find its configuration (typical message) | Terminal is in the wrong folder | Recover to code using Step 1; keep code/exercise siblings. |
| Old behavior persists | Unsaved file, hidden .sql.txt extension or wrong project | Save, check filename extensions and use the exact -p name in every command. |
| Startup cannot claim 5432 (typical message) | Another lab owns the host port | Stop the previous lab from its own code folder; never kill unrelated processes. |
| Tied amounts no longer share a rank | sale_id was added to the ranking ORDER BY | Use amount alone for peer rank; keep the tiebreaker for row_number. |
| Running totals jump on a shared date | The default peer-inclusive frame was used | Use an explicit ROWS frame and a deterministic row order. |
| An IDE rejects a backslash line (typical message) | psql meta-commands were sent as SQL | Use psql for whole scripts; select only server SQL in an IDE. |

## Best practice
Specify ordering and frame semantics rather than relying on peer-sensitive defaults. Source: [PostgreSQL 17: window tutorial](https://www.postgresql.org/docs/17/tutorial-window.html).

## Going further
Official PostgreSQL **17** references checked for this draft:
- [PostgreSQL 17: window tutorial](https://www.postgresql.org/docs/17/tutorial-window.html)
- [Window function reference](https://www.postgresql.org/docs/17/functions-window.html)

This returns in [lesson 11](../phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md): every schema/query/routine decision also needs a permission and recovery story.

## Summary
- You worked through how to rank detail rows per partition with deliberate tie behavior.
- You worked through how to calculate a deterministic running total and previous-row value.
- You worked through how to filter window results in an outer query.
- The code and derived output remain written but not run; the draft notice is intentional.

## Next lesson
[06. JSONB without abandoning a schema](../phase-2-querying/06-jsonb.md): Choose relational columns versus optional JSONB attributes.
