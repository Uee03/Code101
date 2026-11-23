---
track: databases
level: 301
phase: 3
phase_name: security-and-multitenancy
lesson: 07
title: "Multi-tenant designs: shared tables, schema per tenant, database per tenant"
time: 90 min
prerequisites: [301.3.06, 301.1.03]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/07-multi-tenant-designs/
assets: []
---

# 07. Multi-tenant designs: shared tables, schema per tenant, database per tenant

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Compare three multi-tenant designs against isolation, operations, cost and migration criteria, and write the decision as an ADR (architecture decision record).
- Enforce tenant integrity in the shared-table design with composite keys, and show the hole a single-column foreign key leaves.
- Provision tenants as schemas safely (validated identifiers, quoted names) and run a migration across all of them.
- Name the signals that tell you to move a tenant from one design to another.

## Recap
- Lesson 06: what makes a `tenant_id` context setting a claim and not authentication?
  <details><summary>Answer</summary>Any code that can run SQL under a role allowed to set it can choose the tenant; only trusted code that cannot be bypassed should set it.</details>
- Lesson 03: which partitioning method gives you "drop one tenant's data in one statement"?
  <details><summary>Answer</summary>List partitioning with one partition per tenant (at a cost in partition count).</details>

## Why it matters
"Multi-tenant" is a decision made once and lived with for years. It sets how you isolate customers, how long migrations take, how you restore one customer's data, what a noisy neighbour can do, and what each tenant costs. A wrong choice is expensive to reverse because every table, query and operational script assumes it.

## What you will build
A shared-table model with composite keys that make cross-tenant references impossible (and the single-column alternative that does not), a function that provisions a schema per tenant with validated names, and a fan-out migration over every tenant schema. Database per tenant is analysed in text and a decision table; it is not run, because it needs multiple databases and connections.

