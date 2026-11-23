# Databases 101 - authoring brief

## Audience and promise
Complete beginners from any field: start with an organised filing cabinet, finish with a runnable library database. Twelve lessons in three four-lesson phases; 25 minutes for most lessons, 45 for initial setup and the project. PostgreSQL runs **only in Docker**; no host PostgreSQL or psql install. Prerequisite: Docker 101 lesson 01 (tutorials/docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md).

## Scope and sequence
| Phase | Lessons (one main idea each) |
|---|---|
| 1 - first-queries | 01 What a database is + Docker; 02 Connect with a tool; 03 Tables and data types; 04 Reading data |
| 2 - shaping-data | 05 Changing data; 06 Keys and relationships; 07 Joining tables; 08 Summaries |
| 3 - designing | 09 Good design; 10 Transactions; 11 Indexes and EXPLAIN; 12 Project: a library database |

## Teaching and delivery decisions
Analogy first; define new words before use. Every lesson is independent: its own Compose file, .env.example and SQL, full copied file contents and real psql tables. Explain all Compose/environment lines in 01; repeat the identical configuration with explicit lesson-folder differences later. Publish only 127.0.0.1:5432:5432; one lab at a time. Named data volume, healthcheck, read-only SQL mount. Copy .env.example to .env; use disposable, clearly labelled local-only credentials. No Dockerfile: official image runs unchanged. No .dockerignore: no image build. No art (assets: []). snake_case, named constraints, identity primary keys, dedicated schemas, exact numeric amounts. Introduce PRIMARY KEY in 06 rather than ahead of the concept in 03.

Lesson 02 includes psql and exact JetBrains/VS Code connection fields; Visual Studio gets an honest provider-support note and Npgsql connection string, not an invented Server Explorer integration. Lesson 12 includes parameterized-query safety, a NOLOGIN read-only group role, pg_dump and restore using container tools and copy commands (no PowerShell binary redirection).

## Verification and release
Check docker info, verify postgres:17-alpine on Docker Hub dated 2026-11-23, pull/run it, capture all displayed outputs/errors. Author code first, run it, then copy files/output into template lessons. Each verify.json requires docker, checks engine, copies .env.example, starts a temporary code101-verify project with --wait, runs main SQL once and exercise solution once, always downs with -v --remove-orphans. Run sequentially. Mark verified only after the repository verifier PASS. Inspect containers/volumes/networks after the final run. Build databases-101 phase/all zips with the repository script (its generated dist/packs outputs are the requested packaging exception to the track-only editing scope). Never change other tracks or shared files.

## Approved sources (Tier 1: official)
- PostgreSQL 17 tutorial and SQL reference: https://www.postgresql.org/docs/17/tutorial.html
- Types/constraints/transactions/indexes: https://www.postgresql.org/docs/17/ddl-constraints.html ; https://www.postgresql.org/docs/17/tutorial-transactions.html ; https://www.postgresql.org/docs/17/using-explain.html
- Roles/backups: https://www.postgresql.org/docs/17/user-manag.html ; https://www.postgresql.org/docs/17/app-pgdump.html ; https://www.postgresql.org/docs/17/app-pgrestore.html
- Official image/tag: https://hub.docker.com/_/postgres ; https://hub.docker.com/v2/repositories/library/postgres/tags/17-alpine
- Compose: https://docs.docker.com/reference/compose-file/services/
- IDEs: https://www.jetbrains.com/help/datagrip/postgresql.html ; https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/quickstart-connect-query ; https://www.npgsql.org/doc/basic-usage.html

Lesson-specific official reference pages: https://www.postgresql.org/docs/17/sql-insert.html ; https://www.postgresql.org/docs/17/queries-limit.html ; https://www.postgresql.org/docs/17/dml-returning.html ; https://www.postgresql.org/docs/17/queries-table-expressions.html ; https://www.postgresql.org/docs/17/tutorial-agg.html ; https://learn.microsoft.com/en-us/azure/postgresql/development/vs-code-extension/connections
