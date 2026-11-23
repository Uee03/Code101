---
track: databases
level: 101
phase: 3
phase_name: designing
lesson: 09
title: "Good design"
time: 25 min
prerequisites: [101.2.08]
versions: { docker: "29.9.3", compose: "5.7.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0
source: source/databases/101-zero-to-hero/phase-3-designing/09-good-design/
assets: []
---

# 09. Good design

## Why it matters
If you copy a member email onto every loan card, changing it means finding every copy. Keep the member fact once and link to it instead. Good design reduces contradictory copies, while constraints stop impossible facts entering the cabinet.

## What you will build
A member list with unique emails and a book catalogue with required fields, non-negative amounts and useful defaults.

## Before you start
- Docker installed and running in Linux-container mode. Follow [Docker 101 lesson 01](../../../docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md) first if needed. No system-wide PostgreSQL or psql install, and no host programming language needed.
- Author baseline: Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine. A plain-text editor is enough (Notepad on Windows works); optional IDE setup is in lesson 02.
- Time: about 25 minutes (about 5 minutes per new idea plus setup).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/databases/101-zero-to-hero/phase-3-designing/09-good-design/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). Either way, keep a `code` folder and an `exercise` folder side by side: Compose mounts both.
- Work on **one database lesson at a time**. Finish the previous lesson's stop/cleanup before starting this one: every lab deliberately uses host port 5432.
- All data and credentials here are disposable local examples. The SQL reset scripts remove their sample schema; never point them at your own or an employer's data. Do not share the tutorial password with a real service.

