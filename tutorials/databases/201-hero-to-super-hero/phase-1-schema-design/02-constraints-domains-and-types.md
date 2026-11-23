---
track: databases
level: 201
phase: 1
phase_name: schema-design
lesson: 02
title: "Constraints, domains, enums and types done right"
time: 55 min
prerequisites: [201.1.01]
versions: { postgres_image: "17-alpine", postgresql: "17", compose: "5.7.0", docker: "29.9.3" }
verified: not yet run
source: source/databases/201-hero-to-super-hero/phase-1-schema-design/02-constraints-domains-and-types/
assets: []
---

# 02. Constraints, domains, enums and types done right

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Choose between a CHECK, domain, enum and lookup table.
- Explain NULL behavior and enforce a cross-column invariant.
- Construct and read a composite value without treating it as a constrained table.

## Recap
- Where does the sale price belong?
  <details><summary>Answer</summary>On the order line as a historical fact, separate from the current product price.</details>
- What does UNIQUE do with NULL by default?
  <details><summary>Answer</summary>It treats NULLs as distinct; pair with NOT NULL for a required business key.</details>

## Why it matters
Application validation improves feedback but cannot protect writes from every client. Database constraints provide a final boundary. Choosing the wrong abstraction makes that boundary hard to evolve.

## What you will build
A product amount domain, a deliberately stable order-state enum, a date-range rule and a typed price quote.

## Before you start
- Finished [Databases 101](../../101-zero-to-hero/phase-3-designing/12-library-project.md): Docker PostgreSQL, psql/IDE connections, joins, transactions and basic indexes. No host PostgreSQL or psql install is needed.
- Docker in Linux-container mode with Compose, a text editor, and the same `postgres:17-alpine` image as 101. Docker/Compose versions above are the inherited authoring baseline, not a new runtime check. The tag pins major version/flavour, not a patch digest.
- Time: 55 minutes including reading, typing and exercise. Two sittings are reasonable: save the feature files before Step 5, then return for the run and exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/databases/201-hero-to-super-hero/phase-1-schema-design/02-constraints-domains-and-types/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`). Generated phase pack: `databases-201-phase-1-schema-design.zip`.
- **One database lab at a time:** stop the previous 101/201 or capstone lab before using 127.0.0.1:5432. Do not stop unrelated services. These lessons are independent; do not carry a schema forward.
- All reset scripts/passwords are disposable local examples. Never aim them at work data. `learner` is the official image's initial administrative user, not an application login design.
- SQL, Docker, negative cases and IDE steps have not been run for this lesson. Result rows are derived by hand; variable tool output is described, not invented.

## Steps
### Step 1. Prepare the lesson workspace
1. In your home folder create `code101` with your file manager. Obtain the source folder from the repository link above, or extract the phase ZIP: Windows **right-click > Extract All**; macOS double-click; Linux use your archive manager's **Extract Here**. Move `databases-201-phase-1-schema-design` into `code101`. Keep `02-constraints-domains-and-types/code` and its sibling `exercise` together.
2. Without a pack, create the same `databases-201-phase-1-schema-design/02-constraints-domains-and-types/code` structure and sibling `exercise/starter` and `exercise/solution` folders using **New Folder**. You will create every file shown below. Leave the finished solution unopened until you try the exercise.
3. Open a terminal (Windows: type `powershell` in File Explorer's address bar in the code folder; macOS/Linux: open Terminal). Do not type a prompt's `>` or `$`. The text before the prompt shows your current directory. Recover to this exact folder if needed:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Set-Location "$HOME\code101\databases-201-phase-1-schema-design\02-constraints-domains-and-types\code"
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cd "$HOME/code101/databases-201-phase-1-schema-design/02-constraints-domains-and-types/code"
```

Expected result, not yet run: the prompt is in this lesson code folder; Set-Location/cd normally print no text. Using the repository directly is also fine: open its matching source code folder and use the same subsequent relative commands.

4. Open that folder in your editor. For each file caption choose **File > New File > Save As** at the shown path relative to the lesson root (`code/` is where your terminal is). If supplied, open and compare instead of creating duplicates. Create displayed subfolders first. Save as UTF-8 without BOM; use LF for shell files. On Windows enable **View > Show > File name extensions** so `.sql.txt` cannot hide. Save with Ctrl+S (Cmd+S on macOS); an editor-tab dot often means unsaved changes.

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

