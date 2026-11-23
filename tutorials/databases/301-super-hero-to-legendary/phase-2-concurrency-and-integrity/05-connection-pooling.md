---
track: databases
level: 301
phase: 2
phase_name: concurrency-and-integrity
lesson: 05
title: "Connection pooling: PgBouncer concepts and pool sizing by reasoning"
time: 75 min
prerequisites: [301.2.04]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/05-connection-pooling/
assets: []
---

# 05. Connection pooling: PgBouncer concepts and pool sizing by reasoning

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain why PostgreSQL connections are expensive and why "more connections" does not mean more throughput.
- Calculate a connection budget across services and predict when scaling out an application breaks it.
- Size a pool from request rate and latency (Little's law) and say which measurements would confirm it.
- Choose a pooling mode and list the session features that break in transaction pooling.

## Recap
- Lesson 04: why is a session-level advisory lock dangerous behind a pooler?
  <details><summary>Answer</summary>The lock belongs to the server connection, which the pooler hands to other clients.</details>
- 201 lesson 11: what does `SET LOCAL` do that `SET` does not?
  <details><summary>Answer</summary>It lasts only until the end of the current transaction, so it is safe to use with transaction-level pooling.</details>

## Why it matters
Every PostgreSQL connection is a separate server process with its own memory and scheduling cost. An application that scales by adding instances multiplies its pools, and one night the database refuses connections. Pools decouple many clients from few server connections, but they add a layer with its own limits, queues, modes and failure modes.

## What you will build
A small table of services (instances times pool size per instance), SQL that computes the connection budget and when it breaks, the pool-size reasoning with Little's law, and a demonstration of why session-level `SET` is unsafe behind a pooler. A complete example `pgbouncer.ini` is explained line by line but **not started**: no pooler is run in this lesson.

## Before you start
- **Prerequisites:** [Databases 301 lesson 04, transactions, isolation and locking](04-transactions-isolation-and-locking.md).
- Finished lesson 04 and 201 lesson 11. No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lessons 02 to 04.
- Time: 75 minutes.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/05-connection-pooling/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-2-concurrency-and-integrity.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; results are derived by hand.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 04, Step 1](04-transactions-isolation-and-locking.md#step-1-prepare-the-workspace) (genuinely identical) with the lesson folder `05-connection-pooling`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-2-concurrency-and-integrity\05-connection-pooling\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-2-concurrency-and-integrity/05-connection-pooling/code"
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

### Step 4. Model the budget, then save the files
New terms. **Connection budget**: the connections the server allows minus those reserved, which every client pool must share. **Pool**: a bounded set of reusable connections. **Application pool** lives inside each application instance; a **server-side pooler** such as PgBouncer sits between all clients and the database. **Pool mode**: when a server connection returns to the pool: **session** (when the client disconnects), **transaction** (after each transaction) or **statement** (after each statement; no multi-statement transactions). **Little's law**: the average number of busy servers equals arrival rate times average time in the system.

**Server limits.** `max_connections` (default 100) is the total. `superuser_reserved_connections` (default 3) keeps slots for administrators; `reserved_connections` (default 0, since PostgreSQL 16) reserves slots for a role with `pg_use_reserved_connections`. What is left is the budget for all application pools, and you also want a reserve for migrations, monitoring, backups and you at 3 a.m. The lab uses an operations reserve of 10, a policy choice.

**Seed.** Three services: `api` six instances with a pool of 10 (60 connections), `worker` four instances with 5 (20), `admin` one instance with 3 (3). Demand 83.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.services (
    service text NOT NULL,
    instances integer NOT NULL,
    pool_per_instance integer NOT NULL,
    CONSTRAINT pk_services PRIMARY KEY (service),
    CONSTRAINT ck_services_positive CHECK (instances > 0 AND pool_per_instance > 0)
);
INSERT INTO app.services (service, instances, pool_per_instance) VALUES
    ('api', 6, 10),
    ('worker', 4, 5),
    ('admin', 1, 3);
```

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT current_setting('max_connections')::int AS max_connections,
       current_setting('superuser_reserved_connections')::int AS superuser_reserved,
       current_setting('reserved_connections')::int AS reserved;
SELECT service, instances * pool_per_instance AS connections FROM app.services ORDER BY service;
SELECT sum(instances * pool_per_instance) AS demand,
       current_setting('max_connections')::int - current_setting('superuser_reserved_connections')::int
         - current_setting('reserved_connections')::int AS available,
       10 AS ops_reserve,
       sum(instances * pool_per_instance) <= current_setting('max_connections')::int
         - current_setting('superuser_reserved_connections')::int
         - current_setting('reserved_connections')::int - 10 AS fits
FROM app.services;
WITH base AS (
    SELECT (SELECT pool_per_instance FROM app.services WHERE service = 'api') AS api_pool,
           (SELECT sum(instances * pool_per_instance) FROM app.services WHERE service <> 'api') AS others,
           current_setting('max_connections')::int - current_setting('superuser_reserved_connections')::int
             - current_setting('reserved_connections')::int - 10 AS budget
)
SELECT n AS api_instances, n * api_pool + others AS demand, n * api_pool + others <= budget AS fits
FROM base, generate_series(4, 10, 2) AS n
ORDER BY n;
SELECT round(500 * 0.020, 1) AS busy_connections, ceil(500 * 0.020 / 0.7) AS pool_at_70_percent;
SET app.tenant_id = 'leaky';
BEGIN;
SET LOCAL app.tenant_id = 'scoped';
SELECT current_setting('app.tenant_id') AS inside_transaction;
COMMIT;
SELECT current_setting('app.tenant_id') AS after_commit_session_set;
RESET app.tenant_id;
SELECT nullif(current_setting('app.tenant_id', true), '') AS after_reset;
```

Reading the script. The first query reads the server limits (a default Docker image has `max_connections` 100). The second shows what each service asks for. The third compares total demand with the budget. The fourth is the failure story: keep the `api` pool at 10 and let autoscaling add instances (4, 6, 8, 10). The fifth is Little's law: 500 requests per second, each holding a connection 20 ms, keeps 500 x 0.020 = 10 connections busy on average; sizing for 70 percent utilisation gives about 14.3, rounded up to 15. The last block shows session state: a plain `SET` survives the transaction (and would be inherited by the next client that gets this connection), while `SET LOCAL` disappears at commit. `app.tenant_id` is a custom setting name (any `prefix.name` is allowed); lesson 06 uses it for row-level security.

**File: `code/pgbouncer.ini`** (an example that is explained but never started in this lesson)
```ini
; Example only. This file is NOT started by the lesson's Compose file; nothing in the lab reads it.
[databases]
code101 = host=db port=5432 dbname=code101

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
admin_users = pgbouncer_admin
pool_mode = transaction
default_pool_size = 15
reserve_pool_size = 3
reserve_pool_timeout = 5
max_client_conn = 500
max_db_connections = 40
query_wait_timeout = 10
server_idle_timeout = 600
server_lifetime = 3600
max_prepared_statements = 100
ignore_startup_parameters = extra_float_digits
```

| Line(s) | Meaning and what changing it does |
|---|---|
| `[databases]` and `code101 = host=db ...` | Maps the pooler's database name to a real server. `db` is the Compose service name when the pooler runs beside it. |
| `listen_addr`, `listen_port` | Where clients connect (conventionally 6432). Binding to loopback keeps it private; bind to a private interface only with network controls. |
| `auth_type = scram-sha-256` and `auth_file` | Clients authenticate to the pooler with SCRAM verifiers listed in a user file. The pooler needs credentials to reach PostgreSQL too. Never commit that file. |
| `admin_users` | Roles that may use the pooler's admin console (`SHOW POOLS;`, `SHOW STATS;`). |
| `pool_mode = transaction` | A server connection is attached to a client only while a transaction runs. Highest reuse; breaks session features (below). |
| `default_pool_size = 15` | Server connections per database/user pair. This is the number Little's law gave. |
| `reserve_pool_size`, `reserve_pool_timeout` | Extra connections granted to clients that wait longer than the timeout (seconds): a burst valve. |
| `max_client_conn = 500` | How many client connections the pooler accepts. This is cheap compared with server connections, and is how 500 clients share 15 server connections. |
| `max_db_connections = 40` | A hard cap of server connections per database across users, protecting `max_connections`. |
| `query_wait_timeout = 10` | Seconds a client may wait for a free server connection before it is disconnected: converts overload into a fast error instead of an infinite queue. |
| `server_idle_timeout`, `server_lifetime` | Close idle server connections and recycle old ones, so memory and stale state do not accumulate. |
| `max_prepared_statements = 100` | Lets the pooler track protocol-level prepared statements in transaction mode (available in recent PgBouncer releases; check your version's documentation). |
| `ignore_startup_parameters` | Parameters some drivers send that the pooler does not track; listing them avoids a startup error. |

All values are illustrations to reason about, not tuned recommendations; the file is validated by reading the [PgBouncer configuration reference](https://www.pgbouncer.org/config.html), not by running it.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-05 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-05 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 05`.

## Run it
**Predict first.** (a) How many connections can application pools use on a default server after the reserved ones? (b) With 10 `api` instances and a pool of 10, does the budget hold? (c) After `COMMIT`, what does `current_setting('app.tenant_id')` return when it was set with plain `SET` before the transaction?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
max_connections|superuser_reserved|reserved
100|3|0
service|connections
admin|3
api|60
worker|20
demand|available|ops_reserve|fits
83|97|10|t
api_instances|demand|fits
4|63|t
6|83|t
8|103|f
10|123|f
busy_connections|pool_at_70_percent
10.0|15
inside_transaction
scoped
after_commit_session_set
leaky
after_reset
(null)
```

Derivations: 100 - 3 - 0 = 97 available, 87 after the operations reserve of 10; demand is 60 + 20 + 3 = 83, which fits. With the other two services fixed at 23, each `api` instance adds 10: 4 instances give 63, 6 give 83, 8 give 103 (over 87), 10 give 123. Little's law gives 10.0 busy connections; dividing by a 0.7 utilisation target gives 14.29, rounded up to 15. The plain `SET` value `leaky` is still there after the transaction, so the next client to receive that server connection would inherit it. If your server returns different limits (a changed image or flags), the first lines will differ and the arithmetic follows them.

## How it works
**Why connections cost.** Each connection is a process: kernel structures, memory for caches and for every `work_mem` allocation a query uses, and scheduling overhead. Beyond roughly the number of CPU cores plus a margin for I/O waits, extra active connections mostly queue inside PostgreSQL (lock manager, CPU run queue), so throughput flattens or falls and latency rises. Idle connections are cheaper but not free, and they still count toward `max_connections`.

**Sizing by reasoning, then by measurement.**
1. Estimate demand with Little's law: `busy = rate x time_holding_a_connection`. Hold time is transaction time, not request time: do not keep a connection while calling another service.
2. Add headroom for variance: divide by a target utilisation (0.6 to 0.8 is a starting range, not a rule).
3. Compare with what the database can run concurrently: cores and I/O. A common starting heuristic from connection-pool guidance is about two connections per core plus the number of disk spindles; treat it as a hypothesis to test, not as a law.
4. Load test with realistic mixes (for example `pgbench` with your own script file) at pool sizes around your estimate, and measure throughput, p95 and p99 latency, and queue wait. Choose the **smallest** pool that gives the best throughput.

**Where pools live.**

| Layer | Strength | Weakness |
|---|---|---|
| In each application instance | Simple, language-aware, no extra hop | Total = instances x pool; scales badly with autoscaling and serverless |
| Server-side pooler (PgBouncer and similar) | Caps server connections across all clients; absorbs spikes | Another component to run, secure, size and keep highly available; mode limits |
| Managed pooler of a hosted platform | No operations | Platform-specific modes and limits (read your provider's pooling documentation) |

**Pool modes and what breaks in transaction mode.**

| Feature | Session mode | Transaction mode |
|---|---|---|
| `SET` (session level), `SET ROLE` | works | leaks to the next client or is lost; use `SET LOCAL` inside the transaction |
| `pg_advisory_lock` (session level) | works | unsafe; use `pg_advisory_xact_lock` |
| `LISTEN` / `NOTIFY` | works | does not work across transactions |
| Temporary tables, `WITH HOLD` cursors | work | break across transactions |
| Protocol-level prepared statements | work | need pooler support and configuration; otherwise errors or surprising behaviour |
| `SET LOCAL app.tenant_id` for row-level security | works | works, and is the recommended pattern (lesson 06) |

**Failure modes.** Pool exhaustion converts into queueing, then timeouts, then client retries that increase load (a **retry storm**); put timeouts and jittered backoff in clients and cap concurrency at the front door. Leaked connections (not returned on an error path) slowly drain a pool; long transactions and `idle in transaction` sessions hold connections hostage. A single-threaded pooler can become the CPU bottleneck. The pooler itself must be redundant. Credentials: keep pooler and server authentication consistent and rotate secrets without downtime.

**Why this, not that.** Raising `max_connections` is not a fix for exhaustion: it raises memory risk and contention. Put a pooler in front, shrink pools, shorten transactions, and make the budget a reviewed number, not an accident of defaults. Do not use statement pooling unless you never need a transaction.

**Measurements to take (production checklist).**
- [ ] Connections by state: `SELECT state, count(*) FROM pg_stat_activity GROUP BY state;` and the share `idle in transaction`.
- [ ] Budget table (services x instances x pool) reviewed whenever autoscaling limits change.
- [ ] Pooler statistics: clients waiting (`cl_waiting`), maximum wait, server connections in use, per pool (`SHOW POOLS;`, `SHOW STATS;`).
- [ ] Application metrics: pool wait time, pool saturation, connection errors, retries.
- [ ] Throughput and p99 at several pool sizes in a load test before choosing one.
- [ ] `idle_in_transaction_session_timeout`, `statement_timeout`, and client timeouts agree with the pooler's `query_wait_timeout`.

## Try it
Keep `db` running.

1. **Guided:** Add a `reports` service (2 instances, pool of 8 each) and replace both `NULL` values: the total demand and whether it fits within 97 - 10.

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
-- TODO: insert a service 'reports' with 2 instances and a pool of 8 connections per instance.
-- TODO: replace both NULL values. demand is the sum of instances * pool_per_instance over all services.
-- fits compares demand with 97 - 10 (available connections minus the operations reserve).
SELECT NULL AS demand, NULL AS fits;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target, derived by hand: 83 + 2 x 8 = 99, which is more than 87.

**Expected output, not yet run:**

```text
demand|fits
99|f
```

3. **Change:** With the other services unchanged, how many connections are left for `reports` (87 - 83)? Choose an instance count and pool size that fit, and edit your insert. Then explain what you would do if the `reports` service really needs 16 connections (hint: a pooler, a separate replica, or a smaller `api` pool).
4. **Stretch (optional, no single answer):** You run 40 serverless function instances that each open one connection, and the database has 16 cores. Sketch a pooling design: where the pool lives, which mode, which numbers, which settings (timeouts, limits) and how you would verify the design under a load test.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
INSERT INTO app.services (service, instances, pool_per_instance) VALUES ('reports', 2, 8);
SELECT sum(instances * pool_per_instance) AS demand,
       sum(instances * pool_per_instance) <= 97 - 10 AS fits
FROM app.services;
```

For the change rung: four connections are left, so for example two instances with a pool of 2 fit exactly; if 16 are really required, put a transaction-mode pooler in front of the database so many clients share a few server connections, or run reports on a replica (lesson 08) so they do not consume the primary's budget. For the stretch rung a defensible design is a server-side pooler in transaction mode with a pool near the core-count-based estimate, serverless clients using one short-lived connection to the pooler, `query_wait_timeout` and client timeouts set to fail fast, and a load test that ramps instances while measuring queue wait and p99.

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
docker compose -p code101-db301-05 stop
docker compose -p code101-db301-05 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. Eight `api` instances with a pool of 10, plus 23 other connections, on a server with 97 usable connections and a 10-connection reserve: does it fit? <details><summary>Answer</summary>No: demand is 103, the budget is 87.</details>
2. 200 requests per second, each holding a connection for 50 ms. Average busy connections? <details><summary>Answer</summary>200 x 0.050 = 10.</details>
3. Why is plain `SET app.tenant_id = '...'` a security bug behind a transaction-mode pooler? <details><summary>Answer</summary>It persists on the server connection after the transaction, so the next client can run with another tenant's context. Use `SET LOCAL` inside the transaction.</details>
4. Find the problem: the team doubles `max_connections` to fix "too many connections" during a spike. <details><summary>Answer</summary>It increases memory use and contention without increasing capacity; use a pooler, smaller pools and shorter transactions, and keep the budget deliberate.</details>
5. Which measurement tells you the pool is too small? <details><summary>Answer</summary>Clients waiting at the pooler or application pool wait time rising while server CPU and I/O are not saturated.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| A "sorry, too many clients already" error (typical message) | Total connections reached `max_connections` | Check the budget; add or resize a pooler; look for leaks |
| Intermittent wrong-tenant or wrong-role behaviour behind a pooler | Session-level `SET` or `SET ROLE` in transaction pooling | Use `SET LOCAL` inside each transaction |
| Prepared-statement errors only behind the pooler (typical) | Protocol-level prepared statements not supported or not configured in transaction mode | Check your pooler version's documentation; configure or disable driver caching |
| Clients hang under load | No `query_wait_timeout` or client timeout, so the queue never fails fast | Set timeouts and cap concurrency |
| `\ir` cannot find a file | Wrong folder, or `setup.sql` not saved | Run from the lesson `code` folder; save all files |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Treat the connection budget as a reviewed number: services times instances times pool, plus an operations reserve, and use `SET LOCAL` for per-request context. Source: [PostgreSQL 17: Connections and Authentication](https://www.postgresql.org/docs/17/runtime-config-connection.html) and the [PgBouncer documentation](https://www.pgbouncer.org/).

## Going further
- [PgBouncer features and pool modes](https://www.pgbouncer.org/features.html).
- Supabase platform guidance on connections and performance: [supabase.com/docs/guides/platform/performance](https://supabase.com/docs/guides/platform/performance) (Tier 2).
- Capstone: the platform backends set `app.current_user_id` with `set_config(..., true)` inside each write transaction, which is the pooler-safe pattern: [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You explained why connections are costly and why more of them do not mean more throughput.
- You calculated a connection budget and saw autoscaling break it.
- You sized a pool with Little's law and named the measurements to confirm it.
- You listed what breaks in transaction pooling and the `SET LOCAL` rule.

## Next lesson
06. Row-level security in depth: policies, performance rules and testing policies.
