---
track: databases
level: 301
phase: 4
phase_name: scale-and-operations
lesson: 10
title: "Other engines: SQL Server and SQLite differences, and a production readiness review"
time: 120 min
prerequisites: [301.4.08, 301.3.06, 201.3.09]
versions: { postgres_image: "17-alpine", postgresql: "17", sql_server: "2022 or later (reference only)", sqlite: "3.37 or later (reference only)", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/10-other-engines-and-readiness/
assets: []
---

# 10. Other engines: SQL Server and SQLite differences, and a production readiness review

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Translate common PostgreSQL syntax and types into SQL Server (T-SQL) and SQLite, and name the behaviours that differ silently (case sensitivity, typing, transactions, concurrency).
- Compare stored procedures and programmability across the three engines, and decide which engine fits a workload and why.
- Run a catalog-based readiness review that finds missing primary keys, unindexed foreign keys, timestamps without time zone and risky server settings.
- Write a review: findings with risk, severity, fix and verification, ending in a go or no-go decision.

## Recap
- Lesson 08: what separates a backup from a replica?
  <details><summary>Answer</summary>A replica copies mistakes quickly; a backup with archived WAL lets you go back in time. Prove it with a restore drill.</details>
- 201 lesson 09: what is the difference between a function and a procedure in PostgreSQL?
  <details><summary>Answer</summary>A function is called in an expression and returns a value; a procedure is invoked with `CALL`, can manage transactions at the top level and returns no value directly.</details>

## Why it matters
You will meet other engines: an acquired company runs SQL Server, a mobile app ships SQLite, a test suite uses an in-memory substitute and quietly passes code that would fail on PostgreSQL. Knowing the differences prevents silent bugs and bad engine choices. And every system you build ends the same way: someone must decide whether it is ready for production. A written review beats a feeling.

## What you will build
A deliberately flawed order schema, a catalog-driven set of checks over it, a table of server settings against a production policy, and two **reference-only** scripts that show the same tasks in T-SQL and SQLite. The reference scripts are not executed by this lesson: SQL Server and SQLite are not part of the lab, so their syntax is checked against the vendors' documentation, not by running it.

## Before you start
- **Prerequisites:** Databases 301 lessons [06, row-level security in depth](../phase-3-security-and-multitenancy/06-row-level-security-in-depth.md) and [08, replication and high availability](08-replication-and-high-availability.md); [Databases 201 lesson 09, functions and procedures](../../201-hero-to-super-hero/phase-3-programmable-database/09-functions-and-procedures.md).
- Finished lessons 01 to 09 of this level (this is the last), or at least lessons 06 and 08. No host PostgreSQL needed. SQL Server and SQLite are **not** needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lessons 02 to 08.
- Time: 120 minutes, two sittings: break after Run it.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/10-other-engines-and-readiness/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-4-scale-and-operations.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; the checks' results are derived from the schema text and the documented defaults.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 08, Step 1](08-replication-and-high-availability.md#step-1-prepare-the-workspace) (genuinely identical) with the lesson folder `10-other-engines-and-readiness`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-4-scale-and-operations\10-other-engines-and-readiness\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-4-scale-and-operations/10-other-engines-and-readiness/code"
```

Create the sub-folder `reference` inside `code` for the two reference scripts.

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

Identical to [lesson 02, Step 2](../phase-1-performance/02-statistics-vacuum-and-bloat.md#step-2-save-the-complete-compose-configuration); the line-by-line table is in [lesson 01, Step 2](../phase-1-performance/01-query-tuning-method.md#step-2-save-the-complete-compose-configuration). No Dockerfile; no art (`assets: []`).

### Step 3. Create the environment files
**File: `code/.env.example`**
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

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: nothing printed.

### Step 4. The schema under review and the checks
New terms. A **catalog** is the set of system tables in which a database describes itself (`pg_class` for relations, `pg_constraint` for constraints, `pg_attribute` for columns, `pg_settings` for settings). A **readiness review** is a structured check of a system against a list of operational criteria before it takes real traffic. **Severity** ranks a finding by the harm if it ships. **T-SQL** is SQL Server's dialect and procedural language. **Type affinity** is SQLite's rule for how a column's declared type influences, but does not enforce, the type of stored values.

**The schema under review** has deliberate flaws a reviewer should find: `audit_events` has no primary key; `orders.customer_id` is a foreign key with no supporting index; `orders.total` is `double precision` (a binary floating-point money column); and two `timestamp` columns have no time zone.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE FUNCTION app.attempt(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_rows bigint;
BEGIN
    EXECUTE p_sql;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RETURN 'ok:' || v_rows;
EXCEPTION WHEN OTHERS THEN
    RETURN 'err:' || SQLSTATE;
END
$$;
CREATE TABLE app.customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY,
    email text NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    customer_id bigint NOT NULL,
    total double precision NOT NULL,
    created_at timestamp NOT NULL DEFAULT now(),
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES app.customers (customer_id)
);
CREATE TABLE app.audit_events (
    event text NOT NULL,
    occurred_at timestamp NOT NULL
);
```

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT 'abc' = 'ABC' AS equals, 'abc' LIKE 'ABC' AS like_match, 'abc' ILIKE 'ABC' AS ilike_match;
SELECT (SELECT string_agg(n::text, ',' ORDER BY n)
        FROM (SELECT n FROM generate_series(1, 5) AS n ORDER BY n LIMIT 2 OFFSET 1) AS a) AS limit_offset,
       (SELECT string_agg(n::text, ',' ORDER BY n)
        FROM (SELECT n FROM generate_series(1, 5) AS n ORDER BY n OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY) AS b) AS fetch_next;
SELECT app.attempt('SELECT ''abc''::integer') AS text_into_integer;
SELECT check_name, object FROM (
    SELECT 'no_primary_key' AS check_name, format('%I.%I', n.nspname, c.relname) AS object
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p')
      AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'p')
    UNION ALL
    SELECT 'fk_without_index', format('%I.%I.%I', n.nspname, c.relname, k.conname)
    FROM pg_constraint k
    JOIN pg_class c ON c.oid = k.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND k.contype = 'f'
      AND NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = k.conrelid AND i.indkey[0] = k.conkey[1])
    UNION ALL
    SELECT 'timestamp_without_tz', format('%I.%I.%I', n.nspname, c.relname, a.attname)
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
      AND format_type(a.atttypid, a.atttypmod) = 'timestamp without time zone'
) AS findings
ORDER BY check_name, object;
SELECT s.name, s.setting, v.target, s.setting = v.target AS meets
FROM (VALUES ('archive_mode', 'on'), ('data_checksums', 'on'), ('fsync', 'on'), ('full_page_writes', 'on'),
             ('idle_in_transaction_session_timeout', '60000'), ('password_encryption', 'scram-sha-256'),
             ('ssl', 'on'), ('statement_timeout', '30000')) AS v(name, target)
