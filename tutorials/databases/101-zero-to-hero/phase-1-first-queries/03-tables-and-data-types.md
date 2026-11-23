---
track: databases
level: 101
phase: 1
phase_name: first-queries
lesson: 03
title: "Tables and data types"
time: 25 min
prerequisites: [101.1.02]
versions: { docker: "29.9.3", compose: "5.7.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0
source: source/databases/101-zero-to-hero/phase-1-first-queries/03-tables-and-data-types/
assets: []
---

# 03. Tables and data types

## Why it matters
A library catalogue has one card per book and the same labelled spaces on every card. A table follows that pattern: each row is one record, and each column has a label and a kind of value. Types catch mix-ups such as putting a title into a price field.

## What you will build
A four-row book catalogue with text, whole numbers, exact decimal prices, yes/no values and dates.

## Before you start
- Docker installed and running in Linux-container mode. Follow [Docker 101 lesson 01](../../../docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md) first if needed. No system-wide PostgreSQL or psql install, and no host programming language needed.
- Author baseline: Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine. A plain-text editor is enough (Notepad on Windows works); optional IDE setup is in lesson 02.
- Time: about 25 minutes (about 5 minutes per new idea plus setup).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/databases/101-zero-to-hero/phase-1-first-queries/03-tables-and-data-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). Either way, keep a `code` folder and an `exercise` folder side by side: Compose mounts both.
- Work on **one database lesson at a time**. Finish the previous lesson's stop/cleanup before starting this one: every lab deliberately uses host port 5432.
- All data and credentials here are disposable local examples. The SQL reset scripts remove their sample schema; never point them at your own or an employer's data. Do not share the tutorial password with a real service.

