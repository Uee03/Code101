# Databases 301 - Super Hero to Legendary

## Audience and promise
Completed Databases 201 and the capstone platform (stored functions, RLS-ready schema); about three or more years of experience. Ten PostgreSQL 17 lessons in four phases, numbering restarted at 01. Voice 301: trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), production checklists and ADR-style decisions. Each lesson has full files, a hand-derived worked example, a prediction step, guided/change/stretch exercises with starter and solution, answers and common mistakes. Allow 75 to 120 minutes per lesson.

## Scope and sequence
| Phase | Lesson | Main outcome |
|---|---|---|
| phase-1-performance | 01. Query tuning method | Pick a statement from pg_stat_statements, read EXPLAIN (ANALYZE, BUFFERS), fix anti-patterns, write a tuning record. |
| phase-1-performance | 02. Statistics, vacuum, autovacuum and bloat | Read pg_stats, repair a correlated-column misestimate, compute and tune autovacuum triggers. |
| phase-1-performance | 03. Partitioning | Choose range, list or hash, prove pruning, attach and detach as a retention routine. |
| phase-2-concurrency-and-integrity | 04. Transactions, isolation levels and locking | Reproduce lost update and deadlock with two terminals and fix them; retry rule. |
| phase-2-concurrency-and-integrity | 05. Connection pooling | Compute a connection budget, size a pool with Little's law, know what breaks in transaction pooling. |
| phase-3-security-and-multitenancy | 06. Row-level security in depth | Write per-command policies, apply performance rules, test policies as the restricted role. |
| phase-3-security-and-multitenancy | 07. Multi-tenant designs | Compare shared tables, schema per tenant and database per tenant; composite keys; fan-out migration; ADR. |
| phase-4-scale-and-operations | 08. Replication and high availability | Read replication and archiving settings; RPO/RTO; failover procedure; restore drill. |
| phase-4-scale-and-operations | 09. pgvector and search | Embeddings, distance operators, hnsw versus ivfflat, full-text search, hybrid search. |
| phase-4-scale-and-operations | 10. Other engines and readiness | SQL Server and SQLite differences; catalog checks; a written production readiness review. |

## Delivery and safety decisions
- Lesson folder: tutorials/databases/301-super-hero-to-legendary; source: source/databases/301-super-hero-to-legendary. Every phase has PACK-README.md and every lesson has code, starter, solution and verify.json.
- Compose: the 201 file unchanged (postgres:17-alpine, 127.0.0.1:5432, named volume, healthcheck, read-only /scripts and /exercises mounts) in lessons 02 to 08 and 10. Exceptions: lesson 01 adds a command block loading pg_stat_statements and track_io_timing; lesson 09 uses the pgvector image pgvector/pgvector:0.8.7-pg17-trixie (tag seen on Docker Hub when written; the pgvector README documents the floating pg17 tag). Full file, .env.example and .gitignore shown in every lesson; line-by-line table in lesson 01, differences only elsewhere.
- Seeds are tiny or formula-generated so every result is derivable by hand. Plans (EXPLAIN) are in separate plans.sql scripts and never asserted. No timings, costs, buffer counts or speedups are given.
- Multi-session behaviour (lesson 04) uses two terminals, pg_sleep and documented interleavings; error texts are marked typical unless documented. Lesson 06 uses NOLOGIN role plus SET LOCAL ROLE, a policy simulation, not an authentication test.
- Lesson 05 pgbouncer.ini, lesson 08 *.conf.example files and lesson 10 reference/sqlserver.sql and reference/sqlite.sql are explained and never executed or applied.
- Capstone links: platform database and procedures chapter and TDD. Ollama link: tutorials/ollama/101-zero-to-hero/phase-2-building-with-ollama/07-embeddings-search.md.

## Verification policy
No smoke tests and no execution of Docker, psql, SQL, shell, restores, EXPLAIN, pgbouncer, SQL Server, SQLite or benchmarks during authoring. Full code is copied into lessons from the source files. Every H1 is followed by the verbatim draft notice. Front matter is `verified: not yet run`; state is `written (not run)`. Only allowed checks: `python scripts/verify_labs.py --static databases/301` and `python scripts/build_packs.py databases-301`.

## Sources
Tier 1: https://www.postgresql.org/docs/17/ pages linked per lesson (pgstatstatements, using-explain, routine-vacuuming, planner-stats, ddl-partitioning, transaction-iso, explicit-locking, runtime-config-connection, ddl-rowsecurity, sql-createpolicy, ddl-schemas, continuous-archiving, high-availability, logical-replication, textsearch, catalogs); pgvector README (github.com/pgvector/pgvector); PgBouncer documentation (pgbouncer.org); Microsoft T-SQL reference and SQLite documentation for lesson 10. Tier 2: use-the-index-luke.com; Supabase (RLS performance KB page, platform performance guide); Neon postgres-best-practices skill; pgEdge HA article (all in docs/LINKS.md).
