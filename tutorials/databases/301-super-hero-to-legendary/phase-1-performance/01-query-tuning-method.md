---
track: databases
level: 301
phase: 1
phase_name: performance
lesson: 01
title: "Query tuning as a method: pg_stat_statements, EXPLAIN (ANALYZE, BUFFERS) and anti-patterns"
time: 90 min
prerequisites: [201.2.07]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-1-performance/01-query-tuning-method/
assets: []
---

# 01. Query tuning as a method: pg_stat_statements, EXPLAIN (ANALYZE, BUFFERS) and anti-patterns

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Choose which query to tune from `pg_stat_statements` evidence (total time, calls, rows) instead of from intuition.
- Read an `EXPLAIN (ANALYZE, BUFFERS)` plan: estimated versus actual rows, loops, filters, sorts and buffer activity.
- Recognise and rewrite four common anti-patterns (function on a column, OFFSET paging, missing foreign-key index, `SELECT *`) and state what you would measure to prove each rewrite helped.
- Write a one-page tuning record: baseline, hypothesis, change, re-measurement, regression guard.

## Recap
- In 201 lesson 07, why can a sequential scan beat an index on four rows?
  <details><summary>Answer</summary>Reading one page is cheaper than a lookup structure; an index is a hypothesis about selectivity and row count, not a guarantee.</details>
- What does `EXPLAIN ANALYZE` do that plain `EXPLAIN` does not?
  <details><summary>Answer</summary>It executes the statement and reports measured rows, time and loops next to the estimates. Never run it on a write without a transaction you can roll back.</details>

## Why it matters
Most database slowness is one or two statements that run too often or read too much. Tuning without a method turns into index roulette: every added index costs write time, disk and vacuum work. A method makes each change a falsifiable experiment with a before and an after, and it tells you when to stop.

## What you will build
A 1,000-row `app.orders` table whose contents you can compute by hand, a PostgreSQL server that records statement statistics, a deterministic report of what `pg_stat_statements` counted, and a separate plan script whose output you read yourself. No plan text, cost or timing is predicted or invented in this lesson.

## Before you start
- Finished Databases 201, in particular [lesson 07, indexes and EXPLAIN](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md). No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the `postgres:17-alpine` image used by 101 and 201. Docker/Compose versions in the front matter are the inherited authoring baseline, not a new check.
- Time: 90 minutes including reading, typing and the exercise. Two sittings are reasonable: break after Step 5, before Run it.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-1-performance/01-query-tuning-method/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-1-performance.zip`.
- **One database lab at a time:** stop any other 101, 201, 301 or capstone lab before using `127.0.0.1:5432`. Do not stop unrelated services. These lessons are independent; no schema carries forward.
- All passwords are disposable local examples; never point these scripts at real data.
- Nothing in this lesson has been run. Result tables are derived by hand from the seed formulas; variable output is described, never invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101`. Obtain the source folder from the repository link above, or extract the phase ZIP (Windows **right-click > Extract All**; macOS double-click; Linux **Extract Here**), and move `databases-301-phase-1-performance` into `code101`. Keep `01-query-tuning-method/code` and its sibling `exercise` together; the Compose file mounts both.
2. Without a pack, create the same folders by hand (`code`, `exercise/starter`, `exercise/solution`) and every file shown below.
3. Open a terminal in the lesson `code` folder. The text before the prompt shows your current folder. To recover:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-1-performance\01-query-tuning-method\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-1-performance/01-query-tuning-method/code"
```

Save files as UTF-8 without BOM. On Windows enable **View > Show > File name extensions** so `.sql.txt` cannot hide. A dot on an editor tab usually means unsaved changes.

### Step 2. Save the complete Compose configuration
This file differs from the 201 Compose file in exactly one way: the `command:` block, which starts PostgreSQL with `pg_stat_statements` loaded. Everything else is identical, so the table explains only the new lines and then the unchanged ones briefly.

**File: `code/docker-compose.yml`**
```yaml
services:
  db:
    image: postgres:17-alpine
    command:
      - postgres
      - -c
      - shared_preload_libraries=pg_stat_statements
      - -c
      - track_io_timing=on
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

