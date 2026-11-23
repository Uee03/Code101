---
track: databases
level: 301
phase: 3
phase_name: security-and-multitenancy
lesson: 06
title: "Row-level security in depth: policies, performance rules and testing"
time: 105 min
prerequisites: [301.2.05, 201.4.11]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/06-row-level-security-in-depth/
assets: []
---

# 06. Row-level security in depth: policies, performance rules and testing

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Write `USING` and `WITH CHECK` policies per command, and predict which rows each command can see, change or create.
- Apply the performance rules for policies: index the policy column, evaluate context once, keep predicates simple, and know what "leakproof" means.
- Explain the limits of row-level security: owners, superusers, views, security-definer functions, constraint checks, and context settings that are claims rather than authentication.
- Write a repeatable policy test that runs under the restricted role and fails when a policy is wrong.

## Recap
- 201 lesson 11: which users bypass row-level security?
  <details><summary>Answer</summary>Superusers and roles with `BYPASSRLS` always; table owners unless the table uses `FORCE ROW LEVEL SECURITY`.</details>
- Lesson 05: why must per-request context be set with `SET LOCAL`?
  <details><summary>Answer</summary>A transaction-mode pooler reuses server connections, so session-level settings leak between clients.</details>

## Why it matters
Row-level security (RLS) moves a tenant or ownership filter from every query in every service into the database, where one wrong `WHERE` cannot expose another customer's rows. It also adds a hidden predicate to every query, a trust boundary you must test, and a set of sharp edges that have caused real leaks. Used well it is a strong defence in depth. Used carelessly it is a false sense of safety.

## What you will build
A `documents` table shared by two tenants, a restricted role that is not the owner, one policy per command, and a table-driven policy test script whose results you can derive by hand. A second script lets you compare plans for two ways of writing the policy.

## Before you start
- **Prerequisites:** [Databases 301 lesson 05, connection pooling](../phase-2-concurrency-and-integrity/05-connection-pooling.md); [Databases 201 lesson 11, roles, RLS, backup and pooling](../../201-hero-to-super-hero/phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md).
- Finished lessons 04 and 05 and 201 lesson 11. No host PostgreSQL needed.
- Docker with Compose and `postgres:17-alpine`; same Compose file as lessons 02 to 05.
- Time: 105 minutes. Two sittings: break after Step 4.
- Source pack (optional): every file is shown here. Finished code, starter and solution: https://github.com/Uee03/Code101 under `source/databases/301-super-hero-to-legendary/phase-3-security-and-multitenancy/06-row-level-security-in-depth/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-301-phase-3-security-and-multitenancy.zip`.
- **One database lab at a time:** stop other labs before using `127.0.0.1:5432`.
- Disposable local credentials only. Nothing here has been run; results are derived by hand. The role `tenant_app` is created with `NOLOGIN` and used through `SET LOCAL ROLE`: this simulates policy behaviour, it is **not** a test of password authentication.

