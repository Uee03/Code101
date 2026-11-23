# Databases 201 state

Updated: 2026-11-23. Status: **written (not run)**. Eleven lessons, four phases. Databases 101 and its existing _STATE.md are unchanged.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01-data-modeling-and-3nf | phase-1-schema-design | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 02-constraints-domains-and-types | phase-1-schema-design | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 03-plain-sql-migrations | phase-1-schema-design | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 04-ctes-and-recursive-queries | phase-2-querying | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 05-window-functions | phase-2-querying | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 06-jsonb | phase-2-querying | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 07-indexes-and-explain | phase-2-querying | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 08-views-and-materialized-views | phase-3-programmable-database | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 09-functions-and-procedures | phase-3-programmable-database | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 10-triggers-and-auditing | phase-3-programmable-database | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |
| 11-roles-rls-backup-and-pooling | phase-4-operations-and-security | written (not run) | Source/lesson authored; expected rows hand-derived from seed; runtime not authorized. |

## Scope and honesty
- Every lesson carries the mandatory draft notice directly under H1 and `verified: not yet run`. Static checking never upgrades runtime status to verified.
- No Docker, psql, SQL, plan query, migration runner, exercise, trigger, security check or backup/restore command was executed. No measured performance claims. Error descriptions are symptoms or explicitly typical, not invented transcripts.
- Checked syntax/semantics against official PostgreSQL 17 docs. Pin remains postgres:17-alpine from 101, not latest or a fabricated patch digest. Existing 101 IDE/Compose pattern reused; IDE UI not clicked during this work.
- Source files were written first, then starters, solutions and verify.json. Full lesson listings were read from those files, never independently retyped. No art or external assets; each front matter has assets: [].
- Pending runtime review: every SQL path and derived result, procedure transaction behavior in real clients, first-run role setup, RLS/grants under actual login connections, backup/restore on a fresh cluster, IDE labels, variable Compose output, and representative-data query plans. Four-row seeds cannot establish index speedups.
- Migration limitations are explicit: manual registration, no checksums/automatic discovery, single initializer and no production orchestration. Lesson 11 setup is first-run only; exercises preserve it. NOLOGIN/SET ROLE is policy simulation, not production authentication.

## Static and packaging evidence
Completed on 2026-11-23. The only check run was the requested static check (twice, both clean). The final check was followed by the authorized ZIP packaging command. No lab program was executed, and runtime status remains **written (not run)**.

Repository-root command:

```powershell
python scripts\verify_labs.py --static databases/201
```

Actual final static-check output:

```text
[STATIC    ] source/databases/201-hero-to-super-hero/phase-1-schema-design/01-data-modeling-and-3nf
[STATIC    ] source/databases/201-hero-to-super-hero/phase-1-schema-design/02-constraints-domains-and-types
[STATIC    ] source/databases/201-hero-to-super-hero/phase-1-schema-design/03-plain-sql-migrations
[STATIC    ] source/databases/201-hero-to-super-hero/phase-2-querying/04-ctes-and-recursive-queries
[STATIC    ] source/databases/201-hero-to-super-hero/phase-2-querying/05-window-functions
[STATIC    ] source/databases/201-hero-to-super-hero/phase-2-querying/06-jsonb
[STATIC    ] source/databases/201-hero-to-super-hero/phase-2-querying/07-indexes-and-explain
[STATIC    ] source/databases/201-hero-to-super-hero/phase-3-programmable-database/08-views-and-materialized-views
[STATIC    ] source/databases/201-hero-to-super-hero/phase-3-programmable-database/09-functions-and-procedures
[STATIC    ] source/databases/201-hero-to-super-hero/phase-3-programmable-database/10-triggers-and-auditing
[STATIC    ] source/databases/201-hero-to-super-hero/phase-4-operations-and-security/11-roles-rls-backup-and-pooling

0 passed, 11 static-checked (not run), 0 failed, 0 unverified (missing tools)
```

This proves source/lesson text consistency and parseable verification specifications only. It is not SQL parsing, runtime verification, performance evidence or a production security review.

Repository-root packaging command:

```powershell
python scripts\build_packs.py databases-201
```

Actual packaging output:

```text
built databases-201-phase-1-schema-design.zip (30 files)
built databases-201-phase-2-querying.zip (34 files)
built databases-201-phase-3-programmable-database.zip (25 files)
built databases-201-phase-4-operations-and-security.zip (10 files)
built databases-201-all.zip (4 phases)
```

Generated archives are in dist/packs under the explicit packaging scope exception. No .env, dump, runtime artifact or temporary authoring helper was generated in source. Authoring-only metadata/helpers were removed from tutorials/databases before final checking. No shared scripts, 101 lessons, context, curriculum or other tracks were edited.