| Configuration line(s) | Meaning and consequence of changing it |
|---|---|
| `services:`, `db:` | One service named `db`; every command below uses that name. |
| `image: postgres:17-alpine` | The official image, major version 17. The tag pins the major version and flavour, not a patch digest; pin a digest in production. |
| `command:` list starting with `postgres` | Replaces the image's default command. The list is the server executable followed by arguments; each `-c` is followed by one `name=value` setting. |
| `shared_preload_libraries=pg_stat_statements` | Loads the statistics module at server start. It allocates shared memory, so changing it needs a restart, not a reload. Without it `CREATE EXTENSION` succeeds but the view refuses to answer. |
| `track_io_timing=on` | Lets `EXPLAIN (ANALYZE, BUFFERS)` and `pg_stat_statements` report time spent on reads and writes. It calls the clock more often, so measure its overhead on your hardware before enabling it on a busy production server. |
| `environment:` with `POSTGRES_*` | Initialise the database, administrator and password from `.env` only when the data volume is empty. |
| `PGDATABASE`, `PGUSER` | Defaults for the client programs inside the container. |
| `ports: "127.0.0.1:5432:5432"` | Publishes only on IPv4 loopback so other machines on your network cannot connect. |
| `volumes:` `pg_data`, `.:/scripts:ro`, `../exercise:/exercises:ro` | A named volume for data, and read-only mounts of your scripts and exercises. |
| `healthcheck:` and its four timing keys | Runs `pg_isready` every 2 seconds; `$$` defers variable expansion to the container shell. `up --wait` uses this status. |
| Final `volumes:` / `pg_data:` | Declares the volume, scoped by the Compose project name. |

Indent with spaces. No Dockerfile or `.dockerignore`: nothing is built. No art is used (`assets: []`).

### Step 3. Create the local environment file
**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

Copy it to `.env`, which Compose reads for the `${...}` values:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: a successful copy prints nothing. The generated `.env` is identical to the example and is not shipped.

**File: `code/.gitignore`**
```gitignore
.env
*.dump
```

These patterns keep `.env` and dump archives out of Git. They do not encrypt anything and do not untrack files already committed.

### Step 4. Learn the method, then save the files
**The method (write it on a card):**
1. **Find** the statement worth tuning: highest total time, or highest calls times mean time, from `pg_stat_statements`. A 2 ms query called 50 million times beats a 5 s report run once a day.
2. **Reproduce** it with realistic parameters and realistic data volume. Four rows prove nothing about speed.
3. **Read** `EXPLAIN (ANALYZE, BUFFERS)`: where do estimates and actuals diverge, where is the work and the I/O?
4. **Hypothesise** one change. Change one thing at a time.
5. **Re-measure** with the same input, several runs, and keep the "before" number.
6. **Guard** it: add the statement to your regular statistics review so regressions show up.

New terms. **`pg_stat_statements`** is an extension that keeps one row of cumulative counters for each normalised statement (constants replaced by `$1`, `$2`). **Normalised** means two queries differing only in literal values share a row. **Plan node** is one step in a plan (a scan, a join, a sort); a plan is a tree of nodes. **Estimated rows** are the planner's guess; **actual rows** are what really passed through. **Loops** is how many times a node ran, and node figures are per loop. **Buffers** are 8 kB pages: a **hit** came from PostgreSQL's shared buffer cache, a **read** was requested from the operating system (which may still be cached by the OS). **Sargable** means a predicate in a form an index can answer (`column op constant`).

Backslash commands are psql client commands, not server SQL: `\set ON_ERROR_STOP on` stops at the first error, `\pset` changes output format, `\ir` includes a file relative to the including file, `\o /dev/null` discards output until a bare `\o` restores it. Use psql for whole scripts; in an IDE select only the server SQL.

**Seed arithmetic.** For `n` from 1 to 1000: `customer_id = 1 + (n % 10)` so each customer has exactly 100 orders; every 20th order is `cancelled`; `placed_at` is 2026-01-01 00:00:00 UTC plus `n` hours. These formulas are why the result tables below are derivable by hand.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    customer_id integer NOT NULL,
    status text NOT NULL,
    total_cents integer NOT NULL,
    placed_at timestamptz NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);
