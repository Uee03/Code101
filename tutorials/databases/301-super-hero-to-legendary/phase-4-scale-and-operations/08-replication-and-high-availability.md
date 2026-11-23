---
track: databases
level: 301
phase: 4
phase_name: scale-and-operations
lesson: 08
title: "Replication and high availability: streaming replication, failover and WAL/PITR backups"
time: 105 min
prerequisites: [301.2.05, 301.1.02]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/08-replication-and-high-availability/
assets: []
---

# 08. Replication and high availability: streaming replication, failover and WAL/PITR backups

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain how write-ahead log (WAL) shipping gives you a standby, a backup chain and point-in-time recovery, and read the settings that control each.
- Compare asynchronous and synchronous replication by data-loss risk (RPO), recovery time (RTO) and write latency, and choose with a stated reason.
- Describe a failover as an ordered procedure (detect, fence, promote, redirect, rebuild) and name split brain and the unused-slot disk-full failure.
- Write a restore-drill plan with a data fingerprint query, and say what you would measure.

## Recap
- Lesson 02: what can an abandoned replication slot do to a primary?
  <details><summary>Answer</summary>It pins the oldest data the server must keep, so vacuum cannot clean up and WAL accumulates without limit.</details>
- 201 lesson 11: why is a logical dump not enough for fast, complete disaster recovery?
  <details><summary>Answer</summary>It restores logical content only, not a continuous recovery point, and it is slow at scale; continuous WAL archiving allows recovery to a chosen moment.</details>

## Why it matters
Hardware fails, deployments go wrong and people run `DELETE` without `WHERE`. High availability limits how long you are down; backups with WAL archiving limit how much you lose and let you go back in time. They are different tools: a standby faithfully copies your mistakes within milliseconds. Teams that confuse replication with backup learn the difference at the worst moment.

## What you will build
A single-node lab that you can **inspect without building a cluster**: the settings that enable replication and archiving, the log position moving as you write, a replication slot appearing and disappearing, and a publication with its replica-identity trap. Four example configuration files show a primary, a standby, point-in-time recovery and the access rule for replication; none of them is applied. Building a real two-node cluster is described as a runbook, not executed.