## Steps
### Step 1. Make your lesson folder and open a terminal
1. Your home folder is `C:\Users\<your-name>` on Windows (open File Explorer and type `%USERPROFILE%` in its address bar), `/Users/<your-name>` on macOS, or `/home/<your-name>` on Linux. A terminal is a window in which you type commands and press Enter. Do not type a prompt's `>` or `$` character.
2. Open a terminal: on Windows press Start, type **Windows PowerShell** and open it. On macOS open Terminal; on Linux open your terminal application.
3. Create the lesson folder `code101/databases-101-phase-3-designing/09-good-design/` with a `code` folder and, beside it, an `exercise/starter` folder. (If you downloaded the optional pack, copy the `09-good-design` folder from the repository's `source/databases/101-zero-to-hero/phase-3-designing/` into `code101/databases-101-phase-3-designing/` instead, and skip the commands below.)

**Terminal (PowerShell; folder: any)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\databases-101-phase-3-designing\09-good-design\code","$HOME\code101\databases-101-phase-3-designing\09-good-design\exercise\starter" | Out-Null
```

**Terminal (macOS/Linux alternative; folder: any)**
```bash
mkdir -p "$HOME/code101/databases-101-phase-3-designing/09-good-design/code" "$HOME/code101/databases-101-phase-3-designing/09-good-design/exercise/starter"
```

4. The prompt shows the current folder before `>` or `$`. If it is not the code folder, move there with the appropriate command below. Keep this terminal in that folder for the entire lesson.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-3-designing\09-good-design\code"
```

**Terminal (macOS/Linux; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```bash
cd "$HOME/code101/databases-101-phase-3-designing/09-good-design/code"
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

This is **identical** to [lesson 01, Step 2](../phase-1-first-queries/01-what-a-database-is.md#step-2-read-the-full-docker-configuration), including the loopback port, named volume, both read-only mounts and healthcheck. Repeat those same configuration steps; the concrete differences are the current lesson folder `09-good-design` and command project name `code101-db09` instead of `code101-db01`. There are **no changed configuration lines**. `-p` prefixes this lesson's container, volume and network names. No Dockerfile or .dockerignore is needed because nothing is built.

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

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-3-designing/09-good-design/code`)**
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
**Normalization** means giving each fact one sensible home and linking related facts with keys. A catalogue cell should contain one value, not a comma-separated list of books. Keep members separate from books, and loans separate from both: changing an email then changes one row, not every loan. Do not copy a book title into every new loan as in the early lesson 06 sketch; lesson 12 uses book_id instead. Splitting data does not mean splitting every word into a new table: group facts by the thing they describe.

`NOT NULL` requires a value but does not forbid an empty string. `UNIQUE` prevents repeated emails; pairing it with NOT NULL also requires an email. `CHECK (stock >= 0)` rejects negative stock, and another check rejects negative prices. A CHECK alone permits NULL when its expression is unknown; NOT NULL handles that separately. `DEFAULT 0` supplies stock when INSERT omits it; `DEFAULT CURRENT_DATE` supplies the server date for joined_on. Defaults do not replace an explicitly supplied NULL.

**snake_case** means lowercase words joined by underscores. Use plural table names, singular column names, dedicated library schema, and named `pk_`, `uq_`, `ck_` constraints. This training model assumes one catalogue entry per unique title; real libraries distinguish editions and copies. Do not blindly make every real-world title unique.

Lines beginning with a backslash are **psql commands**, interpreted by the client, not SQL sent to the server. `\set ON_ERROR_STOP on` stops a script on its first error. `\pset null '(none)'` makes missing values visible. `\ir` reads another file relative to the including script, or at the shown absolute container path. Run these whole files with psql, not an IDE SQL runner; an IDE can run the SQL statements alone.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS library CASCADE;
CREATE SCHEMA library;
CREATE TABLE library.members (
    member_id bigint GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    email text NOT NULL,
    joined_on date NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT uq_members_email UNIQUE (email)
);
CREATE TABLE library.books (
    book_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    stock integer NOT NULL DEFAULT 0,
    price numeric(10,2) NOT NULL,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_title UNIQUE (title),
    CONSTRAINT ck_books_stock CHECK (stock >= 0),
    CONSTRAINT ck_books_price CHECK (price >= 0)
);
INSERT INTO library.members (name, email)
VALUES ('Ava', 'ava@example.test'), ('Ben', 'ben@example.test');
INSERT INTO library.books (title, stock, price)
VALUES ('Field Notes', 3, 12.50), ('City Maps', 2, 8.00);
```

This file resets the dedicated sample schema, defines the tables and inserts the starting rows. A first-run notice saying the schema does not exist is harmless: IF EXISTS handles that. Run the main script below to include setup automatically.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir setup.sql
INSERT INTO library.members (name, email)
VALUES ('Cora', 'cora@example.test') RETURNING name, email;
INSERT INTO library.books (title, price)
VALUES ('Trail Guide', 9.00) RETURNING title, stock;
SELECT name, email FROM library.members ORDER BY member_id;
```

### Step 5. Start and inspect PostgreSQL
In this code folder, keep Docker Desktop open. `-p` chooses a project name; use this same name for all commands in this lesson. `up` creates/starts the service, `-d` leaves it in the background, and `--wait` waits for the healthcheck. The first run downloads the image if necessary.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 up -d --wait
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Volume code101-db09_pg_data Creating 
 Volume code101-db09_pg_data Creating 
 Network code101-db09_default Creating 
 Network code101-db09_default Creating 
 Volume code101-db09_pg_data Created 
 Volume code101-db09_pg_data Created 
 Network code101-db09_default Created 
 Network code101-db09_default Created 
 Container code101-db09-db-1 Creating 
 Container code101-db09-db-1 Created 
 Container code101-db09-db-1 Starting 
 Container code101-db09-db-1 Started 
 Container code101-db09-db-1 Waiting 
 Container code101-db09-db-1 Healthy 
```

Check status. The format prints service name, running state and health, without variable IDs or uptime. The quoted format works in PowerShell and macOS/Linux shells.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured status output**
```text
db running healthy
```

Read the last two log lines (`--no-log-prefix` hides the Compose service prefix; `--tail 2` avoids a wall of text). Times and process numbers will differ; look for readiness.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 logs --no-log-prefix --tail 2 db
```

**Captured log output (your timestamps and process numbers differ)**
```text
2026-11-23 06:13:07.284 UTC [57] LOG:  database system was shut down at 2026-11-23 06:13:07 UTC
2026-11-23 06:13:07.288 UTC [1] LOG:  database system is ready to accept connections
```

## Run it
Run the entry script once from this lesson code folder. `-T` avoids an interactive terminal, `-X` ignores personal psql startup settings, `-q` suppresses routine command tags, `-v ON_ERROR_STOP=1` stops on an SQL error, `-U` chooses the user, `-d` the database, and `-f` the file **inside** the container. Every later lesson uses this identical command pattern with its own project and filename.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected psql output (captured from these files)**
```text
 name |       email       
------+-------------------
 Cora | cora@example.test
(1 row)

    title    | stock 
-------------+-------
 Trail Guide |     0
(1 row)

 name |       email       
------+-------------------
 Ava  | ava@example.test
 Ben  | ben@example.test
 Cora | cora@example.test
(3 rows)
```

Notices about a schema being absent (first run) or dependent objects being dropped (repeat reset) go to a separate diagnostic stream. They do not change these result tables. Quiet mode hides CREATE/INSERT/BEGIN command tags, not errors.

## How it works
The Compose service starts first. psql reads lesson.sql, applies its client display/error settings, includes setup.sql if present, and sends the SQL statements in file order. SQL semicolons, not line breaks, separate statements. The server returns the result tables above.

New terms for this lesson (also in the track glossary):

- **normalization**: Organising facts to reduce duplication and conflicting updates.
- **NOT NULL**: A constraint requiring a value.
- **UNIQUE**: A constraint rejecting duplicate values or combinations.
- **CHECK**: A constraint requiring an expression not to be false.
- **DEFAULT**: A value supplied when a column is omitted or DEFAULT is requested.
- **snake_case**: Lowercase names with words separated by underscores.
- **CURRENT_DATE**: The current calendar date according to the database session.

## Try it
Insert a book named `Forest Walks` costing 15.00, without specifying stock. Return title, stock and price. The stock column should show the default, zero.

1. Keep db running. Create `exercise.sql` in this code folder: copy the starter (with the optional pack) or type the contents shown in step 2.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-3-designing/09-good-design/code`)**
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

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

An answer matching the supplied solution produces:

**Expected exercise output (captured from solution)**
```text
    title     | stock | price 
--------------+-------+-------
 Forest Walks |     0 | 15.00
(1 row)
```

<details><summary>Solution</summary>

4. If stuck, replace your entire code/exercise.sql with this file, save, then run the same exercise command in step 3. The copy in exercise/solution is the same answer; you do not need a separate server for it.

**File: `code/exercise.sql` (solution; supplied at `exercise/solution/exercise.sql`)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/setup.sql
INSERT INTO library.books (title, price)
VALUES ('Forest Walks', 15.00) RETURNING title, stock, price;
```

The setup runs again first, then only the exercise changes or query, which is why the result does not depend on a previous attempt.

</details>

### Finish: stop, inspect, then remove this disposable lab
`stop` stops the server **without deleting saved data**. A later up command with the same project and .env starts it again with that data. Run these commands only after finishing the query, exercise and any backup work.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 stop
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db09-db-1 Stopping 
 Container code101-db09-db-1 Stopped 
```

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 ps --all --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured stopped status output**
```text
db exited 
```

For this disposable course lab, now delete the container, its project network and **its saved volume**. `-v` is destructive; never use it on data you want to keep. `--remove-orphans` also removes leftover services belonging to this project, not unrelated projects. This frees 5432 for the next lesson.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/09-good-design/code`)**
```powershell
docker compose -p code101-db09 down -v --remove-orphans
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db09-db-1 Stopping 
 Container code101-db09-db-1 Stopped 
 Container code101-db09-db-1 Removing 
 Container code101-db09-db-1 Removed 
 Volume code101-db09_pg_data Removing 
 Network code101-db09_default Removing 
 Volume code101-db09_pg_data Removed 
 Network code101-db09_default Removed 
```

