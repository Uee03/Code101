# Databases 301: phase-2-concurrency-and-integrity

Status: **written (not run)**. SQL, Docker, exercises and two-terminal scenarios have not been executed. Expected values are hand-derived. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `04-transactions-isolation-and-locking/`: [Transactions, isolation levels and locking](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/04-transactions-isolation-and-locking.md). Needs **two terminals** for the lock, lost-update and deadlock scenarios.
- `05-connection-pooling/`: [Connection pooling](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-2-concurrency-and-integrity/05-connection-pooling.md). `code/pgbouncer.ini` is an explained example that nothing starts.

Each lesson contains `code/`, `exercise/starter/`, `exercise/solution/`, and a `verify.json` reserved for a future authorized runtime check. The source matches the full listings in the matching tutorial. No icons, custom image, host PostgreSQL or host psql are required.

## Prerequisites and extraction
Finish Databases 201 and phase 1 of this level. Use Docker in Linux-container mode with Compose, a text editor and `postgres:17-alpine`. Every lab publishes only `127.0.0.1:5432:5432`, so run only one lab at a time.

Download from https://github.com/Uee03/Code101 (**Code > Download ZIP**) or use the generated phase pack. On Windows right-click the ZIP > Extract All; macOS double-click; Linux use Extract Here. Keep each lesson's `code` and `exercise` folders as siblings.

## Run one lesson later, when ready
In the extracted phase folder choose one lesson, open its `code` subfolder in your terminal and copy `.env.example` to `.env`. With the project name of that lesson (`code101-db301-04` or `code101-db301-05`):

```powershell
docker compose -p code101-db301-04 up -d --wait
docker compose -p code101-db301-04 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Lesson 04 resets its data with `/scripts/setup.sql` before each two-terminal scenario; its timing (`pg_sleep`) is what makes the interleaving repeatable, so start the second terminal within the stated seconds.

Clean up (this deletes only that disposable project's data):

```powershell
docker compose -p code101-db301-04 stop
docker compose -p code101-db301-04 down -v --remove-orphans
```

Credentials are disposable local examples; do not commit `.env` or dump files.