JOIN pg_settings s ON s.name = v.name
ORDER BY s.name;
```

Reading the script. The first three queries show PostgreSQL behaviours that differ in the other engines: `=` is case sensitive, `LIKE` is case sensitive and `ILIKE` is not; two spellings of paging (`LIMIT/OFFSET` and the standard `OFFSET ... FETCH`) give the same rows; and the type system is strict, so text cannot enter an integer (SQLSTATE `22P02`, invalid text representation). Then the **review checks**, each a catalog query that returns the offending objects:

- *No primary key*: a table with no `p` constraint in `pg_constraint`.
- *Foreign key without index*: a foreign key whose first column is not the first column of any index on that table. `pg_index.indkey` is a zero-based vector of column numbers and `pg_constraint.conkey` a one-based array; this check is for single-column keys and is a first-pass heuristic (a composite foreign key needs all leading columns).
- *Timestamp without time zone*: columns whose formatted type is `timestamp without time zone`.

The last query compares live server settings with a **policy table** (`VALUES`): the target values are an example policy, to be replaced by yours. `idle_in_transaction_session_timeout` and `statement_timeout` are in milliseconds.

### Step 5. The reference scripts for SQL Server and SQLite
They show the same tasks in the other two engines so you can compare line by line. **They are not run in this lesson**, and no output is claimed for them; they are checked by reading the vendors' documentation. Save them under `code/reference/`.

**File: `code/reference/sqlserver.sql`**
```sql
-- Reference only (T-SQL for SQL Server 2022 or later). NOT run by this lesson.
-- The same tasks as lesson.sql; compare each statement with its PostgreSQL form.
-- GO is a batch separator understood by sqlcmd and SQL Server Management Studio, not a T-SQL statement.
CREATE SCHEMA app;
GO
CREATE TABLE app.customers (
    customer_id bigint IDENTITY(1,1) NOT NULL,
    email nvarchar(320) NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id)
);
GO
CREATE TABLE app.orders (
    order_id bigint IDENTITY(1,1) NOT NULL,
    customer_id bigint NOT NULL,
    total decimal(12,2) NOT NULL,
    created_at datetime2 NOT NULL CONSTRAINT df_orders_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES app.customers (customer_id)
);
GO
SELECT 'abc' + 'def' AS concat_plus, CONCAT('abc', 'def') AS concat_function;
SELECT CASE WHEN 'abc' = 'ABC' THEN 1 ELSE 0 END AS equals_with_a_case_insensitive_collation;
SELECT n FROM (VALUES (1), (2), (3), (4), (5)) AS t(n) ORDER BY n OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY;
SELECT TOP (2) n FROM (VALUES (1), (2), (3), (4), (5)) AS t(n) ORDER BY n;
GO
CREATE OR ALTER PROCEDURE app.place_order
    @customer_id bigint,
    @total decimal(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO app.orders (customer_id, total)
        OUTPUT inserted.order_id
        VALUES (@customer_id, @total);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
EXEC app.place_order @customer_id = 1, @total = 12.50;
```

Differences to notice, in file order: `IDENTITY(1,1)` replaces `GENERATED ... AS IDENTITY`; `nvarchar` stores Unicode (a plain `varchar` uses a code page unless the collation is a UTF-8 one); `decimal(12,2)` is the money-safe type; `datetime2` with `SYSUTCDATETIME()` is the UTC timestamp (it carries no offset: use `datetimeoffset` if you need one); `+` concatenates strings (`CONCAT` treats NULL as empty); the default collation of many installations is **case-insensitive**, so `'abc' = 'ABC'` is true, the opposite of PostgreSQL; `TOP` and `OFFSET ... FETCH` page results (`OFFSET` requires `ORDER BY`); a procedure is the unit of server-side logic: parameters start with `@`, `SET NOCOUNT ON` suppresses row-count messages, `SET XACT_ABORT ON` rolls back the transaction on most runtime errors, `OUTPUT inserted.col` is the counterpart of `RETURNING`, `TRY ... CATCH` with `THROW` replaces `EXCEPTION` blocks.

**File: `code/reference/sqlite.sql`**
```sql
-- Reference only (SQLite 3.37 or later, for STRICT tables). NOT run by this lesson.
-- The same tasks as lesson.sql; compare each statement with its PostgreSQL form.
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    email TEXT NOT NULL
) STRICT;
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers (customer_id),
    total_cents INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
) STRICT;
CREATE TABLE loose (n INTEGER);
INSERT INTO loose (n) VALUES ('abc');
SELECT n, typeof(n) FROM loose;
SELECT 'abc' = 'ABC' AS equals, 'abc' LIKE 'ABC' AS like_match;
WITH t(n) AS (VALUES (1), (2), (3), (4), (5))
SELECT n FROM t ORDER BY n LIMIT 2 OFFSET 1;
INSERT INTO customers (email) VALUES ('ada@example.com') RETURNING customer_id;
INSERT INTO orders (customer_id, total_cents) VALUES (1, 1250) RETURNING order_id;
```

Differences to notice: foreign keys are **off by default per connection** (`PRAGMA foreign_keys = ON` each time you connect); `journal_mode = WAL` lets readers proceed while one writer writes; `INTEGER PRIMARY KEY` is an alias for the row id and auto-assigns; `STRICT` (3.37 and later) makes column types enforced, whereas an ordinary table such as `loose` uses **type affinity**: the text `'abc'` is stored in the `INTEGER` column and `typeof(n)` reports `text`; there are no real date or boolean types (dates are text, real numbers or integers by convention; booleans are integers); money must be integer cents (there is no exact decimal type); `'abc' = 'ABC'` is false but `LIKE` is case-insensitive for ASCII by default; there are **no stored procedures** and no users or roles (the file's permissions are the access control).

### Step 6. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-10 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-10 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 10`.

