---
track: databases
level: 101
phase: 3
phase_name: designing
lesson: 12
title: "Project: a library database"
time: 75 min (two sittings)
prerequisites: [101.3.11]
versions: { docker: "29.9.3", compose: "5.7.0", postgres_image: "17-alpine" }
verified: 2026-11-23 on Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0
source: source/databases/101-zero-to-hero/phase-3-designing/12-library-project/
assets: []
---

# 12. Project: a library database

## Why it matters
A small library needs a catalogue, a member register and a loan ledger that agree with each other. You now have the pieces to build that system rather than just isolated queries. Reports answer useful questions, while permissions and backups help protect the work.

## What you will build
A three-table library created from schema.sql and seed.sql by one run.sql script, with active-loan reports, a parameter example, a read-only role, and a tested backup/restore walkthrough.

## Before you start
- Docker installed and running in Linux-container mode. Follow [Docker 101 lesson 01](../../../docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md) first if needed. No system-wide PostgreSQL or psql install, and no host programming language needed.
- Author baseline: Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine. A plain-text editor is enough (Notepad on Windows works); optional IDE setup is in lesson 02.
- Time: about 75 minutes in two sittings (about 5 minutes per new idea plus setup). The first sitting ends after "Run it"; the marked break comes before the backup section.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/databases/101-zero-to-hero/phase-3-designing/12-library-project/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`). Either way, keep a `code` folder and an `exercise` folder side by side: Compose mounts both.
- Work on **one database lesson at a time**. Finish the previous lesson's stop/cleanup before starting this one: every lab deliberately uses host port 5432.
- All data and credentials here are disposable local examples. The SQL reset scripts remove their sample schema; never point them at your own or an employer's data. Do not share the tutorial password with a real service.

## Steps
### Step 1. Make your lesson folder and open a terminal
1. Your home folder is `C:\Users\<your-name>` on Windows (open File Explorer and type `%USERPROFILE%` in its address bar), `/Users/<your-name>` on macOS, or `/home/<your-name>` on Linux. A terminal is a window in which you type commands and press Enter. Do not type a prompt's `>` or `$` character.
2. Open a terminal: on Windows press Start, type **Windows PowerShell** and open it. On macOS open Terminal; on Linux open your terminal application.
3. Create the lesson folder `code101/databases-101-phase-3-designing/12-library-project/` with a `code` folder and, beside it, an `exercise/starter` folder. (If you downloaded the optional pack, copy the `12-library-project` folder from the repository's `source/databases/101-zero-to-hero/phase-3-designing/` into `code101/databases-101-phase-3-designing/` instead, and skip the commands below.)

**Terminal (PowerShell; folder: any)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\databases-101-phase-3-designing\12-library-project\code","$HOME\code101\databases-101-phase-3-designing\12-library-project\exercise\starter" | Out-Null
```

**Terminal (macOS/Linux alternative; folder: any)**
```bash
mkdir -p "$HOME/code101/databases-101-phase-3-designing/12-library-project/code" "$HOME/code101/databases-101-phase-3-designing/12-library-project/exercise/starter"
```

4. The prompt shows the current folder before `>` or `$`. If it is not the code folder, move there with the appropriate command below. Keep this terminal in that folder for the entire lesson.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-3-designing\12-library-project\code"
```

**Terminal (macOS/Linux; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```bash
cd "$HOME/code101/databases-101-phase-3-designing/12-library-project/code"
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

