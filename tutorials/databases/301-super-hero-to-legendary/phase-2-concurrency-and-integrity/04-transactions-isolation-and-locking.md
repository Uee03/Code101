---
track: databases
level: 301
phase: 2
phase_name: concurrency-and-integrity
lesson: 04
title: "Transactions, isolation levels and locking"
time: 120 min
prerequisites: [301.1.03, 101.3.10]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/04-transactions-isolation-and-locking/
assets: []
---

# 04. Transactions, isolation levels and locking

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Predict what two concurrent sessions see and end up with under Read Committed, Repeatable Read and Serializable, and name the anomaly each level allows.
- Reproduce a lost update with two terminals, then prevent it with `SELECT ... FOR UPDATE` and with an atomic `UPDATE`.
- Use `NOWAIT`, `SKIP LOCKED`, `lock_timeout` and advisory locks for the problems they fit, and avoid the ones they do not.
- Remove a deadlock by changing lock order, and write the retry rule for serialization failures and deadlocks.

## Recap
- 101 lesson 10: what does a transaction guarantee?
  <details><summary>Answer</summary>All of its changes happen or none do (atomicity), and committed changes are durable; isolation decides what concurrent sessions see in between.</details>
- Lesson 02: why does a long transaction hurt vacuum?
  <details><summary>Answer</summary>It pins the oldest snapshot, so dead row versions newer than it cannot be removed.</details>

## Why it matters
Most concurrency bugs pass every single-user test. They appear as lost money, double-booked seats, jobs run twice, and deadlocks at peak load. Isolation levels are a contract about which of those you must defend against yourself. Locks defend, but they also queue, time out and deadlock. This lesson makes each failure visible with two terminals and a few rows you can compute.

## What you will build
Two accounts and a three-job queue. A single-session script shows the queue claim pattern, advisory locks and a transfer function that locks in a fixed order. Four small two-terminal scripts reproduce lock waits, a lost update and a deadlock. The exercise removes the deadlock.

