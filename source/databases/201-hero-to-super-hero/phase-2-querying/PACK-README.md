# Databases 201: phase-2-querying

Status: **written (not run)**. SQL, Docker, exercises, plans and restores have not been executed. Expected tables are hand-derived. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `04-ctes-and-recursive-queries/`: [CTEs and recursive queries](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-2-querying/04-ctes-and-recursive-queries.md).
- `05-window-functions/`: [Window functions](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-2-querying/05-window-functions.md).
- `06-jsonb/`: [JSONB without abandoning a schema](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-2-querying/06-jsonb.md).
- `07-indexes-and-explain/`: [Indexes in depth and reading EXPLAIN](https://github.com/Uee03/Code101/blob/main/tutorials/databases/201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md).

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

From `04-ctes-and-recursive-queries/code` (all OS):

```powershell
docker compose -p code101-db201-04 up -d --wait
docker compose -p code101-db201-04 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-04 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

From `05-window-functions/code` (all OS):

```powershell
docker compose -p code101-db201-05 up -d --wait
docker compose -p code101-db201-05 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-05 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

From `06-jsonb/code` (all OS):

```powershell
docker compose -p code101-db201-06 up -d --wait
docker compose -p code101-db201-06 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-06 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-06 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

From `07-indexes-and-explain/code` (all OS):

```powershell
docker compose -p code101-db201-07 up -d --wait
docker compose -p code101-db201-07 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db201-07 logs --no-log-prefix --tail 10 db
docker compose -p code101-db201-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Expected output, not yet run: healthy db status, variable startup/log progress and the hand-derived query tables in the matching lesson. Each reset destroys its private sample schema; never point the files at real data. Copy the single starter exercise.sql into the selected code folder, fill TODOs, and run `/scripts/exercise.sql` with the same psql command. Compare with the adjacent solution only after trying.

## Stop and clean up
Close IDE connections. The following exact pairs run in each lesson's own code folder, after its exercise. stop retains data; down -v removes that named disposable project's container/network and **all saved database data**, not unrelated projects. Do not use -v on valuable data.

From `04-ctes-and-recursive-queries/code` (all OS):

```powershell
docker compose -p code101-db201-04 stop
docker compose -p code101-db201-04 down -v --remove-orphans
```

From `05-window-functions/code` (all OS):

```powershell
docker compose -p code101-db201-05 stop
docker compose -p code101-db201-05 down -v --remove-orphans
```

From `06-jsonb/code` (all OS):

```powershell
docker compose -p code101-db201-06 stop
docker compose -p code101-db201-06 down -v --remove-orphans
```

From `07-indexes-and-explain/code` (all OS):

```powershell
docker compose -p code101-db201-07 stop
docker compose -p code101-db201-07 down -v --remove-orphans
```

Expected output, not yet run: variable stop/removal progress; no services should remain in this project. No Dockerfile/.dockerignore: nothing is built. Credentials are disposable local examples; do not commit .env or dump files. Reusing an initialized volume does not apply changed .env credentials. IDE fields: 127.0.0.1, 5432, code101, learner, learn_local_only, password authentication, SSL disabled only for loopback, SSH tunnel off. The lessons include the full 101 IDE pattern.

Lesson 07 keeps plans.sql separate from the deterministic report. No EXPLAIN plans/costs are presented as captured evidence. Inspect your own plan. Four seed rows cannot establish performance.
