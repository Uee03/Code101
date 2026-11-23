---
track: databases
level: 301
phase: 1
phase_name: performance
lesson: 03
title: "Partitioning: range, list, hash, pruning and maintenance"
time: 90 min
prerequisites: [301.1.02]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-1-performance/03-partitioning/
assets: []
---

# 03. Partitioning: range, list, hash, pruning and maintenance

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Choose between range, list and hash partitioning for a stated workload, and say when not to partition at all.
- Prove partition pruning happened (and when it cannot) by reading plans, using a helper that counts the partitions a plan touches.
- Attach, detach and drop partitions as a retention routine, and explain which constraints partitioning changes.
- Write the monthly maintenance routine and the measurements that tell you partitioning is helping.

## Recap
- Lesson 02: what makes `DELETE` of 90 percent of a big table a poor retention strategy?
  <details><summary>Answer</summary>It creates dead tuples that vacuum must process, bloats indexes, and does not shrink the file. Dropping a whole partition removes the file instead.</details>
- Lesson 01: what in a plan tells you a filter is not using an index?
  <details><summary>Answer</summary>A scan node with `Rows Removed by Filter` and no index condition; for partitions, also a scan of every partition.</details>

## Why it matters
Partitioning splits one logical table into physical pieces. It is **not** a general speed-up: a query helps only if the planner can exclude pieces (pruning), and every partition adds planning work, files, and maintenance. Its real payoffs are cheap retention (`DROP` a month), smaller indexes and vacuum units, and data placement. Used on the wrong table it makes queries slower and migrations harder.

## What you will build
Three small partitioned tables whose placement you can derive by hand: measurements by **range** (month), sales by **list** (region, with a default partition) and sessions by **hash** (four buckets). A helper counts how many partitions a query plan touches, and a maintenance sequence attaches and detaches a month.