## Check yourself
1. Does DEFAULT override an explicitly supplied NULL?
   <details><summary>Answer</summary>No.</details>
2. What stops a negative stock value?
   <details><summary>Answer</summary>The ck_books_stock CHECK constraint.</details>
3. Why not store an email on each loan?
   <details><summary>Answer</summary>It duplicates a member fact and can leave conflicting copies after an update.</details>

## Common mistakes
| Symptom or real error text | Cause | Fix |
|---|---|---|
| `ERROR:  syntax error at or near "SELEC"` | Deliberately typed SELEC rather than SELECT | Correct the keyword, keep text in single quotes, save the file, and rerun. In interactive psql a missing semicolon means it is still waiting; add it. |
| `ERROR:  relation "missing_books" does not exist` | Asked for a table that does not exist in this database | Use the fully qualified table name shown here and run the complete script, not just its last SELECT; its setup creates the table. |
| `ERROR:  null value in column "name" of relation "members" violates not-null constraint` | A member name was explicitly NULL | Supply a real name; DEFAULT is not a replacement for NULL. |
| `ERROR:  duplicate key value violates unique constraint "uq_members_email"` | The email already belongs to a member | Use a different email, or update the correct existing member. |
| `ERROR:  new row for relation "books" violates check constraint "ck_books_stock"` | Stock was negative | Use zero or a positive stock value. |
| `Bind for 127.0.0.1:5432 failed: port is already allocated` | The previous database lab is still running and owns port 5432 | Run that lab's `down -v --remove-orphans` from its own code folder, then repeat the up command here. Do not kill unrelated programs. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to this lesson's `code` folder (the `Set-Location` or `cd` command in Step 1) and run the command again. |
| `error during connect` or `failed to connect to the docker API` ... `check if the path is correct and if the daemon is running` (typical message) | Docker Desktop is not running | Start Docker Desktop, wait until it says the engine is running, then repeat the command. |
| `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` (typical message), then the container exits | You forgot to copy `.env.example` to `.env` in the code folder | Run the copy command from the `.env` step in the code folder, then `docker compose -p code101-db09 down -v` and the up command again. |

The `SELEC`, `missing_books` and constraint strings were deliberately triggered, as was the port message in lesson 01; the three marked typical message were not captured here.

## Best practice
Use database constraints as a backstop, not just checks in a screen or application. Source: [PostgreSQL constraints](https://www.postgresql.org/docs/17/ddl-constraints.html).

## Next lesson
[10. Transactions](10-transactions.md): A 25.00 transfer that is committed, then a tentative 10.00 debit that is rolled back.
