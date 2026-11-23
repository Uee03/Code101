---
track: docker
level: 301
phase: 3
phase_name: operations
lesson: 09
title: Production readiness - runbooks, backup and restore drills, upgrades and a review
time: 120 min
prerequisites: ["docker 301 lessons 01 to 08", "docker 201 lessons 05, 06, 10"]
versions: { docker: "29.9.3 (inherited authoring baseline, not re-checked)", compose: "5.7.0 (inherited)", postgres_image: "17-alpine", kubernetes: "client and cluster versions not pinned: use the current stable release" }
verified: not yet run
source: source/docker/301-super-hero-to-legendary/phase-3-operations/09-production-readiness/
assets: []
---

# 09. Production readiness - runbooks, backup and restore drills, upgrades and a review

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Run a backup and a restore drill against a containerised database, and read the evidence (row counts, durations) that proves a restore works.
- Demonstrate the data-loss window of a backup schedule (RPO) by recovering after an operator error.
- Write an incident runbook that someone who did not write it can follow at 3 a.m.
- Plan upgrades of each layer (image, runtime, orchestrator, database) with a rollback for each, and run a production readiness review that ends in a go or no-go decision.

## Recap
- Which two things must a Kubernetes rollout have so a bad release does not cause an outage? (lessons 05 and 06) <details><summary>Answer</summary>Honest readiness probes and `maxUnavailable: 0` (with enough capacity for the surge).</details>
- What was the p95 measurement for in lesson 08? <details><summary>Answer</summary>To set requests from measured use plus stated headroom instead of guessing.</details>
- Why does lesson 07's stack not notify anybody when an alert fires? <details><summary>Answer</summary>It has no Alertmanager; a notification path (and a runbook for each page) is production work still to do.</details>

## Why it matters
Everything in the previous eight lessons reduces the **probability** of a bad day. This lesson is about the bad day itself, and about the one failure that no amount of hardening prevents: losing data. A backup that has never been restored is a hope, not a control. An incident without a runbook turns the person on call into the runbook. An upgrade without a rehearsed rollback is a one-way door. Production readiness is the habit of checking these things **before** launch, with evidence, and writing down who accepted what risk.

## What you will build
A single-container PostgreSQL stack (Compose) with a seed table, a backup script, a **restore drill** script that proves the backup restores into a scratch database, and a recovery script. You will simulate an operator error, recover, and see exactly which row was lost. Then you will read two runbooks (a template and a concrete one), a PodDisruptionBudget, and a scored readiness review, and finish by reviewing a deliberately bad Compose file.

