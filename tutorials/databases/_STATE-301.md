# Databases 301 state

Updated: 2026-11-23. Status: **written (not run)**. Ten lessons, four phases. Databases 101 and 201 files are unchanged.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01-query-tuning-method | phase-1-performance | written (not run) | Source and lesson authored; counts and pg_stat_statements rows derived from seed formulas; plans not asserted. |
| 02-statistics-vacuum-and-bloat | phase-1-performance | written (not run) | Estimates derived from MCV frequencies and independence arithmetic; size comparisons are booleans, not numbers. |
| 03-partitioning | phase-1-performance | written (not run) | Row placement and pruning counts derived by hand; hash placement deliberately not predicted. |
| 04-transactions-isolation-and-locking | phase-2-concurrency-and-integrity | written (not run) | Single-session output derived; two-terminal results derived from the interleaving; error texts marked typical. |
| 05-connection-pooling | phase-2-concurrency-and-integrity | written (not run) | Budget and Little's law arithmetic derived; pgbouncer.ini explained, not started. |
| 06-row-level-security-in-depth | phase-3-security-and-multitenancy | written (not run) | Policy test table derived by hand; NOLOGIN role with SET LOCAL ROLE simulates policies only. |
| 07-multi-tenant-designs | phase-3-security-and-multitenancy | written (not run) | FK results, schema counts and catalog relation count derived; database per tenant is text only. |
| 08-replication-and-high-availability | phase-4-scale-and-operations | written (not run) | Settings are documented defaults of PostgreSQL 17; no standby is started; conf examples never applied. |
| 09-pgvector-and-search | phase-4-scale-and-operations | written (not run) | Distances and full-text matches derived by hand; image tag from Docker Hub listing, not pulled. |
| 10-other-engines-and-readiness | phase-4-scale-and-operations | written (not run) | Catalog check results derived from schema text; SQL Server and SQLite scripts are reference only. |

## Scope and honesty
- Every lesson carries the mandatory draft notice directly under H1 and `verified: not yet run`. Static checking never upgrades runtime status to verified.
- Nothing was executed: no Docker, psql, SQL, EXPLAIN, pgbouncer, replication, restore, SQL Server, SQLite, Ollama or benchmark. No timings, costs, buffer counts, plan text or speedups are claimed. Error texts are SQLSTATE codes or marked "typical message".
- Source files were written first, then verify.json, starters and solutions; the lesson text copies the files and the static check enforces it.
- Pending runtime review (most likely to differ when first run): the `f` for the pre-ANALYZE estimate in lesson 02 and the `dependencies` estimate of 100; pruning counts in lesson 03 (default partition effect is left to the learner); SQLSTATE `0A000` for a unique index missing the partition key (03), `55000` for update without replica identity (08), `22000` for a wrong vector dimension (09), `23514` for no partition (03); deadlock victim and timing of the two-terminal scenarios (04); `data_checksums`, `ssl`, `archive_mode` defaults of the images (08, 10); the pgvector image tag and its data directory (09); `psql` header-only output for empty results and blank-line-free unaligned output (all); exact pg_stat_statements text normalisation (01, only the shape column is asserted).
- Reference-only content, not validated by execution: `pgbouncer.ini` (05), `primary.conf.example`, `standby.conf.example`, `pitr.conf.example`, `pg_hba.conf.example` (08), `reference/sqlserver.sql` and `reference/sqlite.sql` (10).
- Cross-track links: Ollama 101 lesson 07 (embeddings), capstone platform database chapter and TDD, Databases 201 lessons 07 and 11, Databases 101 lesson 02 IDE steps (through 201 lesson 07 Step 6).

## Static and packaging evidence
Completed on 2026-11-23. The only checks run were the static check and the pack build; no lab program was executed.

```powershell
python scripts\verify_labs.py --static databases/301
```

Actual final output (summary line):

```text
0 passed, 10 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

```powershell
python scripts\build_packs.py databases-301
```

Actual packaging output:

```text
built databases-301-phase-1-performance.zip (26 files)
built databases-301-phase-2-concurrency-and-integrity.zip (24 files)
built databases-301-phase-3-security-and-multitenancy.zip (18 files)
built databases-301-phase-4-scale-and-operations.zip (34 files)
built databases-301-all.zip (4 phases)
```

Generated archives are in dist/packs under the explicit packaging scope exception. No .env, dump or runtime artifact exists in source. Only tutorials/databases and source/databases/301-super-hero-to-legendary were edited (plus the generated zips).