## Run it
**Predict first.** (a) Is `'abc' = 'ABC'` true in PostgreSQL? (b) Which objects will the three checks list? (c) Which server settings will fail the example policy on the default image?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-10 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived from the schema text and the documented defaults):**

```text
equals|like_match|ilike_match
f|f|t
limit_offset|fetch_next
2,3|2,3
text_into_integer
err:22P02
check_name|object
fk_without_index|app.orders.fk_orders_customer
no_primary_key|app.audit_events
timestamp_without_tz|app.audit_events.occurred_at
timestamp_without_tz|app.orders.created_at
name|setting|target|meets
archive_mode|off|on|f
data_checksums|off|on|f
fsync|on|on|t
full_page_writes|on|on|t
idle_in_transaction_session_timeout|0|60000|f
password_encryption|scram-sha-256|scram-sha-256|t
ssl|off|on|f
statement_timeout|0|30000|f
```

Why: a case-sensitive `=` and `LIKE` give false, `ILIKE` true; both paging forms return rows 2 and 3. Text cannot enter an integer. The checks list exactly the four flaws built into the schema: the audit table has no key, the order's foreign key has no index, and the two `timestamp` columns lack a zone. The `float` money column is **not** found by these checks: reviews have blind spots, and the exercise adds a check for it. The settings table reflects the default image: archiving off, checksums off, no TLS, no timeouts. If your server was started with other flags, the `setting` column differs.