## Before you start
- **Prerequisites:** Docker 301 lessons [01, threat model for containers](../phase-1-secure-supply-chain/01-threat-model-for-containers.md) to [08, resources, autoscaling and cost](08-resources-autoscaling-and-cost.md); Docker 201 lessons [05, Compose profiles](../../201-hero-to-super-hero/phase-2-compose-in-depth/05-profiles-overrides-extensions.md), [06, secrets and configs](../../201-hero-to-super-hero/phase-2-compose-in-depth/06-secrets-and-configs.md) and [10, backups and upgrades](../../201-hero-to-super-hero/phase-3-workflows/10-backups-and-upgrades.md); [Docker 101 lesson 07, healthchecks and cleanup](../../101-zero-to-hero/phase-2-compose/07-healthchecks-and-cleanup.md).
- Docker running; Compose; a text editor. Python 3.13 or the container route from lesson 01 for the optional audit in the exercise. `kubectl` and a cluster only if you want to apply the PodDisruptionBudget (lesson 05's `kind` cluster).
- Time: 120 minutes. Two sittings: stop after Step 9 (the recovery demonstration) and do the runbook, upgrade and review parts later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/docker/301-super-hero-to-legendary/phase-3-operations/09-production-readiness/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- The database is **not published** to the host (no `ports:`), so nothing here uses port 5432 and nothing clashes with the Databases track.
- The password in `.env.example` is a public demonstration value. Everything in this lab is disposable; Step 13 deletes it.
- The database here has five demonstration rows. A real restore drill needs production-sized data, because duration is the thing you are measuring.

## Concepts first

### The words that make the numbers mean something
- **RPO** (recovery point objective): how much data you can afford to lose, as time. With one backup per day the RPO is up to 24 hours. You choose the backup frequency from the RPO.
- **RTO** (recovery time objective): how long you can be down. The restore drill's duration, plus detection, decision and verification time, is your real RTO.
- **Backup** versus **replica** versus **volume**: a named Docker volume or a replica is **not a backup**. An accidental `DROP TABLE` or a bad deploy replicates and persists instantly. A backup is a separate, restorable copy at a point in time, stored somewhere that the failure you fear cannot reach (a different host, account or site).
- **Logical backup** (`pg_dump`): SQL-level, portable across versions and architectures, restores into a fresh database, slow on big data, a snapshot of one moment. **Physical backup with WAL archiving** (base backup plus write-ahead log): restores to any second (point-in-time recovery), fast for big data, tied to a major version. This lesson uses the logical kind because it is small and portable; most serious systems need the physical kind, or a managed service that does it for them.
- The common **3-2-1 rule**: three copies, on two kinds of media, one off site.

### Incidents
An incident has a lifecycle: **detect, triage, mitigate, communicate, resolve, learn**. Two rules shape the runbook below. **Mitigate before you diagnose**: the first goal is to stop the harm (roll back, fail over, shed load), not to understand it. **Separate roles** in anything serious: someone who fixes, someone who coordinates and communicates. A **blameless review** afterwards asks "what let this happen and what will stop it next time", not "who did it".

### Upgrades: four layers, four rollbacks
| Layer | How it is upgraded | Rollback | The trap |
|---|---|---|---|
| Application image | Rolling update by digest (lesson 06) | Previous digest | Incompatible database change; config not rolled back |
| Base image and OS packages | Rebuild on a schedule, re-scan, re-sign (lesson 02) | Previous digest | Nobody rebuilds because nothing is "broken" |
| Container runtime and host (Docker Engine, containerd, kernel) | One host at a time: drain, upgrade, test, return | Reinstall previous version, keep an unupgraded host | Daemon restart stops containers unless `live-restore` is configured; kernel updates need reboots |
| Orchestrator (Kubernetes) | Control plane first, then nodes, **one minor version at a time**, within the version skew policy | Restore the control-plane backup or build a new cluster | Removed APIs break old manifests; blocked drains from strict disruption budgets |
| Database engine | Minor versions: replace the image and restart. **Major versions: new data format** | Restore the pre-upgrade backup | `postgres:17` to `postgres:18` on the same volume does not start (the data directory is incompatible); you dump and restore, or use `pg_upgrade` |

Always **rehearse the upgrade on a copy built from the same code**, and rehearse the restore into the **new** version before you touch production.

## Steps

### Step 1. Make the lesson folder
**Terminal (PowerShell)**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\docker301\lesson09\code\initdb", "$HOME\code101\docker301\lesson09\code\scripts", "$HOME\code101\docker301\lesson09\code\runbooks", "$HOME\code101\docker301\lesson09\code\k8s" | Out-Null
Set-Location "$HOME\code101\docker301\lesson09\code"
```

**Terminal (macOS/Linux)**
```bash
mkdir -p ~/code101/docker301/lesson09/code/{initdb,scripts,runbooks,k8s}
cd ~/code101/docker301/lesson09/code
```
Expected result: no output; you are inside `code` with four empty subfolders. All commands run here unless stated.

### Step 2. The Compose file and settings
**File: `docker-compose.yml`**
```yaml
name: code101-readiness
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: app
      POSTGRES_DB: orders
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD in .env}
    volumes:
      - pgdata:/var/lib/postgresql/data
      - backups:/backups
      - ./initdb:/docker-entrypoint-initdb.d:ro
      - ./scripts:/scripts:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d orders"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
volumes:
  pgdata:
  backups:
```
Line by line:
- `image: postgres:17-alpine` pins the major version (an incompatible-data-directory trap if you change it later, see the table above). Production would pin a digest.
- `POSTGRES_USER`, `POSTGRES_DB`: the official image creates this superuser and database on first start. `POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?...}` takes the password from `.env` and stops with the message if it is missing. (Lesson 01's reviewed file used a password **file**, which is better; this lab keeps the simple form because the focus is the backup.)
- `pgdata:/var/lib/postgresql/data` is the database's data directory on a named volume. `backups:/backups` is a **second** named volume for dump files. **Both volumes live on the same Docker host**, so this is a lab, not a backup strategy: the point of Step 7 is to move a copy off the host.
- `./initdb:/docker-entrypoint-initdb.d:ro`: the image runs every `.sql` file in this folder **once**, when it creates a new empty data directory. `./scripts:/scripts:ro` makes the scripts visible read-only inside the container.
- `healthcheck`: `pg_isready` reports whether the server accepts connections. `interval`, `timeout`, `retries` and `start_period` as in Docker 101 lesson 07; `up --wait` below uses it.
- `restart: unless-stopped`: restart after a crash or host reboot unless you stopped it by hand.
- `security_opt: no-new-privileges`: lesson 03. This database is **not** run with a read-only root or dropped capabilities here, because the image's start-up needs them; lesson 01's reviewed file shows the numeric-user variant, which has not been run.
- `logging` rotation: lesson 07.
- The top-level `volumes:` block declares both named volumes.

**File: `.env.example`**
```text
POSTGRES_PASSWORD=demo-only-change-me
```
**File: `.gitignore`**
```text
.env
```
**File: `.gitattributes`**
```text
*.sh text eol=lf
```
- `.gitattributes` tells Git to keep shell scripts with Unix line endings even on Windows. A script with Windows line endings (`\r\n`) fails inside a Linux container with confusing errors, because the carriage return becomes part of the commands. If you create the scripts by hand on Windows, save them with **LF** line endings (most editors show this in the status bar).

Create your real settings file: Windows PowerShell `Copy-Item .env.example .env`; macOS/Linux `cp .env.example .env`.

### Step 3. The seed data
**File: `initdb/01-schema.sql`**
```sql
CREATE TABLE orders (
    id integer PRIMARY KEY,
    customer text NOT NULL,
    total_cents integer NOT NULL CHECK (total_cents >= 0)
);