INSERT INTO app.orders (customer_id, status, total_cents, placed_at)
SELECT 1 + (n % 10),
       CASE WHEN n % 20 = 0 THEN 'cancelled' ELSE 'paid' END,
       1000 + n,
       TIMESTAMPTZ '2026-01-01 00:00:00+00' + n * INTERVAL '1 hour'
FROM generate_series(1, 1000) AS n;
ANALYZE app.orders;
```

`DROP SCHEMA ... CASCADE` removes the sample schema; the extension is installed in the default schema and survives. There is deliberately **no index on `customer_id`**: that is the problem the method will find. `ANALYZE` collects planner statistics (lesson 02 explains them).

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SET TIME ZONE 'UTC';
\ir setup.sql
SELECT pg_stat_statements_reset() IS NOT NULL AS stats_cleared;
\o /dev/null
SELECT count(*) FROM app.orders WHERE customer_id = 7;
SELECT count(*) FROM app.orders WHERE customer_id = 8;
SELECT count(*) FROM app.orders WHERE customer_id = 9;
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
SELECT order_id FROM app.orders WHERE customer_id = 8 ORDER BY order_id;
\o
SELECT calls, rows,
       CASE WHEN query LIKE 'SELECT count(*)%' THEN 'count per customer' ELSE 'ids per customer' END AS shape
FROM pg_stat_statements
WHERE query LIKE '%FROM app.orders%' AND query NOT LIKE '%pg_stat_statements%'
ORDER BY shape;
SELECT count(*) AS wrapped_filter FROM app.orders
WHERE date_trunc('day', placed_at) = TIMESTAMPTZ '2026-01-02 00:00:00+00';
SELECT count(*) AS range_filter FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-01-03 00:00:00+00';
SELECT string_agg(order_id::text, ',' ORDER BY order_id) AS offset_page
FROM (SELECT order_id FROM app.orders ORDER BY order_id OFFSET 995 LIMIT 5) AS p;
SELECT string_agg(order_id::text, ',' ORDER BY order_id) AS keyset_page
FROM (SELECT order_id FROM app.orders WHERE order_id > 995 ORDER BY order_id LIMIT 5) AS p;
```

The five statements between `\o /dev/null` and `\o` are the "workload": three calls of one shape, two of another, with different constants. Their output is discarded because only the statistics matter. The report then asks `pg_stat_statements` what it counted. Time zone is pinned to UTC so `date_trunc('day', ...)` cuts at the same instant everywhere.

**File: `code/plans.sql`**
```sql
\set ON_ERROR_STOP on
SET TIME ZONE 'UTC';
DROP INDEX IF EXISTS app.ix_orders_customer;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
CREATE INDEX ix_orders_customer ON app.orders (customer_id, order_id);
ANALYZE app.orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id FROM app.orders WHERE customer_id = 7 ORDER BY order_id;
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM app.orders
WHERE date_trunc('day', placed_at) = TIMESTAMPTZ '2026-01-02 00:00:00+00';
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-02 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-01-03 00:00:00+00';
```

This script is separate on purpose: plan text and timings depend on your machine, so they are never part of the deterministic report. It runs the same query before and after an index, and the wrapped versus range filter side by side. `EXPLAIN ANALYZE` really executes each `SELECT`; these are reads, so it is safe here.