## How it works
**Differences that bite, side by side.**

| Topic | PostgreSQL | SQL Server | SQLite |
|---|---|---|---|
| Typing | Strict | Strict | Dynamic by default (type affinity); `STRICT` tables enforce types |
| Auto keys | `GENERATED ... AS IDENTITY`, sequences | `IDENTITY(seed, step)`, `SEQUENCE` | `INTEGER PRIMARY KEY` (row id alias) |
| Booleans | `boolean` | `bit` | integers 0 and 1 |
| Exact decimals | `numeric(p,s)` | `decimal(p,s)` | none: use integer cents |
| Time | `timestamptz`, `timestamp`, `date`, `interval` | `datetime2`, `datetimeoffset`, `date` | text, real or integer by convention |
| Unicode text | `text` (database encoding, usually UTF-8) | `nvarchar` (and UTF-8 collations for `varchar` in recent versions) | `TEXT` (UTF-8 by default) |
| Default string comparison | Case sensitive (collation set at creation) | Often case insensitive (collation of the database) | `=` case sensitive; `LIKE` case-insensitive for ASCII |
| String concat | `\|\|` (NULL makes the result NULL) | `+` (NULL propagates) or `CONCAT` | `\|\|` |
| Paging | `LIMIT`/`OFFSET` or `OFFSET ... FETCH` | `TOP`, `OFFSET ... FETCH` | `LIMIT`/`OFFSET` |
| Write results back | `RETURNING` | `OUTPUT` | `RETURNING` (3.35 and later) |
| Upsert | `INSERT ... ON CONFLICT` | `MERGE` (read its documented caveats) or `UPDATE` then `INSERT` in a transaction | `INSERT ... ON CONFLICT` |
| JSON | `jsonb` with indexes | JSON functions over text (check your version for a native type) | JSON functions over text (JSON1) |
| Arrays, ranges, custom types | Yes | No (use tables or JSON) | No |
| Transactional DDL | Yes | Yes for most DDL | Yes |
| Concurrency model | MVCC: readers do not block writers | Locking by default; `READ_COMMITTED_SNAPSHOT` gives row versioning | One writer at a time; WAL allows concurrent readers; set a busy timeout |
| Stored logic | PL/pgSQL, other languages, functions and procedures | T-SQL procedures, functions, triggers (and CLR) | Triggers and views only; logic lives in the host application |
| Access control | Roles, grants, row-level security | Logins and users, schemas, row-level security | None: file permissions (encryption needs an extension) |
| Server process | Yes | Yes | No: a library inside your process |

**When each fits.**
- **PostgreSQL**: the default server database for a new product, extensions (pgvector, PostGIS, trigram search), strong SQL, open licensing, portability across clouds.
- **SQL Server**: organisations standardised on Microsoft tooling (.NET, Azure, SSIS and SSRS, Active Directory authentication), existing licensing and skills, or products that must run on it. T-SQL is a capable procedural language.
- **SQLite**: embedded and local-first apps, mobile and desktop, command-line tools, configuration and caches, tests of **your own** SQL when you only use features common to your target engine, and edge devices with one process owning the file. Not for many concurrent writers from different machines over a network.

