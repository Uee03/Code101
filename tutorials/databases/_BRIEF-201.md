# Databases 201 - Hero to Super Hero

## Audience and promise
Completed Databases 101; roughly one to two years of experience. Assume SQL basics, joins, transactions and an index introduction. Eleven independent PostgreSQL lessons in four phases, numbering restarted at 01. Explain why and when not to use each technique, with full files, a worked example, prediction, guided/change/stretch exercises, answers and phase mixed reviews. Allow 45-90 minutes per lesson, including manual typing and review; the operations chapter is two sittings.

## Scope and sequence
| Phase | Lesson | Main outcome |
|---|---|---|
| phase-1-schema-design | 01. Data modeling and normalization to 3NF | Design a four-table order model in third normal form. |
| phase-1-schema-design | 02. Constraints, domains, enums and types done right | Choose between a CHECK, domain, enum and lookup table. |
| phase-1-schema-design | 03. Migrations with plain SQL and a small runner | Apply ordered migrations using a ledger and transactional runner. |
| phase-2-querying | 04. CTEs and recursive queries | Factor an aggregate query into a named CTE. |
| phase-2-querying | 05. Window functions | Rank detail rows per partition with deliberate tie behavior. |
| phase-2-querying | 06. JSONB without abandoning a schema | Choose relational columns versus optional JSONB attributes. |
| phase-2-querying | 07. Indexes in depth and reading EXPLAIN | Match B-tree, partial, covering and GIN indexes to predicates. |
| phase-3-programmable-database | 08. Views and materialized views | Expose a stable query interface using a view. |
| phase-3-programmable-database | 09. Functions and stored procedures | Write and call a validated PL/pgSQL function. |
| phase-3-programmable-database | 10. Triggers for updated_at and an audit trail | Use a BEFORE row trigger to set updated_at on meaningful changes. |
| phase-4-operations-and-security | 11. Roles, row-level security, backups and pooling | Separate administrative ownership from least-privilege runtime grants. |

## Delivery and safety decisions
- Lesson folder: tutorials/databases/201-hero-to-super-hero; source: source/databases/201-hero-to-super-hero. Every phase has PACK-README.md and every lesson has code, starter, solution and verify.json.
- Reuse the 101 Compose configuration unchanged: postgres:17-alpine, host port 127.0.0.1:5432, named volume, healthcheck, read-only /scripts and /exercises mounts. Full config and exact optional IDE fields in each lesson. No art; assets: []. No custom image build.
- Every lab starts independently. Use a private app schema, snake_case and named keys/checks/indexes, generated identity keys, explicit column lists, exact decimal amounts and deliberate FK deletion rules. Tiny seeds make result tables hand-derivable. Trigger clock values are checked by stable logical comparisons, not fabricated measurements.
- Lesson 03 uses two plain SQL migration files, a conditional psql driver, ledger transaction and container sh wrapper. It is not a production migration framework. Explain destructive rollback and expand/backfill/contract.
- Lesson 07 separates plans.sql from deterministic query output. Never promise an index scan, fabricate costs/timings, or force a planner switch to fake success.
- Lesson 09 distinguishes SELECT function from CALL procedure, caller-owned transactions from top-level transaction-control demonstrations, and stable SQLSTATE contracts. Link to capstones/platform/tutorials/phase-2-data/02-database-and-procedures.md.
- Lesson 11 uses non-owner NOLOGIN test roles via SET ROLE, not password-authentication claims. Test read filtering, write checks and denied commands. Restore a saved archive into a different database using binary-safe compose cp. Explain global roles, logical-backup limits and pooled identity hygiene.

## Verification policy
No smoke tests and no execution of Docker, psql, SQL, shell runners, restores, EXPLAIN, test suites or benchmarks during authoring. Full code is copied into lessons from the source files. Every H1 is followed by the required verbatim draft notice. Front matter remains `verified: not yet run`; state remains `written (not run)`. Outputs are explicitly expected/not run and manually derived. No claimed captured error messages or plan text.
Only allowed check: `python scripts/verify_labs.py --static databases/201`. It parses verify.json and compares source/expected text; it does not validate SQL or execute it. Build the requested generated ZIPs with `python scripts/build_packs.py databases-201`; dist/packs is the explicit output-scope exception. Do not modify shared scripts, context, curriculum or 101 content.

## Sources
Tier 1: versioned https://www.postgresql.org/docs/17/ pages linked per lesson (constraints, domains, enums, composite types, psql, ALTER/LOCK, WITH/CYCLE, windows, JSONB/operators, indexes/EXPLAIN, views/refresh, PL/pgSQL/functions/procedures/triggers, roles/RLS, pg_dump/pg_restore and connection settings). Tier 2 optional index-reading supplement: https://use-the-index-luke.com/; not used for version-specific syntax. IDE and Compose setup reuse the finished 101 pattern, which links official vendor documentation.