## Before you start
- Finished lessons 01 and 02 of this level and [201 lesson 07](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md). No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lesson 02.
- Time: 90 minutes. Two sittings are reasonable: break after Step 4.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-1-performance/03-partitioning/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-1-performance.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; results are derived by hand or described.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 01, Step 1](01-query-tuning-method.md#step-1-prepare-the-lesson-workspace) (genuinely identical) with the folder `03-partitioning`. To get back to the right folder:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-1-performance\03-partitioning\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-1-performance/03-partitioning/code"
```

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

Identical to [lesson 02, Step 2](02-statistics-vacuum-and-bloat.md#step-2-save-the-complete-compose-configuration); the line-by-line table is in [lesson 01, Step 2](01-query-tuning-method.md#step-2-save-the-complete-compose-configuration). No Dockerfile; no art (`assets: []`).

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

### Step 4. Model the feature, then save the files
New terms. A **partitioned table** has no rows of its own; it routes each row to a **partition**, an ordinary table, by the **partition key**. **Range** partitioning uses non-overlapping intervals, **list** uses explicit values, **hash** uses `hash(key) MODULUS m = REMAINDER r`. **Pruning** is the planner or executor skipping partitions that cannot match the query's conditions on the key. A **default partition** receives rows that match no other partition. **Attach** and **detach** turn an existing table into a partition and back.

| Method | Use when | Pitfall |
|---|---|---|
| Range (time, ids) | Rolling data with retention and mostly time-bounded queries | Forgotten future partition: inserts fail at midnight on the first of the month |
| List (region, tenant class) | A small, stable set of categories queried one at a time | A default partition that grows silently; blocks adding new partitions until checked |
| Hash | Spreading load or size when there is no natural range and queries filter by the key | Cannot drop "old" data; adding buckets means rewriting data |

**Rules that surprise people.** A primary key or unique constraint on a partitioned table **must include every partition-key column** (uniqueness is enforced per partition, so global uniqueness across partitions is not available). A foreign key can point **to** a partitioned table (PostgreSQL 12 and later) but each referenced row is then identified by the whole key. Indexes are created on each partition. Pruning needs conditions on the **key itself** in a form the planner can compare with the bounds: wrapping the key in a function disables it (the script proves this).

**Seed arithmetic.** Six measurements, two per month January to March 2026 (ids 1 to 6). Four sales: two `eu`, one `us`, one `apac` (no partition for `apac`, so it lands in the default partition). Eight sessions, user ids 1 to 8; hash buckets are **not** predicted, only the totals.

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
CREATE FUNCTION app.partitions_in_plan(p_query text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_line text;
    v_match text[];
    v_found text[] := '{}';
BEGIN
    FOR v_line IN EXECUTE 'EXPLAIN (COSTS OFF) ' || p_query LOOP
        FOR v_match IN SELECT regexp_matches(v_line, 'measurements_[0-9]{4}_[0-9]{2}', 'g') LOOP
            IF NOT (v_match[1] = ANY (v_found)) THEN
                v_found := v_found || v_match[1];
            END IF;
        END LOOP;
    END LOOP;
    RETURN cardinality(v_found);
END
$$;
CREATE TABLE app.measurements (
    measurement_id bigint NOT NULL,
    device_id integer NOT NULL,
    recorded_on date NOT NULL,
    reading numeric(5,1) NOT NULL,
    CONSTRAINT pk_measurements PRIMARY KEY (measurement_id, recorded_on)
) PARTITION BY RANGE (recorded_on);
CREATE TABLE app.measurements_2026_01 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE app.measurements_2026_02 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE app.measurements_2026_03 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES
    (1, 1, DATE '2026-01-05', 10.5),
    (2, 1, DATE '2026-01-20', 11.0),
    (3, 2, DATE '2026-02-03', 9.5),
    (4, 2, DATE '2026-02-14', 9.0),
    (5, 3, DATE '2026-03-01', 12.0),
    (6, 3, DATE '2026-03-31', 12.5);
CREATE TABLE app.sales (
    sale_id integer NOT NULL,
    region text NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (sale_id, region)
) PARTITION BY LIST (region);
CREATE TABLE app.sales_eu PARTITION OF app.sales FOR VALUES IN ('eu');
CREATE TABLE app.sales_us PARTITION OF app.sales FOR VALUES IN ('us');
CREATE TABLE app.sales_other PARTITION OF app.sales DEFAULT;
INSERT INTO app.sales (sale_id, region, amount) VALUES
    (1, 'eu', 10), (2, 'eu', 20), (3, 'us', 30), (4, 'apac', 40);
CREATE TABLE app.sessions (
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT pk_sessions PRIMARY KEY (session_id, user_id)
) PARTITION BY HASH (user_id);
CREATE TABLE app.sessions_p0 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE app.sessions_p1 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE app.sessions_p2 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE app.sessions_p3 PARTITION OF app.sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO app.sessions (session_id, user_id) SELECT n, n FROM generate_series(1, 8) AS n;
ANALYZE app.measurements;
```

The key is the primary key shape `(measurement_id, recorded_on)`: the partition key is part of it. `app.attempt` runs a statement in a sub-transaction and returns `ok:<rows>` or `err:<SQLSTATE>`, so the script can show failures without stopping. `app.partitions_in_plan` runs `EXPLAIN (COSTS OFF)` and counts the **distinct partition names** that appear in the plan text, which is a deterministic way to see pruning; it is a lab helper, not production code (it concatenates SQL text). Bounds are half-open: `FROM` is inclusive and `TO` is exclusive, so month partitions touch without overlapping.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT tableoid::regclass::text AS partition, count(*) AS rows
FROM app.measurements GROUP BY 1 ORDER BY 1;
SELECT app.partitions_in_plan('SELECT * FROM app.measurements') AS all_rows_query,
       app.partitions_in_plan('SELECT * FROM app.measurements WHERE recorded_on >= DATE ''2026-02-01'' AND recorded_on < DATE ''2026-03-01''') AS february_range,
       app.partitions_in_plan('SELECT * FROM app.measurements WHERE date_trunc(''month'', recorded_on) = TIMESTAMP ''2026-02-01 00:00:00''') AS wrapped_in_function;
SELECT tableoid::regclass::text AS partition, count(*) AS rows
FROM app.sales GROUP BY 1 ORDER BY 1;
SELECT count(*) AS total_rows,
       (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.sessions'::regclass) AS partitions
FROM app.sessions;
BEGIN;
SELECT app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (1000, 9, DATE ''2026-02-10'', 1.0)') AS in_range,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (1001, 9, DATE ''2026-07-01'', 1.0)') AS out_of_range,
       app.attempt('CREATE UNIQUE INDEX ux_bad ON app.measurements (device_id)') AS unique_without_key;
ROLLBACK;
CREATE TABLE app.measurements_2026_04 (LIKE app.measurements INCLUDING DEFAULTS);
ALTER TABLE app.measurements_2026_04 ADD CONSTRAINT ck_measurements_2026_04
    CHECK (recorded_on >= DATE '2026-04-01' AND recorded_on < DATE '2026-05-01');
ALTER TABLE app.measurements ATTACH PARTITION app.measurements_2026_04
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading)
VALUES (7, 3, DATE '2026-04-02', 8.0);
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions_after_attach,
       (SELECT count(*) FROM app.measurements) AS rows_after_attach;