## Before you start
- **Prerequisites:** Databases 301 lessons [03, partitioning](../phase-1-performance/03-partitioning.md) and [06, row-level security in depth](06-row-level-security-in-depth.md).
- Finished lessons 05 and 06 and 201 lessons 01 to 03 (keys and migrations). No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lessons 02 to 06.
- Time: 90 minutes. Two sittings: break after Step 4.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/07-multi-tenant-designs/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-3-security-and-multitenancy.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; results are derived by hand.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 06, Step 1](06-row-level-security-in-depth.md#step-1-prepare-the-workspace) (genuinely identical) with the lesson folder `07-multi-tenant-designs`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-3-security-and-multitenancy\07-multi-tenant-designs\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-3-security-and-multitenancy/07-multi-tenant-designs/code"
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

### Step 4. The three designs, then the files
New terms. A **tenant** is one customer organisation whose data must stay separate from other customers'. **Pool model**: all tenants share tables, each row carries a `tenant_id`. **Bridge or schema model**: one schema per tenant inside one database. **Silo model**: one database (or cluster) per tenant. **Noisy neighbour**: one tenant's load degrading others. **Fan-out**: an operation that must be repeated for every tenant. **Composite key**: a key made of several columns, here `(tenant_id, id)`.

**Trade-offs table.**

| Criterion | Shared tables + `tenant_id` (+ RLS) | Schema per tenant | Database per tenant |
|---|---|---|---|
| Isolation strength | Logical; depends on filters/RLS and review | Stronger: separate namespaces and grants, same database | Strongest inside one cluster: separate catalogs and grants; separate clusters for hard isolation |
| Noisy neighbour | Shared cache, I/O and locks; mitigate with timeouts, quotas, moving big tenants out | Same server resources; autovacuum and plans per table | Same server unless clusters are separate; connection and memory per database |
| Onboarding a tenant | One `INSERT`; instant | DDL for the whole schema; seconds to minutes | `CREATE DATABASE ... TEMPLATE` plus provisioning; slowest |
| Schema migration | Once; one lock window for all tenants | Fan-out: N times; partial failures leave tenants on different versions | Fan-out across N databases; same risk, more connections |
| Per-tenant backup and restore | Hard: extract rows; PITR is cluster-wide | `pg_dump -n` per schema; PITR still cluster-wide | `pg_dump` per database easily; true per-tenant PITR needs a separate cluster |
| Offboarding / data deletion | Row deletes (bloat) or list-partition drop | `DROP SCHEMA` | `DROP DATABASE` |
| Catalog and file growth | Fixed table count | Tables grow with tenants x tables; catalog, `pg_dump`, autovacuum scheduling and per-backend caches scale with object count | Same per database, plus a connection pool per database |
| Connection pooling | One pool | One pool, `search_path` per transaction | A pool per database, or a pooler configured per database; more connections |
| Cross-tenant reporting and analytics | Easy (watch the leak risk) | Possible with union views or a warehouse | Needs foreign data wrappers or a warehouse |
| Tenant-specific customisation | Hard (JSONB, optional columns) | Possible, but fan-out grows | Easiest, and drift grows |
| Compliance and data residency | Weakest isolation story | Medium | Strongest; can pin a tenant to a region or cluster |
| Cost per tenant | Lowest | Low to medium | Highest |
| Typical fit | Many small tenants (thousands to millions) | Dozens to a few thousand tenants with moderate size and some customisation | Few, large, regulated tenants |

**Hybrid ("pool plus silo").** Most mature systems end up here: small tenants in shared tables, tenants above a size or compliance threshold moved to their own schema, database or cluster. Design the routing layer (a tenant directory mapping tenant to location) from the start even if every row begins in one place.

**ADR (architecture decision record) for the platform capstone, as an example of the format.**

| Field | Content |
|---|---|
| Context | Tasks and Teams serves teams; each team's data must stay separate; expected tenants: thousands of small teams; one reporting dashboard across teams for operators. |
| Decision | Shared tables with `team_id` on every tenant-owned table, composite keys so references cannot cross tenants, and row-level security as defence in depth (lesson 06). |
| Consequences | One migration path and cheap onboarding; isolation depends on discipline and tests; noisy-neighbour controls needed (timeouts, per-role limits); per-tenant restore requires an extraction procedure. |
| Revisit when | A tenant needs contractual isolation or data residency; a tenant exceeds an agreed share of load or storage; restore-by-tenant requests become frequent. |

**Seed.** Tenants `acme` (id 1) and `globex` (id 2). Tenant 1 has projects 1 and 2; tenant 2 has project 1. Tasks: tenant 1 has two, tenant 2 has one. A second pair of tables, `projects_naive` and `tasks_naive`, models the common shortcut of globally unique project ids and a single-column foreign key.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
DROP SCHEMA IF EXISTS tenant_acme CASCADE;
DROP SCHEMA IF EXISTS tenant_globex CASCADE;
DROP SCHEMA IF EXISTS tenant_initech CASCADE;
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
CREATE TABLE app.tenants (
    tenant_id integer NOT NULL,
    slug text NOT NULL,
    CONSTRAINT pk_tenants PRIMARY KEY (tenant_id),
    CONSTRAINT uq_tenants_slug UNIQUE (slug),
    CONSTRAINT ck_tenants_slug CHECK (slug ~ '^[a-z][a-z0-9_]{1,30}$')
);
INSERT INTO app.tenants (tenant_id, slug) VALUES (1, 'acme'), (2, 'globex');
CREATE TABLE app.projects (
    tenant_id integer NOT NULL,
    project_id integer NOT NULL,
    name text NOT NULL,
    CONSTRAINT pk_projects PRIMARY KEY (tenant_id, project_id),
    CONSTRAINT fk_projects_tenant FOREIGN KEY (tenant_id) REFERENCES app.tenants (tenant_id)
);
CREATE TABLE app.tasks (
    tenant_id integer NOT NULL,
    task_id integer NOT NULL,
    project_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_tasks PRIMARY KEY (tenant_id, task_id),
    CONSTRAINT fk_tasks_project FOREIGN KEY (tenant_id, project_id)
        REFERENCES app.projects (tenant_id, project_id)
);
INSERT INTO app.projects (tenant_id, project_id, name) VALUES
    (1, 1, 'Launch'), (1, 2, 'Support'), (2, 1, 'Ops');
INSERT INTO app.tasks (tenant_id, task_id, project_id, title) VALUES
    (1, 1, 1, 'Pack'), (1, 2, 2, 'Answer'), (2, 1, 1, 'Deploy');
CREATE TABLE app.projects_naive (
    project_id integer NOT NULL,
    tenant_id integer NOT NULL,
    name text NOT NULL,
    CONSTRAINT pk_projects_naive PRIMARY KEY (project_id)
);
CREATE TABLE app.tasks_naive (
    task_id integer NOT NULL,
    tenant_id integer NOT NULL,
    project_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_tasks_naive PRIMARY KEY (task_id),
    CONSTRAINT fk_tasks_naive_project FOREIGN KEY (project_id) REFERENCES app.projects_naive (project_id)
);
INSERT INTO app.projects_naive (project_id, tenant_id, name) VALUES (1, 1, 'Launch'), (2, 2, 'Ops');
INSERT INTO app.tasks_naive (task_id, tenant_id, project_id, title) VALUES (1, 1, 1, 'Pack');
CREATE FUNCTION app.provision_tenant(p_slug text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    v_schema text;
BEGIN
    IF p_slug !~ '^[a-z][a-z0-9_]{1,30}$' THEN
        RAISE EXCEPTION 'invalid tenant slug' USING ERRCODE = '22023';
    END IF;
    v_schema := 'tenant_' || p_slug;
    EXECUTE format('CREATE SCHEMA %I', v_schema);
    EXECUTE format('CREATE TABLE %I.notes (note_id integer PRIMARY KEY, body text NOT NULL)', v_schema);
    RETURN v_schema;
END
$$;
CREATE FUNCTION app.add_note(p_slug text, p_note_id integer, p_body text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('INSERT INTO %I.notes (note_id, body) VALUES ($1, $2)', 'tenant_' || p_slug)
    USING p_note_id, p_body;
END
$$;
CREATE FUNCTION app.tenant_note_count(p_slug text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_count bigint;
BEGIN
    EXECUTE format('SELECT count(*) FROM %I.notes', 'tenant_' || p_slug) INTO v_count;
    RETURN v_count;
END
$$;
CREATE FUNCTION app.add_column_everywhere(p_column text, p_type text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
    v_schema text;
    v_count integer := 0;
BEGIN
    IF p_type NOT IN ('text', 'integer', 'boolean') THEN
        RAISE EXCEPTION 'type not allowed' USING ERRCODE = '22023';
    END IF;
    FOR v_schema IN SELECT nspname FROM pg_namespace WHERE starts_with(nspname, 'tenant_') ORDER BY nspname LOOP
        EXECUTE format('ALTER TABLE %I.notes ADD COLUMN %I %s', v_schema, p_column, p_type);
        v_count := v_count + 1;
    END LOOP;
    RETURN v_count;
END
$$;
```

Reading the shared model. `projects` has the primary key `(tenant_id, project_id)` and `tasks` references **both** columns, so a task can only point at a project **of the same tenant**: the database enforces what RLS cannot (RLS filters rows; it does not stop a valid insert that points at a visible-to-the-owner row of another tenant). The `_naive` pair uses a global project id and a one-column foreign key, which accepts a task of tenant 2 pointing at tenant 1's project.

Reading the schema model. `app.provision_tenant` is **dynamic SQL**, so it must defend itself. The slug is validated against a strict pattern before use (a rejected slug raises SQLSTATE `22023`, invalid parameter value), `format('%I', ...)` quotes the identifier, and the function never concatenates raw input into SQL. `app.add_note` and `app.tenant_note_count` build statements with `%I` and pass values with `USING`. `app.add_column_everywhere` is the **fan-out migration**: one `ALTER TABLE` per tenant schema, with the column type checked against a whitelist because `%s` inserts it unquoted. In real life each tenant's migration must be recorded (a version table per tenant) and be retryable, and you must decide what happens when 3,000 of 3,100 succeed.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT tenant_id, count(*) AS tasks FROM app.tasks GROUP BY tenant_id ORDER BY tenant_id;
BEGIN;
SELECT app.attempt('INSERT INTO app.tasks (tenant_id, task_id, project_id, title) VALUES (2, 2, 2, ''Cross'')') AS composite_fk_blocks_cross_tenant,
       app.attempt('INSERT INTO app.tasks_naive (task_id, tenant_id, project_id, title) VALUES (2, 2, 1, ''Cross'')') AS single_column_fk_allows_it;
ROLLBACK;
SELECT app.provision_tenant('acme') AS schema_1,
       app.provision_tenant('globex') AS schema_2,
       app.provision_tenant('initech') AS schema_3;
\o /dev/null
SELECT app.add_note('acme', 1, 'welcome'), app.add_note('acme', 2, 'plan'), app.add_note('globex', 1, 'hello');
\o
SELECT t.slug, app.tenant_note_count(t.slug) AS notes
FROM (VALUES ('acme'), ('globex'), ('initech')) AS t(slug)
ORDER BY t.slug;
SELECT app.attempt('SELECT app.provision_tenant(''bad; drop'')') AS bad_slug;
SELECT app.add_column_everywhere('pinned', 'boolean') AS schemas_altered;
SELECT count(*) AS notes_tables_with_pinned FROM information_schema.columns
WHERE column_name = 'pinned' AND table_name = 'notes' AND starts_with(table_schema, 'tenant_');
SELECT (SELECT count(*) FROM pg_namespace WHERE starts_with(nspname, 'tenant_')) AS tenant_schemas,
       (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE starts_with(n.nspname, 'tenant_') AND c.relkind IN ('r', 'i')) AS catalog_relations;
```

The script first counts tasks per tenant, then tests both foreign-key styles inside a transaction it rolls back. Then it provisions three tenant schemas, writes notes (the output of the writes is discarded with `\o /dev/null`), counts per tenant, tries an injection-shaped slug, runs the fan-out migration, and counts what exists in the catalog.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-07 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-07 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 07`.

## Run it
**Predict first.** (a) Which of the two cross-tenant task inserts succeeds? (b) What happens to the slug `bad; drop`? (c) How many catalog relations (tables plus indexes) do three tenant schemas create when each has one table with a primary key?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
tenant_id|tasks
1|2
2|1
composite_fk_blocks_cross_tenant|single_column_fk_allows_it
err:23503|ok:1
schema_1|schema_2|schema_3
tenant_acme|tenant_globex|tenant_initech
slug|notes
acme|2
globex|1
initech|0
bad_slug
err:22023
schemas_altered
3
notes_tables_with_pinned
3
tenant_schemas|catalog_relations
3|6
```

Why: tenant 2 has no project 2, so the composite foreign key rejects the insert with SQLSTATE `23503` (foreign key violation); the single-column version only looks for project 1 anywhere and accepts it, silently attaching tenant 2's task to tenant 1's project. The injection-shaped slug fails the pattern check. Each tenant schema creates a table and its primary-key index, so three tenants give six relations: with 40 tables per tenant and 5,000 tenants that is 400,000 relations in the catalog, which is the cost to measure before choosing this design.

## How it works
**Shared tables.** Put `tenant_id` first in primary keys and in the leading position of the indexes your queries filter on, make every foreign key composite, and add RLS (lesson 06) as defence in depth. Unique constraints must include `tenant_id` unless uniqueness is global by design. Whales (very large tenants) show up as skewed statistics (lesson 02) and plans that differ per tenant; consider list partitioning by tenant for the largest ones, or moving them out. Generated identifiers should not leak tenant order (use UUIDs or per-tenant sequences if guessing matters).

**Schema per tenant.** Isolation by permissions and `search_path`: set it per transaction (`SET LOCAL search_path = tenant_acme`), schema-qualify names in functions, and set a safe `search_path` on `SECURITY DEFINER` functions to avoid hijacking. Costs: catalog growth, the migration fan-out, slower tooling (`pg_dump`, schema diff), and a plan cache per table. Benefits: per-tenant dump and restore, simple offboarding, per-tenant customisation. The limit is operational, not a number: measure `pg_dump` time, autovacuum scheduling and relcache memory at your expected scale.

**Database per tenant.** Isolation strongest within one cluster: separate catalogs, `CONNECT` privileges, per-database settings and extensions. Costs: a pool per database (lesson 05), no cross-database queries (use a warehouse or foreign data wrappers), migrations fan out across connections, and per-database autovacuum workers and statistics collectors. For real per-tenant point-in-time recovery or resource isolation you need separate clusters, which is a platform problem: a tenant directory, automation, and monitoring for hundreds of instances.

**Fan-out discipline.** Record the schema version per tenant; run migrations in batches with a concurrency limit and `lock_timeout`; make each step idempotent; stop the rollout on the first failure class; keep application code compatible with versions N and N+1 (expand and contract, as in 201 lesson 03); and report tenants that lag.

**Why this, not that.** Start with the simplest design that meets the **hardest requirement you actually have** (compliance, noisy-neighbour risk, per-tenant restore), not the largest scale you imagine. Pool with composite keys and RLS is the cheapest to run; schema per tenant buys per-tenant restore and customisation; database per tenant buys contractual isolation. Do not choose schema per tenant for "future scale": it scales the wrong axis.

**Measurements to take (production checklist).**
- [ ] Table, index and relation counts per tenant times tenant count; `pg_dump` and restore time at that count (rehearsed).
- [ ] Per-tenant row counts and sizes (`pg_total_relation_size`); top tenants share of storage and I/O.
- [ ] Per-tenant query statistics: `pg_stat_statements` joined to a tenant tag in application logs, since statistics have no tenant column.
- [ ] Migration rollout time and tenants-behind report.
- [ ] Per-tenant restore drill: time to recover one tenant from backup.
- [ ] Cross-tenant leak tests: every foreign key composite; negative tests under the application role (lesson 06).
- [ ] Offboarding: proof that a deleted tenant's data is gone from the database and from backups on schedule.

## Try it
Keep `db` running.

1. **Guided:** In the starter, add the foreign key `fk_comments_task` so a comment can reference only a task of its own tenant: columns `(tenant_id, task_id)` referencing `app.tasks (tenant_id, task_id)`.

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
CREATE TABLE app.comments (
    tenant_id integer NOT NULL,
    comment_id integer NOT NULL,
    task_id integer NOT NULL,
    body text NOT NULL,
    CONSTRAINT pk_comments PRIMARY KEY (tenant_id, comment_id)
    -- TODO: add a composite foreign key named fk_comments_task on (tenant_id, task_id)
    -- referencing app.tasks (tenant_id, task_id). Remember the comma after the primary key line.
);
SELECT app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (1, 1, 1, ''fine'')') AS own_tenant_comment,
       app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (2, 2, 2, ''cross'')') AS cross_tenant_comment;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-07 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand: tenant 1's task 1 exists, tenant 2 has no task 2. The untouched starter has no foreign key at all, so it would print `ok:1|ok:1`.

**Expected output, not yet run:**

```text
own_tenant_comment|cross_tenant_comment
ok:1|err:23503
```

3. **Change:** Write down the single `ALTER TABLE` you would run in each design to add a column `archived boolean` to tasks, and how many times each runs for 2,000 tenants. State the failure you must plan for in the schema-per-tenant case.
4. **Stretch (optional, no single answer):** Write an ADR for a product that has 200 tenants, 5 of them hospitals with contractual isolation and data-residency requirements, and 195 small clinics. Choose a hybrid, name the routing mechanism, and list three triggers that move a clinic to its own schema.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
CREATE TABLE app.comments (
    tenant_id integer NOT NULL,
    comment_id integer NOT NULL,
    task_id integer NOT NULL,
    body text NOT NULL,
    CONSTRAINT pk_comments PRIMARY KEY (tenant_id, comment_id),
    CONSTRAINT fk_comments_task FOREIGN KEY (tenant_id, task_id) REFERENCES app.tasks (tenant_id, task_id)
);
SELECT app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (1, 1, 1, ''fine'')') AS own_tenant_comment,
       app.attempt('INSERT INTO app.comments (tenant_id, comment_id, task_id, body) VALUES (2, 2, 2, ''cross'')') AS cross_tenant_comment;
```

For the change rung: shared tables run one `ALTER TABLE app.tasks ADD COLUMN archived boolean NOT NULL DEFAULT false` (a constant default is applied without rewriting the table) once; schema per tenant and database per tenant run it 2,000 times, so you need a per-tenant version record, batching, and a plan for partial failure (some tenants migrated, some not, application compatible with both). For the stretch rung a defensible answer is: the five hospitals in separate databases or clusters behind a tenant directory, the clinics in shared tables with composite keys and RLS; triggers for moving a clinic out: a contractual isolation request, sustained share of load or storage above an agreed threshold, and frequent per-tenant restore requests.

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
docker compose -p code101-db301-07 stop
docker compose -p code101-db301-07 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data.

## Check yourself
1. Why does a one-column foreign key on `project_id` fail to protect tenant boundaries? <details><summary>Answer</summary>It only checks that the project exists somewhere; it does not check that the task and project belong to the same tenant.</details>
2. Predict how many `ALTER TABLE` statements adding a column takes in each design for 500 tenants. <details><summary>Answer</summary>Shared: 1. Schema per tenant: 500. Database per tenant: 500 (on 500 connections).</details>
3. Find the bug: `EXECUTE 'CREATE SCHEMA tenant_' || p_slug`. <details><summary>Answer</summary>Raw concatenation allows identifier or SQL injection; validate the slug and use `format('%I', ...)`.</details>
4. When do you move a tenant out of shared tables? <details><summary>Answer</summary>When it breaks an agreed threshold (load, storage), requires contractual isolation or residency, or needs per-tenant restore or customisation that the shared design cannot provide cheaply.</details>
5. Which design makes per-tenant point-in-time recovery straightforward? <details><summary>Answer</summary>Only a separate cluster per tenant; schema or database separation within one cluster still shares one WAL stream.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| `schema "tenant_acme" already exists` (typical) | Provisioning ran twice without cleanup | The setup drops the three lab schemas; rerun `setup.sql` |
| An error saying relation `tenant_initech.notes` does not exist (typical) | A tenant function was called before `provision_tenant` for that slug | Provision the tenant first, in the order the script shows |
| Cross-tenant insert succeeds | Single-column foreign key | Use composite keys |
| Fan-out migration fails halfway | One tenant has a conflicting object | Make steps idempotent; record versions; rerun for the remaining tenants |
| A `permission denied` message in the IDE (typical) | The IDE session is not the lab user | Connect as `learner` |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Choose the design for your hardest real requirement, make cross-tenant references impossible with composite keys, validate every identifier you build into SQL, and write the decision as an ADR with the conditions that reopen it. Source: [PostgreSQL 17: Schemas](https://www.postgresql.org/docs/17/ddl-schemas.html) and [Row Security Policies](https://www.postgresql.org/docs/17/ddl-rowsecurity.html).

## Going further
- Supabase platform guidance on RLS-based multi-tenancy and performance: [supabase.com/docs/guides/platform/performance](https://supabase.com/docs/guides/platform/performance) (Tier 2).
- The pgvector README's multi-tenancy note on partitioning by tenant for shared approximate indexes: [github.com/pgvector/pgvector#multitenancy](https://github.com/pgvector/pgvector#multitenancy) (lesson 09).
- Capstone: the platform's team-scoped schema is the shared-table model; see [capstone platform TDD](../../../../capstones/platform/TDD.md) and [database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You compared the three designs with a table and wrote the choice as an ADR.
- You proved that composite keys block cross-tenant references and a single-column key does not.
- You provisioned tenant schemas with validated, quoted identifiers and ran a fan-out migration.
- You listed the measurements and the triggers that move a tenant between designs.

## Next lesson
08. Replication and high availability: streaming replication, failover concepts, and backups with WAL and point-in-time recovery.
