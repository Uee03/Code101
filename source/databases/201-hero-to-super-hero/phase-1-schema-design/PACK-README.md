# Databases 201: phase-1-schema-design

Status: **written (not run)**. SQL, Docker, exercises, plans and restores have not been executed. Expected tables are hand-derived. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `01-data-modeling-and-3nf/`: [Data modeling and normalization to 3NF](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-1-schema-design/01-data-modeling-and-3nf.md).
- `02-constraints-domains-and-types/`: [Constraints, domains, enums and types done right](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-1-schema-design/02-constraints-domains-and-types.md).
- `03-plain-sql-migrations/`: [Migrations with plain SQL and a small runner](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-1-schema-design/03-plain-sql-migrations.md).

Each lesson contains `code/`, `exercise/starter/`, `exercise/solution/`, and a `verify.json` reserved for a future authorized runtime check. The source matches the full listings in the matching tutorial. No icons, custom image, host PostgreSQL or host psql are required.

## Prerequisites and extraction
Finish Databases 101. Use Docker in Linux-container mode with Compose, a text editor and `postgres:17-alpine`. The 101 baseline is Docker 29.9.3 / Compose 5.7.0; this release has not rechecked them. Every lab publishes only `127.0.0.1:5432:5432`, so run only one at a time.

Download from https://github.com/Uee03/Code101 (**Code > Download ZIP**) or use the generated phase pack. On Windows right-click the ZIP > Extract All; macOS double-click; Linux use Extract Here in the archive manager. Keep each lesson/code and lesson/exercise as siblings. Open the corresponding lesson under tutorials/databases/201-hero-to-super-hero for the complete walkthrough. Each phase ends with mixed retrieval questions.

## Run one lesson later, when ready
The commands are learner instructions, not evidence of execution. In the extracted phase folder choose one lesson, then open its code subfolder in your terminal. Copy .env.example to .env:

```powershell
Copy-Item .env.example .env
```

macOS/Linux alternative, same code folder:

```bash
cp .env.example .env
```

Use the per-lesson project name and SQL entry script:

From `01-data-modeling-and-3nf/code` (all OS):

```powershell
docker compose -p code101-db201-01 up -d --wait
docker compose -p code101-db201-01 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-01 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

From `02-constraints-domains-and-types/code` (all OS):

```powershell
docker compose -p code101-db201-02 up -d --wait
docker compose -p code101-db201-02 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-02 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

From `03-plain-sql-migrations/code` (all OS):

```powershell
docker compose -p code101-db201-03 up -d --wait
docker compose -p code101-db201-03 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-03 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-03 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Expected output, not yet run: healthy db status, variable startup/log progress and the hand-derived query tables in the matching lesson. Each reset destroys its private sample schema; never point the files at real data. Copy the single starter exercise.sql into the selected code folder, fill TODOs, and run `/scripts/exercise.sql` with the same psql command. Compare with the adjacent solution only after trying.

## Stop and clean up
Close IDE connections. The following exact pairs run in each lesson's own code folder, after its exercise. stop retains data; down -v removes that named disposable project's container/network and **all saved database data**, not unrelated projects. Do not use -v on valuable data.

From `01-data-modeling-and-3nf/code` (all OS):

```powershell
docker compose -p code101-db201-01 stop
docker compose -p code101-db201-01 down -v --remove-orphans
```

From `02-constraints-domains-and-types/code` (all OS):

```powershell
docker compose -p code101-db201-02 stop
docker compose -p code101-db201-02 down -v --remove-orphans
```

From `03-plain-sql-migrations/code` (all OS):

```powershell
docker compose -p code101-db201-03 stop
docker compose -p code101-db201-03 down -v --remove-orphans
```

Expected output, not yet run: variable stop/removal progress; no services should remain in this project. No Dockerfile/.dockerignore: nothing is built. Credentials are disposable local examples; do not commit .env or dump files. Reusing an initialized volume does not apply changed .env credentials. IDE fields: 127.0.0.1, 5432, code101, learner, learn_local_only, password authentication, SSL disabled only for loopback, SSH tunnel off. The lessons include the full 101 IDE pattern.

Lesson 03: migrate.sh runs inside db with sh; save as LF. The explicit ledger driver makes batches repeatable, not arbitrary drift safe. The down script destroys priority data and is never part of normal setup.
