---
track: databases
level: 301
phase: 1
phase_name: performance
lesson: 02
title: "Statistics, vacuum, autovacuum and bloat"
time: 90 min
prerequisites: [301.1.01]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-1-performance/02-statistics-vacuum-and-bloat/
assets: []
---

# 02. Statistics, vacuum, autovacuum and bloat

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain how the planner turns column statistics into row estimates, and read `pg_stats` for a column.
- Fix a bad estimate for correlated columns with extended statistics, and say when that is the wrong tool.
- Calculate when autovacuum will fire for a table, and tune it per table with a stated reason.
- Distinguish `VACUUM`, `VACUUM FULL` and rewriting tools by what they lock and what they return to the operating system, and name the usual cause of bloat.

## Recap
- Lesson 01: what does a large gap between `rows=` (estimate) and `actual rows` usually point to first?
  <details><summary>Answer</summary>Statistics or data-distribution problems, before indexes or planner settings.</details>
- 101 and 201: what does `UPDATE` do to the old row in PostgreSQL?
  <details><summary>Answer</summary>It leaves the old row version in place and writes a new version (MVCC). The old version becomes dead once no transaction can still see it.</details>

## Why it matters
The planner never looks at your data when it plans; it looks at a summary. If the summary is stale or blind to a relationship between columns, every join order and index decision built on it is a guess. Meanwhile `UPDATE` and `DELETE` leave dead row versions that only vacuum can reclaim. Statistics and vacuum are the two background jobs that keep a healthy database from slowly becoming a slow one, and both fail quietly.

## What you will build
A 1,000-row table with autovacuum switched off on purpose, so the numbers stay deterministic. You will watch estimates change after `ANALYZE`, repair a two-column misestimate with extended statistics, compute autovacuum trigger points, and watch table size react to `DELETE`, `VACUUM` and `VACUUM FULL`.