## Steps
### Step 1. Prepare the workspace
Follow [lesson 04, Step 1](../phase-2-concurrency-and-integrity/04-transactions-isolation-and-locking.md#step-1-prepare-the-workspace) (genuinely identical) with the phase folder `databases-301-phase-3-security-and-multitenancy` and lesson folder `06-row-level-security-in-depth`. To get back:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-301-phase-3-security-and-multitenancy\06-row-level-security-in-depth\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-301-phase-3-security-and-multitenancy/06-row-level-security-in-depth/code"
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

### Step 4. Model the policies, then save the files
New terms. A **policy** is a rule attached to a table and a command. `USING` is the condition on **existing** rows (what you may see, update or delete). `WITH CHECK` is the condition on **new or changed** rows (what you may write). **Permissive** policies (the default) combine with OR; **restrictive** policies (`AS RESTRICTIVE`) combine with AND on top. With RLS enabled and **no** policy for a command, the command sees and changes no rows (default deny). A **leakproof** function cannot reveal its arguments through errors or side channels, so the planner may run it before the policy filter. The **context** is the value the application passes to the database to say who is asking; here the setting `app.tenant_id`.

**What bypasses RLS.** Superusers and roles with `BYPASSRLS` always. The table owner unless `FORCE ROW LEVEL SECURITY` is set. The lab user `learner` is a superuser, so `FORCE` has no effect on it; the lab therefore tests through `tenant_app`, which owns nothing. Foreign-key and unique-constraint checks run with the table owner's rights and ignore policies, so they can reveal that a hidden row exists (a duplicate-key error, a foreign-key error). `pg_dump` skips RLS tables unless told to enable it. A view runs with its **owner's** rights unless it is created `WITH (security_invoker = true)` (PostgreSQL 15 and later): a plain view over an RLS table can bypass the policies for its callers. A `SECURITY DEFINER` function runs with the definer's rights and bypasses RLS if the definer does.

**The context is a claim, not authentication.** The policy trusts `current_setting('app.tenant_id')`. Whoever can run arbitrary SQL under a role that is allowed to `SET` it can **choose** the tenant. The lab proves this in test 8. RLS with a context setting is safe only when untrusted code **cannot send SQL** (an API gateway or application server sets the value, from a verified token, inside each transaction) or when the identity is the database role itself (a role per tenant and `current_user` in policies). Decide which model you are in before you write a policy.

**Seed.** Documents 1 and 2 belong to tenant 1; documents 3 and 4 to tenant 2.

**File: `code/setup.sql`**
```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'tenant_app') THEN
        CREATE ROLE tenant_app NOLOGIN;
    END IF;
END
$$;
DROP SCHEMA IF EXISTS app CASCADE;
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
CREATE FUNCTION app.current_tenant() RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT nullif(current_setting('app.tenant_id', true), '')::integer
$$;
CREATE TABLE app.documents (
    doc_id integer NOT NULL,
    tenant_id integer NOT NULL,
    title text NOT NULL,
    CONSTRAINT pk_documents PRIMARY KEY (doc_id)
);
CREATE INDEX ix_documents_tenant ON app.documents (tenant_id);
INSERT INTO app.documents (doc_id, tenant_id, title) VALUES
    (1, 1, 'plan-a'),
    (2, 1, 'budget-a'),
    (3, 2, 'plan-g'),
    (4, 2, 'secret-g');
CREATE TABLE app.policy_tests (
    test_id integer NOT NULL,
    test text NOT NULL,
    expected text NOT NULL,
    actual text NOT NULL,
    CONSTRAINT pk_policy_tests PRIMARY KEY (test_id)
);
ALTER TABLE app.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.documents FORCE ROW LEVEL SECURITY;
CREATE POLICY documents_select ON app.documents FOR SELECT TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_insert ON app.documents FOR INSERT TO tenant_app
    WITH CHECK (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_update ON app.documents FOR UPDATE TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()))
    WITH CHECK (tenant_id = (SELECT app.current_tenant()));
CREATE POLICY documents_delete ON app.documents FOR DELETE TO tenant_app
    USING (tenant_id = (SELECT app.current_tenant()));
GRANT USAGE ON SCHEMA app TO tenant_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON app.documents TO tenant_app;
GRANT INSERT ON app.policy_tests TO tenant_app;
```

Line by line. The `DO` block creates the role only if missing: **roles are cluster-wide**, so `DROP SCHEMA ... CASCADE` does not remove it and a rerun must not fail. `app.current_tenant()` turns the setting into an integer and returns `NULL` for unset or empty, so the policy compares against `NULL` and matches nothing: **fail closed**. It is `STABLE`, which tells the planner it returns the same value within one statement. `ix_documents_tenant` indexes the column every policy filters on. The four policies cover each command; `UPDATE` has both `USING` (which rows may be updated) and `WITH CHECK` (the new row must still belong to the tenant, so a row cannot be moved to another tenant). Each policy is `TO tenant_app`, so no other role gets a hidden filter. `(SELECT app.current_tenant())` is the **initPlan wrapper**: it asks the planner to compute the value once per statement instead of once per row. `GRANT`s give ordinary privileges; RLS applies on top of them, never instead of them. `app.policy_tests` collects test results; it has no policy, and `tenant_app` may only insert into it.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT count(*) AS superuser_sees FROM app.documents;
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 1 sees own rows', '2', (SELECT count(*)::text FROM app.documents));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (2, 'insert own tenant row', 'ok:1',
        app.attempt('INSERT INTO app.documents (doc_id, tenant_id, title) VALUES (10, 1, ''new-a'')'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (3, 'insert other tenant row', 'err:42501',
        app.attempt('INSERT INTO app.documents (doc_id, tenant_id, title) VALUES (11, 2, ''forged'')'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (4, 'update other tenant row', 'ok:0',
        app.attempt('UPDATE app.documents SET title = ''hacked'' WHERE doc_id = 3'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (5, 'move own row to other tenant', 'err:42501',
        app.attempt('UPDATE app.documents SET tenant_id = 2 WHERE doc_id = 1'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (6, 'delete other tenant row', 'ok:0',
        app.attempt('DELETE FROM app.documents WHERE doc_id = 4'));
SET LOCAL app.tenant_id = '';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (7, 'empty tenant context sees nothing', '0', (SELECT count(*)::text FROM app.documents));
SET LOCAL app.tenant_id = '2';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (8, 'forged tenant context is accepted', '2', (SELECT count(*)::text FROM app.documents));
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
SELECT bool_and(expected = actual) AS all_policy_tests_pass FROM app.policy_tests;
ROLLBACK;
SELECT (SELECT proleakproof FROM pg_proc WHERE proname = 'int4eq') AS int4eq_leakproof,
       (SELECT proleakproof FROM pg_proc WHERE oid = 'app.current_tenant()'::regprocedure) AS own_function_leakproof;
SELECT count(*) AS rows_after_rollback FROM app.documents;
```

The pattern is **arrange, act, assert**: switch to the restricted role and set the context (arrange); run each operation through `app.attempt` or a query (act); store the expected and actual values side by side (assert) and report. Everything runs in one transaction that is rolled back, so the data is untouched. Test 8 is deliberately a **demonstration of a weakness**, written as a passing test: it documents that the claim is accepted. `SQLSTATE 42501` is `insufficient_privilege`, which is what a violated `WITH CHECK` raises (typical message: new row violates row-level security policy for table "documents").

**File: `code/plans.sql`**
```sql
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
EXPLAIN (ANALYZE, BUFFERS)
SELECT doc_id, title FROM app.documents WHERE title LIKE 'plan%';
COMMIT;
DROP POLICY documents_select ON app.documents;
CREATE POLICY documents_select ON app.documents FOR SELECT TO tenant_app
    USING (tenant_id = app.current_tenant());
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '1';
EXPLAIN (ANALYZE, BUFFERS)
SELECT doc_id, title FROM app.documents WHERE title LIKE 'plan%';
COMMIT;
```

The script compares the same query under two spellings of the select policy: wrapped in `(SELECT ...)` and unwrapped. It prints plans only, so nothing is asserted about their text.

### Step 5. Start PostgreSQL
**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-06 up -d --wait
```

Expected output, not yet run: network, volume and `db` container created, then healthy; progress text varies.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-06 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

Optional IDE connection: as in [201 lesson 07, Step 6](../../201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain.md), display name `Code101 DB301 06`.

## Run it
**Predict first.** (a) How many rows does the superuser see? (b) As tenant 1, can you insert a row for tenant 2? Does an `UPDATE` of a tenant-2 row raise an error, or affect zero rows? (c) What does an empty context return? (d) If you set the context to `2` yourself, what happens?

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-06 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run (hand-derived):**

```text
superuser_sees
4
test_id|test|expected|actual|pass
1|tenant 1 sees own rows|2|2|t
2|insert own tenant row|ok:1|ok:1|t
3|insert other tenant row|err:42501|err:42501|t
4|update other tenant row|ok:0|ok:0|t
5|move own row to other tenant|err:42501|err:42501|t
6|delete other tenant row|ok:0|ok:0|t
7|empty tenant context sees nothing|0|0|t
8|forged tenant context is accepted|2|2|t
all_policy_tests_pass
t
int4eq_leakproof|own_function_leakproof
t|f
rows_after_rollback
4
```

Why: the superuser bypasses the policies and sees all four rows. Tenant 1 sees documents 1 and 2. Inserting a row for another tenant violates `WITH CHECK`, which raises an error. Updating or deleting another tenant's row is **silently a no-op** because the row is invisible: zero rows, no error (a common surprise: your application must treat "0 rows affected" as "not found or not allowed"). Moving your own row to another tenant fails the update policy's `WITH CHECK`. An empty context yields `NULL` and nothing matches. A forged context is accepted: documents 3 and 4. Built-in comparison functions such as `int4eq` are marked leakproof; a function you write is not unless you declare it, and you should do so only after proving it cannot leak.

### Compare two policy spellings (not asserted)
After Run it, from this code folder:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-06 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/plans.sql
```

Expected output, not yet run: two plans, whose text and numbers are not predicted. Look for: whether the policy condition appears as an index condition or as a filter; whether the value of `app.current_tenant()` is computed once (an `InitPlan` node) or may be evaluated repeatedly; where the `LIKE` condition runs relative to the policy condition (a function that is not leakproof is not allowed to run before the policy filter on rows the user cannot see, which can prevent an index from being used); buffer counts. On four rows both plans may be a sequential scan: repeat the comparison on a table with many tenants and many rows before concluding anything.

## How it works
**Command semantics.** `SELECT` applies `USING`. `UPDATE` applies `USING` to find rows and `WITH CHECK` to the new version (if omitted, `USING` is also used as the check). `INSERT` applies `WITH CHECK`. `DELETE` applies `USING`. `INSERT ... ON CONFLICT DO UPDATE` and statements with `RETURNING` also need `SELECT` visibility, so a missing `SELECT` policy can make a valid insert fail. `COPY ... FROM` is not supported on a table with row-level security (use `INSERT`); `COPY ... TO` is treated like a `SELECT`.

**Performance rules.**
1. **Index the policy columns.** A policy is a predicate on every query; `tenant_id` needs an index (usually as the leading column of the indexes that serve your main queries).
2. **Evaluate context once.** Write `(SELECT app.current_tenant())` or `(SELECT auth.uid())`-style wrappers so the value is computed once per statement. Measure: modern planners often hoist stable functions anyway, and the Supabase RLS guidance recommends the wrapper because it avoids per-row evaluation in some plans.
3. **Keep policies simple.** A policy with subqueries or joins against other tables (for example "tasks whose project belongs to a team the user is a member of") runs for every row and can nest other policies. Prefer a denormalised `tenant_id` or `team_id` column on every table, or a `STABLE` helper function that returns the caller's team ids once, and index the column.
4. **Repeat the filter in your query.** Application queries should still say `WHERE tenant_id = $1`, so the planner has an index condition it can use even when a non-leakproof function in the query would otherwise stay behind the policy filter.
5. **Specify `TO role`.** A policy without it applies to every role and adds work for roles that do not need it.
6. **Measure with the real role** (`SET LOCAL ROLE`), not the superuser, or you measure a different query.

**Testing policies.** Test as the restricted role, not as owner or superuser; test each command; test the **negative** cases (other tenant, no tenant, forged tenant, removing the policy should make a test fail); keep tests in version control and run them in continuous integration against a throwaway database; rerun after every migration that touches a policy, a column or a view. Extensions such as pgTAP formalise this; the table-driven script above is the same idea without a dependency. Inspect what is in force with `SELECT * FROM pg_policies WHERE schemaname = 'app';`.

**Failure modes.** A view without `security_invoker`; a `SECURITY DEFINER` function owned by a superuser; an owner connection used by the application; `BYPASSRLS` granted "temporarily"; a policy forgotten on a new table; session-level context leaking through a pooler; a `NULL` context treated as "no filter"; error messages and constraint violations leaking existence; a role that can `SET` its own context and also run arbitrary SQL.

**When not to use RLS.** If the application is the only client and has a mature authorization layer, RLS adds cost and complexity; do not use it as the only defence for untrusted SQL access; do not use it for security that depends on rows being invisible in `EXPLAIN` row counts or timing. Use it when many services or direct database clients touch the same tables, or when a direct-to-database API is part of the design.

**Why this, not that.** Filtering in every query is cheaper and visible but fails open when someone forgets. A schema or database per tenant (lesson 07) isolates harder at a higher operational cost. RLS sits in between: one schema, enforced filters, with a trust assumption about the context.

**Measurements to take (production checklist).**
- [ ] Every table with tenant data has RLS enabled, or a documented reason; a catalog query lists tables without it (`pg_class.relrowsecurity`).
- [ ] Application roles are not owners and have no `BYPASSRLS`; views use `security_invoker` where they read RLS tables.
- [ ] Policy tests run in continuous integration and fail when a policy is dropped.
- [ ] Plans for your top statements compared as the application role, with and without wrappers, on production-sized data.
- [ ] The path that sets the context is reviewed: one place, inside each transaction, from verified identity.
- [ ] Audit: who has `BYPASSRLS`, who owns the tables, who owns `SECURITY DEFINER` functions.

## Try it
Keep `db` running.

1. **Guided:** In the starter, fix test 1 so its actual value is the real result of `app.attempt` for deleting document 4 (tenant 2's own row), then add test 2 (tenant 2 cannot see document 1).

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
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '2';
-- TODO: replace 'TODO' below with the actual result of app.attempt for deleting doc_id 4 (tenant 2's own row).
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 2 deletes own row', 'ok:1', 'TODO');
-- TODO: add test 2, named 'tenant 2 cannot see tenant 1 row', expecting '0', whose actual value is the number
-- of rows with doc_id = 1 that tenant 2 can see (as text). Use the same INSERT shape as test 1.
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
ROLLBACK;
```

2. Save and run:

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db301-06 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target for the completed program, derived by hand. The untouched starter shows a failing row 1 (`pass` is `f`, actual `TODO`) and no row 2.

**Expected output, not yet run:**

```text
test_id|test|expected|actual|pass
1|tenant 2 deletes own row|ok:1|ok:1|t
2|tenant 2 cannot see tenant 1 row|0|0|t
```

3. **Change:** Make the test suite catch a broken policy. Edit your copy of `setup.sql` (or run `ALTER POLICY` in a transaction) so the update policy has **no** `WITH CHECK` and a `USING` that is `true`; rerun `lesson.sql`. Which tests fail and why? (Predict first; read the documentation of `CREATE POLICY` on how `UPDATE` combines `USING`, `WITH CHECK` and the `SELECT` policy.) Then restore the file.
4. **Stretch (optional, no single answer):** The platform's `tasks` belong to `projects`, which belong to `teams`, which have `team_members`. Design the policy for `tasks` so the user sees only tasks of their teams, without a three-table subquery on every row. Compare (a) a denormalised `team_id` on `tasks` kept by a trigger, (b) a `STABLE SECURITY DEFINER` helper returning the user's team ids, and (c) application-level filtering only. State trade-offs and how you would test the choice.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
BEGIN;
SET LOCAL ROLE tenant_app;
SET LOCAL app.tenant_id = '2';
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (1, 'tenant 2 deletes own row', 'ok:1', app.attempt('DELETE FROM app.documents WHERE doc_id = 4'));
INSERT INTO app.policy_tests (test_id, test, expected, actual)
VALUES (2, 'tenant 2 cannot see tenant 1 row', '0',
        (SELECT count(*)::text FROM app.documents WHERE doc_id = 1));
RESET ROLE;
SELECT test_id, test, expected, actual, expected = actual AS pass FROM app.policy_tests ORDER BY test_id;
ROLLBACK;
```

For the change rung: without a `WITH CHECK` the `USING (true)` condition is also used as the check, so the move-to-other-tenant test (5) now succeeds (`ok:1` instead of `err:42501`) and fails the suite. Test 4 still passes: an `UPDATE` with a `WHERE` clause also needs the row to be visible through the `SELECT` policy, which still hides other tenants' rows. That is worth remembering: policies for different commands combine. The suite detects the weakening that matters. For the stretch rung, (a) is the simplest and fastest at read time but needs a trigger and a migration, (b) keeps one source of truth but the function owner's rights are a trust boundary and the function must be written carefully (fixed `search_path`), (c) is the weakest because a missed filter leaks data. Test whichever you choose with the negative cases above.

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
docker compose -p code101-db301-06 stop
docker compose -p code101-db301-06 down -v --remove-orphans
```

Expected output, not yet run: variable stop and removal progress. `down -v` deletes this disposable project's data. The role `tenant_app` lives inside that project's database cluster and disappears with its volume.

## Check yourself
1. A tenant-1 session runs `UPDATE documents SET title = 'x' WHERE doc_id = 3`. Error or no error? <details><summary>Answer</summary>No error; zero rows are affected because the row is invisible to the session.</details>
2. What stops a tenant moving its own document to tenant 2? <details><summary>Answer</summary>The `WITH CHECK` of the update policy: the new row must still satisfy the tenant condition.</details>
3. Predict `count(*)` for a `tenant_app` session with no context set. <details><summary>Answer</summary>0: the context is `NULL`, nothing matches, and the policy fails closed.</details>
4. Find the problem: the application connects as the table owner. <details><summary>Answer</summary>The owner bypasses RLS unless `FORCE ROW LEVEL SECURITY` is set; and a superuser or `BYPASSRLS` role always bypasses. Use a separate non-owner role.</details>
5. Why is `tenant_id = current_setting('app.tenant_id')::int` as the only protection weak when clients can run SQL? <details><summary>Answer</summary>The client can `SET` the setting itself. The context is a claim, not authentication.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| A permission-denied or "must be member of role" error on `SET ROLE` (typical) | The connecting user may not switch to `tenant_app` | Run the lab as `learner`, or `GRANT tenant_app TO` the role |
| Test results show everything visible | Tested as the superuser or owner | Use `SET LOCAL ROLE tenant_app` |
| Rows vanish after enabling RLS for an existing role | Default deny: no policy for that command or role | Add a policy for the role and command |
| A view returns rows the user should not see | The view runs with its owner's rights | Create it `WITH (security_invoker = true)` |
| Policy tests leave data behind | Missing `ROLLBACK` | Wrap tests in a transaction that ends with `ROLLBACK` |
| `role "tenant_app" already exists` (typical) | Role creation without the existence check | Keep the `DO` block; roles survive schema drops |
| Port already allocated (typical) | Another lab uses 5432 | Stop it first |

## Best practice
Treat the RLS context as a claim set by trusted code inside each transaction, index every policy column, and test every policy as the restricted role, including the negative cases. Source: [PostgreSQL 17: Row Security Policies](https://www.postgresql.org/docs/17/ddl-rowsecurity.html) and [CREATE POLICY](https://www.postgresql.org/docs/17/sql-createpolicy.html).

## Going further
- Supabase: [RLS performance and best practices](https://supabase.com/kb/troubleshooting/rls-performance-and-best-practices-Z5Jjwv) (Tier 2); the same ideas apply to any `(SELECT ...)`-wrapped identity function.
- [Use The Index, Luke](https://use-the-index-luke.com/) for why the policy column must lead your composite indexes (Tier 2).
- Capstone: the platform schema is "RLS-ready" (team-scoped projects, UUID keys, stored functions that take the actor id); today authorization is in the API layer, described in [capstone platform, database and procedures](../../../../capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md).

## Summary
- You wrote one policy per command and predicted what each command sees, changes and creates.
- You applied the performance rules and named leakproof functions and the `initPlan` wrapper.
- You listed the bypasses and limits, including that a context setting is a claim.
- You wrote a table-driven policy test that runs as the restricted role and catches regressions.

## Next lesson
07. Multi-tenant designs: schema per tenant, shared tables with row-level security, and database per tenant, with a trade-offs table.