## Before you start
- **Prerequisites:** Databases 301 lessons [02, statistics, vacuum and bloat](../phase-1-performance/02-statistics-vacuum-and-bloat.md) and [05, connection pooling](../phase-2-concurrency-and-integrity/05-connection-pooling.md).
- Finished lessons 02, 04 and 05 of this level and 201 lesson 11. No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lessons 02 to 07.
- Time: 105 minutes. Two sittings: break after Run it.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/08-replication-and-high-availability/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-4-scale-and-operations.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run. The hand-derived values depend on default settings of the official image; if you changed flags they will differ.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 06, Step 1](../phase-3-security-and-multitenancy/06-row-level-security-in-depth.md#step-1-prepare-the-workspace) (genuinely identical) with the phase folder `databases-301-phase-4-scale-and-operations` and lesson folder `08-replication-and-high-availability`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-4-scale-and-operations\08-replication-and-high-availability\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-4-scale-and-operations/08-replication-and-high-availability/code"
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

Identical to [lesson 02, Step 2](../phase-1-performance/02-statistics-vacuum-and-bloat.md#step-2-save-the-complete-compose-configuration); the line-by-line table is in [lesson 01, Step 2](../phase-1-performance/01-query-tuning-method.md#step-2-save-the-complete-compose-configuration). One server only: this lab does not start a standby. No Dockerfile; no art (`assets: []`).

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
New terms. **WAL (write-ahead log)**: the sequential record of every change, written before the data files change; it is what makes crash recovery work. **LSN (log sequence number)**: a position in the WAL. **Streaming replication**: a standby connects to the primary and continuously receives and replays WAL. **Hot standby**: a standby that accepts read-only queries. **Replication slot**: a server-side bookmark that makes the primary keep the WAL a standby (or consumer) still needs. **Base backup**: a physical copy of the whole data directory taken while the server runs. **PITR (point-in-time recovery)**: restoring a base backup and replaying archived WAL up to a chosen moment. **RPO (recovery point objective)**: how much recent data you can afford to lose. **RTO (recovery time objective)**: how long you can afford to be down. **Failover**: promoting a standby to take over. **Split brain**: two nodes both believing they are the primary.

**Lab data.** Three orders (1 250, 830 and 2 000 cents). The lesson adds a fourth of 500 cents, so the fingerprint after the lesson is 4 orders, 4,580 cents in total, last id 4. `audit_events` deliberately has **no primary key**, to show a replica-identity problem.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
DROP PUBLICATION IF EXISTS pub_orders;
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
CREATE TABLE app.orders (
    order_id integer NOT NULL,
    customer text NOT NULL,
    total_cents integer NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id)
);
INSERT INTO app.orders (order_id, customer, total_cents) VALUES
    (1, 'ada', 1250),
    (2, 'bo', 830),
    (3, 'cy', 2000);
CREATE TABLE app.audit_events (
    event text NOT NULL
);
INSERT INTO app.audit_events (event) VALUES ('start');
```

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT name, setting FROM pg_settings
WHERE name IN ('wal_level', 'max_wal_senders', 'max_replication_slots', 'archive_mode',
               'synchronous_commit', 'hot_standby', 'fsync', 'full_page_writes')
ORDER BY name;
SELECT pg_is_in_recovery() AS in_recovery, (SELECT count(*) FROM pg_stat_replication) AS standbys_connected;
SELECT pg_current_wal_lsn() AS lsn_before \gset
INSERT INTO app.orders (order_id, customer, total_cents) VALUES (4, 'di', 500);
SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), :'lsn_before') > 0 AS wal_advanced;
SELECT slot_name FROM pg_create_physical_replication_slot('code101_slot');
SELECT slot_name, slot_type, active FROM pg_replication_slots;
SELECT pg_drop_replication_slot('code101_slot') \gset
SELECT count(*) AS slots_after_drop FROM pg_replication_slots;
CREATE PUBLICATION pub_orders FOR TABLE app.orders, app.audit_events;
SELECT pubname, pubinsert, pubupdate, pubdelete FROM pg_publication;
SELECT app.attempt('UPDATE app.audit_events SET event = ''renamed''') AS update_without_identity;
ALTER TABLE app.audit_events REPLICA IDENTITY FULL;
SELECT app.attempt('UPDATE app.audit_events SET event = ''renamed''') AS update_with_full_identity;
DROP PUBLICATION pub_orders;
SELECT count(*) AS orders, sum(total_cents) AS total_cents, max(order_id) AS last_order FROM app.orders;
```

Reading the script. The first query lists the settings that decide what the server can do: `wal_level` must be at least `replica` for physical standbys and archiving (and `logical` for logical replication); `max_wal_senders` and `max_replication_slots` bound connections that stream WAL; `archive_mode` turns continuous archiving on; `synchronous_commit` decides whether a commit waits for the WAL flush (and, with synchronous standbys, for them); `fsync` and `full_page_writes` protect against corruption and must stay `on`. The second query shows this server is a primary (not in recovery) with no standbys connected. The third block captures the WAL position into a psql variable (`\gset`; `:'lsn_before'` inserts it as a quoted literal), writes a row, and shows the position moved forward: every write is WAL. The slot block creates a physical slot, lists it as inactive, and drops it. The publication block shows logical replication's trap: a published table with no replica identity cannot be updated, because the subscriber could not find the row to change.

**File: `code/primary.conf.example`**
```ini
# Example settings for a primary that feeds a standby and archives WAL. NOT applied by this lesson.
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
max_slot_wal_keep_size = '20GB'
archive_mode = on
archive_command = 'test ! -f /mnt/wal_archive/%f && cp %p /mnt/wal_archive/%f'
synchronous_commit = on
synchronous_standby_names = 'ANY 1 (standby1, standby2)'
```

| Line | Meaning and what changing it does |
|---|---|
| `wal_level = replica` | Records enough WAL for physical standbys and archiving. `minimal` cannot support them; `logical` adds information for logical decoding at some WAL-volume cost. |
| `max_wal_senders`, `max_replication_slots` | Upper bounds on streaming connections and slots. Leave room for base backups and tools as well as standbys; changing them needs a restart. |
| `max_slot_wal_keep_size = '20GB'` | Safety valve: a slot that falls further behind than this loses its WAL (and the consumer must be rebuilt) instead of filling the primary's disk. Choose it from your disk size and tolerance. |
| `archive_mode = on` | Hands each completed WAL segment to `archive_command`. Requires a restart to enable. |
| `archive_command = 'test ! -f ... && cp %p ...'` | `%p` is the segment's path and `%f` its file name. It must **return success only if the file is safely stored** and must not overwrite an existing file. This copy-to-a-mount example is the documentation's simplest illustration; real systems use a tool that handles durability, compression and encryption (pgBackRest, WAL-G, Barman and similar). |
| `synchronous_commit = on` | A commit returns after its WAL is flushed locally and, when synchronous standbys are named, after they confirm. `remote_apply` waits until the standby has replayed the change; `off` risks losing the last commits on a crash. |
| `synchronous_standby_names = 'ANY 1 (standby1, standby2)'` | Quorum commit: any one of the two named standbys must confirm. Commits stop waiting forever only if at least one is reachable, so plan for what happens when none is. |

**File: `code/standby.conf.example`**
```ini
# Example settings for a streaming standby. NOT applied by this lesson.
# A standby also needs an empty file named standby.signal in its data directory.
hot_standby = on
primary_conninfo = 'host=10.0.0.11 port=5432 user=replicator application_name=standby1 sslmode=verify-full passfile=/var/lib/postgresql/.pgpass'
primary_slot_name = 'standby1_slot'
restore_command = 'cp /mnt/wal_archive/%f %p'
hot_standby_feedback = off
max_standby_streaming_delay = 30s
```

| Line | Meaning and what changing it does |
|---|---|
| `hot_standby = on` | The standby accepts read-only queries while replaying WAL. |
| `primary_conninfo` | How the standby reaches the primary. `application_name` is the name used in `synchronous_standby_names`. `sslmode=verify-full` encrypts and verifies the server identity; `passfile` keeps the password out of the configuration. |
| `primary_slot_name` | The slot that guarantees the primary keeps the WAL this standby needs. Without a slot, a long outage may make the standby unrecoverable from streaming alone (an archive can rescue it). |
| `restore_command` | Fetches archived segments when streaming cannot supply them (after an outage, or while catching up). |
| `hot_standby_feedback = off` | When on, the standby tells the primary which rows its queries still need, preventing cancelled queries but holding back cleanup on the primary (the bloat risk from lesson 02). |
| `max_standby_streaming_delay = 30s` | How long replay waits for conflicting standby queries before cancelling them; larger values trade query success for replication lag. |

**File: `code/pitr.conf.example`**
```ini
# Example settings to restore a base backup to a moment in time. NOT applied by this lesson.
# Also create an empty file named recovery.signal in the restored data directory (not standby.signal).
restore_command = 'cp /mnt/wal_archive/%f %p'
recovery_target_time = '2026-11-23 09:55:00+00'
recovery_target_action = 'pause'
```

| Line | Meaning |
|---|---|
| `restore_command` | Fetches each archived WAL segment the recovery needs, in order. |
| `recovery_target_time` | Stop replay at this timestamp. Choose the moment **just before** the mistake. Alternatives: a named restore point, a transaction id or an LSN. |
| `recovery_target_action = 'pause'` | Stop and wait so you can inspect the data read-only before deciding to promote; `promote` ends recovery and opens for writes, `shutdown` stops the server. |

**File: `code/pg_hba.conf.example`**
```ini
# Example pg_hba.conf line: only the replication role, from the standby's address, over TLS with SCRAM. NOT applied.
hostssl replication replicator 10.0.0.12/32 scram-sha-256
```

The fields are connection type (`hostssl`: TLS only), database (the special word `replication` matches replication connections, **not** a database called replication), role, the single allowed client address, and the authentication method. A replication role should be able to replicate and nothing else (`CREATE ROLE replicator LOGIN REPLICATION PASSWORD ...`, with the password from a secret store).

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-08 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-08 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 08`.

## Run it
**Predict first.** (a) Is archiving on in the default image? (b) Does the log position move when you insert one row? (c) Is a freshly created slot active? (d) What happens when you update a published table that has no primary key and no replica identity?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-08 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived from the documented defaults of PostgreSQL 17):**

```text
name|setting
archive_mode|off
fsync|on
full_page_writes|on
hot_standby|on
max_replication_slots|10
max_wal_senders|10
synchronous_commit|on
wal_level|replica
in_recovery|standbys_connected
f|0
wal_advanced
t
slot_name
code101_slot
slot_name|slot_type|active
code101_slot|physical|f
slots_after_drop
0
pubname|pubinsert|pubupdate|pubdelete
pub_orders|t|t|t
update_without_identity
err:55000
update_with_full_identity
ok:1
orders|total_cents|last_order
4|4580|4
```

Why: the default image keeps `archive_mode` off but `wal_level` at `replica`, so the server is **ready to feed a standby but not archiving**, a state worth noticing in an inherited system. No standby is connected. The slot is not active because no consumer is attached; **an inactive slot still retains WAL**, which is exactly why unused slots are dangerous. The update on a published table with no replica identity fails with SQLSTATE `55000` (object not in prerequisite state; the typical message says the table cannot be updated because it does not have a replica identity and publishes updates); setting `REPLICA IDENTITY FULL` (every old column value identifies the row) lets it succeed, at the price of larger WAL; a primary key is the better fix. The fingerprint is 1,250 + 830 + 2,000 + 500 = 4,580 over 4 orders.

## How it works
**Physical streaming replication.** The primary's WAL sender streams WAL to the standby's receiver, which replays it. The standby is a byte-for-byte copy at the same major version, read-only (hot standby). It copies **everything**, including your accidental `DROP TABLE`, within moments. Replicas are for availability and read scaling, not for undoing mistakes.

**Asynchronous versus synchronous.**

| Mode | Data loss on primary failure (RPO) | Commit latency | Failure behaviour |
|---|---|---|---|
| Asynchronous | The most recent commits not yet received by the standby may be lost | Local flush only | Primary never waits for the standby |
| Synchronous (`on`, quorum of standbys) | Zero for acknowledged commits if at least one acknowledging standby survives | Adds a network round trip per commit; `remote_apply` adds replay time | If no listed standby is reachable, commits **wait**; availability is traded for durability |

Choose synchronous only for data whose loss you cannot accept, put standbys in separate failure domains, and keep the round trip short. Many systems use async plus archiving and accept a small RPO. Measure lag (`pg_stat_replication`: `write_lag`, `flush_lag`, `replay_lag`; or `pg_wal_lsn_diff(sent_lsn, replay_lsn)`).

**Reading from replicas.** A replica may be seconds behind. Read-your-own-writes fails if you read a just-written row from a replica; route such reads to the primary, or wait for an LSN. Long replica queries conflict with replay (cancelled queries or lag), and `hot_standby_feedback` converts that into primary-side bloat.

**Failover as a procedure.**
1. **Detect** failure reliably (a health check from more than one vantage point, with a timeout that tolerates a brief network blip).
2. **Fence** the old primary: make sure it cannot accept writes (stop it, cut its network, revoke its storage). Skipping this is how **split brain** happens.
3. **Choose** the most up-to-date standby (compare replay LSNs).
4. **Promote** it (`pg_ctl promote` or `SELECT pg_promote();`). It leaves recovery and accepts writes.
5. **Redirect** clients (virtual IP, DNS, a proxy or a pooler configuration, or a failover-aware driver), and drain stale connections.
6. **Rebuild** the old primary as a standby (`pg_rewind` can resynchronise a former primary if prerequisites such as `wal_log_hints` or data checksums were enabled; otherwise take a new base backup).
Automating this is a tool's job (Patroni, repmgr, pg_auto_failover, or a managed service); the risk is not the promote command but wrong detection and missing fencing. Rehearse it on a schedule.

**Logical replication.** Publications and subscriptions replicate **row changes** per table, across major versions and to non-identical schemas. It is used for upgrades, selective replication and feeding other systems. It does not replicate DDL, sequences' current values (handle separately), or large objects, and tables need a replica identity (the lab's trap). It is not a substitute for physical standbys in high availability.

**Backups: three layers.**
1. **Logical dumps** (`pg_dump`, `pg_dumpall --globals-only`): portable, per-database, slow to restore at size, no recovery point inside a day.
2. **Physical base backups** (`pg_basebackup`, or a backup tool) plus **continuous WAL archiving**: restore to any moment between the backup and the end of the archive (PITR). PostgreSQL 17 can take **incremental** base backups (`pg_basebackup --incremental`, combined with `pg_combinebackup`; WAL summarisation must be enabled), reducing backup volume and time.
3. **Storage snapshots**: fast, but only consistent if you follow your storage's procedure for databases; combine with WAL archiving.

A PITR in outline (not run; commands vary by tool): stop the damaged instance, restore the base backup into a **new** data directory, add `recovery.signal` and the settings from `pitr.conf.example`, start it, wait for it to reach the target and pause, **verify the data** with a fingerprint query, then promote, or export the lost rows and reinsert them into production. Never restore over the only copy.

**Failure modes (the ones that cause real outages).**
- WAL archive failing silently, so you have no PITR: monitor `pg_stat_archiver` (`failed_count`, `last_failed_wal`, `last_archived_time`).
- Unused or lagging slot filling `pg_wal` and the disk: monitor retained WAL per slot; set `max_slot_wal_keep_size`.
- A "backup" never restored: untested backups are hopes. Drill the restore, time it, compare a fingerprint.
- Standby on a different minor/major version or with different extensions installed.
- Synchronous standby down, so every commit hangs.
- Failover without fencing, then two primaries diverge.
- Credentials for the replication role reused or stored in the repository.
- Backups in the same failure domain as the database (same account, same disk, same region) and with no retention for ransomware or an operator error noticed late.

**When not to build this yourself.** Use a managed service or an established operator unless you have people who will rehearse and be on call for failover; a hand-rolled script that has never failed over is a liability. Hosted platforms document their own replication, backup and PITR options: read them before assuming parity with what this lesson describes.

**Why this, not that.** Do not use replication as a backup; do not use backups as availability. Do not turn on synchronous replication to feel safe without measuring its latency and defining what happens when the standby is gone.

**Measurements to take (production checklist).**
- [ ] RPO and RTO written down per system, and a restore drill that proves the numbers (time to restore, time to replay, fingerprint comparison).
- [ ] Replication lag (write, flush, replay) and its alert threshold; connection count of senders.
- [ ] `pg_stat_archiver` freshness and failures; archive storage growth and retention; WAL generation rate.
- [ ] Per-slot retained WAL (`pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)`), `max_slot_wal_keep_size` set, free space on the `pg_wal` volume.
- [ ] Last successful base backup age and its size; verification of backup integrity (`pg_verifybackup`).
- [ ] A failover rehearsal log: detection time, promotion time, redirect time, number of lost transactions.
- [ ] Standby parity: version, extensions, `max_connections` (a standby needs values at least those of the primary), configuration drift.
- [ ] Access: replication role limited, `pg_hba.conf` rule narrow, TLS verified, secrets in a store.

## Try it
Keep `db` running.

1. **Guided:** Create a physical slot named `exercise_slot` that **reserves WAL immediately**, so you can see an inactive slot that already retains WAL. The starter prints whether the slot retains WAL; then it drops the slot.

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
\o /dev/null
-- TODO: create a physical replication slot named exercise_slot that reserves WAL immediately.
-- Pass true as the second argument (immediately_reserve).
SELECT pg_create_physical_replication_slot('exercise_slot');
\o
SELECT slot_name, active, restart_lsn IS NOT NULL AS retains_wal FROM pg_replication_slots;
SELECT pg_drop_replication_slot('exercise_slot') \gset
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-08 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: the slot is not active (nothing is connected) but it holds a restart position, so it retains WAL. The untouched starter creates the slot without a reservation, and should show `exercise_slot|f|f` (no restart position until a consumer connects).

**Expected output, not yet run:**

```text
slot_name|active|retains_wal
exercise_slot|f|t
```

3. **Change:** Write the monitoring query you would alert on for every slot: its name, whether it is active, and the bytes of WAL it forces the primary to keep, using `pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)`. Run it in your IDE with the slot present and say what the number means for your disk.
4. **Stretch (optional, no single answer):** A business has RPO 0 for payments and RPO 15 minutes for everything else; one region, two zones. Sketch the topology (which standbys, sync or async, which archive and where), the failover procedure with fencing, and a quarterly restore drill with its pass criteria.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
\o /dev/null
SELECT pg_create_physical_replication_slot('exercise_slot', true);
\o
SELECT slot_name, active, restart_lsn IS NOT NULL AS retains_wal FROM pg_replication_slots;
SELECT pg_drop_replication_slot('exercise_slot') \gset
```

