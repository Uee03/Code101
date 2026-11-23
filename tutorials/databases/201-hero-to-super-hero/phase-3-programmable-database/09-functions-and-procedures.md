---
track: databases
level: 201
phase: 3
phase_name: programmable-database
lesson: 09
title: "Functions and stored procedures"
time: 65 min
prerequisites: [201.3.08]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/201-hero-to-super-hero/phase-3-programmable-database/09-functions-and-procedures/
assets: []
---

# 09. Functions and stored procedures

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Write and call a validated PL/pgSQL function.
- Use CALL and explain caller-owned versus procedure-owned transactions.
- Raise and handle custom SQLSTATE errors without parsing message text.

## Recap
- What does ROLLBACK cancel?
  <details><summary>Answer</summary>Changes in the current uncommitted transaction, not work committed earlier.</details>
- Is a view necessarily a permission boundary?
  <details><summary>Answer</summary>No. Caller/owner permission semantics must be chosen deliberately.</details>

## Why it matters
Some operations must be consistent across several applications. A small database routine can own a precise invariant near the data. Moving an entire service into procedural SQL would create a different maintenance problem.

## What you will build
A pure line-total function, a conditional order-payment procedure, two caught custom errors and an isolated procedure transaction-control demonstration.

## Before you start
- Finished [Databases 101](../../101-zero-to-hero/phase-3-designing/12-library-project.md): Docker PostgreSQL, psql/IDE connections, joins, transactions and basic indexes. No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the same `postgres:17-alpine` image as 101. Docker/Compose versions above are the inherited authoring baseline, not a new runtime check. The tag pins major version/flavour, not a patch digest.
- Time: 65 minutes including reading, typing and exercise. Two sittings are reasonable: save the feature files before Step 5, then return for the run and exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/201-hero-to-super-hero/phase-3-programmable-database/09-functions-and-procedures/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-201-phase-3-programmable-database.zip`.
- **One database lab at a time:** stop the previous 101/201 or capstone lab before using 127.0.0.1:5432. Do not stop unrelated services. These lessons are independent; do not carry a schema forward.
- All reset scripts/passwords are disposable local examples. Never aim them at work data. `learner` is the official image's initial administrative user, not an application login design.
- SQL, Docker, negative cases and IDE steps have not been run for this lesson. Result rows are derived by hand; variable tool output is described, not invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101` with your file manager. Obtain the source folder from the repository link above, or extract the phase ZIP: Windows **right-click > Extract All**; macOS double-click; Linux use your archive manager's **Extract Here**. Move `databases-201-phase-3-programmable-database` into `code101`. Keep `09-functions-and-procedures/code` and its sibling `exercise` together.
2. Without a pack, create the same `databases-201-phase-3-programmable-database/09-functions-and-procedures/code` structure and sibling `exercise/starter` and `exercise/solution` folders using **New Folder**. You will create every file shown below. Leave the finished solution unopened until you try the exercise.
3. Open a terminal (Windows: type `powershell` in File Explorer's address bar in the code folder; macOS/Linux: open Terminal). Do not type a prompt's `>` or `$`. The text before the prompt shows your current directory. Recover to this exact folder if needed:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-201-phase-3-programmable-database\09-functions-and-procedures\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-201-phase-3-programmable-database/09-functions-and-procedures/code"
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

This file is genuinely identical to [201 lesson 01, Step 2](../phase-1-schema-design/01-data-modeling-and-3nf.md#step-2-save-the-complete-compose-configuration). Repeat that step with only these differences: workspace `09-functions-and-procedures` instead of `01-data-modeling-and-3nf`, project `code101-db201-09` instead of `code101-db201-01`, and this lesson's SQL. **No YAML line changes.** Full configuration is repeated to keep this pack standalone.

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
**PL/pgSQL** is PostgreSQL procedural SQL language: it adds variables, branching and exception handling around SQL. A **stored procedure** is a named operation invoked with CALL. A function returns a value and can appear in SELECT; a procedure is invoked as an operation, not a SELECT expression.

Dollar quotes `$$` delimit the body without escaping every inner quote. PL/pgSQL BEGIN/END groups statements; it does not start/commit an SQL transaction. STRICT means a function returns NULL without running its body when any input is NULL. IMMUTABLE promises equal inputs give equal outputs without reading mutable database state. SECURITY INVOKER uses caller privileges.

**SQLSTATE** is a five-character machine-readable error code. P2011/P2012 are application-chosen codes here, not built-in PostgreSQL conditions. Avoid 00000 and category-like codes ending in three zeroes. Clients should branch on SQLSTATE, not translated or reformatted message text.

Read/save all files before running. SQL ends statements with semicolons. Backslash commands are **psql client commands**, not server SQL: ON_ERROR_STOP stops at the first unexpected error; `\ir` includes relative to its containing script; unaligned format uses `|` between columns; footer off removes row-count footers; the null setting displays SQL NULL as `(null)`. Use psql for whole scripts; in an IDE select server SQL, not the backslash commands. The entry script arranges setup automatically. Never execute sample reset files on valuable data.

Defines the isolated example and seed. DROP SCHEMA app CASCADE removes the sample schema and its dependent objects. Use a disposable database.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    state text NOT NULL DEFAULT 'draft',
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT ck_orders_state CHECK (state IN ('draft', 'paid'))
);
CREATE TABLE app.markers (
    marker_id bigint GENERATED ALWAYS AS IDENTITY,
    note text NOT NULL,
    CONSTRAINT pk_markers PRIMARY KEY (marker_id)
);
CREATE TABLE app.error_checks (
    code text,
    CONSTRAINT pk_error_checks PRIMARY KEY (code)
);
INSERT INTO app.orders DEFAULT VALUES;
CREATE FUNCTION app.line_total(p_quantity integer, p_unit_price numeric)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    IF p_quantity <= 0 OR p_unit_price < 0 THEN
        RAISE EXCEPTION 'quantity must be positive and price nonnegative'
            USING ERRCODE = 'P2011';
    END IF;
    RETURN p_quantity * p_unit_price;
END;
$$;
CREATE PROCEDURE app.pay_order(p_order_id bigint)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    UPDATE app.orders SET state = 'paid'
    WHERE order_id = p_order_id AND state = 'draft';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'order missing or not draft' USING ERRCODE = 'P2012';
    END IF;
END;
$$;
CREATE PROCEDURE app.commit_markers(p_note text)
LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    INSERT INTO app.markers (note) VALUES (p_note || ':first');
    COMMIT;
    INSERT INTO app.markers (note) VALUES (p_note || ':second');
    COMMIT;
END;
$$;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA app FROM PUBLIC;
REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA app FROM PUBLIC;
```

The entry script includes setup or the migration driver, then performs the worked example.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
BEGIN;
SELECT app.line_total(2, 5.00)::numeric(10,2) AS total;
CALL app.pay_order(1);
SELECT state AS inside_transaction FROM app.orders WHERE order_id = 1;
ROLLBACK;
SELECT state AS after_rollback FROM app.orders WHERE order_id = 1;
DO $$
BEGIN
    BEGIN
        PERFORM app.line_total(0, 5.00);
        RAISE EXCEPTION 'expected P2011';
    EXCEPTION WHEN SQLSTATE 'P2011' THEN
        INSERT INTO app.error_checks (code) VALUES ('P2011');
    END;
    BEGIN
        CALL app.pay_order(999);
        RAISE EXCEPTION 'expected P2012';
    EXCEPTION WHEN SQLSTATE 'P2012' THEN
        INSERT INTO app.error_checks (code) VALUES ('P2012');
    END;
END;
$$;
SELECT code AS caught_sqlstate FROM app.error_checks ORDER BY code;
CALL app.commit_markers('demo');
SELECT note FROM app.markers ORDER BY marker_id;
```

### Step 5. Start and inspect PostgreSQL
From this code folder use project `code101-db201-09` consistently. `-p` isolates names/volumes, not the shared host port. Keep Docker Desktop running. `up -d --wait` starts the service and waits for readiness; an initial image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and db container, then reports healthy readiness. Progress order, IDs and timings vary; no startup transcript is claimed.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 logs --no-log-prefix --tail 10 db
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
| Display name | `Code101 DB201 09` |

- JetBrains: **Database / Database Explorer > + > Data Source > PostgreSQL**; enter General fields, **Download missing driver files** if offered, then **SSH/SSL** off for this local lab, **Test Connection > OK > New Query Console**. Run selected SQL with Ctrl+Enter (Cmd+Enter on macOS).
- VS Code: Microsoft's **PostgreSQL** extension (`ms-ossdata.vscode-pgsql`), **PostgreSQL > Connections > + / Add New Connection > Parameters**; enter fields, **Advanced** port/SSL, then **Test Connection > Save & Connect > New Query**. Run selected SQL with Ctrl+Shift+E (Cmd+Shift+E on macOS). UI labels may vary; 101 links the vendor directions.
- Visual Studio is not VS Code. Built-in SQL Server Object Explorer is not a PostgreSQL tool; Npgsql alone does not install a Server Explorer provider. Use the existing provider if available, or the terminal/IDE routes above.

Run only selected queries after setup; do not casually reapply destructive setup. A socket connection inside db does not prove a host-network password works. Require TLS for remote production connections; disabling SSL is only for local practice.

## Run it
**Predict first:** Predict the order state after the outer ROLLBACK, and whether the two marker rows can be undone by a later unrelated rollback.


From this code folder run the entry file. `exec -T` runs the container client without a pseudo-terminal; `-X` ignores psql startup customization; `-q` suppresses routine tags; ON_ERROR_STOP fails fast; `-U`/`-d` name role/database; `-f` is the container file path. Quiet mode does not hide server errors/notices on stderr.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run:**

```text
total
10.00
inside_transaction
paid
after_rollback
draft
caught_sqlstate
P2011
P2012
note
demo:first
demo:second
```

The function returns 2 x 5.00 = 10.00. pay_order changes draft to paid inside the transaction; rollback restores draft. Both deliberately invalid calls raise their designated codes and are caught. The top-level marker CALL commits first and second rows, so both notes persist.

These are hand-derived unaligned result tables, not captured output. Missing-schema/dependency notices may appear on stderr; they are not data rows. An unexpected error means stop and inspect the first failing file/statement before continuing.

## How it works
`UPDATE ... WHERE state = draft` combines the state precondition with the write, avoiding a separate unprotected read-then-update. FOUND is the PL/pgSQL flag set by the preceding command; if no row changed, the procedure raises P2012. A second payment would therefore fail too. This example does not model a real payment gateway or external money movement.

The anonymous DO block is a one-off procedural block. PERFORM discards a function result. Nested BEGIN/EXCEPTION blocks catch only the specified codes and roll back work done inside the failed sub-block. If a deliberately invalid call unexpectedly succeeds, the sentinel exception is not caught as P2011/P2012, so the script fails instead of falsely reporting a pass.

**Why this, not that:** the normal pay_order procedure has no COMMIT, so the application can combine it with other work atomically. Use a function for an expression result, and a procedure for an operation. Neither is automatically faster or safer than well-written SQL.

The separate commit_markers procedure demonstrates transaction control, not a recommended order workflow. Top-level CALL in autocommit mode may commit; PostgreSQL starts the next transaction automatically. A function cannot commit. A procedure called within BEGIN/COMMIT cannot commit either. Transaction control also cannot occur inside a block with exception handlers, through an intervening SELECT call, in a SECURITY DEFINER procedure, or in one declared with a SET configuration clause. Run this script with psql -f, never psql --single-transaction; an IDE that wraps scripts in a transaction will block this demonstration. If the second marker insert failed, the first would still be committed.

Routine EXECUTE is granted to PUBLIC by default, so the setup revokes it in the private schema. Here the owner still runs the routines; lesson 11 separates runtime roles. Keep application routines SECURITY INVOKER unless you have a reviewed need for privilege elevation; definer routines require hardened search_path and grants.

## Try it
Keep db running after Run it. The starter resets the disposable schema, except lesson 03 which expects the already-applied migrations and rolls back its trial column.

1. **Guided:** Complete a discounted-amount function with the same validation, STRICT and custom-error pattern. For 100.00 and 10 percent, return 90.00.
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
CREATE FUNCTION app.discounted(p_amount numeric, p_percent integer)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    -- TODO: reject negative amount or percent outside 0..100 with SQLSTATE P2013.
    -- TODO: return amount * (100 - percent) / 100.
    RETURN p_amount;
END;
$$;
REVOKE EXECUTE ON FUNCTION app.discounted(numeric, integer) FROM PUBLIC;
SELECT app.discounted(100.00, 10)::numeric(10,2) AS discounted;
```

3. Fill the TODOs, save, then run your working file from this code folder.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target after completing the TODOs:

**Expected output, not yet run:**

```text
discounted
90.00
```

The target is for the completed program, not the untouched starter, which deliberately may return no rows or an uncorrected value.

4. **Change:** Test a percent of 101 in a transaction and confirm the application-defined P2013 error; then rollback. Also predict the NULL result from a STRICT NULL input.
5. **Stretch (optional):** Choose whether retrying pay_order should fail or be idempotently successful. Describe a contract change and how callers would distinguish missing orders.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE FUNCTION app.discounted(p_amount numeric, p_percent integer)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE STRICT SECURITY INVOKER AS $$
BEGIN
    IF p_amount < 0 OR p_percent < 0 OR p_percent > 100 THEN
        RAISE EXCEPTION 'invalid discount input' USING ERRCODE = 'P2013';
    END IF;
    RETURN p_amount * (100 - p_percent) / 100;
END;
$$;
REVOKE EXECUTE ON FUNCTION app.discounted(numeric, integer) FROM PUBLIC;
SELECT app.discounted(100.00, 10)::numeric(10,2) AS discounted;
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
docker compose -p code101-db201-09 stop
docker compose -p code101-db201-09 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: variable stop progress, then:

```text
db exited
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 down -v --remove-orphans
```

Expected output, not yet run: Compose removes this project container/network and saved volume; exact progress text varies. **-v destroys saved database data**, including the restored target in lesson 11. It does not erase other projects or the host dump file. Never use it on valuable data.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-09 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: no service rows; port 5432 is no longer held by this project.

## Check yourself
1. Why is line_total legitimately IMMUTABLE?
   <details><summary>Answer</summary>It depends only on its inputs and arithmetic, not current rows, time or session state.</details>
2. Can CALL commit_markers run inside BEGIN and still commit?
   <details><summary>Answer</summary>No. Transaction control in a procedure requires an eligible top-level CALL, not an explicit transaction block.</details>
3. What should a client inspect for a rejected payment?
   <details><summary>Answer</summary>SQLSTATE P2012, not the wording of the message.</details>

## Common mistakes
No new error transcript has been captured. These are symptoms; wording marked typical message is illustrative, not observed output.

| Symptom | Cause | Fix |
|---|---|---|
| Compose cannot find its configuration (typical message) | Terminal is in the wrong folder | Recover to code using Step 1; keep code/exercise siblings. |
| Old behavior persists | Unsaved file, hidden .sql.txt extension or wrong project | Save, check filename extensions and use the exact -p name in every command. |
| Startup cannot claim 5432 (typical message) | Another lab owns the host port | Stop the previous lab from its own code folder; never kill unrelated processes. |
| Procedure transaction termination is rejected (typical message) | The client wrapped CALL in an explicit transaction | Use autocommit/top-level CALL for the marker demo; keep ordinary business procedures caller-transactional. |
| An invalid call is reported as successful | A broad exception handler swallowed the sentinel | Catch only the intended SQLSTATE, and rethrow unexpected conditions. |
| An IDE rejects a backslash line (typical message) | psql meta-commands were sent as SQL | Use psql for whole scripts; select only server SQL in an IDE. |

## Best practice
Keep transaction ownership explicit and report application errors using stable SQLSTATE contracts. Source: [PostgreSQL 17: CREATE FUNCTION](https://www.postgresql.org/docs/17/sql-createfunction.html).

## Going further
Official PostgreSQL **17** references checked for this draft:
- [PostgreSQL 17: CREATE FUNCTION](https://www.postgresql.org/docs/17/sql-createfunction.html)
- [CREATE PROCEDURE](https://www.postgresql.org/docs/17/sql-createprocedure.html)
- [CALL](https://www.postgresql.org/docs/17/sql-call.html)
- [PL/pgSQL transaction management](https://www.postgresql.org/docs/17/plpgsql-transactions.html)
- [Errors and messages](https://www.postgresql.org/docs/17/plpgsql-errors-and-messages.html)

See [Platform: database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md) for shared task/team routines used by the backend capstones. Compare its function contracts with CALL: PostgreSQL functions and procedures are not interchangeable client APIs.

This returns in [lesson 11](../phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md): every schema/query/routine decision also needs a permission and recovery story.

## Summary
- You worked through how to write and call a validated PL/pgSQL function.
- You worked through how to use CALL and explain caller-owned versus procedure-owned transactions.
- You worked through how to raise and handle custom SQLSTATE errors without parsing message text.
- The code and derived output remain written but not run; the draft notice is intentional.

## Next lesson
[10. Triggers for updated_at and an audit trail](../phase-3-programmable-database/10-triggers-and-auditing.md): Use a BEFORE row trigger to set updated_at on meaningful changes.