**Do not test PostgreSQL code against SQLite or an in-memory substitute and call it tested.** Case sensitivity, types, transactions, locking, `RETURNING`, JSON and extensions all differ. Test against the engine you deploy (a container, as these labs do).

**Programmability compared.** PostgreSQL: a function runs inside a statement, a procedure with `CALL` can commit and roll back at the top level. SQL Server: a procedure is the standard API, with `TRY`/`CATCH` and `THROW`, `OUTPUT` parameters or result sets; table-valued functions return rowsets. SQLite: none; use a view, a trigger, or write the logic in your application language (some libraries register application functions in the connection).

**Why this, not that.** Choose the engine from constraints you can state (who operates it, where it runs, concurrency, licensing, ecosystem), not from familiarity or fashion. Keep SQL portable only where portability has a real, near-term payoff; otherwise use the engine's strengths and isolate them (a data-access layer, stored functions with a documented contract as in the capstone).

**The readiness review method.** Review against a **written checklist**, with **evidence** per item (a query result, a plan, a drill log), assign **severity**, require a **named fix and a verification step** per finding, and end in a **decision** (ready, ready with conditions, not ready). Revisit at each major change. A checklist is a floor: add items after every incident.

## Production readiness checklist (the 301 database track in one page)
Tick an item only with evidence (a query, a dashboard, a drill record). The lesson that teaches it is in brackets.

**Schema and change management**
- [ ] Every table has a primary key; every foreign key has a supporting index and a deliberate delete rule (the checks above; 201 lessons 01 and 02).
- [ ] Money is `numeric` or integer minor units; instants are `timestamptz` (201 lesson 02).
- [ ] Migrations are versioned, reviewed, run with a `lock_timeout`, and follow expand, backfill, contract (201 lesson 03; 301 lesson 07 fan-out).
- [ ] Tenant references cannot cross tenants (composite keys) [301.07].

**Performance**
- [ ] `pg_stat_statements` loaded; top statements reviewed on a schedule; baselines recorded [301.01].
- [ ] Autovacuum tuned for the largest tables; dead-tuple, oldest-transaction and wraparound alerts [301.02].
- [ ] Partitioning only with a stated reason; future partitions automated; default partition monitored [301.03].

**Concurrency and integrity**
- [ ] Write paths are atomic, lock in a consistent order, and retry `40001` and `40P01` idempotently [301.04].
- [ ] `statement_timeout`, `idle_in_transaction_session_timeout` and `lock_timeout` set per role or migration [301.04].
- [ ] A connection budget exists (services times instances times pool plus reserve); pooling mode known; no session-level state behind a transaction pooler [301.05].

**Security**
- [ ] Application roles are not owners, superusers or `BYPASSRLS`; least-privilege grants; passwords with SCRAM; TLS on; `pg_hba.conf` narrow.
- [ ] Row-level security (if used) is tested as the restricted role, including negative cases; views use `security_invoker`; the context is set only by trusted code [301.06].
- [ ] Secrets live in a secret store, not in the repository or `.env` files that are committed.

**Availability and recovery**
- [ ] RPO and RTO written down; base backups plus WAL archiving; `pg_stat_archiver` alerts [301.08].
- [ ] A restore drill with a fingerprint query, timed, in the last quarter; failover rehearsed with fencing [301.08].
- [ ] Replication slots monitored; `max_slot_wal_keep_size` set; disk alerts on the WAL volume [301.08].

**Observability and capacity**
- [ ] Metrics: connections by state, replication lag, cache hit ratio trends, lock waits, slow statements, disk growth.
- [ ] Logs: slow statements, lock waits, autovacuum, connection errors; retention and access controlled.
- [ ] Capacity forecast: storage growth, connection growth, index size against memory; load test at 2x peak.

**Search features (if used)**
- [ ] Embedding model and dimension recorded; re-embedding plan; recall and latency measured on real data [301.09].

## Try it
Keep `db` running.

1. **Guided:** Add the missing review check: list columns whose type is `double precision` or `real` and whose name contains `total`, `price`, `amount` or `balance`. Fill the TODO query.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