ALTER TABLE app.measurements DETACH PARTITION app.measurements_2026_04;
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions_after_detach,
       (SELECT count(*) FROM app.measurements) AS rows_after_detach,
       (SELECT count(*) FROM app.measurements_2026_04) AS detached_rows;
DROP TABLE app.measurements_2026_04;
```

Reading the script: `tableoid::regclass` is the table a row physically lives in, which shows routing. The `BEGIN ... ROLLBACK` block keeps the test inserts out of the data. The attach sequence builds the new month as a plain table first, adds a `CHECK` constraint that proves its rows fit the bounds (so `ATTACH` can skip a validation scan), then attaches, inserts through the parent, detaches, and drops. That is the monthly routine.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-03 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created and reported healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-03 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md) with display name `Code101 DB301 03`.

## Run it
**Predict first.** (a) In which partition does 2026-03-01 land? (b) How many partitions does the unfiltered query touch, the February range query, and the `date_trunc` query? (c) What happens to an insert dated July 2026? (d) Can you create a unique index on `device_id` alone?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
partition|rows
app.measurements_2026_01|2
app.measurements_2026_02|2
app.measurements_2026_03|2
all_rows_query|february_range|wrapped_in_function
3|1|3
partition|rows
app.sales_eu|2
app.sales_other|1
app.sales_us|1
total_rows|partitions
8|4
in_range|out_of_range|unique_without_key
ok:1|err:23514|err:0A000
partitions_after_attach|rows_after_attach
4|7
partitions_after_detach|rows_after_detach|detached_rows
3|6|1
```

Derivations. The upper bound is exclusive, so 2026-03-01 belongs to March. `apac` has no list partition and falls to the default partition (`sales_other`). The unfiltered query reads all three partitions; a range condition on the key leaves only February; a function wrapped around the key hides the key from the planner, so all three are read again. A row that fits no partition and has no default raises a check violation (SQLSTATE `23514`; the typical message says there is no partition of the relation for the row). A unique index that omits the partition key is rejected with `0A000` (feature not supported; the typical message says the unique constraint must include all partitioning columns). Hash placement is not predicted, only the eight rows and four partitions.