### Step 5. Start and inspect PostgreSQL
Use project name `code101-db301-01` consistently. `-p` isolates names and volumes, not the shared host port.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and `db` container and reports it healthy. Progress order and timings vary; no transcript is claimed. A first image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 exec -T db psql -X -q -U learner -d code101 -c "SHOW shared_preload_libraries"
```

Expected output, not yet run: a table whose single value is `pg_stat_statements`. If it is empty, the `command:` block was not applied: check indentation and recreate the container.

Optional IDE connection: repeat [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md) with display name `Code101 DB301 01`; the host, port, database, user, password and SSL fields are unchanged (`127.0.0.1`, `5432`, `code101`, `learner`, `learn_local_only`, SSL disabled for this loopback lab only).

## Run it
**Predict first.** Customer 7 has 100 orders. Before you run: (a) how many `calls` and `rows` will each statement shape show? (b) Does `date_trunc('day', placed_at) = ...` return the same count as the half-open range for 2 January? (c) Which `OFFSET 995` rows come back?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

`exec -T` runs without a pseudo-terminal, `-X` ignores psql startup files, `-q` hides command tags, `-f` names the script inside the container.

**Expected output, not yet run (hand-derived):**

```text
stats_cleared
t
calls|rows|shape
3|3|count per customer
2|200|ids per customer
wrapped_filter
24
range_filter
24
offset_page
996,997,998,999,1000
keyset_page
996,997,998,999,1000
```

Why each number: `count(*)` returns one row per call, so 3 calls produce 3 rows. The two `order_id` listings return 100 rows each, so 200. Different constants shared one entry because statistics store the normalised text with `$1`. Orders 24 to 47 fall on 2 January (hour 24 is 2 January 00:00, hour 48 is 3 January 00:00), so both filters count 24. Order IDs follow insertion order, so `OFFSET 995` and `order_id > 995` both return 996 to 1000.

Expected stderr, not yet run: notices such as "schema ... does not exist, skipping" on a first run. They are not data rows.

### Read your own plans
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/plans.sql
```

Expected output, not yet run: four plans. Their exact nodes, costs, times and buffer counts are intentionally not predicted. Look for the following, and write down what you see:

| Look at | What it tells you | Typical meaning |
|---|---|---|
| `rows=` estimate versus `actual ... rows=` | Statistics quality | A ratio far from 1 is a statistics problem before it is an index problem (lesson 02). |
| `loops=` | How often a node ran | Actual time and rows are per loop; multiply for total work. |
| `Rows Removed by Filter` | Work thrown away | A large number next to a small result suggests a missing or unusable index. |
| `Sort Method:` | Memory or disk sort | `external merge` with a `Disk:` figure means the sort spilled past `work_mem`. |
| `Buffers: shared hit=... read=...` | Cache versus requested reads | Hits are pages found in shared buffers; reads are requested from the OS, not necessarily physical disk. |
| `I/O Timings:` | Time waiting on reads | Present because `track_io_timing=on`. |
| `Planning Time` / `Execution Time` | Where the milliseconds are | Planning time matters for very short queries and many partitions (lesson 03). |
| `Heap Fetches` on an index-only scan | Visibility map coverage | High means the index-only scan still visits the table (lesson 02). |

On 1,000 rows a sequential scan can legitimately win even after the index exists. Do not disable sequential scans to manufacture a nicer plan; if you want to see the alternative, repeat the experiment with a table of realistic size and compare **several runs**, discarding the first (cold cache).