**File: `exercise/starter/exercise.sql`** (copy to `code/exercise.sql`)
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: write a query that returns the check name 'float_money' and the object name (schema.table.column)
-- of every column in schema app whose type is double precision or real and whose name contains
-- total, price, amount or balance. Use the same catalog joins as the checks in lesson.sql.
SELECT 'float_money' AS check_name, NULL AS object;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-10 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: only `orders.total` matches. The untouched starter prints `(null)` for the object.

**Expected output, not yet run:**

```text
check_name|object
float_money|app.orders.total
```

3. **Change (the review exercise):** Using the output of `lesson.sql` and your new check, write a readiness review in a copy of the template below. Give every finding a risk, a severity, one concrete fix and a verification step, and finish with a decision. Do the review before you open the solution.

**File: `exercise/starter/REVIEW.md`** (copy to `code/REVIEW.md` and fill it in)
```markdown
# Production readiness review: orders database

Reviewer: (your name)  Date: (today)

Evidence: the output of `lesson.sql` (checks and settings) and the schema in `setup.sql`.

## Findings

| # | Finding (what you saw) | Risk if left alone | Severity (blocker, high, medium, low) | Fix (one concrete step) | How you will verify the fix |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

## Decision

- [ ] Ready for production
- [ ] Ready with conditions (list them)
- [ ] Not ready (list blockers)

Reason for the decision (two sentences):
```

4. **Stretch (optional, no single answer):** Your team's mobile app uses SQLite locally and syncs to a PostgreSQL service. List the five behaviours from the comparison table most likely to cause sync bugs (types, time, case sensitivity, keys and booleans are good starting points) and the contract tests you would write against **both** engines.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT 'float_money' AS check_name, format('%I.%I.%I', n.nspname, c.relname, a.attname) AS object
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
  AND format_type(a.atttypid, a.atttypmod) IN ('double precision', 'real')
  AND a.attname ~ '(total|price|amount|balance)'
ORDER BY object;
```

**File: `exercise/solution/REVIEW.md`** (one acceptable answer; yours may rank differently if you justify it)
```markdown
# Production readiness review: orders database

Reviewer: (your name)  Date: (today)

Evidence: the output of `lesson.sql` (checks and settings) and the schema in `setup.sql`.

## Findings

| # | Finding (what you saw) | Risk if left alone | Severity (blocker, high, medium, low) | Fix (one concrete step) | How you will verify the fix |
|---|---|---|---|---|---|
| 1 | `archive_mode` is off, so there is no WAL archive | No point-in-time recovery; a bad `DELETE` or a lost disk loses everything since the last dump | blocker | Enable archiving to storage in another failure domain, take a base backup, add `pg_stat_archiver` alerts | Timed restore drill to a chosen time; fingerprint query matches |
| 2 | `app.audit_events` has no primary key | Cannot be replicated logically or de-duplicated; updates and deletes by key are impossible | high | Add an identity primary key in a migration | The no_primary_key check returns no rows |
| 3 | `fk_orders_customer` has no index on `orders.customer_id` | Deleting or updating a customer scans `orders` and holds locks longer; joins on the column scan | high | `CREATE INDEX CONCURRENTLY ix_orders_customer ON app.orders (customer_id)` | The fk_without_index check returns no rows; plan for a customer delete shows an index scan |
| 4 | `orders.total` is `double precision` | Binary floating point cannot represent money exactly; totals drift by fractions of a cent | high | Migrate to `numeric(12,2)` or integer cents (expand, backfill, contract) | The float_money check returns no rows; reconciliation of totals before and after matches to the cent |
| 5 | `timestamp` columns have no time zone | Offsets are lost; ambiguous around daylight-saving changes and across regions | medium | Convert to `timestamptz`, stating the zone the old values were in | The timestamp_without_tz check returns no rows; sample rows compared before and after |
| 6 | `statement_timeout` and `idle_in_transaction_session_timeout` are 0 | A runaway query or forgotten transaction holds locks and connections indefinitely | medium | Set per-role timeouts for the application role | `SHOW` as the application role returns the new values |
| 7 | `ssl` is off and `data_checksums` is off | Traffic is unencrypted; silent disk corruption can go undetected | high for `ssl` on any network beyond loopback, medium for checksums (needs a new cluster or an offline enable) | Enable TLS with a verified certificate; plan checksums for the next rebuild | `pg_stat_ssl` shows encrypted connections; the settings table passes |

## Decision

- [ ] Ready for production
- [ ] Ready with conditions (list them)
- [x] Not ready (list blockers)