## Before you start
- Finished lesson 01 of this level and 201 [lesson 07](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md). No host PostgreSQL is needed.
- Docker with Compose and the `postgres:17-alpine` image. Same Compose file as the 201 labs, no changes.
- Time: 90 minutes. Two sittings are reasonable: break after Step 4.
- Source pack (optional): every file is shown in full here. The finished code, starter and solution are in https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-1-performance/02-statistics-vacuum-and-bloat/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-1-performance.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; results are derived by hand or described.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 01, Step 1](01-query-tuning-method.md#step-1-prepare-the-lesson-workspace) (genuinely identical), changing the folder to `02-statistics-vacuum-and-bloat`. To get back to the right folder:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-1-performance\02-statistics-vacuum-and-bloat\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-1-performance/02-statistics-vacuum-and-bloat/code"
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

This is lesson 01's file without the `command:` block (this lab does not need `pg_stat_statements`). The line-by-line table in [lesson 01, Step 2](01-query-tuning-method.md#step-2-save-the-complete-compose-configuration) applies to every other line. In short: `image` pins the major version, `ports` publishes on loopback only, the two read-only mounts expose your scripts and exercises, and the healthcheck lets `up --wait` return when the server is ready. No Dockerfile; no art (`assets: []`).

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

Copy the example to `.env` (not shipped):

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: nothing printed.

### Step 4. Understand the model, then save the files
**How the planner estimates.** `ANALYZE` reads a random sample of rows (about 300 times `default_statistics_target`, so 30,000 rows at the default of 100; a table smaller than that is read completely) and stores, per column, in `pg_statistic` (readable through the `pg_stats` view): the fraction of NULLs, `n_distinct`, the **most common values** (MCV) with their frequencies, and a **histogram** of the remaining values. For `status = 'open'` the planner looks the value up in the MCV list and multiplies the frequency by the table's row count. For two predicates joined by AND it multiplies the two selectivities, which assumes the columns are **independent**.

New terms. **Dead tuple**: an old row version no transaction can see any more. **Bloat**: table or index space occupied by dead or unused versions. **Vacuum**: reclaims dead tuples for reuse (inside the file), updates the visibility map and free-space map, and freezes old transaction IDs. **Autovacuum**: the background launcher that runs vacuum and analyze when counters cross thresholds. **Extended statistics**: multi-column statistics created with `CREATE STATISTICS`. **Functional dependency**: a relationship such that one column's value determines another's (zone determines region).

**Seed arithmetic.** For `n` from 1 to 1000: `status` is `done` when `n` is divisible by 4 (250 rows) and `open` otherwise (750). `zone = n % 10` (ten zones, 100 rows each); `region = (n % 10) / 5` with integer division, so zones 0 to 4 are region 0 and zones 5 to 9 are region 1. Zone fully determines region. Each row carries a 100-character payload so the table spans many pages.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.events (
    event_id integer NOT NULL,
    status text NOT NULL,
    zone integer NOT NULL,
    region integer NOT NULL,
    payload text NOT NULL,
    CONSTRAINT pk_events PRIMARY KEY (event_id)
) WITH (autovacuum_enabled = false);
INSERT INTO app.events (event_id, status, zone, region, payload)
SELECT n,
       CASE WHEN n % 4 = 0 THEN 'done' ELSE 'open' END,
       n % 10,
       (n % 10) / 5,
       repeat('x', 100)
FROM generate_series(1, 1000) AS n;
CREATE FUNCTION app.estimated_rows(p_query text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_plan json;
BEGIN
    EXECUTE 'EXPLAIN (FORMAT JSON) ' || p_query INTO v_plan;
    RETURN (v_plan -> 0 -> 'Plan' ->> 'Plan Rows')::bigint;
END
$$;
```

`WITH (autovacuum_enabled = false)` is a **lab device only**: without it, autovacuum might analyze or vacuum the table at an unpredictable moment and change the numbers. Never disable autovacuum on a production table; if it falls behind, fix its settings. `app.estimated_rows` runs `EXPLAIN (FORMAT JSON)` on any query text and returns the top node's estimated row count, so the lab can print estimates as plain numbers. It only plans; it never executes the query, and it is a lab helper, not something to expose to untrusted input (it builds SQL from text).

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT app.estimated_rows('SELECT * FROM app.events WHERE status = ''open''') = 750 AS before_analyze_equals_750;
ANALYZE app.events;
SELECT app.estimated_rows('SELECT * FROM app.events WHERE status = ''open''') AS open_estimate,
       app.estimated_rows('SELECT * FROM app.events WHERE status = ''done''') AS done_estimate;
SELECT n_distinct, most_common_vals::text AS vals, most_common_freqs::text AS freqs
FROM pg_stats
WHERE schemaname = 'app' AND tablename = 'events' AND attname = 'status';
SELECT app.estimated_rows('SELECT * FROM app.events WHERE zone = 3 AND region = 0') AS estimate_without_extended,
       (SELECT count(*) FROM app.events WHERE zone = 3 AND region = 0) AS actual_rows;
CREATE STATISTICS app.st_events_zone_region (dependencies) ON zone, region FROM app.events;
ANALYZE app.events;
SELECT app.estimated_rows('SELECT * FROM app.events WHERE zone = 3 AND region = 0') AS estimate_with_dependencies;
SELECT current_setting('autovacuum') AS autovacuum_on,
       round(current_setting('autovacuum_vacuum_threshold')::numeric
             + current_setting('autovacuum_vacuum_scale_factor')::numeric * 1000) AS trigger_at_1000_rows,
       round(current_setting('autovacuum_vacuum_threshold')::numeric
             + current_setting('autovacuum_vacuum_scale_factor')::numeric * 10000000) AS trigger_at_10m_rows;
ALTER TABLE app.events SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_vacuum_threshold = 100);
SELECT option_name, option_value
FROM pg_options_to_table((SELECT reloptions FROM pg_class WHERE oid = 'app.events'::regclass))
ORDER BY option_name;
SELECT pg_relation_size('app.events') AS full_size \gset
DELETE FROM app.events WHERE event_id % 10 <> 0;
SELECT pg_relation_size('app.events') = :full_size AS size_after_delete_unchanged;
VACUUM app.events;
SELECT pg_relation_size('app.events') = :full_size AS size_after_vacuum_unchanged;
VACUUM FULL app.events;
SELECT pg_relation_size('app.events') < :full_size AS size_after_vacuum_full_smaller;
```

Notes on the script. The first estimate is compared with 750 and expected to be false: a table that was never analyzed has no column statistics, so the planner falls back to default selectivities. The exact pre-analyze number is deliberately not asserted. `\gset` stores the result of the query in a psql variable (`:full_size`) instead of printing it. The delete keeps every tenth row, so each page keeps some live rows and the file cannot be shortened by trimming empty pages at its end. `VACUUM` and `VACUUM FULL` cannot run inside a transaction block, which is fine because psql runs each statement on its own here.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-02 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then reported healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-02 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 02`.

## Run it
**Predict first.** (a) Will the `open` estimate before `ANALYZE` equal 750? (b) After `ANALYZE`, what will the estimate be for `done`? (c) For `zone = 3 AND region = 0` the true count is 100. What does the independence assumption produce: 1000 x 0.1 x 0.5? (d) When does autovacuum fire for 1,000 rows, and for ten million?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
before_analyze_equals_750
f
open_estimate|done_estimate
750|250
n_distinct|vals|freqs
2|{open,done}|{0.75,0.25}
estimate_without_extended|actual_rows
50|100
estimate_with_dependencies
100
autovacuum_on|trigger_at_1000_rows|trigger_at_10m_rows
on|250|2000050
option_name|option_value
autovacuum_enabled|false
autovacuum_vacuum_scale_factor|0.02
autovacuum_vacuum_threshold|100
size_after_delete_unchanged
t
size_after_vacuum_unchanged
t
size_after_vacuum_full_smaller
t
```

Derivations. 750 and 250: 1,000 rows times the MCV frequencies 0.75 and 0.25 (the whole table is sampled, so frequencies are exact). 50: independence gives 1,000 x 0.1 x 0.5 = 50, half the truth, because zone 3 always implies region 0. 100: with a functional dependency recorded the planner stops multiplying the second condition. 250: the default trigger is `autovacuum_vacuum_threshold` (50) plus `autovacuum_vacuum_scale_factor` (0.2) times the row count, so 50 + 200. 2,000,050: 50 + 0.2 x 10,000,000. The three size lines are `true` because a delete only marks versions dead, plain `VACUUM` makes space reusable inside the file but returns it to the operating system only when the end of the file is entirely empty, and `VACUUM FULL` rewrites the table into a new compact file.

If a line differs (for example the estimates), trust your server and compare the setting values with the official statistics documentation before concluding anything.

## How it works
**Estimates.** One-column estimates come from the MCV list and histogram. Estimates multiply across columns unless extended statistics say otherwise. `CREATE STATISTICS` supports `ndistinct` (how many distinct combinations: helps `GROUP BY`), `dependencies` (equality on a determining column implies the other) and `mcv` (the most common value combinations). They cost `ANALYZE` time and planning time, so create them only for column groups that appear together in predicates **and** cause a measured misestimate.

**When estimates still go wrong.** Skew beyond the MCV list (raise `ALTER TABLE ... ALTER COLUMN ... SET STATISTICS n` for that column and re-analyze), expressions (create an expression index or extended expression statistics so the planner has numbers for `lower(email)`), parameters in prepared statements (generic plans use averages), and stale statistics after a bulk load. After a large load run `ANALYZE` yourself instead of waiting.

**Vacuum in one paragraph.** MVCC keeps old versions so readers never block writers. A version is removable only when it is older than the oldest snapshot any session, replication slot or prepared transaction could still need (the **xmin horizon**). `VACUUM` marks removable space reusable, updates the free-space and visibility maps (index-only scans depend on the latter), and **freezes** very old row versions so transaction IDs, which are 32-bit and wrap around, never become ambiguous. `VACUUM FULL` rewrites the whole table under an `ACCESS EXCLUSIVE` lock: readers and writers wait. Use it rarely, in a maintenance window, with enough free disk for a second copy. Tools such as `pg_repack` (an extension, not core) rebuild with shorter locks; `REINDEX ... CONCURRENTLY` rebuilds bloated indexes without blocking writes.

**Autovacuum.** A launcher starts workers (up to `autovacuum_max_workers`) for tables whose dead-tuple count exceeds `threshold + scale_factor x rows`. Workers are deliberately **throttled** (`autovacuum_vacuum_cost_delay` and `autovacuum_vacuum_cost_limit`) so they do not starve foreground work. The failure mode on big, busy tables is not "autovacuum is off", it is "autovacuum starts late (a 20 percent scale factor on a 500-million-row table means 100 million dead rows first) and is throttled to a crawl". Per-table `ALTER TABLE ... SET (...)` is the standard remedy, as in the script; set it from evidence, then watch it.

**What really causes runaway bloat.**
1. A long-running or forgotten transaction (including `idle in transaction`) pins the xmin horizon, so vacuum runs but removes nothing.
2. An abandoned replication slot or a lagging standby with `hot_standby_feedback` on pins it too.
3. Update-heavy tables with no free room: lowering `fillfactor` leaves space for **HOT** (heap-only tuple) updates that avoid index writes, at the price of a larger table.
4. A large one-off `DELETE` or `UPDATE` of most of a table.

**Why this, not that.** Do not turn autovacuum off, and do not schedule a nightly `VACUUM FULL`. Tune thresholds per table, fix the transaction that pins the horizon, and use rewriting tools only when you have measured bloat that vacuum can no longer reuse.

**Measurements to take (production checklist).**
- [ ] `pg_stat_user_tables`: `n_live_tup`, `n_dead_tup`, `last_autovacuum`, `last_autoanalyze`, `n_mod_since_analyze` per large table; alert when dead tuples stay high or `last_autovacuum` is old.
- [ ] `pg_stat_activity`: oldest `xact_start`, sessions `idle in transaction`; set `idle_in_transaction_session_timeout`.
- [ ] `pg_replication_slots`: inactive slots and the WAL each retains (lesson 08).
- [ ] `age(datfrozenxid)` per database against `autovacuum_freeze_max_age`; page someone well before wraparound protection forces an aggressive vacuum.
- [ ] `log_autovacuum_min_duration` set so slow or frequent autovacuum runs appear in the log.
- [ ] Bloat estimated with `pgstattuple` or `pgstattuple_approx` (extensions) on suspect tables, before any rewrite.
- [ ] Row-estimate error (`rows=` against `actual rows`) reviewed for your top statements from lesson 01.

**When not to do any of this.** A small, mostly static table needs none of it. Do not create extended statistics "just in case" and do not lower `fillfactor` on read-mostly tables.

## Try it
Keep `db` running.

1. **Guided:** In the starter, replace both `NULL` values with the autovacuum trigger point for a 250,000-row table: default settings (50 + 0.2 x rows) and a tuned table (50 + 0.01 x rows). Round each to a whole number. Do not look at the answer first.

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
-- TODO: replace both NULL values with the autovacuum trigger point for a 250000-row table.
-- Formula: threshold + scale_factor * rows. Default is 50 + 0.2 * rows; the tuned table uses 50 + 0.01 * rows.
-- Round each result to a whole number.
SELECT NULL AS default_trigger, NULL AS tuned_trigger;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: 0.2 x 250,000 = 50,000 plus 50, and 0.01 x 250,000 = 2,500 plus 50.

**Expected output, not yet run:**

```text
default_trigger|tuned_trigger
50050|2550
```

3. **Change:** At 250,000 rows, how many dead rows can accumulate under the default before vacuum starts, expressed as a percentage of the table? Then suppose the table receives 5,000 updates per hour: how many hours until each trigger fires? Show your arithmetic in a SQL comment.
4. **Stretch (optional, no single answer):** A 400-million-row `events` table receives about 3 percent updates per day and has one slow monthly report. List what you would measure first, whether a per-table scale factor is enough, and under which finding you would consider partitioning (lesson 03) instead.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
SELECT round(50 + 0.2 * 250000) AS default_trigger, round(50 + 0.01 * 250000) AS tuned_trigger;
```

For the change rung: 50,050 dead rows is about 20 percent of 250,000; at 5,000 updates per hour the default fires after about 10 hours and the tuned setting after about half an hour (2,550 / 5,000). For the stretch rung, a defensible answer starts with dead-tuple and `last_autovacuum` evidence plus the horizon check, applies a smaller per-table scale factor first, and considers partitioning only if retention, maintenance windows or the report itself justify it.

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
docker compose -p code101-db301-02 stop
docker compose -p code101-db301-02 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. Why can a perfectly analyzed table still get a 2x-wrong estimate for `WHERE zone = 3 AND region = 0`? <details><summary>Answer</summary>The planner multiplies selectivities as if the columns were independent. A functional dependency violates that; extended statistics of kind `dependencies` correct it.</details>
2. Predict: after `DELETE` of 90 percent of the rows, what does `pg_relation_size` do? <details><summary>Answer</summary>It stays the same; the space is reusable only after vacuum, and returned to the operating system only by trimming empty pages at the end of the file or by a rewrite.</details>
3. Autovacuum is on, yet a table keeps growing and dead tuples never drop. Name two suspects. <details><summary>Answer</summary>A long-running or idle-in-transaction session, or a stale replication slot or standby feedback, pinning the xmin horizon; also thresholds too high for the table's size.</details>
4. Find the problem: a nightly job runs `VACUUM FULL` on a 300 GB table. <details><summary>Answer</summary>It takes an `ACCESS EXCLUSIVE` lock for the duration and needs space for a second copy. Fix the cause of bloat, tune autovacuum, and use `pg_repack` or a partition swap if a rewrite is truly needed.</details>
5. What does `autovacuum_enabled = false` in the lab prove about production? <details><summary>Answer</summary>Nothing; it only removes background timing from a deterministic exercise. Never copy it.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| Estimates unchanged after bulk load | No `ANALYZE` since the load and autovacuum has not triggered | Run `ANALYZE table` after bulk loads |
| `VACUUM` cannot run inside a transaction block (typical message) | Statement sent inside `BEGIN`, or by a tool that wraps scripts in a transaction | Run it on its own, outside any transaction |
| `VACUUM FULL` seems to hang | It waits for or holds an `ACCESS EXCLUSIVE` lock | Check `pg_stat_activity`; schedule it in a window |
| `pg_stats` returns no row | The table has never been analyzed, or the column name is wrong | Run `ANALYZE` and check `schemaname`, `tablename`, `attname` |
| Exercise prints `(null)` values | The TODO was not completed | Replace the `NULL` values with the formulas |
| Compose "port is already allocated" (typical) | Another lab is using 5432 | Stop it first |

## Best practice
Keep autovacuum on, tune it per table from evidence, and treat a long transaction as the first suspect for bloat. Source: [PostgreSQL 17: Routine Vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html), [Extended statistics](https://www.postgresql.org/docs/17/planner-stats.html) and [CREATE STATISTICS](https://www.postgresql.org/docs/17/sql-createstatistics.html).

## Going further
- [Autovacuum configuration](https://www.postgresql.org/docs/17/runtime-config-autovacuum.html) and [pgstattuple](https://www.postgresql.org/docs/17/pgstattuple.html).
- [Use The Index, Luke](https://use-the-index-luke.com/): how statistics and indexes interact (Tier 2).
- Capstone: the platform's `audit_log` and `idempotency_keys` tables are insert-heavy and purged; see [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md) for how the purge function is used.

## Summary
- You read column statistics and watched estimates move from unknown to exactly derivable.
- You repaired a correlated-column misestimate with `CREATE STATISTICS` and said when not to.
- You computed autovacuum trigger points and tuned one table.
- You separated `VACUUM`, `VACUUM FULL` and rewriting tools, and named the pinned-horizon cause of bloat.

## Next lesson
03. Partitioning: range, list and hash, pruning, and the maintenance work partitioning creates.