## How it works
**Find.** `pg_stat_statements` accumulates since the last reset (or restart). Rank by `total_exec_time` for "where does the server spend time", by `calls` for "what is chatty", and by `mean_exec_time` for "what is slow each time". Also look at `rows / calls` (a query returning 50,000 rows per call is a client problem), `shared_blks_read` (cache pressure) and, on 17, `shared_blk_read_time` when `track_io_timing` is on. Read the column list for your version in the [pg_stat_statements documentation](https://www.postgresql.org/docs/17/pgstatstatements.html); names changed between releases.

A report you can type in your IDE (not part of the lab files):

```sql
SELECT calls, round(total_exec_time::numeric, 1) AS total_ms,
       round(mean_exec_time::numeric, 2) AS mean_ms, rows, left(query, 60) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

**Read.** A plan is a tree; execution starts at the leaves. Compare estimates with actuals at each node, then find the node where time or buffers jump. `EXPLAIN` alone shows estimates only; `ANALYZE` executes. `BUFFERS` adds page counts. See [Using EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html).

**Anti-patterns and their repairs.**

| Anti-pattern | Why it hurts | Repair | What to measure |
|---|---|---|---|
| Function on the indexed column: `date_trunc('day', placed_at) = X` | The index on `placed_at` cannot answer an expression of it | Half-open range `placed_at >= X AND placed_at < X + 1 day`, or an expression index if the wrapper is unavoidable | Plan node type, rows removed by filter, buffers |
| `OFFSET n` paging | The server produces and discards `n` rows every page; cost grows with depth | Keyset paging: `WHERE order_id > :last ORDER BY order_id LIMIT k` | Buffers and time for page 1 versus page 10,000 |
| Foreign key without an index on the referencing column | A parent delete or update scans the child table; joins on the column scan too | Index the referencing column (a leading column of a composite index also works) | Time of `DELETE` on the parent; lock duration |
| `SELECT *` | Moves unused columns, blocks index-only scans, breaks when columns are added | Name the columns | Row width, `Heap Fetches`, network bytes |
| N+1 queries from the application | `calls` in statistics explodes while each call is fast | One query with a join or `ANY($1::bigint[])` | `calls` per request in `pg_stat_statements` |
| Leading wildcard `LIKE '%x'` | A B-tree cannot use it | `pg_trgm` GIN index, or full-text search (lesson 09) | Plan node, index size |
| `NOT IN (subquery)` where the subquery can return NULL | Returns no rows once a NULL appears | `NOT EXISTS` | Correctness first, then plan |
| Implicit or explicit cast on the indexed side | Prevents index use | Cast the constant, not the column; match types | Plan node |

**Why this, not that.** Do not tune by adding an index first. An index speeds specific reads and slows every write that touches the table, consumes disk and memory, and adds vacuum work. Rewrite a non-sargable predicate first (free), then index with evidence.

**When not to tune.** Skip a statement that is 0.1 percent of total time, a query that runs once during a nightly job that finishes comfortably, and anything you cannot reproduce with realistic data. Do not tune against a laptop with a cache fully warm and a production server that is I/O-bound without saying so.

**Measurements to take (production checklist).**
- [ ] `pg_stat_statements` is in `shared_preload_libraries`, and someone reviews the top ten on a schedule.
- [ ] You record a baseline (calls, mean, total, buffers) before every change and the same numbers after.
- [ ] Plans are captured on data volumes and distributions close to production, several runs each.
- [ ] `EXPLAIN ANALYZE` of writes runs inside `BEGIN ... ROLLBACK`.
- [ ] `log_min_duration_statement` or `auto_explain` is configured with a threshold, so slow plans are captured when they happen, not after.
- [ ] Every new index has a named workload that justifies it and is removed if `pg_stat_user_indexes.idx_scan` stays zero over a full business cycle (check replicas too).

## Try it
Keep `db` running. The starter resets the disposable schema through the setup script.

1. **Guided:** In the starter, replace the `date_trunc('month', ...)` filter by a half-open range covering January 2026 UTC. The count must stay the same.
2. Copy the starter. This copies a single file, not a folder.

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
SET TIME ZONE 'UTC';
\ir /scripts/setup.sql
-- TODO: rewrite the filter as a half-open range on placed_at (no function on the column).
-- The range must start at 2026-01-01 00:00:00+00 and end before 2026-02-01 00:00:00+00.
SELECT count(*) AS january_orders FROM app.orders
WHERE date_trunc('month', placed_at) = TIMESTAMPTZ '2026-01-01 00:00:00+00';
```

3. Save your edit and run it:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand (hours 1 to 743 after 1 January 00:00 fall in January; hour 744 is 1 February):

**Expected output, not yet run:**

```text
january_orders
743
```

4. **Change:** Predict, then compute, how many January orders are `cancelled` (every 20th hour number up to 743). Add a second query to check your prediction. Then run `EXPLAIN (ANALYZE, BUFFERS)` on your range filter before and after `CREATE INDEX ix_orders_placed ON app.orders (placed_at)` and write down which numbers you compare.
5. **Stretch (optional, no single answer):** The application's most frequent query is `WHERE customer_id = $1 AND status = 'paid' ORDER BY placed_at DESC LIMIT 20`. Design the index, say which order of columns you chose and why, and list the three measurements that would convince you it is worth its write cost.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
SET TIME ZONE 'UTC';
\ir /scripts/setup.sql
SELECT count(*) AS january_orders FROM app.orders
WHERE placed_at >= TIMESTAMPTZ '2026-01-01 00:00:00+00' AND placed_at < TIMESTAMPTZ '2026-02-01 00:00:00+00';
```

The range is half-open (`>=` start, `<` next start) so no boundary instant is counted twice and no midnight is missed. For the change rung, the cancelled orders are hours 20, 40, ..., 740, which is 37. For the stretch rung, a reasonable answer is `(customer_id, placed_at DESC) WHERE status = 'paid'` or `(customer_id, status, placed_at DESC)`: equality columns first, then the ordering column, so the server can read 20 index entries in order and stop. Measure buffers per call, the write overhead on `INSERT` and `UPDATE` of `status`, and the index size.

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
Close IDE connections first. `stop` keeps data; `down -v` removes this named project's container, network and **all its saved data**.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-01 stop
docker compose -p code101-db301-01 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress; no service should remain in this project.

## Check yourself
1. A statement shows `calls = 2,000,000` and `mean_exec_time = 0.4 ms`; another shows `calls = 3` and `mean_exec_time = 900 ms`. Which has more total time? <details><summary>Answer</summary>The first: about 800,000 ms against 2,700 ms. Rank by total, then judge whether mean time or call count is the lever.</details>
2. Predict the `rows` value for a statement that ran 4 times and returned 100 rows each time. <details><summary>Answer</summary>400, because `rows` is the cumulative total.</details>
3. Why are `customer_id = 7` and `customer_id = 8` one entry in `pg_stat_statements`? <details><summary>Answer</summary>Statements are normalised: constants become `$1`, so the queries share one text and one row of counters.</details>
4. Find the bug: `WHERE lower(email) = 'ada@example.com'` is slow although `email` has a B-tree index. <details><summary>Answer</summary>The index is on the raw column, but the predicate is on `lower(email)`. Create an expression index on `lower(email)`, or store and compare a normalised column.</details>
5. What would convince you an index was worth keeping? <details><summary>Answer</summary>A before/after measurement of the target query on realistic data, plus the measured write and size cost, and evidence it is used (`idx_scan`).</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| A message saying `pg_stat_statements` must be loaded via `shared_preload_libraries` (typical message) | The `command:` block is missing or mis-indented, or the container was not recreated after editing | Fix the file, then `docker compose -p code101-db301-01 up -d --force-recreate --wait` |
| The statistics report is empty | `pg_stat_statements_reset()` ran after your workload, or your filter text does not match | Run the workload after the reset and check `query LIKE` patterns |
| Compose complains about an unset variable or the database does not accept the password | `.env` missing, or an old volume was initialised with other credentials | Create `.env` from the example; for a disposable lab run `down -v` and start again |
| `bind` or "port is already allocated" (typical) | Another lab uses `127.0.0.1:5432` | Stop that lab first |
| `exercise.sql` not found | The starter was not copied into `code/`, or the file is saved elsewhere | Repeat the copy command in the `code` folder |
| `date_trunc` and range counts differ | The session time zone is not UTC | Keep `SET TIME ZONE 'UTC'` at the top, as in the files |

## Best practice
Tune from evidence: rank by total time, change one thing, re-measure on realistic data, and keep the numbers. Source: [PostgreSQL 17: pg_stat_statements](https://www.postgresql.org/docs/17/pgstatstatements.html) and [Using EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html).

## Going further
- [PostgreSQL 17: Performance Tips](https://www.postgresql.org/docs/17/performance-tips.html).
- [Use The Index, Luke](https://use-the-index-luke.com/) for index design from first principles (Tier 2 supplement; syntax and behaviour for 17 come from the PostgreSQL manual).
- [Supabase: performance and Postgres best practices](https://supabase.com/docs/guides/platform/performance) and the [Neon Postgres best-practices skill](https://github.com/neondatabase/postgres-skills/blob/main/skills/postgres-best-practices/SKILL.md) for hosted-platform checklists (Tier 2).
- Capstone use: the platform schema indexes for its list endpoints are explained in [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You chose a statement to tune from statistics, not intuition, and saw why constants normalise into one entry.
- You listed what to read in a plan: estimates versus actuals, loops, filters, sorts, buffers.
- You rewrote non-sargable predicates and OFFSET paging, and named the measurement for each.
- You wrote a tuning record: baseline, hypothesis, change, re-measure, guard.

## Next lesson
02. Statistics, vacuum, autovacuum and bloat: why the planner's estimates go wrong and what keeps tables healthy.
