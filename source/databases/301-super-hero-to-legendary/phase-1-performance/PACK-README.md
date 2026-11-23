# Databases 301: phase-1-performance

Status: **written (not run)**. SQL, Docker, exercises and plans have not been executed. Expected tables are hand-derived from small seeds. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `01-query-tuning-method/`: [Query tuning as a method](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-1-performance/01-query-tuning-method.md). Its Compose file adds `command:` to load `pg_stat_statements`.
- `02-statistics-vacuum-and-bloat/`: [Statistics, vacuum, autovacuum and bloat](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-1-performance/02-statistics-vacuum-and-bloat.md).
- `03-partitioning/`: [Partitioning](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-1-performance/03-partitioning.md).

Each lesson contains `code/`, `exercise/starter/`, `exercise/solution/`, and a `verify.json` reserved for a future authorized runtime check. The source matches the full listings in the matching tutorial. No icons, custom image, host PostgreSQL or host psql are required. `plans.sql` in lesson 01 prints plans whose text is never asserted.

## Prerequisites and extraction
Finish Databases 201. Use Docker in Linux-container mode with Compose, a text editor and `postgres:17-alpine`. Every lab publishes only `127.0.0.1:5432:5432`, so run only one lab at a time.

Download from https://github.com/Uee03/Code101 (**Code > Download ZIP**) or use the generated phase pack. On Windows right-click the ZIP > Extract All; macOS double-click; Linux use Extract Here. Keep each lesson's `code` and `exercise` folders as siblings.

## Run one lesson later, when ready
The commands are learner instructions, not evidence of execution. In the extracted phase folder choose one lesson, open its `code` subfolder in your terminal and copy `.env.example` to `.env` (`Copy-Item .env.example .env` on Windows, `cp .env.example .env` on macOS or Linux). Then, with the project name of that lesson (`code101-db301-01`, `code101-db301-02` or `code101-db301-03`):

```powershell
docker compose -p code101-db301-01 up -d --wait
docker compose -p code101-db301-01 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Clean up (this deletes only that disposable project's data):

```powershell
docker compose -p code101-db301-01 stop
docker compose -p code101-db301-01 down -v --remove-orphans
```

Credentials are disposable local examples; do not commit `.env` or dump files.