This file is genuinely identical to [201 lesson 01, Step 2](../phase-1-schema-design/01-data-modeling-and-3nf.md#step-2-save-the-complete-compose-configuration). Repeat that step with only these differences: workspace `02-constraints-domains-and-types` instead of `01-data-modeling-and-3nf`, project `code101-db201-02` instead of `code101-db201-01`, and this lesson's SQL. **No YAML line changes.** Full configuration is repeated to keep this pack standalone.

| Configuration line(s) | Meaning and consequence of changing it |
|---|---|
| `services:`, `db:` | Define one service named db; commands below must use that name. |
| `image: postgres:17-alpine` | Use the unchanged official image. A different major version changes the data-directory compatibility contract. |
| `environment:` and POSTGRES_DB/USER/PASSWORD | Initialize the database/admin/password from .env only when the data volume is empty. |
| `PGDATABASE`, `PGUSER` | Set container-client defaults; commands also name user/database explicitly for clarity. |
| `ports:` with `127.0.0.1:5432:5432` | Publish only IPv4 loopback on host port 5432, not every host interface. Host tools use 127.0.0.1; another Compose service would use db. |
| `volumes:` and `pg_data:/var/lib/postgresql/data` | Keep data in this project's named volume. Removing the container alone does not erase it. |
| `.:/scripts:ro` | Mount this code folder read-only; saved host edits are visible to psql. It is not a writable backup location. |
| `../exercise:/exercises:ro` | Mount the sibling exercise folder read-only. Flattening the pack breaks the path. |
| `healthcheck:` and `test:` | Run pg_isready inside db. `$$` defers variable expansion to its shell, not Compose. Readiness is not a password/security test. |
| `interval: 2s`, `timeout: 3s` | Check every two seconds, allowing three seconds per probe. |
| `retries: 30`, `start_period: 5s` | Allow startup time before declaring failure; --wait uses health status. |
| Final `volumes:`, `pg_data:` | Declare the volume, scoped by the explicit project name. |

Indent with spaces. No Dockerfile/.dockerignore: nothing is built. No art is used (`assets: []`).

### Step 3. Create the local environment file
**File: `code/.env.example`**
```dotenv
# Disposable local practice only. Never reuse this password elsewhere.
POSTGRES_DB=code101
POSTGRES_USER=learner
POSTGRES_PASSWORD=learn_local_only
```

The comment marks local-only credentials. POSTGRES_DB names the initial database, POSTGRES_USER its administrator, and POSTGRES_PASSWORD its disposable password. Compose substitutes `${...}` in YAML using a file named exactly `.env`.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item .env.example .env
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp .env.example .env
```

Expected output, not yet run: a successful copy prints no text. The complete generated local file is:

**File: `code/.env`** (local copy, not shipped)
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

These patterns exclude .env and dump archives from Git; they do not encrypt them or remove already tracked files. Editing .env later does not change an initialized database password. Reset only this disposable volume if reinitializing.

### Step 4. Model the feature, then save its files
A **domain** is a reusable base type plus constraints; VALUE denotes the input being checked. Keep nullability on the table column, not in the domain, because domain values can appear as NULL in query contexts. An **enum** is a named ordered set of labels; order follows declaration, not alphabetical sorting. A **composite type** is a named row-shaped value, not a table with all table constraints.

This lesson simplifies an order to one product so the focus stays on invariants (conditions that must hold). `CHECK (ends_on >= starts_on)` compares columns in one row. A CHECK accepts true or unknown, so both date columns also need NOT NULL. A default is not a constraint: explicitly inserting NULL still needs NOT NULL to reject it.

| Requirement | Choice | Why this, not that |
|---|---|---|
| One table needs quantity > 0 | CHECK | No shared type to maintain |
| Several tables share a money rule | Domain | One definition of the scalar range |
| Small, stable technical states | Enum | Typed, ordered labels; removal/reordering needs a type migration |
| Business-managed states with descriptions | Lookup table + foreign key | Add metadata and retire values without replacing a type |
| A function exchanges SKU and amount together | Composite | Convenience for a boundary, not a substitute for relational columns |

Do not use a CHECK that reads another table to enforce a cross-row rule. Use a foreign key or UNIQUE where possible; use a transaction/routine for a rule that truly needs coordinated work.

Read/save all files before running. SQL ends statements with semicolons. Backslash commands are **psql client commands**, not server SQL: ON_ERROR_STOP stops at the first unexpected error; `\ir` includes relative to its containing script; unaligned format uses `|` between columns; footer off removes row-count footers; the null setting displays SQL NULL as `(null)`. Use psql for whole scripts; in an IDE select server SQL, not the backslash commands. The entry script arranges setup automatically. Never execute sample reset files on valuable data.

Defines the isolated example and seed. DROP SCHEMA app CASCADE removes the sample schema and its dependent objects. Use a disposable database.

**File: `code/setup.sql`**
```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE DOMAIN app.nonnegative_amount AS numeric(10,2)
    CONSTRAINT ck_nonnegative_amount CHECK (VALUE >= 0);
CREATE TYPE app.order_state AS ENUM ('draft', 'paid', 'shipped');
CREATE TYPE app.price_quote AS (sku text, amount numeric(10,2));
CREATE TABLE app.products (
    product_id bigint GENERATED ALWAYS AS IDENTITY,
    sku text NOT NULL,
    price app.nonnegative_amount NOT NULL,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku UNIQUE (sku)
);
CREATE TABLE app.orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY,
    product_id bigint NOT NULL,
    state app.order_state NOT NULL DEFAULT 'draft',
    quantity integer NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_products FOREIGN KEY (product_id)
        REFERENCES app.products (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_orders_quantity CHECK (quantity > 0),
    CONSTRAINT ck_orders_dates CHECK (ends_on >= starts_on)
);
CREATE INDEX ix_orders_product_id ON app.orders (product_id);
INSERT INTO app.products (sku, price) VALUES ('N1', 5.00), ('P1', 2.00);
INSERT INTO app.orders (product_id, quantity, starts_on, ends_on)
VALUES (1, 2, DATE '2026-01-10', DATE '2026-01-11');
```

The entry script includes setup or the migration driver, then performs the worked example.

**File: `code/lesson.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT order_id, state, quantity FROM app.orders ORDER BY order_id;
SELECT ('-1'::numeric >= 0) AS negative_passes_check,
       (NULL::numeric >= 0) IS NULL AS null_check_is_unknown;
WITH quotes AS (
    SELECT ROW(sku, price)::app.price_quote AS quote FROM app.products
)
SELECT (quote).sku AS sku, (quote).amount AS amount
FROM quotes ORDER BY (quote).sku;
```

An intentionally failing boundary check, run separately after the successful example.

**File: `code/reject.sql`**
```sql
\set ON_ERROR_STOP on
INSERT INTO app.products (sku, price) VALUES ('BAD', -1.00);
```

### Step 5. Start and inspect PostgreSQL
From this code folder use project `code101-db201-02` consistently. `-p` isolates names/volumes, not the shared host port. Keep Docker Desktop running. `up -d --wait` starts the service and waits for readiness; an initial image download takes extra time.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 up -d --wait
```

Expected output, not yet run: Compose creates the network, volume and db container, then reports healthy readiness. Progress order, IDs and timings vary; no startup transcript is claimed.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 ps --format "{{.Service}} {{.State}} {{.Health}}"
```

**Expected output, not yet run:**

```text
db running healthy
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 logs --no-log-prefix --tail 10 db
```

Expected output, not yet run: timestamped PostgreSQL log lines indicating readiness to accept connections. Exact timestamps/process IDs are unpredictable. Read real logs if startup fails.

### Step 6. Connect using the existing 101 IDE pattern (optional)
The psql command below is sufficient. Repeat [101 lesson 02's IDE steps](../../101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool.md) with these fields; the differences are this lesson workspace and display name. No server install or Azure sign-in is needed for local access.

| Field | Value |
|---|---|
| Host / Server | `127.0.0.1` (IPv4 localhost) |
| Port | `5432` |
| Database | `code101` |
| User | `learner` |
| Password | `learn_local_only` (local only) |
| Authentication | Password / User & Password |
| SSL mode | Disable, only for this loopback lab |
| SSH tunnel | off |
| Display name | `Code101 DB201 02` |

- JetBrains: **Database / Database Explorer > + > Data Source > PostgreSQL**; enter General fields, **Download missing driver files** if offered, then **SSH/SSL** off for this local lab, **Test Connection > OK > New Query Console**. Run selected SQL with Ctrl+Enter (Cmd+Enter on macOS).
- VS Code: Microsoft's **PostgreSQL** extension (`ms-ossdata.vscode-pgsql`), **PostgreSQL > Connections > + / Add New Connection > Parameters**; enter fields, **Advanced** port/SSL, then **Test Connection > Save & Connect > New Query**. Run selected SQL with Ctrl+Shift+E (Cmd+Shift+E on macOS). UI labels may vary; 101 links the vendor directions.
- Visual Studio is not VS Code. Built-in SQL Server Object Explorer is not a PostgreSQL tool; Npgsql alone does not install a Server Explorer provider. Use the existing provider if available, or the terminal/IDE routes above.

Run only selected queries after setup; do not casually reapply destructive setup. A socket connection inside db does not prove a host-network password works. Require TLS for remote production connections; disabling SSL is only for local practice.

## Run it
**Predict first:** Predict the two Boolean cells for negative input and NULL. Does CHECK by itself make a value mandatory?


From this code folder run the entry file. `exec -T` runs the container client without a pseudo-terminal; `-X` ignores psql startup customization; `-q` suppresses routine tags; ON_ERROR_STOP fails fast; `-U`/`-d` name role/database; `-f` is the container file path. Quiet mode does not hide server errors/notices on stderr.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

**Expected output, not yet run:**

```text
order_id|state|quantity
1|draft|2
negative_passes_check|null_check_is_unknown
f|t
sku|amount
N1|5.00
P1|2.00
```

The seed omits state, so order 1 is draft. Negative one fails the range expression; NULL makes it unknown. The quote cast preserves N1 5.00 and P1 2.00, sorted by SKU.

These are hand-derived unaligned result tables, not captured output. Missing-schema/dependency notices may appear on stderr; they are not data rows. An unexpected error means stop and inspect the first failing file/statement before continuing.

### Deliberately test the domain boundary
After Run it, run reject.sql from this same code folder with the command below. It is supposed to fail and stops at the insert. No BAD row should be committed. This is not part of the successful result table.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/reject.sql
```
Expected output, not yet run: a nonzero exit and a diagnostic naming `ck_nonnegative_amount` (typical message: value violates a domain check). It is not a captured error. Re-run lesson.sql to reset before practicing a different rejection.

## How it works
The domain is created before the table that uses it. The enum and composite type have different jobs: order_state constrains a field; price_quote bundles output fields. Parentheses around `(quote).sku` disambiguate composite field access.

The `WITH quotes` expression names a query result just for this statement; lesson 04 develops that pattern. `bool_and` returns true only when all non-NULL input Boolean values are true; the required quantity column avoids ambiguity here.

Test map: the main file checks default/NULL semantics and typed extraction. The reject file deliberately violates ck_nonnegative_amount. In a separate IDE transaction, changing the trial insert to a duplicate SKU tests uq_products_sku; a NULL price tests NOT NULL; an unknown product_id tests fk_orders_products; an end date before start tests ck_orders_dates. Roll back each failed trial before trying the next. Error wording is version-dependent; rely on the named constraint, not a guessed whole message.

## Try it
Keep db running after Run it. The starter resets the disposable schema, except lesson 03 which expects the already-applied migrations and rolls back its trial column.

1. **Guided:** Add a named upper bound of 10 to quantity. Use bool_and to check the existing seed; the one output cell should be t.
2. Copy the single starter file into your code folder. This is a file copy, not a folder copy; setup includes use the absolute container /scripts path. Without a pack create the file from the complete starter listing. Edit only your working copy and save it.

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\starter\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/starter/exercise.sql ./exercise.sql
```

Expected output, not yet run: no text after a successful copy.

**File: `exercise/starter/exercise.sql`** (copy to `code/exercise.sql`)
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
-- TODO: add a named CHECK enforcing quantity <= 10 on app.orders.
-- TODO: show whether every existing quantity is <= 10 using bool_and.
```

3. Fill the TODOs, save, then run your working file from this code folder.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/exercise.sql
```

Target after completing the TODOs:

**Expected output, not yet run:**

```text
all_quantities_valid
t
```

The target is for the completed program, not the untouched starter, which deliberately may return no rows or an uncorrected value.

4. **Change:** Try an insert with quantity 11 in a disposable transaction. Explain why the new check, not the lower bound, rejects it.
5. **Stretch (optional):** Write a migration plan from the enum to a lookup table if business users need translated state descriptions.

<details><summary>Solution (open after trying)</summary>

**File: `exercise/solution/exercise.sql`**
```sql
\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
ALTER TABLE app.orders ADD CONSTRAINT ck_orders_quantity_limit CHECK (quantity <= 10);
SELECT bool_and(quantity <= 10) AS all_quantities_valid FROM app.orders;
```

The solution implements the guided TODOs using the worked example's constructs. Compare its rows with the target above. To compare in your workspace, repeat the starter-copy step with only the source directory changed from starter to solution, then run the exact exercise command above:

**Terminal (PowerShell; folder: this lesson `code/`)**
```powershell
Copy-Item ..\exercise\solution\exercise.sql .\exercise.sql
```

**Terminal (macOS/Linux; folder: this lesson `code/`)**
```bash
cp ../exercise/solution/exercise.sql ./exercise.sql
```

</details>

### Stop and clean up before the next lab
Close IDE connections first. These commands apply only to this named disposable project.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 stop
docker compose -p code101-db201-02 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: variable stop progress, then:

```text
db exited
```

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 down -v --remove-orphans
```

Expected output, not yet run: Compose removes this project container/network and saved volume; exact progress text varies. **-v destroys saved database data**, including the restored target in lesson 11. It does not erase other projects or the host dump file. Never use it on valuable data.

**Terminal (all OS; folder: this lesson `code/`)**
```powershell
docker compose -p code101-db201-02 ps -a --format "{{.Service}} {{.State}}"
```

Expected output, not yet run: no service rows; port 5432 is no longer held by this project.

## Check yourself
1. When is a lookup table better than an enum?
   <details><summary>Answer</summary>When values change often, need metadata, or are administered as business data.</details>
2. Find the bug: CHECK(price >= 0) is enough to require a price.
   <details><summary>Answer</summary>NULL makes the check unknown, which passes. Add NOT NULL on the column.</details>
3. Do composite values inherit all table constraints?
   <details><summary>Answer</summary>No. A composite describes fields and types; table constraints do not automatically apply outside its table.</details>

## Common mistakes
No new error transcript has been captured. These are symptoms; wording marked typical message is illustrative, not observed output.

| Symptom | Cause | Fix |
|---|---|---|
| Compose cannot find its configuration (typical message) | Terminal is in the wrong folder | Recover to code using Step 1; keep code/exercise siblings. |
| Old behavior persists | Unsaved file, hidden .sql.txt extension or wrong project | Save, check filename extensions and use the exact -p name in every command. |
| Startup cannot claim 5432 (typical message) | Another lab owns the host port | Stop the previous lab from its own code folder; never kill unrelated processes. |
| An omitted state differs from an explicit NULL state | DEFAULT only fills an omitted value | Use the default by omitting the column; keep NOT NULL. |
| A quote with a negative amount can be constructed | The composite amount is numeric, not the domain | Keep persistence validation at the table boundary; select a domain field type if needed. |
| An IDE rejects a backslash line (typical message) | psql meta-commands were sent as SQL | Use psql for whole scripts; select only server SQL in an IDE. |

## Best practice
Keep CHECK rules row-local and use dedicated constraint types for relationships. Source: [PostgreSQL 17: constraints](https://www.postgresql.org/docs/17/ddl-constraints.html).

## Going further
Official PostgreSQL **17** references checked for this draft:
- [PostgreSQL 17: constraints](https://www.postgresql.org/docs/17/ddl-constraints.html)
- [CREATE DOMAIN](https://www.postgresql.org/docs/17/sql-createdomain.html)
- [Enums](https://www.postgresql.org/docs/17/datatype-enum.html)
- [Composite types](https://www.postgresql.org/docs/17/rowtypes.html)

This returns in [lesson 11](../phase-4-operations-and-security/11-roles-rls-backup-and-pooling.md): every schema/query/routine decision also needs a permission and recovery story.

## Summary
- You worked through how to choose between a CHECK, domain, enum and lookup table.
- You worked through how to explain NULL behavior and enforce a cross-column invariant.
- You worked through how to construct and read a composite value without treating it as a constrained table.
- The code and derived output remain written but not run; the draft notice is intentional.

## Next lesson
[03. Migrations with plain SQL and a small runner](../phase-1-schema-design/03-plain-sql-migrations.md): Apply ordered migrations using a ledger and transactional runner.
