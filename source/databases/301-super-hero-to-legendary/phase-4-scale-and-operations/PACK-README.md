# Databases 301: phase-4-scale-and-operations

Status: **written (not run)**. SQL, Docker, exercises and plans have not been executed. Expected values are hand-derived. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `08-replication-and-high-availability/`: [Replication and high availability](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/08-replication-and-high-availability.md). The four `*.conf.example` files are explained and **never applied**; the lab inspects one server only.
- `09-pgvector-and-search/`: [pgvector and search](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/09-pgvector-and-search.md). **Uses a different image**, `pgvector/pgvector:0.8.7-pg17-trixie`, because the Alpine image has no pgvector; verify the tag on Docker Hub before relying on it.
- `10-other-engines-and-readiness/`: [Other engines and a production readiness review](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-4-scale-and-operations/10-other-engines-and-readiness.md). `code/reference/sqlserver.sql` and `code/reference/sqlite.sql` are reference scripts for other engines and are never run by the lab.

Each lesson contains `code/`, `exercise/starter/`, `exercise/solution/`, and a `verify.json` reserved for a future authorized runtime check. The source matches the full listings in the matching tutorial. No icons, host PostgreSQL or host psql are required.

## Prerequisites and extraction
Finish Databases 201 and the earlier phases of this level. Use Docker in Linux-container mode with Compose and a text editor. Every lab publishes only `127.0.0.1:5432:5432`, so run only one lab at a time.

Download from https://github.com/Uee03/Code101 (**Code > Download ZIP**) or use the generated phase pack. On Windows right-click the ZIP > Extract All; macOS double-click; Linux use Extract Here. Keep each lesson's `code` and `exercise` folders as siblings.

## Run one lesson later, when ready
In the extracted phase folder choose one lesson, open its `code` subfolder in your terminal and copy `.env.example` to `.env`. With the project name of that lesson (`code101-db301-08`, `code101-db301-09` or `code101-db301-10`):

```powershell
docker compose -p code101-db301-08 up -d --wait
docker compose -p code101-db301-08 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Clean up (this deletes only that disposable project's data):

```powershell
docker compose -p code101-db301-08 stop
docker compose -p code101-db301-08 down -v --remove-orphans
```

Credentials are disposable local examples; do not commit `.env` or dump files.