## Before you start
- **Prerequisites:** Databases 301 lesson [03, partitioning](../phase-1-performance/03-partitioning.md); [Databases 101 lesson 10, transactions](../../101-zero-to-hero/phase-3-designing/10-transactions.md).
- Finished lessons 01 to 03 of this level and 101 lesson 10 on transactions. No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; the same Compose file as lessons 02 and 03.
- **Two terminals** open in the lesson `code` folder for the multi-session steps.
- Time: 120 minutes. Two sittings: break after Run it, before the two-terminal part.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/04-transactions-isolation-and-locking/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-2-concurrency-and-integrity.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run. Final values are derived by hand; error texts are marked typical unless they are the documented message.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 01, Step 1](../phase-1-performance/01-query-tuning-method.md#step-1-prepare-the-lesson-workspace) (genuinely identical), using the phase folder `databases-301-phase-2-concurrency-and-integrity` and lesson folder `04-transactions-isolation-and-locking`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-2-concurrency-and-integrity\04-transactions-isolation-and-locking\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-2-concurrency-and-integrity/04-transactions-isolation-and-locking/code"
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

### Step 4. Learn the model, then save the files
New terms. **Isolation level**: how much of other sessions' concurrent work one transaction can see. **Snapshot**: the set of committed changes a statement or transaction sees. **Lost update**: two sessions read a value, both compute from it, the second write silently overwrites the first. **Row lock**: a lock on a row version taken by `UPDATE`, `DELETE` or `SELECT ... FOR UPDATE`; it does not block plain reads (MVCC). **Deadlock**: two or more transactions each waiting for a lock the other holds. **Serialization failure**: PostgreSQL aborting a transaction (SQLSTATE `40001`) because committing it would break the promised isolation; the application must retry. **Advisory lock**: an application-defined lock on a number; PostgreSQL stores it but gives it no meaning.

**What PostgreSQL really guarantees** (see [Transaction Isolation](https://www.postgresql.org/docs/17/transaction-iso.html)):

| Level | Snapshot taken | Allowed in PostgreSQL | You must still defend against |
|---|---|---|---|
| Read Committed (default; Read Uncommitted behaves the same) | At the start of **each statement** | Non-repeatable read, phantom read, serialization anomalies | Lost updates, check-then-act races |
| Repeatable Read | At the first statement of the transaction | Serialization anomalies such as write skew | Write skew; retry on `40001` |
| Serializable | As Repeatable Read, plus dependency tracking (SSI) | None, at the cost of aborts | Retry on `40001`; more aborts under contention |

Dirty reads never happen in PostgreSQL. In Repeatable Read a concurrent committed change to a row you try to update aborts you with `40001` (the documented message begins "could not serialize access due to concurrent update"). In Read Committed the same collision does not abort: the update waits, then re-evaluates its `WHERE` against the new row version, but values you computed in your **application** from an earlier read are stale. That is the lost update the lab reproduces.

**Write skew** (not run here): two doctors are on call and a rule says at least one must remain. Each transaction checks `count(*) >= 2` and then removes its own row. Under Repeatable Read both see two doctors, both succeed, nobody is on call. Under Serializable PostgreSQL aborts one of them with `40001`. Under Read Committed you would need an explicit lock (`SELECT ... FOR UPDATE` on both rows, or a locked parent row).

**Row-lock modes** (from [Explicit Locking](https://www.postgresql.org/docs/17/explicit-locking.html)):

| Requested mode | Conflicts with |
|---|---|
| `FOR KEY SHARE` | `FOR UPDATE` |
| `FOR SHARE` | `FOR NO KEY UPDATE`, `FOR UPDATE` |
| `FOR NO KEY UPDATE` | `FOR SHARE`, `FOR NO KEY UPDATE`, `FOR UPDATE` |
| `FOR UPDATE` | all four |

An ordinary `UPDATE` that does not change key columns takes `FOR NO KEY UPDATE`; foreign-key checks take `FOR KEY SHARE`, so child inserts do not block non-key updates of the parent.

**Seed.** Account 1 (Ada) and account 2 (Bo) each hold 100.00; a `CHECK` forbids negative balances. Three jobs are `pending`.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.accounts (
    account_id integer NOT NULL,
    owner text NOT NULL,
    balance numeric(10,2) NOT NULL,
    CONSTRAINT pk_accounts PRIMARY KEY (account_id),
    CONSTRAINT ck_accounts_balance CHECK (balance >= 0)
);
INSERT INTO app.accounts (account_id, owner, balance) VALUES (1, 'Ada', 100.00), (2, 'Bo', 100.00);
CREATE TABLE app.jobs (
    job_id integer NOT NULL,
    state text NOT NULL,
    CONSTRAINT pk_jobs PRIMARY KEY (job_id),
    CONSTRAINT ck_jobs_state CHECK (state IN ('pending', 'running'))
);
INSERT INTO app.jobs (job_id, state) VALUES (1, 'pending'), (2, 'pending'), (3, 'pending');
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
CREATE FUNCTION app.transfer(p_from integer, p_to integer, p_amount numeric) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM app.accounts WHERE account_id IN (p_from, p_to) ORDER BY account_id FOR UPDATE;
    UPDATE app.accounts SET balance = balance - p_amount WHERE account_id = p_from;
    UPDATE app.accounts SET balance = balance + p_amount WHERE account_id = p_to;
END
$$;
```

`app.transfer` first locks **both** account rows in ascending id order, whatever the direction of the transfer, then updates. Always acquiring locks in one global order is the standard cure for deadlocks between row updates. `app.attempt` (as in lesson 03) turns a failure into an `err:<SQLSTATE>` string for the report.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT current_setting('transaction_isolation') AS default_isolation;
WITH next AS (
    SELECT job_id FROM app.jobs WHERE state = 'pending' ORDER BY job_id LIMIT 1 FOR UPDATE SKIP LOCKED
)
UPDATE app.jobs AS j SET state = 'running' FROM next WHERE j.job_id = next.job_id RETURNING j.job_id AS claimed_job;
WITH next AS (
    SELECT job_id FROM app.jobs WHERE state = 'pending' ORDER BY job_id LIMIT 1 FOR UPDATE SKIP LOCKED
)
UPDATE app.jobs AS j SET state = 'running' FROM next WHERE j.job_id = next.job_id RETURNING j.job_id AS claimed_job;
BEGIN;
SELECT pg_try_advisory_xact_lock(42) AS first_try, pg_try_advisory_xact_lock(42) AS second_try_same_session;
SELECT count(*) AS advisory_locks_held FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid();
COMMIT;
SELECT count(*) AS advisory_locks_after_commit FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid();
SELECT app.attempt('SELECT app.transfer(1, 2, 30)') AS transfer_30;
SELECT app.attempt('SELECT app.transfer(1, 2, 500)') AS transfer_500;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
```

The claim statement is the **queue pattern**: pick the first pending job, lock it, **skip** rows another worker has already locked, mark it running. Many workers can run it at once and never claim the same job. `LIMIT 1 FOR UPDATE SKIP LOCKED` inside a CTE is the documented idiom.

Now the four two-terminal scripts. They use `pg_sleep` to hold a transaction open long enough for you to start the other terminal, which makes the interleaving repeatable.

**File: `code/hold_lock.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
SELECT account_id AS locked_account FROM app.accounts WHERE account_id = 1 FOR UPDATE;
SELECT pg_sleep(12) \gset
COMMIT;
```

`\gset` stores the (empty) result of `pg_sleep` in a variable so nothing is printed. The row lock on account 1 is held for 12 seconds.

**File: `code/try_lock.sql`**
```sql
\set ON_ERROR_STOP off
\pset format unaligned
\pset footer off
SELECT account_id AS nowait_result FROM app.accounts WHERE account_id = 1 FOR UPDATE NOWAIT;
SELECT account_id AS skip_locked_result FROM app.accounts WHERE account_id = 1 FOR UPDATE SKIP LOCKED;
SELECT account_id AS other_row FROM app.accounts WHERE account_id = 2 FOR UPDATE NOWAIT;
SET lock_timeout = '1s';
UPDATE app.accounts SET balance = balance WHERE account_id = 1;
```

`ON_ERROR_STOP off` lets the script continue after each expected error. `NOWAIT` fails at once if the row is locked; `SKIP LOCKED` returns no rows for a locked row; account 2 is free so its lock is taken and released immediately; with `lock_timeout` the plain `UPDATE` gives up after one second instead of waiting forever.

**File: `code/lost_update_a.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN ISOLATION LEVEL :iso;
SELECT balance AS seen FROM app.accounts WHERE account_id = 1 \gset
SELECT pg_sleep(6) \gset
UPDATE app.accounts SET balance = :seen - 30 WHERE account_id = 1;
COMMIT;
SELECT balance AS a_final FROM app.accounts WHERE account_id = 1;
```

Session A reads the balance into a psql variable (`:seen`), "thinks" for six seconds, then writes `seen - 30`. This is exactly what an application does when it reads, computes in code, and writes back. The isolation level is a psql variable you pass with `-v`.

**File: `code/lost_update_b.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
UPDATE app.accounts SET balance = balance - 50 WHERE account_id = 1;
SELECT balance AS b_final FROM app.accounts WHERE account_id = 1;
```

Session B subtracts 50 atomically in a single statement. Run it a couple of seconds after A has read.

**File: `code/deadlock_a.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
UPDATE app.accounts SET balance = balance - 10 WHERE account_id = 1;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance + 10 WHERE account_id = 2;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
```

**File: `code/deadlock_b.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
UPDATE app.accounts SET balance = balance - 5 WHERE account_id = 2;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance + 5 WHERE account_id = 1;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
```

A locks account 1 then wants 2. B locks account 2 then wants 1. Opposite order is the classic deadlock.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md) with display name `Code101 DB301 04`. For the two-terminal part, use two terminals; IDE consoles often share one connection.

## Run it
**Predict first.** (a) What is the default isolation level? (b) Which job does the second claim take? (c) How many advisory locks does the session hold after locking key 42 twice, and after `COMMIT`? (d) After a 30.00 transfer and a 500.00 transfer, what are the balances?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
default_isolation
read committed
claimed_job
1
claimed_job
2
first_try|second_try_same_session
t|t
advisory_locks_held
1
advisory_locks_after_commit
0
transfer_30
ok:1
transfer_500
err:23514
account_id|balance
1|70.00
2|130.00
```

Why: the first claim locks and updates job 1, the second sees job 1 as running and picks job 2. Advisory locks are re-entrant for the same session, so the second attempt also succeeds, and `pg_locks` shows one lock; a transaction-level advisory lock is released at `COMMIT`. The 30.00 transfer commits (the helper reports one row from the `SELECT`); the 500.00 transfer would make account 1 negative, so the `CHECK` fails with SQLSTATE `23514` and the failed call changes nothing.

### Two-terminal scenario 1: waiting, `NOWAIT`, `SKIP LOCKED`, `lock_timeout`
Reset the data, then use two terminals in the lesson `code` folder. Start terminal 1 and, **within about five seconds**, run terminal 2.

**Terminal (all OS; folder: this lesson `code/`; run once)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/setup.sql
```

**Terminal 1 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -U learner -d code101 -f /scripts/hold_lock.sql
```

**Terminal 2 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -U learner -d code101 -f /scripts/try_lock.sql
```

**Expected output, not yet run.** Terminal 1 prints, then waits 12 seconds:

```text
locked_account
1
```

Terminal 2 prints on standard output (hand-derived; the empty `SKIP LOCKED` result prints only its header):

```text
skip_locked_result
other_row
2
```

Terminal 2 also prints two **errors on standard error**. Typical messages: for the `NOWAIT` statement, `could not obtain lock on row in relation "accounts"` (SQLSTATE `55P03`); for the final `UPDATE`, `canceling statement due to lock timeout` (also `55P03`). Compare them with what you actually see.

### Two-terminal scenario 2: the lost update
Reset first, then start A, then B **within three seconds**.

**Terminal (all OS; folder: this lesson `code/`; run once per attempt)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/setup.sql
```

**Terminal 1 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v "iso=read committed" -U learner -d code101 -f /scripts/lost_update_a.sql
```

**Terminal 2 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lost_update_b.sql
```

**Expected output, not yet run (hand-derived).** B prints at once (100.00 - 50):

```text
b_final
50.00
```

A prints about six seconds after it started:

```text
a_final
70.00
```

Both customers were charged but the final balance is 70.00. The correct total is 100 - 30 - 50 = 20.00. A overwrote B's change with a value computed from a stale read. Now repeat with `-v "iso=repeatable read"` in terminal 1. Expected, not yet run: B prints 50.00 as before, and A stops with an error whose documented text starts `could not serialize access due to concurrent update` (SQLSTATE `40001`) and prints no `a_final` row. The database refused the lost update; your application must **retry the whole transaction**.

### Two-terminal scenario 3: the deadlock
Reset, start A, then B within one second.

**Terminal (all OS; folder: this lesson `code/`; run once per attempt)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/setup.sql
```

**Terminal 1 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/deadlock_a.sql
```

**Terminal 2 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/deadlock_b.sql
```

Expected, not yet run: **exactly one** of the two terminals fails with an error beginning `deadlock detected` (SQLSTATE `40P01`), usually after about a second (`deadlock_timeout`, default 1 s) of waiting, followed by `DETAIL` lines naming the two processes. Which one is chosen as the victim is not predictable. The survivor commits and prints its balances: if A survives, `1|90.00` and `2|110.00`; if B survives, `1|105.00` and `2|95.00`. Never write code that assumes which transaction loses.

## How it works
**Choose the weakest tool that is correct.** (1) Make the write atomic in SQL: `SET balance = balance - 30` needs no lock beyond the row lock the update takes and cannot lose updates. (2) If you must read, compute and write, lock the read: `SELECT ... FOR UPDATE`. (3) If you can accept an abort, use Repeatable Read or Serializable and retry. (4) An optimistic version column (`UPDATE ... WHERE version = $1`, check the row count) works across HTTP requests where holding a lock is impossible; the capstone platform uses it for `If-Match`.

**Lock waits are queues.** A waiting `UPDATE` holds nothing yet, but everything behind it waits as well. The worst version is DDL: `ALTER TABLE` needs `ACCESS EXCLUSIVE`, which waits behind any open transaction that touched the table and then **blocks every new query** behind it. Run migrations with a short `lock_timeout`, retry, and keep transactions short. See [Explicit Locking](https://www.postgresql.org/docs/17/explicit-locking.html) for table-level modes.

**Deadlocks.** PostgreSQL detects them (after `deadlock_timeout`) and aborts one participant. You prevent them by acquiring locks in a consistent order (as `app.transfer` does), keeping transactions short, and not holding locks while calling external services.

**Retry rule.** Retry the **entire transaction** on `40001` (serialization failure) and `40P01` (deadlock detected), with a small bounded number of attempts and jittered backoff. Do not retry constraint violations (`23xxx`) automatically. Make retried work idempotent: a retry after an unknown commit outcome (connection dropped at `COMMIT`) can otherwise run twice; an idempotency key or a unique constraint on the business operation is the guard.

**Queue pattern with `SKIP LOCKED`.** Correct for work distribution; it intentionally gives no fairness or strict ordering across workers. Keep claim and completion in transactions that are short, and record a lease/timeout so a crashed worker's job returns to `pending`.

**Advisory locks.** Use them to serialize work that has no row to lock: one cron-like job at a time, or per-entity critical sections. Prefer `pg_try_advisory_xact_lock` (released at commit or rollback). Session-level locks (`pg_advisory_lock`) survive until you release them or the session ends and are **dangerous with connection pooling** (lesson 05): the server connection is reused by other clients. Key collisions between features are your responsibility; define a key convention.

**Why this, not that.** Do not reach for `SERIALIZABLE` globally to avoid thinking; it is a good tool when you can retry and when the invariant is hard to lock, and it costs aborts under contention. Do not use `LOCK TABLE` to simulate a queue. Do not rely on application-level mutexes across several servers.

**Measurements to take (production checklist).**
- [ ] `log_lock_waits = on` (logs waits longer than `deadlock_timeout`) and `log_min_error_statement` for `40001`/`40P01`; count them per hour.
- [ ] A query for blocked sessions you can run during an incident: `SELECT pid, pg_blocking_pids(pid), wait_event_type, state, left(query, 60) FROM pg_stat_activity WHERE cardinality(pg_blocking_pids(pid)) > 0;`.
- [ ] `idle_in_transaction_session_timeout` and `statement_timeout` set per role or connection; `lock_timeout` set in migrations.
- [ ] Oldest transaction age (`now() - xact_start`) alerting.
- [ ] Retry count and final failure count in your application metrics.
- [ ] Load test the invariant with concurrent workers before release; one-user tests do not exercise any of this.

## Try it
Keep `db` running.

1. **Guided:** The starter is session B of the deadlock demo. It locks account 2 first. Reorder the two `UPDATE` statements so account 1 is always locked first, with the same arithmetic (account 2 loses 5, account 1 gains 5).

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
-- TODO: this is session B of the deadlock demo. It moves 5 from account 2 to account 1 but locks
-- account 2 first. Reorder the two UPDATE statements so that account 1 is always locked first.
-- Keep the same arithmetic: account 2 loses 5 and account 1 gains 5.
BEGIN;
UPDATE app.accounts SET balance = balance - 5 WHERE account_id = 2;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance + 5 WHERE account_id = 1;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
```

2. Reset the data, start `deadlock_a.sql` in terminal 1, and within one second run your `exercise.sql` in terminal 2:

**Terminal 2 (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: B now waits for A to commit, then applies its changes. A prints after its commit, **before** B has committed, so A shows 90.00 and 110.00; B prints last and shows both transfers applied: account 1 = 100 - 10 + 5 = 95.00 and account 2 = 100 + 10 - 5 = 105.00.

**Expected output, not yet run:** terminal 2

```text
account_id|balance
1|95.00
2|105.00
```

3. **Change:** Predict the output of `lost_update_a.sql` if you add `FOR UPDATE` to its `SELECT ... \gset` line, with `-v "iso=read committed"`, while B runs as before. Run both and compare with your prediction: what does B print, and when?
4. **Stretch (optional, no single answer):** Ticket booking: 500 buyers compete for 100 seats. Compare (a) `SELECT ... FOR UPDATE SKIP LOCKED` to grab a free seat row, (b) an `UPDATE ... WHERE state = 'free'` with row-count check, (c) Serializable with retry. State what each guarantees, how each behaves under contention, and what you would measure in a load test.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
BEGIN;
UPDATE app.accounts SET balance = balance + 5 WHERE account_id = 1;
SELECT pg_sleep(3) \gset
UPDATE app.accounts SET balance = balance - 5 WHERE account_id = 2;
COMMIT;
SELECT account_id, balance FROM app.accounts ORDER BY account_id;
```

Both sessions now lock account 1 first, so one simply waits for the other and no cycle can form. If you run the solution alone, after resetting with `setup.sql` and with no terminal 1, it applies only its own transfer and prints this (expected output, not yet run):

```text
account_id|balance
1|105.00
2|95.00
```

 For the change rung: `FOR UPDATE` in A takes the row lock when A reads, so B's `UPDATE` waits roughly until A commits (about six seconds), then B subtracts 50 from the committed 70.00 and prints 20.00; A prints 70.00. For the stretch rung, (a) and (b) lock only the row you take and scale well; (b) needs no read at all; (c) is simplest to reason about and costs aborts; measure throughput, abort/retry rate and tail latency at your contention level.

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
Close any open psql terminals first.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-04 stop
docker compose -p code101-db301-04 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. Under Read Committed, why can `UPDATE t SET x = x - 30` never lose an update, while read-compute-write in the application can? <details><summary>Answer</summary>The single statement is atomic: after waiting for a concurrent change it re-reads the current row version and applies the arithmetic to it. The application used a value read earlier.</details>
2. Predict the outcome for the lost-update script at Repeatable Read. <details><summary>Answer</summary>A's `UPDATE` fails with a serialization failure (`40001`) because the row changed after A's snapshot; B's change stands (50.00); A must retry.</details>
3. Two sessions each update two rows in opposite order. What happens, and which one fails? <details><summary>Answer</summary>A deadlock; PostgreSQL aborts one of them (not predictable) with `40P01`. Fix by locking in one global order.</details>
4. Find the problem: a worker uses `pg_advisory_lock(7)` through a transaction-mode pooler. <details><summary>Answer</summary>The lock belongs to the server connection, which the pooler hands to other clients and may not release; use `pg_advisory_xact_lock` inside a transaction, or a session pool.</details>
5. Which errors may be retried automatically, and what do you retry? <details><summary>Answer</summary>`40001` and `40P01`; retry the whole transaction, bounded, with backoff and idempotent effects.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| A syntax error near `:iso` or `ISOLATION LEVEL` (typical) | `-v "iso=..."` not passed, so psql sends the text `:iso` | Pass `-v "iso=read committed"` as shown |
| Terminal 2 finishes instantly and shows no waiting | The scripts did not overlap in time | Start terminal 2 within the stated seconds, or lengthen `pg_sleep` |
| `relation "app.accounts" does not exist` (typical) | `setup.sql` was not run, or another lab changed the volume | Run the reset command first |
| Both deadlock terminals succeed | They did not overlap | Start B within one second of A |
| Scenario results differ from the table | State left over from a previous scenario | Rerun `setup.sql` before each scenario |
| Commands print nothing | Connected to a stopped project | Check `docker compose -p code101-db301-04 ps` |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Make writes atomic in SQL, lock in one global order, keep transactions short, and treat `40001` and `40P01` as normal events your code retries. Source: [PostgreSQL 17: Concurrency Control](https://www.postgresql.org/docs/17/mvcc.html), [Transaction Isolation](https://www.postgresql.org/docs/17/transaction-iso.html) and [Explicit Locking](https://www.postgresql.org/docs/17/explicit-locking.html).

## Going further
- [SELECT: The Locking Clause](https://www.postgresql.org/docs/17/sql-select.html#SQL-FOR-UPDATE-SHARE) and [Advisory Locks](https://www.postgresql.org/docs/17/explicit-locking.html#ADVISORY-LOCKS).
- Capstone: the platform's `complete_task` and `reassign_task` lock the task row with `FOR UPDATE` and compare an expected version; see [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).
- [Use The Index, Luke](https://use-the-index-luke.com/) on why missing foreign-key indexes lengthen lock waits (Tier 2).

## Summary
- You predicted and reproduced a lost update, and fixed it three ways.
- You used `NOWAIT`, `SKIP LOCKED`, `lock_timeout` and advisory locks for the cases they fit.
- You removed a deadlock by lock ordering and wrote the retry rule.
- You listed what to monitor: lock waits, blocked sessions, transaction age and retry counts.

## Next lesson
05. Connection pooling: why connections are expensive and how to size a pool by reasoning rather than guessing.