### Read your own plans
These are statements to run in your IDE or with `psql -c`. Their exact text depends on your server, so none is asserted:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM app.measurements
WHERE recorded_on >= DATE '2026-02-01' AND recorded_on < DATE '2026-03-01';
```

Look for: only one partition named under the plan; with a prepared statement and a parameter, **runtime pruning** (partitions listed but marked as not executed or removed); the number of partitions in `Planning` work. With thousands of partitions, planning time becomes a cost on every query that cannot prune.

## How it works
**Pruning.** At plan time the planner compares constants in your `WHERE` with the partition bounds and drops the others. When a value is only known at execution (a parameter, a subquery), the executor can prune at start-up or per loop. Conditions must be on the key columns in comparable form; casts and functions on the key usually defeat pruning. `enable_partition_pruning` is on by default; do not turn it off.

**What partitioning costs.** More relations to plan, more catalog entries and files, more indexes to create and maintain, and per-partition constraints on uniqueness. Queries that cannot prune touch every partition and are **slower** than on one table. A partitioned table with a few hundred rows per partition is a mistake.

**When to use it, when not to.**
- Use range partitioning for large append-mostly data with retention (logs, metrics, events, ledgers) where most queries carry a time bound.
- Use it to make deletion cheap: `DROP` or `DETACH` of a partition replaces a huge `DELETE` and its vacuum bill (lesson 02).
- Consider list partitioning when each category is queried and maintained separately (also a tenant isolation device, lesson 07).
- Do not partition to "speed up" a table you can fix with an index or a rewritten predicate (lesson 01). A rule of thumb to **measure**, not trust: partitioning becomes worth discussing when a single table's size makes maintenance (vacuum, index builds, backups) painful, not at a fixed row count.

**Maintenance routine (range by month).**
1. Create next month's partition early (a scheduled job, or an extension such as `pg_partman`). Alert when fewer than N future partitions exist.
2. Build the new partition as a plain table with its `CHECK` constraint, then `ATTACH` (as in the script) when loading data from outside.
3. Retire old data with `DETACH PARTITION` (on busy systems `DETACH PARTITION ... CONCURRENTLY`, which cannot run inside a transaction block and has restrictions, for example with a default partition); archive the detached table, then `DROP` it.
4. Keep a default partition only if you also monitor it: a non-empty default blocks creating a partition whose range overlaps its rows, and attaching scans it to check.
5. Remember `ANALYZE` on the parent is not run by autovacuum for partitioned tables; analyze them yourself on a schedule.

**Failure modes.** Missing future partition (inserts fail at the boundary); `ATTACH` taking a lock while it scans a large table without a matching `CHECK`; unique constraints missing across partitions (enforce global uniqueness another way, for example by including the key in application identifiers); queries wrapping the key in functions; over-partitioning (daily partitions for ten years of low volume).

**Measurements to take (production checklist).**
- [ ] Planning time and execution time of your top statements before and after, on production-sized data.
- [ ] Number of partitions touched per hot query (pruning proof from the plan).
- [ ] Partition sizes (`pg_total_relation_size` per partition) and the size of the largest.
- [ ] Time to create, attach and drop a partition in a rehearsal; lock waits during it.
- [ ] Existence of future partitions and the row count of any default partition.
- [ ] Backup and restore time for the table before and after (lesson 08).

## Try it
Keep `db` running.

1. **Guided:** Create the May 2026 partition in the starter (from 2026-05-01 up to, but not including, 2026-06-01). The final query counts partitions and attempts a May insert.

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
-- TODO: create app.measurements_2026_05 as a partition of app.measurements for May 2026
-- (from 2026-05-01 up to, but not including, 2026-06-01).
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (50, 1, DATE ''2026-05-10'', 2.0)') AS may_insert;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: three partitions plus May makes four, and the insert now finds a home. Before you fill the TODO, the starter should show three partitions and a failure code for the insert.

**Expected output, not yet run:**

```text
partitions|may_insert
4|ok:1
```

3. **Change:** Add a `DEFAULT` partition to `app.measurements`, rerun the three `partitions_in_plan` queries from `lesson.sql` and **record what you observe** for the February range query. Explain the result from the documentation of default partitions and pruning; do not guess a number in advance.
4. **Stretch (optional, no single answer):** A table of 2 billion event rows is queried mostly by `tenant_id` and `created_at` range, with 400 days retention. Choose between (a) range by month, (b) list by tenant, (c) hash by tenant with a time index, (d) no partitioning with partial indexes. State the pruning guarantee each gives your top queries and the operational cost of each.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE TABLE app.measurements_2026_05 PARTITION OF app.measurements
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
SELECT (SELECT count(*) FROM pg_inherits WHERE inhparent = 'app.measurements'::regclass) AS partitions,
       app.attempt('INSERT INTO app.measurements (measurement_id, device_id, recorded_on, reading) VALUES (50, 1, DATE ''2026-05-10'', 2.0)') AS may_insert;
```