For the change rung, a reasonable query is `SELECT slot_name, active, pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS retained_bytes FROM pg_replication_slots;`: the number grows as the primary writes while nobody consumes, until the disk is full or `max_slot_wal_keep_size` invalidates the slot. For the stretch rung, a defensible answer puts payments on a synchronous quorum of two standbys in two zones (so one zone can fail without stalling commits) and everything else on asynchronous replication, archives WAL to storage in a separate failure domain, fences by stopping the old primary and revoking its network or storage, and passes the drill only when a restored copy matches the fingerprint within the RTO.

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
docker compose -p code101-db301-08 stop
docker compose -p code101-db301-08 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. A developer runs `DROP TABLE orders` at 10:03. The standby is one second behind. Can you fail over to it to recover the table? <details><summary>Answer</summary>No: it replays the drop within a second. Recover from a base backup plus archived WAL to a point before 10:03 (PITR), or from a delayed replica if you have one.</details>
2. Predict what happens to commits with `synchronous_standby_names = 'standby1'` when `standby1` is down. <details><summary>Answer</summary>They wait (hang) until a listed standby confirms or the setting is changed; availability is sacrificed for durability.</details>
3. Find the problem: an old replication slot for a decommissioned standby still exists. <details><summary>Answer</summary>It forces the primary to retain WAL indefinitely and may fill the disk; drop it and set `max_slot_wal_keep_size`.</details>
4. What turns a backup into something you can rely on? <details><summary>Answer</summary>A timed restore drill that verifies the restored data against a fingerprint, plus monitoring of base backup and WAL archive freshness.</details>
5. What is the purpose of fencing in a failover? <details><summary>Answer</summary>To make sure the old primary cannot accept writes after a standby has been promoted, preventing split brain.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| `pg_create_physical_replication_slot` result prints rows into your expected output | The function result was not discarded | Use `\o /dev/null` or `\gset`, as in the lesson |
| A "replication slot already exists" message (typical) | A previous run stopped before the drop | `SELECT pg_drop_replication_slot('code101_slot');` then rerun |
| `err:55000` in your own update of a published table | No replica identity | Add a primary key, or `REPLICA IDENTITY FULL` as a last resort |
| Settings differ from the expected table | Different image flags or configuration | Compare with `SHOW` and the 17 documentation; the lab values are the defaults |
| Disk fills in production with archiving "on" | The archive command is failing, so WAL piles up | Alert on `pg_stat_archiver.failed_count` and `last_archived_time` |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Write RPO and RTO per system, take base backups with continuous WAL archiving, and prove the numbers with a regular timed restore drill that checks a data fingerprint. Source: [PostgreSQL 17: Continuous Archiving and Point-in-Time Recovery](https://www.postgresql.org/docs/17/continuous-archiving.html) and [High Availability, Load Balancing, and Replication](https://www.postgresql.org/docs/17/high-availability.html).

## Going further
- [Streaming replication and standby setup](https://www.postgresql.org/docs/17/warm-standby.html), [pg_basebackup](https://www.postgresql.org/docs/17/app-pgbasebackup.html), [pg_rewind](https://www.postgresql.org/docs/17/app-pgrewind.html) and [Logical Replication](https://www.postgresql.org/docs/17/logical-replication.html).
- A practitioner overview of HA strategies and tools: [pgEdge: PostgreSQL high availability strategies, tools and best practice](https://www.pgedge.com/blog/postgresql-high-availability-strategies-tools-best-practice) (Tier 2).
- Capstone: the platform capstone runs one database service in Compose for development; see [capstone platform TDD](../../../../capstones/platform/TDD.md) for its data requirements, then apply this lesson's RPO/RTO questions to them.

## Summary
- You read the settings that make a server a primary, a standby or an archiver, and watched WAL move.
- You compared asynchronous and synchronous replication by RPO, RTO and commit latency.
- You wrote failover as an ordered procedure with fencing, and listed the failure modes that cause real outages.
- You planned a restore drill with a fingerprint query.

## Next lesson
09. pgvector and search: embeddings, approximate indexes and full-text search.