This is **identical** to [lesson 01, Step 2](../phase-1-first-queries/01-what-a-database-is.md#step-2-read-the-full-docker-configuration), including the loopback port, named volume, both read-only mounts and healthcheck. Repeat those same configuration steps; the concrete differences are the current lesson folder `12-library-project` and command project name `code101-db12` instead of `code101-db01`. There are **no changed configuration lines**. `-p` prefixes this lesson's container, volume and network names. No Dockerfile or .dockerignore is needed because nothing is built.

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

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-3-designing/12-library-project/code`)**
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
The project has three **entities**, things we keep facts about: members, books and loans. Members and books each relate one-to-many to loans. The foreign keys stop loans pointing to nonexistent members or books. `borrowed_on` defaults to the current date; the fixed dates in seed.sql make the reports reproducible. `due_on >= borrowed_on` prevents a due date before borrowing. The return-date check accepts NULL for books still out, but rejects a known return date before borrowing.

run.sql includes schema, seed, reports and safety in that order. A **seed** is a small initial dataset. The first report joins all three tables and keeps unreturned loans. The second keeps all members with a LEFT JOIN, puts the active-loan test in ON so Cora remains, and counts `l.loan_id` rather than `*` so her missing match counts as zero. Group by member_id as well as name so two different members with the same name are not merged.

A **parameterized query** separates SQL structure from input values. PREPARE declares a bigint parameter; `$1` is the first value, not a string to concatenate. EXECUTE supplies the value 1; DEALLOCATE removes the prepared statement from this session. Application drivers such as Npgsql bind values separately too. Never assemble SQL by joining raw user input into the SQL text. This SQL demonstration is not a C# program and needs no host programming toolchain.

A **role** is a PostgreSQL permission identity. CREATE ROLE library_reader NOLOGIN makes a group of permissions, not a passwordless login. GRANT CONNECT permits entering this database, USAGE permits looking up this schema, and SELECT permits reading its existing tables. SET ROLE temporarily adopts it for a read; RESET ROLE returns to learner. This is **least privilege**: only the access needed for a job. New tables need new grants (or a deliberate default-privileges policy). A real application would use a separate login role and membership, not this tutorial superuser. POSTGRES_USER creates an administrative bootstrap role; learner is convenient for local schema creation, not safe application credentials.

A **backup** is a separate recoverable copy. A **restore** reconstructs data from it. The custom dump below includes this database schema and data, not cluster-wide roles; --no-acl and --no-owner deliberately omit original grants and ownership. Recreate reviewed least-privilege roles/grants separately when restoring a real system.

Lines beginning with a backslash are **psql commands**, interpreted by the client, not SQL sent to the server. `\set ON_ERROR_STOP on` stops a script on its first error. `\pset null '(none)'` makes missing values visible. `\ir` reads another file relative to the including script, or at the shown absolute container path. Run these whole files with psql, not an IDE SQL runner; an IDE can run the SQL statements alone.

Use a fresh lab volume for the project first run: safety.sql creates a role once. To restart the entire project later, finish the down -v cleanup below, then up again and rerun run.sql. This intentionally erases the sample database. Do not rerun only the seed: it would duplicate data.

**File: `code/schema.sql`**
```sql
DROP SCHEMA IF EXISTS library CASCADE;
CREATE SCHEMA library;
CREATE TABLE library.members (
    member_id bigint GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    email text NOT NULL,
    CONSTRAINT pk_members PRIMARY KEY (member_id),
    CONSTRAINT uq_members_email UNIQUE (email)
);
CREATE TABLE library.books (
    book_id bigint GENERATED ALWAYS AS IDENTITY,
    title text NOT NULL,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_title UNIQUE (title)
);
CREATE TABLE library.loans (
    loan_id bigint GENERATED ALWAYS AS IDENTITY,
    member_id bigint NOT NULL,
    book_id bigint NOT NULL,
    borrowed_on date NOT NULL DEFAULT CURRENT_DATE,
    due_on date NOT NULL,
    returned_on date,
    CONSTRAINT pk_loans PRIMARY KEY (loan_id),
    CONSTRAINT fk_loans_members FOREIGN KEY (member_id)
        REFERENCES library.members (member_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_loans_books FOREIGN KEY (book_id)
        REFERENCES library.books (book_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_loans_due CHECK (due_on >= borrowed_on),
    CONSTRAINT ck_loans_returned CHECK (returned_on >= borrowed_on)
);
```

Create tables before seeding. The named foreign keys and checks express rules, not report formatting. CASCADE here is a schema-reset operation, not the ON DELETE policy on a foreign key.

**File: `code/seed.sql`**
```sql
INSERT INTO library.members (name, email)
VALUES ('Ava', 'ava@example.test'), ('Ben', 'ben@example.test'),
       ('Cora', 'cora@example.test');
INSERT INTO library.books (title)
VALUES ('Field Notes'), ('Quiet Rivers'), ('City Maps'), ('Forest Walks');
INSERT INTO library.loans (member_id, book_id, borrowed_on, due_on, returned_on)
VALUES (1, 1, '2026-11-01', '2026-12-01', NULL),
       (1, 2, '2026-11-01', '2026-12-01', '2026-11-18'),
       (2, 3, '2026-11-05', '2026-12-05', NULL);
```

Seed members and books first so the loan references exist. Fixed dates keep this lesson independent of today's date.

**File: `code/reports.sql`**
```sql
SELECT m.name, b.title, l.due_on
FROM library.loans AS l
INNER JOIN library.members AS m ON m.member_id = l.member_id
INNER JOIN library.books AS b ON b.book_id = l.book_id
WHERE l.returned_on IS NULL
ORDER BY m.name, b.title;
SELECT m.name, COUNT(l.loan_id) AS active_loans
FROM library.members AS m
LEFT JOIN library.loans AS l
    ON l.member_id = m.member_id AND l.returned_on IS NULL
GROUP BY m.member_id, m.name
ORDER BY m.name;
```

These are the two useful reports: which books are out and how many active loans every member has.

**File: `code/safety.sql`**
```sql
PREPARE member_loans(bigint) AS
SELECT loan_id, book_id FROM library.loans
WHERE member_id = $1 ORDER BY loan_id;
EXECUTE member_loans(1);
DEALLOCATE member_loans;
CREATE ROLE library_reader NOLOGIN;
GRANT CONNECT ON DATABASE code101 TO library_reader;
GRANT USAGE ON SCHEMA library TO library_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA library TO library_reader;
SET ROLE library_reader;
SELECT current_user AS reading_as;
RESET ROLE;
```

The prepared query and permission demonstration run after the reports. NOLOGIN is intentional: this is a permission group, not another application password.

**File: `code/run.sql`**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir schema.sql
\ir seed.sql
\ir reports.sql
\ir safety.sql
```

This is the single entry script; its include lines run the other files in the shown order.

### Step 5. Start and inspect PostgreSQL
In this code folder, keep Docker Desktop open. `-p` chooses a project name; use this same name for all commands in this lesson. `up` creates/starts the service, `-d` leaves it in the background, and `--wait` waits for the healthcheck. The first run downloads the image if necessary.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 up -d --wait
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Network code101-db12_default Creating 
 Volume code101-db12_pg_data Creating 
 Volume code101-db12_pg_data Creating 
 Network code101-db12_default Creating 
 Volume code101-db12_pg_data Created 
 Volume code101-db12_pg_data Created 
 Network code101-db12_default Created 
 Network code101-db12_default Created 
 Container code101-db12-db-1 Creating 
 Container code101-db12-db-1 Created 
 Container code101-db12-db-1 Starting 
 Container code101-db12-db-1 Started 
 Container code101-db12-db-1 Waiting 
 Container code101-db12-db-1 Healthy 
```

Check status. The format prints service name, running state and health, without variable IDs or uptime. The quoted format works in PowerShell and macOS/Linux shells.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured status output**
```text
db running healthy
```

Read the last two log lines (`--no-log-prefix` hides the Compose service prefix; `--tail 2` avoids a wall of text). Times and process numbers will differ; look for readiness.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 logs --no-log-prefix --tail 2 db
```

**Captured log output (your timestamps and process numbers differ)**
```text
2026-11-23 06:22:59.095 UTC [57] LOG:  database system was shut down at 2026-11-23 06:22:58 UTC
2026-11-23 06:22:59.100 UTC [1] LOG:  database system is ready to accept connections
```

## Run it
Run the entry script once from this lesson code folder. `-T` avoids an interactive terminal, `-X` ignores personal psql startup settings, `-q` suppresses routine command tags, `-v ON_ERROR_STOP=1` stops on an SQL error, `-U` chooses the user, `-d` the database, and `-f` the file **inside** the container. Every later lesson uses this identical command pattern with its own project and filename.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/run.sql
```

**Expected psql output (captured from these files)**
```text
 name |    title    |   due_on   
------+-------------+------------
 Ava  | Field Notes | 2026-12-01
 Ben  | City Maps   | 2026-12-05
(2 rows)

 name | active_loans 
------+--------------
 Ava  |            1
 Ben  |            1
 Cora |            0
(3 rows)

 loan_id | book_id 
---------+---------
       1 |       1
       2 |       2
(2 rows)

   reading_as   
----------------
 library_reader
(1 row)
```

Notices about a schema being absent (first run) or dependent objects being dropped (repeat reset) go to a separate diagnostic stream. They do not change these result tables. Quiet mode hides CREATE/INSERT/BEGIN command tags, not errors.

## How it works
The Compose service starts first; psql then reads run.sql, schema.sql, seed.sql, reports.sql and safety.sql in that order. The server persists tables in pg_data; SQL result tables are just a view of those saved facts.

New terms for this lesson (also in the track glossary):

- **entity**: A kind of thing about which we store facts, such as a member or book.
- **seed**: An initial dataset used to populate a database.
- **parameterized query**: A query whose input values are bound separately from its SQL structure.
- **prepared statement**: A named SQL statement that can receive parameter values in a session.
- **role**: A PostgreSQL permission identity, with or without login ability.
- **NOLOGIN**: A role property that prevents using that role to log in directly.
- **GRANT**: A statement giving a role a permission.
- **least privilege**: Giving only the permissions needed for a task.
- **backup**: A separate copy from which data can be recovered.
- **restore**: Reconstructing a database from a backup.
- **pg_dump**: The PostgreSQL tool that exports one database.
- **pg_restore**: The PostgreSQL tool that restores a custom-format dump.
- **ACL**: Access control list: stored permission grants.

### Break point: end of the first sitting
You can stop here. Leave the lab running, or run the Finish commands further down and start again later: after a restart, repeat Step 5 and the Run it command before the backup section below.

### Back up, then restore into a separate database

Do this **after Run it above and before Try it below**, while db is running. All commands work in PowerShell, macOS and Linux. A custom-format dump is binary: do not use PowerShell output redirection to save it. Write it inside the container with -f, then copy it.

`pg_dump` exports one database. `-Fc` selects its custom archive format; `-f` chooses an inside-container file. --no-owner and --no-acl omit ownership and grants. PostgreSQL tools run only in the container.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db pg_dump -U learner -d code101 -Fc --no-owner --no-acl -f /tmp/library.dump
```

Successful completion prints no text.

Copy the backup out of the container onto your computer. A file left only in /tmp would disappear when the container is removed. Keep important backups on separate storage, not merely beside the original data.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 cp db:/tmp/library.dump ./library.dump
```

**Captured backup/restore output**
```text
 code101-db12-db-1 Copying code101-db12-db-1:/tmp/library.dump to ./library.dump
 code101-db12-db-1 Copied code101-db12-db-1:/tmp/library.dump to ./library.dump
```

Copy the local archive back to a different temporary name. This demonstrates restoring from the saved copy, rather than assuming the first temporary file survived.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 cp ./library.dump db:/tmp/restore.dump
```

**Captured backup/restore output**
```text
 code101-db12-db-1 Copying ./library.dump to code101-db12-db-1:/tmp/restore.dump
 code101-db12-db-1 Copied ./library.dump to code101-db12-db-1:/tmp/restore.dump
```

Create a new, empty database called code101_restore. It must not be your live database. Use this name only once per fresh lab volume; do not overwrite a real database.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db createdb -U learner code101_restore
```

Successful completion prints no text.

Restore into that empty database, deliberately without original owners or grants. This dump does not contain global roles; permissions need separate reviewed setup in a real recovery.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db pg_restore -U learner -d code101_restore --no-owner --no-acl /tmp/restore.dump
```

Successful completion prints no text.

Read the restored database, not the original. All three loan rows should be present.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db psql -X -q -U learner -d code101_restore -c "SELECT COUNT(*) AS restored_loans FROM library.loans;"
```

**Captured backup/restore output**
```text
 restored_loans 
----------------
              3
(1 row)
```

## Try it
Report every book title with its total number of loans, including books that have never been borrowed. Order by title. The supplied seed includes Forest Walks, which has never been borrowed: its count must be zero, not one.

1. Keep db running. Create `exercise.sql` in this code folder: copy the starter (with the optional pack) or type the contents shown in step 2.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux alternative; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

2. Open exercise.sql. Its complete starting contents are:

**File: `code/exercise.sql` (copied starter)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/schema.sql
\ir /scripts/seed.sql
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

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

An answer matching the supplied solution produces:

**Expected exercise output (captured from solution)**
```text
    title     | times_borrowed 
--------------+----------------
 City Maps    |              1
 Field Notes  |              1
 Forest Walks |              0
 Quiet Rivers |              1
(4 rows)
```

<details><summary>Solution</summary>

4. If stuck, replace your entire code/exercise.sql with this file, save, then run the same exercise command in step 3. The copy in exercise/solution is the same answer; you do not need a separate server for it.

**File: `code/exercise.sql` (solution; supplied at `exercise/solution/exercise.sql`)**
```sql
\set ON_ERROR_STOP on
\pset null '(none)'
\ir /scripts/schema.sql
\ir /scripts/seed.sql
SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM library.books AS b
LEFT JOIN library.loans AS l ON l.book_id = b.book_id
GROUP BY b.book_id, b.title ORDER BY b.title;
```

The setup runs again first, then only the exercise changes or query, which is why the result does not depend on a previous attempt.

</details>

The exercise recreates the library schema and its seed data, so it also removes the old schema/table grants used by the earlier reader demonstration. Re-run the project only with a fresh volume as described in Step 4; backups should be taken before the exercise.

### Finish: stop, inspect, then remove this disposable lab
`stop` stops the server **without deleting saved data**. A later up command with the same project and .env starts it again with that data. Run these commands only after finishing the query, exercise and any backup work.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 stop
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db12-db-1 Stopping 
 Container code101-db12-db-1 Stopped 
```

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 ps --all --format "{{.Service}} {{.State}} {{.Health}}"
```

**Captured stopped status output**
```text
db exited 
```

For this disposable course lab, now delete the container, its project network and **its saved volume**. `-v` is destructive; never use it on data you want to keep. `--remove-orphans` also removes leftover services belonging to this project, not unrelated projects. This frees 5432 for the next lesson.

**Terminal (PowerShell; folder: `databases-101-phase-3-designing/12-library-project/code`)**
```powershell
docker compose -p code101-db12 down -v --remove-orphans
```

**Captured output (timestamps and progress ordering can vary)**
```text
 Container code101-db12-db-1 Stopping 
 Container code101-db12-db-1 Stopped 
 Container code101-db12-db-1 Removing 
 Container code101-db12-db-1 Removed 
 Network code101-db12_default Removing 
 Volume code101-db12_pg_data Removing 
 Volume code101-db12_pg_data Removed 
 Network code101-db12_default Removed 
```

The library.dump you copied to your computer is not removed by Docker cleanup. Keep it if you want to practice later; for a real backup, copy it to separate protected storage. The container copy and both practice databases are gone with the volume.

## Check yourself
1. Why not store the member email in every loan?
   <details><summary>Answer</summary>It duplicates a member fact and makes updates inconsistent.</details>
2. Why COUNT(l.loan_id) rather than COUNT(*) after LEFT JOIN?
   <details><summary>Answer</summary>The non-NULL loan identifier counts only actual matching loans.</details>
3. Can library_reader log in directly?
   <details><summary>Answer</summary>No. It is a NOLOGIN permission group.</details>
4. Does a successful pg_dump prove recovery works?
   <details><summary>Answer</summary>No. Restore into a separate database and inspect the restored data.</details>

## Common mistakes
| Symptom or real error text | Cause | Fix |
|---|---|---|
| `ERROR:  syntax error at or near "SELEC"` | Deliberately typed SELEC rather than SELECT | Correct the keyword, keep text in single quotes, save the file, and rerun. In interactive psql a missing semicolon means it is still waiting; add it. |
| `ERROR:  relation "missing_books" does not exist` | Asked for a table that does not exist in this database | Use the fully qualified table name shown here and run the complete script, not just its last SELECT; its setup creates the table. |
| `ERROR:  insert or update on table "loans" violates foreign key constraint "fk_loans_members"` | A loan used member_id 999, which is not present | Insert the member first or choose an existing member_id. Do not disable the constraint. |
| `ERROR:  permission denied for table loans` | Tried DELETE after SET ROLE library_reader | This is the intended read-only boundary. RESET ROLE returns to the administrative tutorial login; do not give the reader DELETE just to silence it. |
| `Bind for 127.0.0.1:5432 failed: port is already allocated` | The previous database lab is still running and owns port 5432 | Run that lab's `down -v --remove-orphans` from its own code folder, then repeat the up command here. Do not kill unrelated programs. |
| `no configuration file provided: not found` (typical message) | You ran `docker compose` in the wrong folder, one without `docker-compose.yml` | Move to this lesson's `code` folder (the `Set-Location` or `cd` command in Step 1) and run the command again. |
| `error during connect` or `failed to connect to the docker API` ... `check if the path is correct and if the daemon is running` (typical message) | Docker Desktop is not running | Start Docker Desktop, wait until it says the engine is running, then repeat the command. |
| `The "POSTGRES_PASSWORD" variable is not set. Defaulting to a blank string.` (typical message), then the container exits | You forgot to copy `.env.example` to `.env` in the code folder | Run the copy command from the `.env` step in the code folder, then `docker compose -p code101-db12 down -v` and the up command again. |

The `SELEC`, `missing_books`, foreign key and `permission denied` strings were deliberately triggered, as was the port message in lesson 01; the three marked typical message were not captured here.

## Best practice
Practice restoring backups into a separate database, and keep real backups away from the original data volume. Source: [PostgreSQL pg_dump](https://www.postgresql.org/docs/17/app-pgdump.html).

Also: bind parameters rather than concatenating input ([Npgsql parameters](https://www.npgsql.org/doc/basic-usage.html)), and grant only necessary permissions ([PostgreSQL roles](https://www.postgresql.org/docs/17/user-manag.html)).

## Next lesson
None: you have completed Databases 101. Revisit [09. Good design](09-good-design.md), then adapt a **copy** of this library for your own catalogue; keep this baseline unchanged.