For the change rung, read [Partition pruning](https://www.postgresql.org/docs/17/ddl-partitioning.html#DDL-PARTITION-PRUNING) and the default-partition notes in the same page; whether the default partition appears depends on whether the query's range is fully covered by existing partitions, and you should confirm it by your own plan. For the stretch rung there are two defensible answers: (a) when most queries carry a time bound, retention is a `DROP`, and pruning is by time; (b) or a composite approach (list or hash by tenant then range by month) only if tenants are large and few, because the partition count multiplies.

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
docker compose -p code101-db301-03 stop
docker compose -p code101-db301-03 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. Why must the primary key of a partitioned table include the partition key? <details><summary>Answer</summary>Each partition enforces uniqueness only inside itself; including the key guarantees equal keys always land in the same partition, so a per-partition check is a global check.</details>
2. Predict the partition for `recorded_on = '2026-02-01'` with bounds `FROM ('2026-01-01') TO ('2026-02-01')` for January. <details><summary>Answer</summary>February. `TO` is exclusive.</details>
3. A query `WHERE date_trunc('month', recorded_on) = ...` touches every partition. Fix it. <details><summary>Answer</summary>Rewrite as a half-open range on `recorded_on` so the planner can compare it with the bounds.</details>
4. When is hash partitioning a poor choice? <details><summary>Answer</summary>When you need to drop old data or query ranges; hash gives no ordering or retention boundary, and changing the number of buckets rewrites data.</details>
5. Which measurement tells you partitioning helped a query? <details><summary>Answer</summary>Fewer partitions touched in the plan plus lower execution time and buffers on production-sized data, with planning time not rising materially.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| Insert fails with a "no partition of relation found for row" message (typical) | No partition covers the date and there is no default partition | Create the partition ahead of time, or add a monitored default |
| A message that the unique constraint must include all partitioning columns (typical) | Primary key or unique index omits the partition key | Add the key columns, or enforce uniqueness another way |
| Every partition appears in the plan | Condition not on the key, wrapped in a function, or cast | Compare the bare key column with constants or parameters |
| `ATTACH` is slow or blocks | No matching `CHECK` constraint, so the table is scanned to validate | Add the `CHECK` first, as in the script |
| Cannot create a partition because rows exist in the default partition | Overlapping rows must be moved first | Move rows, then create the partition |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Partition for a stated operational reason (retention, maintenance size, placement), prove pruning in the plan, and automate partition creation and retirement. Source: [PostgreSQL 17: Table Partitioning](https://www.postgresql.org/docs/17/ddl-partitioning.html).

## Going further
- [ALTER TABLE ... DETACH PARTITION ... CONCURRENTLY](https://www.postgresql.org/docs/17/sql-altertable.html) and the best-practice section of the partitioning page.
- [Use The Index, Luke](https://use-the-index-luke.com/): index design that makes partitioning unnecessary for many tables (Tier 2).
- Capstone: the platform's `audit_log` is the kind of append-mostly table that would be range-partitioned by month at scale; see [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You chose between range, list and hash from workload, and named when not to partition.
- You proved pruning (and its failure) with a plan-reading helper.
- You attached, detached and dropped a partition as a retention routine.
- You listed the failure modes and the measurements for a partitioning decision.

## Next lesson
04. Transactions, isolation levels and locking: what concurrent sessions can see, and how rows are protected.
