# Databases 301: phase-3-security-and-multitenancy

Status: **written (not run)**. SQL, Docker, exercises, role switching and plans have not been executed. Expected values are hand-derived. See each lesson's visible draft notice. Static checks do not prove runtime correctness.

## Contents
- `06-row-level-security-in-depth/`: [Row-level security in depth](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/06-row-level-security-in-depth.md). Creates the cluster-wide role `tenant_app` (`NOLOGIN`, used through `SET LOCAL ROLE`); `plans.sql` prints plans whose text is never asserted.
- `07-multi-tenant-designs/`: [Multi-tenant designs](https://github.com/Uee03/Code101/blob/main/tutorials/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/07-multi-tenant-designs.md). Creates and drops the schemas `tenant_acme`, `tenant_globex` and `tenant_initech` in the lab database.

Each lesson contains `code/`, `exercise/starter/`, `exercise/solution/`, and a `verify.json` reserved for a future authorized runtime check. The source matches the full listings in the matching tutorial. No icons, custom image, host PostgreSQL or host psql are required.

## Prerequisites and extraction
Finish Databases 201 (especially lesson 11) and the earlier phases of this level. Use Docker in Linux-container mode with Compose, a text editor and `postgres:17-alpine`. Every lab publishes only `127.0.0.1:5432:5432`, so run only one lab at a time.

Download from https://github.com/Uee03/Code101 (**Code > Download ZIP**) or use the generated phase pack. On Windows right-click the ZIP > Extract All; macOS double-click; Linux use Extract Here. Keep each lesson's `code` and `exercise` folders as siblings.

## Run one lesson later, when ready
In the extracted phase folder choose one lesson, open its `code` subfolder in your terminal and copy `.env.example` to `.env`. With the project name of that lesson (`code101-db301-06` or `code101-db301-07`):

```powershell
docker compose -p code101-db301-06 up -d --wait
docker compose -p code101-db301-06 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

Clean up (this deletes only that disposable project's data, including the roles and schemas created inside it):

```powershell
docker compose -p code101-db301-06 stop
docker compose -p code101-db301-06 down -v --remove-orphans
```

The `NOLOGIN` role with `SET LOCAL ROLE` simulates policy behaviour; it is not a test of password authentication or of a production deployment. Credentials are disposable local examples; do not commit `.env` or dump files.
