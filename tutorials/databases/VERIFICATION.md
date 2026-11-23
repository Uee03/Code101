# Databases 101 verification

Date: 2026-11-23. Windows 11, Docker CLI/Engine 29.9.3, Compose 5.7.0.
All SQL, starter and solution files ran before lesson text was generated from them. Real SQL tables, full configuration and deliberately triggered errors are preserved in the lessons and _captures.json. No host PostgreSQL installation. IDE UI guidance is vendor-documentation checked, not an automated GUI test.

## Individual repository smoke checks
Each command ran from the repository root, sequentially, with cleanup in verify.json. Each SQL entry script and exercise solution ran once per temporary project.

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-1-first-queries/01-what-a-database-is`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/01-what-a-database-is

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-1-first-queries/03-tables-and-data-types`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/03-tables-and-data-types

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-1-first-queries/04-reading-data`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/04-reading-data

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-2-shaping-data/05-changing-data`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/05-changing-data

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-2-shaping-data/06-keys-and-relationships`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/06-keys-and-relationships

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-2-shaping-data/07-joining-tables`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/07-joining-tables

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-2-shaping-data/08-summaries`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/08-summaries

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-3-designing/09-good-design`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/09-good-design

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-3-designing/10-transactions`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/10-transactions

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-3-designing/11-indexes-and-explain`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/11-indexes-and-explain

1 passed, 0 failed, 0 unverified (missing tools)
```

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero/phase-3-designing/12-library-project`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/12-library-project

1 passed, 0 failed, 0 unverified (missing tools)
```

## Final recheck after inserting evidence

Command: `python scripts/verify_labs.py source/databases/101-zero-to-hero`

```text
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/01-what-a-database-is
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/02-connect-with-a-tool
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/03-tables-and-data-types
[PASS      ] source/databases/101-zero-to-hero/phase-1-first-queries/04-reading-data
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/05-changing-data
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/06-keys-and-relationships
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/07-joining-tables
[PASS      ] source/databases/101-zero-to-hero/phase-2-shaping-data/08-summaries
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/09-good-design
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/10-transactions
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/11-indexes-and-explain
[PASS      ] source/databases/101-zero-to-hero/phase-3-designing/12-library-project

12 passed, 0 failed, 0 unverified (missing tools)
```

## Docker cleanup after the final verification
Commands: docker ps -a; docker volume ls; docker network ls.
The deliberate failed port-allocation probe left one anonymous image-declared volume. Its creation time matched that probe, it was unused, and it was removed by exact name (no broad prune and no unrelated resources touched). Repeated inventory output:

```text
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
DRIVER    VOLUME NAME
NETWORK ID     NAME      DRIVER    SCOPE
2241ff88a2db   bridge    bridge    local
d9f1d5a54f80   host      host      local
f8a2e3425af8   none      null      local
```

No code101-verify* or author containers, volumes or networks remain. No images were built; the official pulled image remains shared cache. Author helper scripts and intermediate narrative data were removed. Code and lessons are UTF-8 without BOM; no .env or dump files are shipped. The Docker 101 prerequisite markdown belongs to the concurrent Docker task and was not present when checked; the link matches that owner's reserved source path.

## Built source packs

Command: `python scripts/build_packs.py databases-101`

```text
built databases-101-phase-1-first-queries.zip (31 files)
built databases-101-phase-2-shaping-data.zip (33 files)
built databases-101-phase-3-designing.zip (36 files)
built databases-101-all.zip (3 phases)
```

- `dist/packs/databases-101-all.zip`: 52,617 bytes, 100 files; no generated .env, dumps or author helpers.
- `dist/packs/databases-101-phase-1-first-queries.zip`: 15,283 bytes, 31 files; no generated .env, dumps or author helpers.
- `dist/packs/databases-101-phase-2-shaping-data.zip`: 16,612 bytes, 33 files; no generated .env, dumps or author helpers.
- `dist/packs/databases-101-phase-3-designing.zip`: 17,966 bytes, 36 files; no generated .env, dumps or author helpers.

Final navigation recheck: the concurrent Docker task has now written its lesson 01 at the linked path; the prerequisite dependency is resolved. No decisions or UNVERIFIED lessons remain.