INSERT INTO orders (id, customer, total_cents) VALUES
    (1, 'Ada', 1250),
    (2, 'Grace', 4200),
    (3, 'Linus', 999),
    (4, 'Margaret', 15000),
    (5, 'Dennis', 300);
```
- `CREATE TABLE orders` defines three columns; `PRIMARY KEY` makes `id` unique and indexed; `NOT NULL` and the `CHECK` reject missing customers and negative totals (money is stored in integer cents to avoid rounding errors).
- The `INSERT` adds five rows. Five is the number the drill will compare.

### Step 4. The scripts
All three run **inside** the database container (so they work the same on every host OS) and use the container's `POSTGRES_USER` and `POSTGRES_DB` variables.

**File: `scripts/backup.sh`**
```sh
#!/bin/sh
set -eu
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="/backups/orders-${STAMP}.dump"
START="$(date +%s)"
pg_dump --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --format=custom --file="$FILE"
pg_restore --list "$FILE" > /dev/null
END="$(date +%s)"
echo "backup written: $FILE"
echo "backup took $((END - START)) seconds"
```
- `#!/bin/sh` runs the script with the container's POSIX shell. `set -eu` makes it stop at the first failed command (`-e`) and treat an unset variable as an error (`-u`): a backup script that continues after a failure reports success while writing nothing.
- `STAMP` is a UTC timestamp (`date -u`), so file names sort chronologically and mean the same everywhere. `FILE` is the target path.
- `pg_dump --format=custom` writes PostgreSQL's compressed **custom** archive format, which `pg_restore` can restore selectively. `--file` names the output (no shell redirection, which would break on Windows PowerShell, whose `>` writes text in the wrong encoding for binary data).
- `pg_restore --list "$FILE" > /dev/null` reads the archive's table of contents: a cheap check that the file is a valid archive. It does **not** prove the data restores; the drill does.
- `START`/`END` use seconds since the epoch to print the duration: the number you will track over time.