Reason for the decision (two sentences): There is no archive for point-in-time recovery, which is a blocker for any data we cannot recreate. Several schema and security findings are cheap to fix now and expensive after launch.
```

Notes on the review. The decision is "not ready" because of finding 1, a blocker, not because there are seven findings: severity decides, count does not. Findings 2 to 5 are schema debt that gets more expensive with every row. Finding 7's severity depends on where the database sits: on a private loopback it is lower. The stretch rung's answer should name types, time zones and offsets, case-sensitive comparisons, integer versus boolean values, and key generation (client-generated UUIDs avoid collisions between devices), with contract tests that insert and read the same values through both engines.

To compare in your workspace, repeat the copy with `solution` instead of `starter`:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\solution\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/solution/exercise.sql ./exercise.sql
```

</details>

### Stop and clean up
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-10 stop
docker compose -p code101-db301-10 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. A query `WHERE email = 'Ada@Example.com'` returns the row on SQL Server but not on PostgreSQL. Why? <details><summary>Answer</summary>The SQL Server database uses a case-insensitive collation by default; PostgreSQL's `=` is case sensitive. Use `lower()` with a matching expression index or `citext`, deliberately.</details>
2. Predict what SQLite does for `INSERT INTO loose (n) VALUES ('abc')` into an `INTEGER` column of an ordinary table. <details><summary>Answer</summary>It stores the text; type affinity does not reject it. A `STRICT` table would refuse it.</details>
3. Find the flaw in a review that says "ready" because all checks returned no rows. <details><summary>Answer</summary>Checks have blind spots (the float money column was not caught by the first three) and cover only what you wrote. Readiness also needs evidence for recovery, security and capacity, not just schema checks.</details>
4. Which engine gives you stored procedures, row-level security and an access-control model out of the box, besides PostgreSQL? <details><summary>Answer</summary>SQL Server. SQLite has none of these.</details>
5. What turns a finding into something a team can act on? <details><summary>Answer</summary>A severity, one concrete fix and a verification step.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| The checks list nothing | `setup.sql` was not run, so schema `app` is missing or empty | Run `lesson.sql`, which includes the setup |
| The settings table shows different values | The container was started with other flags, or an older volume | Compare with `SHOW name`; reset the disposable volume if needed |
| `GO` fails in another client (typical) | `GO` is a client batch separator, not SQL | Use sqlcmd or SSMS for the reference script, or remove the separators and run batches separately |
| SQLite foreign keys are ignored | `PRAGMA foreign_keys` is off by default on each connection | Turn it on after every connect |
| Reference scripts produce errors on your engine versions | Different engine version or edition | Read the vendor documentation for your version; the reference scripts target the versions in their headers |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Review before launch with a written checklist, evidence for each item, a severity for each finding and a decision. Source: [PostgreSQL 17: System Catalogs](https://www.postgresql.org/docs/17/catalogs.html) for the checks, [Microsoft T-SQL reference](https://learn.microsoft.com/en-us/sql/t-sql/language-reference) and the [SQLite documentation](https://www.sqlite.org/docs.html) for the other engines.

## Going further
- SQLite: [datatypes](https://www.sqlite.org/datatype3.html), [STRICT tables](https://www.sqlite.org/stricttables.html) and [write-ahead logging](https://www.sqlite.org/wal.html).
- SQL Server: [CREATE PROCEDURE](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql) and [TRY...CATCH](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql).
- Best-practice checklists from hosted platforms: the [Neon Postgres best-practices skill](https://github.com/neondatabase/postgres-skills/blob/main/skills/postgres-best-practices/SKILL.md) and Supabase's [performance guidance](https://supabase.com/docs/guides/platform/performance) (Tier 2).
- Capstone: read the platform's [database and procedures chapter](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md) as a reviewer, using this lesson's checklist, and write the review.

## Summary
- You translated PostgreSQL idioms into T-SQL and SQLite and listed the silent differences.
- You compared stored logic, security and concurrency across the three engines and matched engines to workloads.
- You ran catalog-based checks and a settings policy, and learned their blind spots.
- You wrote a readiness review with findings, severities, fixes, verification and a decision, and have a one-page production checklist for the whole track.

## Next lesson
None: this completes Databases 301. Continue with the capstone chapters that use these skills, such as the [platform capstone](../../../../capstones/platform/README.md).