## Steps
### Step 1. Make your lesson folder and open a terminal
1. Your home folder is `C:\Users\<your-name>` on Windows (open File Explorer and type `%USERPROFILE%` in its address bar), `/Users/<your-name>` on macOS, or `/home/<your-name>` on Linux. A terminal is a window in which you type commands and press Enter. Do not type a prompt's `>` or `$` character.
2. Open a terminal: on Windows press Start, type **Windows PowerShell** and open it. On macOS open Terminal; on Linux open your terminal application.
3. Create the lesson folder `code101/databases-101-phase-1-first-queries/03-tables-and-data-types/` with a `code` folder and, beside it, an `exercise/starter` folder. (If you downloaded the optional pack, copy the `03-tables-and-data-types` folder from the repository's `source/databases/101-zero-to-hero/phase-1-first-queries/` into `code101/databases-101-phase-1-first-queries/` instead, and skip the commands below.)

**Terminal (PowerShell; folder: any)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\databases-101-phase-1-first-queries\03-tables-and-data-types\code","$HOME\code101\databases-101-phase-1-first-queries\03-tables-and-data-types\exercise\starter" | Out-Null
```

**Terminal (macOS/Linux alternative; folder: any)**
```bash
mkdir -p "$HOME/code101/databases-101-phase-1-first-queries/03-tables-and-data-types/code" "$HOME/code101/databases-101-phase-1-first-queries/03-tables-and-data-types/exercise/starter"
```

4. The prompt shows the current folder before `>` or `$`. If it is not the code folder, move there with the appropriate command below. Keep this terminal in that folder for the entire lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-1-first-queries\03-tables-and-data-types\code"
```

**Terminal (macOS/Linux; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```bash
cd "$HOME/code101/databases-101-phase-1-first-queries/03-tables-and-data-types/code"
```

Open this code folder in your editor. Create each file shown below: choose **File > New**, type the shown contents, then **Save As** in this code folder with the exact filename, not a trailing .txt (with the optional pack the files already exist; open each one to compare). Enable **View > Show > File name extensions** in Windows Explorer to check. Save after each change (Ctrl+S, or Cmd+S on macOS); a dot on an editor tab often means unsaved changes.

### Step 2. Read the full Docker configuration
The indentation below uses spaces. Keep every line in this file.

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

This is **identical** to [lesson 01, Step 2](01-what-a-database-is.md#step-2-read-the-full-docker-configuration), including the loopback port, named volume, both read-only mounts and healthcheck. Repeat those same configuration steps; the concrete differences are the current lesson folder `03-tables-and-data-types` and command project name `code101-db03` instead of `code101-db01`. There are **no changed configuration lines**. `-p` prefixes this lesson's container, volume and network names. No Dockerfile or .dockerignore is needed because nothing is built.

### Step 3. Create the local environment file
First open the example. A leading `#` makes a comment, not a setting.

**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

`POSTGRES_DB` names the initial database; `POSTGRES_USER` names its initial administrative login; `POSTGRES_PASSWORD` is the disposable local password. Compose reads these from a file literally named `.env` in this code folder. Changing the template alone does not change it.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```bash
cp .env.example .env
```

The copy succeeds without printing text. The complete generated file is:

**File: `code/.env` (created locally; not shipped)**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

These initialisation settings apply only when the data volume is empty. Editing the password later does not change an existing database login. For this disposable practice only, cleaning with down -v and then starting again creates a fresh volume; it destroys saved data.

**File: `code/.gitignore`**
```gitignore
.env
*.dump
```

This tells Git not to record the local .env file or dump archives. It does not encrypt anything; never put real credentials in the template.

### Step 4. Read and save the SQL files
A **table** stores records in rows and labelled columns. A **row** is one record; a **column** is one kind of fact. A **schema** is a named grouping of database objects, like a labelled drawer. The dot in `practice.books` means the books table in the practice schema. A **data type** limits the kinds of values a column accepts.

`DROP SCHEMA IF EXISTS practice CASCADE` resets only our sample drawer and everything inside it; `IF EXISTS` avoids an error on the first run. `CREATE SCHEMA` makes it again. `CREATE TABLE` lists column names and types inside parentheses, separated by commas. `integer` stores whole numbers, `text` stores words, `numeric(10,2)` stores exact decimals with ten total digits and two after the decimal point, `boolean` stores true/false, and `date` stores a calendar date. Use quoted year-month-day dates, not ambiguous day/month formats. psql displays true as `t`, false as `f`.

`INSERT INTO` names the target columns explicitly. Each parenthesised VALUES group becomes one row in that order. `NULL` means missing or unknown, not zero or an empty word. Our psql display setting prints `(none)` for it; that label is not stored data. `SELECT *` reads all columns. It is useful for exploration; explicit columns are more predictable in real reports. The setup has no keys yet: lesson 06 adds them.

Lines beginning with a backslash are **psql commands**, interpreted by the client, not SQL sent to the server. `\set ON_ERROR_STOP on` stops a script on its first error. `\pset null '(none)'` makes missing values visible. `\ir` reads another file relative to the including script, or at the shown absolute container path. Run these whole files with psql, not an IDE SQL runner; an IDE can run the SQL statements alone.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS practice CASCADE;
CREATE SCHEMA practice;
CREATE TABLE practice.books (
    book_id integer,
    title text,
    price numeric(10,2),
    available boolean,
    published_on date
);
INSERT INTO practice.books (book_id, title, price, available, published_on)
VALUES
    (1, 'Field Notes', 12.50, true, '2024-01-15'),
    (2, 'Quiet Rivers', 20.00, false, NULL),
    (3, 'City Maps', 8.00, true, '2023-06-01'),
    (4, 'Forest Walks', 15.00, true, '2025-03-10');
```

This file resets the dedicated sample schema, defines the tables and inserts the starting rows. A first-run notice saying the schema does not exist is harmless: IF EXISTS handles that. Run the main script below to include setup automatically.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
SELECT * FROM practice.books;
```

### Step 5. Start and inspect PostgreSQL
In this code folder, keep Docker Desktop open. `-p` chooses a project name; use this same name for all commands in this lesson. `up` creates/starts the service, `-d` leaves it in the background, and `--wait` waits for the healthcheck. The first run downloads the image if necessary.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 up -d --wait
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Network code101-db03_default Creating 
 Volume code101-db03_pg_data Creating 
 Volume code101-db03_pg_data Creating 
 Network code101-db03_default Creating 
 Volume code101-db03_pg_data Created 
 Volume code101-db03_pg_data Created 
 Network code101-db03_default Created 
 Network code101-db03_default Created 
 Container code101-db03-db-1 Creating 
 Container code101-db03-db-1 Created 
 Container code101-db03-db-1 Starting 
 Container code101-db03-db-1 Started 
 Container code101-db03-db-1 Waiting 
 Container code101-db03-db-1 Healthy 
```

Check status. The format prints service name, running state and health, without variable IDs or uptime. The quoted format works in PowerShell and macOS/Linux shells.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured status output**
```text
db running healthy
```

Read the last two log lines (`--no-log-prefix` hides the Compose service prefix; `--tail 2` avoids a wall of text). Times and process numbers will differ; look for readiness.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 logs --no-log-prefix --tail 2 db
```

**Captured log output (your timestamps and process numbers differ)**
```text
2026-11-23 06:12:23.475 UTC [58] LOG:  database system was shut down at 2026-11-23 06:12:23 UTC
2026-11-23 06:12:23.480 UTC [1] LOG:  database system is ready to accept connections
```

## Run it
Run the entry script once from this lesson code folder. `-T` avoids an interactive terminal, `-X` ignores personal psql startup settings, `-q` suppresses routine command tags, `-v ON_ERROR_STOP=1` stops on an SQL error, `-U` chooses the user, `-d` the database, and `-f` the file **inside** the container. Every later lesson uses this identical command pattern with its own project and filename.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected psql output (captured from these files)**
```text
 book_id |    title     | price | available | published_on 
---------+--------------+-------+-----------+--------------
       1 | Field Notes  | 12.50 | t         | 2024-01-15
       2 | Quiet Rivers | 20.00 | f         | (none)
       3 | City Maps    |  8.00 | t         | 2023-06-01
       4 | Forest Walks | 15.00 | t         | 2025-03-10
(4 rows)
```

Notices about a schema being absent (first run) or dependent objects being dropped (repeat reset) go to a separate diagnostic stream. They do not change these result tables. Quiet mode hides CREATE/INSERT/BEGIN command tags, not errors.

## How it works
The Compose service starts first. psql reads lesson.sql, applies its client display/error settings, includes setup.sql if present, and sends the SQL statements in file order. SQL semicolons, not line breaks, separate statements. The server returns the result tables above.

New terms for this lesson (also in the track glossary):

- **table**: A collection of rows with the same named columns.
- **row**: One record in a table.
- **column**: A named kind of fact in a table.
- **schema**: A named group of database objects.
- **data type**: A rule for what kind of value a column stores.
- **integer**: A whole-number type.
- **bigint**: A whole-number type with a larger range than integer.
- **text**: A type for character strings.
- **numeric(p,s)**: An exact decimal type with p total digits and s fractional digits.
- **boolean**: A true/false type.
- **date**: A calendar date without a time of day.
- **NULL**: A marker for a missing or unknown value.
- **statement**: One complete SQL instruction, usually ending in a semicolon.
- **CASCADE**: Also remove dependent objects when dropping a schema here.

## Try it
Read only `title` and `price`, in that order, from `practice.books`. Do not change any rows. No ORDER BY yet, so the observed insertion order is not a promise.

1. Keep db running. Create `exercise.sql` in this code folder: copy the starter (with the optional pack) or type the contents shown in step 2.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

2. Open exercise.sql. Its complete starting contents are:

**File: `code/exercise.sql` (copied starter)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
-- TODO: replace this SELECT with the exercise described in the lesson.
SELECT 'Try the exercise' AS next_step;
```

The initialisation include, where present, resets the sample; leave it in place. Replace the TODO comment and placeholder SELECT with your answer and save. This reset makes the exercise independent of writes in Run it. If you run the unchanged starter, it prints:

**Captured unchanged starter output**
```text
    next_step     
------------------
 Try the exercise
(1 row)
```

3. Run your saved exercise from the same code folder:

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

An answer matching the supplied solution produces:

**Expected exercise output (captured from solution)**
```text
    title     | price 
--------------+-------
 Field Notes  | 12.50
 Quiet Rivers | 20.00
 City Maps    |  8.00
 Forest Walks | 15.00
(4 rows)
```

<details><summary>Solution</summary>

4. If stuck, replace your entire code/exercise.sql with this file, save, then run the same exercise command in step 3. The copy in exercise/solution is the same answer; you do not need a separate server for it.

**File: `code/exercise.sql` (solution; supplied at `exercise/solution/exercise.sql`)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
SELECT title, price FROM practice.books;
```

The setup runs again first, then only the exercise changes or query, which is why the result does not depend on a previous attempt.

</details>

### Finish: stop, inspect, then remove this disposable lab
`stop` stops the server **without deleting saved data**. A later up command with the same project and .env starts it again with that data. Run these commands only after finishing the query, exercise and any backup work.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 stop
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db03-db-1 Stopping 
 Container code101-db03-db-1 Stopped 
```

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 ps --all --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured stopped status output**
```text
db exited 
```

For this disposable course lab, now delete the container, its project network and **its saved volume**. `-v` is destructive; never use it on data you want to keep. `--remove-orphans` also removes leftover services belonging to this project, not unrelated projects. This frees 5432 for the next lesson.

**Terminal (PowerShell; folder: `databases-101-phase-1-first-queries/03-tables-and-data-types/code`)**
```powershell
docker compose -p code101-db03 down -v --remove-orphans
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db03-db-1 Stopping 
 Container code101-db03-db-1 Stopped 
 Container code101-db03-db-1 Removing 
 Container code101-db03-db-1 Removed 
 Volume code101-db03_pg_data Removing 
 Network code101-db03_default Removing 
 Volume code101-db03_pg_data Removed 
 Network code101-db03_default Removed 
```

## Check yourself
1. How many rows does the INSERT add?
   <details><summary>Answer</summary>Four.</details>
2. Is NULL the same as zero?
   <details><summary>Answer</summary>No. It means missing or unknown.</details>
3. Why use numeric for prices?
   <details><summary>Answer</summary>It represents decimal amounts exactly rather than with floating-point rounding.</details>

## Common mistakes
| Symptom or real error text | Cause | Fix |
|---|---|---|
| `ERROR:  syntax error at or near "SELEC"` | Deliberately typed SELEC rather than SELECT | Correct the keyword, keep text in single quotes, save the file, and rerun. In interactive psql a missing semicolon means it is still waiting; add it. |
| `ERROR:  relation "missing_books" does not exist` | Asked for a table that does not exist in this database | Use the fully qualified table name shown here and run the complete script, not just its last SELECT; its setup creates the table. |
| `Bind for 127.0.0.1:5432 failed: port is already allocated` | The previous database lab is still running and owns port 5432 | Run that lab's `down -v --remove-orphans` from its own code folder, then repeat the up command here. Do not kill unrelated programs. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to this lesson's `code` folder (the `Set-Location` or `cd` command in Step 1) and run the command again. |
| `error during connect` or `failed to connect to the docker API` ... `check if the path is correct and if the daemon is running` (typical message) | Docker Desktop is not running | Start Docker Desktop, wait until it says the engine is running, then repeat the command. |
| `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` (typical message), then the container exits | You forgot to copy `.env.example` to `.env` in the code folder | Run the copy command from the `.env` step in the code folder, then `docker compose -p code101-db03 down -v` and the up command again. |

The `SELEC` and `missing_books` strings were deliberately triggered, as was the port message in lesson 01; the three marked typical message were not captured here.

## Best practice
Use explicit target column lists in INSERT so column order changes do not silently change your meaning. Source: [PostgreSQL INSERT](https://www.postgresql.org/docs/17/sql-insert.html).

## Next lesson
[04. Reading data](04-reading-data.md): Three focused reading queries: cheapest available books, titles beginning with F, and books with an unknown publication date.