**File: `scripts/restore-drill.sh`**
```sh
#!/bin/sh
set -eu
LATEST="$(ls -1 /backups/orders-*.dump 2>/dev/null | sort | tail -n 1)"
if [ -z "$LATEST" ]; then
  echo "no backup found in /backups" >&2
  exit 1
fi
echo "restoring $LATEST into scratch database restore_drill"
START="$(date +%s)"
dropdb --username="$POSTGRES_USER" --if-exists restore_drill
createdb --username="$POSTGRES_USER" restore_drill
pg_restore --username="$POSTGRES_USER" --dbname=restore_drill --no-owner "$LATEST"
END="$(date +%s)"
SOURCE_ROWS="$(psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --tuples-only --no-align --command='SELECT count(*) FROM orders')"
RESTORED_ROWS="$(psql --username="$POSTGRES_USER" --dbname=restore_drill --tuples-only --no-align --command='SELECT count(*) FROM orders')"
echo "source rows: $SOURCE_ROWS, restored rows: $RESTORED_ROWS"
echo "restore took $((END - START)) seconds"
if [ "$SOURCE_ROWS" != "$RESTORED_ROWS" ]; then
  echo "DRILL FAILED: row counts differ" >&2
  exit 1
fi
dropdb --username="$POSTGRES_USER" restore_drill
echo "drill passed"
```
- `LATEST` picks the newest dump by name (the timestamp sorts correctly). If none exists, the script says so on standard error and stops. (Without that guard, an empty variable would produce a confusing error later; `set -e` does not catch a failure inside a pipeline's earlier commands.)
- The drill restores into a **scratch database** (`restore_drill`) and never touches the live one: `dropdb --if-exists` removes a leftover from a previous drill, `createdb` makes an empty one, `pg_restore` loads the archive into it. `--no-owner` skips setting the original owner of each object, which avoids errors when the restoring role differs.
- `psql --tuples-only --no-align --command='SELECT count(*) ...'` prints just the number, so the script can store it in a variable. The script compares the row count of the live table with the restored one and fails the drill if they differ.
- **What this check cannot prove:** equal row counts do not mean equal data. A real drill adds a stronger check (checksums of important aggregates, an application smoke test against the restored copy) and runs on production-sized data.
- On success the script removes the scratch database and prints `drill passed`.

**File: `scripts/recover-latest.sh`**
```sh
#!/bin/sh
set -eu
LATEST="$(ls -1 /backups/orders-*.dump 2>/dev/null | sort | tail -n 1)"
if [ -z "$LATEST" ]; then
  echo "no backup found in /backups" >&2
  exit 1
fi
echo "recovering from $LATEST"
pg_restore --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --clean --if-exists --no-owner "$LATEST"
psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --tuples-only --no-align --command='SELECT count(*) FROM orders'
```
- This restores **over the live database**, which is the dangerous operation: it is used during a real recovery, after the drill has proved the file restores. `--clean --if-exists` drops each object (if it exists) before recreating it from the archive, so the command works whether the table is intact or was dropped. It then prints the row count.
- It replaces whatever is in the tables with the backup's content: **everything written after the backup is lost**. That is the RPO, and you will see it in Step 9.

### Step 5. Start the stack
**Terminal (any OS; folder: `code`)**
```bash
docker compose up -d --wait
```
`--wait` returns only when the service's health check passes. Expected output (not yet run; image pull lines vary):
```text
 Container code101-readiness-db-1  Healthy
```
Check the seed rows:

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db psql -U app -d orders -c "SELECT count(*) FROM orders"
```
Expected output (derived from the SQL; not yet run):
```text
 count 
-------
     5
(1 row)

```
If the container is unhealthy or the table is missing, run `docker compose logs db`; the seed script runs only the first time the data volume is empty.

### Step 6. Take a backup
**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db sh /scripts/backup.sh
```
Expected output (the timestamp and the duration vary; not yet run):
```text
backup written: /backups/orders-<UTC timestamp>.dump
backup took <number> seconds
```
For five rows the duration is tiny and tells you nothing about production. **Write down the real number from your real data**, each time, as a metric.

### Step 7. Get a copy off the host
A dump in a volume on the same machine dies with the machine. Copy it out; in real life the destination is object storage in another account or site, encrypted, with retention rules:

**Terminal (any OS; folder: `code`)**
```bash
docker compose cp db:/backups ./off-host-backups
```
Expected result (not yet run): a folder `off-host-backups` in `code` containing the dump file (Compose may nest it inside a `backups` folder; list it to see). This is only a demonstration of the step. **Never commit backup files**: they contain your data. Add `off-host-backups/` to your `.gitignore` if you keep the folder.

### Step 8. The restore drill
**Predict first:** what two numbers will the drill print, and what must be true for it to say `drill passed`? Then:

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db sh /scripts/restore-drill.sh
```
Expected output (the dump name and duration vary; the dropdb line may print a notice that the scratch database does not exist; not yet run):
```text
restoring /backups/orders-<UTC timestamp>.dump into scratch database restore_drill
source rows: 5, restored rows: 5
restore took <number> seconds
drill passed
```
The run proves the file can be restored and that the data has the expected shape. It does **not** prove the application works against it, nor that the restore would finish within your RTO on real data.

### Step 9. A disaster: operator error, then recovery
First add a row **after** the backup, simulating normal life between backups:

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db psql -U app -d orders -c "INSERT INTO orders VALUES (6, 'Zoe', 777)"
```
Expected output (not yet run): `INSERT 0 1`. Now the mistake: an operator drops the table, thinking they are on a test system.

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db psql -U app -d orders -c "DROP TABLE orders"
```
Expected output (not yet run): `DROP TABLE`. Nothing warned you; a replica would have dropped it too. Recover:

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db sh /scripts/recover-latest.sh
```
**Predict first:** what count will the script print, 5 or 6? Expected output (not yet run):
```text
recovering from /backups/orders-<UTC timestamp>.dump
5
```
The answer is 5. The recovered table is the state at backup time: **Zoe's order (id 6) is gone**. The time between the backup and the failure is the **data-loss window**, and it is exactly what your RPO describes. To lose less you need more frequent backups, or point-in-time recovery from archived WAL, or an application that can replay lost writes from another source. Check it yourself:

**Terminal (any OS; folder: `code`)**
```bash
docker compose exec db psql -U app -d orders -c "SELECT id, customer FROM orders ORDER BY id"
```
Expected output (derived; not yet run): ids 1 to 5 only (Ada, Grace, Linus, Margaret, Dennis).

### Step 10. Runbooks
Two files. The first is a template every runbook follows, so on-call people always find things in the same place.

**File: `runbooks/RUNBOOK-TEMPLATE.md`**
```markdown
# Runbook: <alert or symptom name>

Owner: <team and on-call rotation>
Last tested: <date of the last drill or real use>
Severity guide: S1 customers cannot use the service; S2 degraded; S3 no user impact yet.

## Symptoms
- Alert names and dashboards that point here.
- What a user sees.

## Impact and urgency
- Who is affected and how badly.
- What gets worse if nobody acts in 15 minutes.

## First checks (2 minutes)
1. Is it real? Open the dashboard and compare with the alert.
2. What changed recently? Releases, config, certificates, traffic.
3. Is a dependency down? Check its status first.

## Mitigate (stop the harm before finding the cause)
1. The safest action first (for example roll back the last release).
2. The next action, with the exact command.
3. Stop and escalate if none of these works within 30 minutes.

## Verify recovery
- The metric or check that proves it is fixed.
- How long to watch before closing the incident.

## Escalate
- Who to call and when, with the contact method.

## Afterwards
- Open a blameless review within five working days.
- Update this runbook with what was missing.
```
- `Owner` and `Last tested` make decay visible: a runbook nobody has run for a year is probably wrong.
- Sections follow the incident order. **Mitigate** comes before cause analysis, with exact commands, so nobody has to think while stressed. The 30-minute limit is a decision made calmly in advance.

**File: `runbooks/db-unavailable.md`**
```markdown
# Runbook: orders database unavailable

Owner: platform on-call
Last tested: record the date of your drill here
Severity guide: S1 customers cannot place orders; S2 reads work, writes fail; S3 slow queries.

## Symptoms
- The orders service reports connection errors or health checks fail.
- `docker compose ps` shows the `db` service as unhealthy, restarting or exited.

## Impact and urgency
- No orders can be created or read while the database is down.
- Every minute adds to lost orders: escalate at once if not back within 15 minutes.

## First checks (2 minutes)
1. `docker compose ps` shows the state and the health of `db`.
2. `docker compose logs --tail 100 db` shows the last errors.
3. `docker system df` shows whether the disk is full (a full disk is a common cause).

## Mitigate
1. If the container exited or is unhealthy and the disk is not full: `docker compose restart db`, then check `docker compose ps` again.
2. If the disk is full: free space (old logs, unused images) without touching the `pgdata` volume, then restart as above.
3. If the data is damaged or lost: restore from the latest backup (see Recover below) and tell the owner how much data was lost.
4. If none of these works within 30 minutes: escalate.

## Recover from a backup
1. Prove the backup restores: `docker compose exec db sh /scripts/restore-drill.sh` must end with `drill passed`.
2. Restore over the live database: `docker compose exec db sh /scripts/recover-latest.sh`.
3. Count the rows in the key tables and compare with the last known value.

## Verify recovery
- `docker compose ps` shows `db` as healthy.
- The orders service health check passes and an order can be created and read back.
- Watch the error rate for 30 minutes.

## Escalate
- The database owner, then the engineering manager. Record who was called and when.

## Afterwards
- Write a blameless review within five working days.
- Record the data-loss window: the time between the last good backup and the failure.
```
- Notice the order of the mitigation steps: least destructive first (restart), restore last. **Destructive actions need a drill behind them**: "Recover from a backup" first proves the backup restores, then restores.
- The data-loss window is recorded on purpose: it feeds the next RPO discussion with real numbers.

### Step 11. Keep a service available through maintenance: the disruption budget
When a node is drained for an upgrade, Kubernetes **evicts** the pods on it. A **PodDisruptionBudget** limits how many pods of a service may be evicted voluntarily at once.

**File: `k8s/pdb.yaml`**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api
  namespace: code101
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: api
```
- `policy/v1` and `kind: PodDisruptionBudget` are the object's type. It applies in the `code101` namespace of lesson 05.
- `minAvailable: 1`: at least one matching pod must stay available during voluntary disruptions (node drains, upgrades). With two replicas, a drain can evict one, wait for its replacement to become Ready on another node, then evict the other.
- `selector.matchLabels` picks the pods, the same labels as the lesson 05 Deployment.
- **The trap:** with a **single** replica and `minAvailable: 1`, a drain can never evict the pod, so the upgrade blocks until someone overrides it. Use at least two replicas, or `maxUnavailable: 1` if brief downtime is acceptable. A budget does not protect against involuntary failures such as a node crash.

Apply it only if your lesson 05 cluster is running: `kubectl --context kind-code101 apply -f k8s/pdb.yaml`. Expected output (not yet run): `poddisruptionbudget.policy/api created`.

### Step 12. The readiness review template
**File: `READINESS-REVIEW.md`**
```markdown
# Production readiness review

Service: <name>
Reviewed by: <names>
Date: <date>

Score every row: 0 = missing, 1 = partly, 2 = done and evidenced.
Rows marked MUST cannot be 0 for a launch. Write the evidence (a link, a command and its result), not a promise.

| Area | Check | MUST | Score | Evidence |
|------|-------|------|-------|----------|
| Security | Runs as non-root, read-only root, no extra capabilities | yes | | |
| Security | Images pinned by digest and signed; base image policy passes | yes | | |
| Security | No secrets in images, environment files in Git or logs | yes | | |
| Security | Only needed ports published; databases never published | yes | | |
| Reliability | Health checks or probes reflect real readiness | yes | | |
| Reliability | At least two replicas and a disruption budget, or a written reason | no | | |
| Reliability | Rollback tested with the real release process | yes | | |
| Reliability | Restart policy and shutdown handling (SIGTERM) verified | yes | | |
| Observability | RED metrics, structured logs and traces exist | yes | | |
| Observability | Page alerts exist for symptoms and each has a runbook | yes | | |
| Data | Backup runs on a schedule and is stored off the host | yes | | |
| Data | Restore drill passed in the last quarter; RPO and RTO measured | yes | | |
| Capacity | Requests and limits come from measurements; autoscaling bounded | no | | |
| Capacity | Log and metric retention fit the disk; rotation configured | yes | | |
| Operations | On-call owner and escalation path named | yes | | |
| Operations | Upgrade plan for the runtime, base images and database | no | | |

Result: launch only if no MUST row is 0 and the total is at least 70 percent of the maximum.
Open risks accepted by the owner, with an expiry date:
-
```
How to use it: the two columns that matter are **MUST** and **Evidence**. A MUST row with a 0 blocks the launch. The 70 percent threshold is an example; **set your own and write down why**. Accepting a risk is allowed, but an owner must name it and give it an expiry date, otherwise "temporary" becomes permanent. Each row maps to a lesson of this level: security rows to lessons 01 to 03, delivery to 04 to 06, observability to 07, capacity to 08, data and operations to this lesson.

### Step 13. Clean up
**Terminal (any OS; folder: `code`)**
```bash
docker compose down -v
```
`-v` deletes both volumes: the database **and the backups** in this lab. In real life that flag on a production stack is the incident. Remove the `off-host-backups` folder yourself if you made it.

## How it works
The drill is the control; the backup is only its input. The sequence you ran is the same one a real recovery uses: **prove the backup is restorable** (scratch database, row counts, duration), **restore** with a script nobody has to type from memory, **verify**, then **measure the loss**. What it measured, per run, is what lets you make promises: how long a restore takes (RTO input) and how much data one backup interval can lose (RPO).

Misconceptions to correct. First, "the data is on a volume, so it is safe": a volume survives container removal and nothing else. Second, "the backup job succeeded, so we have a backup": it only proves the dump finished. Third, "high availability replaces backups": replication copies mistakes instantly. Fourth, "we will write the runbook after the first incident": the first incident is the most expensive time to learn.

## Decision record (ADR-09): launch gate and drill cadence
- **Context:** services go live when "the code works"; the last restore anyone remembers was eighteen months ago; two incidents were extended by missing runbooks.
- **Decision:** a service launches only with a completed readiness review (no MUST row at 0), a runbook per page alert, and a passed restore drill within 90 days of launch. Restore drills repeat every quarter with timings recorded, and after every major version change of the database or backup tooling. Risk acceptances carry an owner and an expiry date.
- **Consequences:** launch dates slip when drills fail (that is the point); someone owns the review template and the drill calendar; drill timings become a dashboard.
- **Alternatives rejected:** a review only for "critical" services (criticality is judged late and wrongly); relying on cloud snapshots without a restore test (snapshots are a mechanism, not evidence).
- **Revisit when:** the data volume grows enough that a quarterly full restore is itself a risk or a cost; then drill on a sample and verify the rest by checksums.

## When not to use this
- A throwaway demo or a developer's local database does not need drills or runbooks. The first time a database holds something irreplaceable, it does.
- Do not use logical dumps as your only backup for a large, busy database: dump time, load and the data-loss window grow. Move to physical backups with WAL archiving, or a managed service, and keep a drill for that mechanism too.
- Do not run production databases in containers by default if you cannot meet the same bar you would for a virtual machine. A managed database service is often the lower-risk choice; this lesson's drill applies to it as well (restore from a snapshot into a new instance and check).
- Do not turn the readiness review into a ritual of ticking boxes. Rows without evidence score 0.

## Failure modes
- **Untested restore:** the backup is corrupt, incomplete or in a format the new version cannot read. The drill is the control.
- **Backups on the same failure domain:** same disk, host, account or credentials as the data. A ransomware or account-compromise event takes both. Keep one copy that production credentials cannot delete.
- **Unencrypted backups:** the dump is a complete copy of your data. Encrypt in transit and at rest, and restrict who can read them.
- **Backup job silently failing:** alert on "no successful backup in N hours", not on the job's exit code alone.
- **Restore too slow for the RTO:** found out during the real incident. Measure on production-sized data.
- **Runbook rot:** commands that no longer work, wrong names. Test them in drills; record the date.
- **Destructive command in the wrong place:** `down -v` or `DROP` against production. Separate production credentials and contexts, and make the production shell prompt unmistakable.
- **Upgrade without rollback:** a major database upgrade whose only rollback is a restore that has not been rehearsed with the new version.
- **Blocked drains:** a strict disruption budget with a single replica stalls a node upgrade.
- **Review theatre:** a green checklist nobody verified.

## Measurements to take
- Backup duration, size and success per run; time since the last successful backup.
- Restore drill duration on production-sized data, and the date of the last passing drill.
- The data-loss window achieved in each drill or incident, compared with the RPO.
- Time to detect, time to mitigate and time to resolve for every incident, and how many used a runbook.
- Runbook coverage: share of page alerts with a runbook, and the share tested in the last six months.
- Upgrade rehearsal results: time, failures and the rollback time.

## Production checklist
- [ ] Backup schedule matches the RPO; at least one copy is off the host and out of reach of production credentials; backups are encrypted.
- [ ] A restore drill passed in the last quarter with timings recorded; the restore was verified by more than a row count.
- [ ] Alerts exist for failed or missing backups.
- [ ] Every page alert has a runbook with an owner and a last-tested date.
- [ ] An incident process exists: roles, severity levels, communication channel and a blameless review habit.
- [ ] Upgrade plans exist per layer, with a rehearsal and a rollback for each.
- [ ] Services have at least two replicas and a disruption budget, or a written reason why not.
- [ ] The readiness review was completed with evidence, and accepted risks have owners and expiry dates.

## Try it
Work in a folder `exercise`. This is the review exercise for the whole level. You will review a deliberately bad Compose file as if it were proposed for production.

**File: `exercise/legacy-compose.yml` (starter)**
```yaml
services:
  web:
    image: myorg/web:latest
    ports:
      - "80:8000"
    environment:
      - DATABASE_URL=postgres://app:secret@db/app
      - SESSION_SECRET=changeme
    depends_on:
      - db
  db:
    image: postgres
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - ./pgdata:/var/lib/postgresql/data
```
**File: `exercise/review.md` (starter)**
```markdown
# Review of legacy-compose.yml

## Findings the audit reports
TODO: run the lesson 01 audit on the file and copy each finding on one line.

## Findings only a human finds
TODO: at least six more, each with the risk and the fix. Think about startup order, healthchecks,
credentials outside the lint's patterns, where the data lives, backups, restarts, limits and logs.

## Decision
TODO: launch, launch with conditions, or do not launch, and the reason in two sentences.
```
1. **Guided:** copy `audit_compose.py` from lesson 01 next to the file and run it. **Predict first:** how many findings (the lint has nine forbidden and four required rules)? Copy them into `review.md`. Expected output (derived by reading the lesson 01 script; not yet run): findings on lines 3, 5, 8, 12, 14 and 16, plus the four missing-setting findings R1 to R4, and the last line `10 finding(s)`.
2. **Change:** complete the second section of `review.md`: at least six problems the lint **cannot** see, each with the risk and the fix, using the readiness table as a prompt. Then write `fixed-compose.yml` that addresses them and passes the audit, and state what the audit still cannot tell you about the fixed file.
3. **Stretch (no single answer):** you own this service and the launch is next week. Fill the scored readiness table for it as the owner would, mark the rows you cannot evidence, and write the decision: which risks do you accept, for how long, and what do you do first?

<details><summary>Solution</summary>

Expected audit output for the starter (not yet run):
```text
legacy-compose.yml:3: [C5] image has no tag or uses latest (mutable)
legacy-compose.yml:5: [C6] port published on every interface
legacy-compose.yml:8: [C7] secret value written in the file
legacy-compose.yml:12: [C5] image has no tag or uses latest (mutable)
legacy-compose.yml:14: [C6] port published on every interface
legacy-compose.yml:16: [C7] secret value written in the file
legacy-compose.yml: [R1] no user: key, so the process may run as root
legacy-compose.yml: [R2] no read_only: true, so the root filesystem is writable
legacy-compose.yml: [R3] no cap_drop, so default capabilities are kept
legacy-compose.yml: [R4] no no-new-privileges option
10 finding(s)
```
Notice line 7 is **not** reported: `DATABASE_URL=postgres://app:secret@db/app` contains a password but its variable name does not end in PASSWORD, SECRET or TOKEN, so the lint misses it. That is the lesson of the exercise.

**File: `exercise/solution/review.md`**
```markdown
# Review of legacy-compose.yml

## Findings the audit reports (10)
- Line 3 and line 12: `latest` or no tag, so the image can change under you.
- Line 5 and line 14: ports published on every interface, including the database.
- Line 8 and line 16: secret values written in the file.
- Missing: user, read_only, cap_drop and no-new-privileges.

## Findings only a human finds
- The database URL on line 7 contains a password and the lint cannot see it: move it to a secret file.
- `depends_on` without a health condition: the web service can start before the database accepts connections.
- No healthcheck on either service: nothing knows when they are ready or broken.
- Data in a host folder `./pgdata`: ownership and backup depend on the host, and a wrong `docker compose down -v` habit is not the only way to lose it. Use a named volume and a scheduled backup stored elsewhere.
- No backup or restore drill is described: data loss cannot be recovered.
- No restart policy, memory limit or log rotation: one crash stays down; a leak or a log flood takes the host.
- The web service listens on port 80 on the host: use a reverse proxy with TLS in front, and publish to loopback.

## Decision
Do not launch. Several MUST items fail (secrets, published database port, no health checks, no backup). Launch after the fixed file passes the audit, a restore drill passes and the owner accepts any remaining risks with an expiry date.
```
**File: `exercise/solution/fixed-compose.yml`**
```yaml
name: orders-prod
services:
  web:
    image: myorg/web:1.4.2
    ports:
      - "127.0.0.1:8000:8000"
    environment:
      DATABASE_HOST: db
      DATABASE_PASSWORD_FILE: /run/secrets/db_password
      SESSION_SECRET_FILE: /run/secrets/session_secret
    secrets:
      - db_password
      - session_secret
    depends_on:
      db:
        condition: service_healthy
    user: "10001:10001"
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    mem_limit: 256m
    pids_limit: 128
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
  db:
    image: postgres:17-alpine
    user: "70:70"
    read_only: true
    tmpfs:
      - /tmp
      - /run/postgresql
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    environment:
      POSTGRES_USER: app
      POSTGRES_DB: orders
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d orders"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s
    mem_limit: 512m
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
volumes:
  pgdata:
secrets:
  db_password:
    file: ./secrets/db_password.txt
  session_secret:
    file: ./secrets/session_secret.txt
```
Expected audit result for the fixed file (derived; not yet run): `fixed-compose.yml: no findings`. What the audit still cannot tell you: that `myorg/web:1.4.2` is signed, scanned and pinned by digest; that the web service has a health check or probes; that the application actually reads the `_FILE` variables (the application code must support them: the official Postgres image does, your own code may not); that the database starts as user 70 on a read-only root (not run here); that a backup exists and restores; or that anyone is on call. A pass is permission to continue the review, not a verdict. A defensible stretch answer accepts a missing disruption budget for a month if a written date and owner exist, and does **not** accept a missing restore drill.

</details>

## Check yourself
1. Your backup job runs every night and exits 0. Why can you still lose the database? <details><summary>Answer</summary>Exit 0 does not prove the file restores, the copy may sit on the same host or account, and nothing alerts when it stops. Drill the restore and keep an off-host copy.</details>
2. Predict: backup at 02:00, a row inserted at 09:00, a `DROP TABLE` at 10:00, recovery from the 02:00 backup. How much is lost? <details><summary>Answer</summary>Everything written between 02:00 and 10:00 (the 09:00 row included): eight hours, the data-loss window. The RPO must be at most that for the backup to be acceptable.</details>
3. Why does the restore drill use a scratch database? <details><summary>Answer</summary>It proves the backup is restorable without touching the live data, so the drill is safe to run in production.</details>
4. A `PodDisruptionBudget` with `minAvailable: 1` protects a single-replica service from a node drain. Right or wrong? <details><summary>Answer</summary>Wrong: with one replica the drain can never evict the pod, so the maintenance blocks. Use at least two replicas.</details>
5. Why is `postgres:17-alpine` to `postgres:18-alpine` on the same volume not an upgrade? <details><summary>Answer</summary>The data directory format is incompatible between major versions: the new server refuses to start. You dump and restore (or `pg_upgrade`) after a rehearsal.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Set POSTGRES_PASSWORD in .env` | No `.env` file | Copy `.env.example` to `.env` |
| The scripts fail with odd errors mentioning `\r` or options on the first lines (typical symptom) | Windows line endings (CRLF) in the `.sh` files | Save as LF; the `.gitattributes` line keeps them LF in Git |
| `no backup found in /backups` | The drill or recovery ran before any backup, or the backups volume was removed | Run `scripts/backup.sh` first |
| `relation "orders" does not exist` right after start | The seed script did not run because the data volume already existed | `docker compose down -v` (lab only) and start again |
| `docker compose cp` complains the path is missing (typical) | The service is not running | `docker compose up -d` first |
| `service "db" is unhealthy` from `up --wait` (typical wording) | The database failed to start or the check fails | `docker compose logs db` |
| `pg_restore: error: ... already exists` (typical wording) | Restoring into a database that still has the objects, without `--clean` | Use the recovery script, or restore into a fresh scratch database |
| `$'\r': command not found` (typical message) | CRLF line endings | Convert the file to LF |

## Best practice
Treat a backup as proven only after a restore drill, measure RPO and RTO from real runs, write runbooks with exact commands, and gate launches on a review with evidence. Source: Kubernetes documentation, Specifying a Disruption Budget for your Application https://kubernetes.io/docs/tasks/run-application/configure-pdb/ and PostgreSQL documentation, Backup and Restore (project documentation, not a Tier 1 source) https://www.postgresql.org/docs/current/backup.html

## Going further
- OWASP Docker Security Cheat Sheet (revisit the checklist items with your review in hand): https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- Kubernetes version skew policy and cluster upgrades: https://kubernetes.io/releases/version-skew-policy/ and https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- Safely draining a node: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
- Docker live restore (keep containers running while the daemon restarts): https://docs.docker.com/engine/containers/live-restore/
- Apply the review table to a capstone's Compose file: the reviewed and audited patterns of this level are the target.

## Summary
- You ran a backup and a restore drill, and read their counts and durations as evidence.
- You recovered from an operator error and measured the data-loss window.
- You read a runbook template and a concrete runbook, and a disruption budget with its single-replica trap.
- You planned upgrades per layer and ran a readiness review that ends in a decision.

## Next lesson
This is the last lesson of Docker 301. Next steps: apply the readiness review to the platform capstone's Compose stack, and use the lesson 01 threat model as the first page of every new service's design document.
