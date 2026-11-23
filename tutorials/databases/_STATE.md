# Databases track state

Updated: 2026-11-23. Status: **verified**. Level 101 complete: 12 lessons, 3 phases.

| Lesson | Phase | Status | Evidence |
|---|---|---|---|
| 01-what-a-database-is | phase-1-first-queries | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 02-connect-with-a-tool | phase-1-first-queries | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 03-tables-and-data-types | phase-1-first-queries | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 04-reading-data | phase-1-first-queries | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 05-changing-data | phase-2-shaping-data | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 06-keys-and-relationships | phase-2-shaping-data | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 07-joining-tables | phase-2-shaping-data | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 08-summaries | phase-2-shaping-data | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 09-good-design | phase-3-designing | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 10-transactions | phase-3-designing | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 11-indexes-and-explain | phase-3-designing | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |
| 12-library-project | phase-3-designing | verified | Repository verifier PASS; SQL and exercise solution run; exact output in lesson. |

## Environment and decisions
- Windows 11; Docker CLI/Engine 29.9.3; Compose 5.7.0. docker info confirms engine running. No host PostgreSQL or psql install. Docker required a registry PATH refresh in the author shell.
- Official postgres:17-alpine confirmed on Docker Hub and pulled 2026-11-23. Digest: sha256:f9cf3e1f0066f0eb0c48707d864f0ac5941e9ff454a072077d97a4d278d07d73. Pins major/flavour, not immutable future patches; never latest.
- Only 127.0.0.1:5432:5432 published. Independent, sequential labs; named pg_data volumes and readiness healthchecks. No custom images or art. Every code file and full generated .env shown in each lesson; identical configuration differences explicitly listed.
- Author ran finished SQL, all starters and all solutions before copying code into lessons. Triggered real syntax, missing-relation, not-null, foreign-key, unique, check, password, busy-port, refused-connection and read-only permission errors. _captures.json preserves raw evidence.
- The image trusts some local in-container connections. The actual wrong-password error was captured using network host db, not a trusted loopback/socket connection. Connection refused was captured with a temporary Docker client while the server was stopped.
- JetBrains and Microsoft VS Code UI steps/fields checked against official vendor documentation. IDE clicks and Npgsql integration are not automated verification claims. Visual Studio has an explicit provider limitation note; installing Npgsql alone does not provide Server Explorer integration.
- Lesson 12's run.sql is a first-run script (creates a role); reset its disposable volume to rerun. Exercises reset schemas. Backup/restore was manually run into a separate database, including a binary-safe docker compose cp round trip. The final book report includes a zero-loan book.
- Verification is smoke-only: engine, temporary up --wait, one SQL entry script and one solution, always down -v --remove-orphans. No test suites, linters or benchmarks. No UNVERIFIED lessons; no pending decisions.
- Learner time: 25 minutes most lessons; 45 for initial environment orientation and the integrated project. All helper authoring scripts are removed before delivery; raw captures/verifier evidence remain within this track.

Final sequential recheck, Docker resource inventory and pack build are recorded in VERIFICATION.md. No commits. Shared context, scripts, docs and other tracks are untouched by this task; dist/packs outputs are generated only by the explicitly requested build command.

Docker cleanup: all author projects, code101-verify-* projects, named volumes and networks removed. A single anonymous volume from the intentionally failed port-allocation probe was identified by its creation time (2026-11-23 06:12:12Z), verified unused, and removed by exact name. Final inventory: zero containers, zero volumes, only bridge/host/none networks. No custom images built; the official pulled PostgreSQL image remains as shared toolchain cache.

Cross-track dependency resolved: tutorials/docker/101-zero-to-hero/phase-1-containers/01-what-is-a-container.md now exists, so all 12 prerequisite links resolve. The Docker track was authored by its owner and was not edited by this task.

Packs built successfully: 3 phase ZIPs and databases-101-all.zip in dist/packs. All are below 25 MB; archive inventory contains no generated .env, dump files or temporary author helpers.

101 text fixes (no code changed, nothing run): optional source-pack sentence (repo + Download ZIP/git clone) and a make-your-own-folder Step 1 replace the unzip wording; author smoke blocks removed; time bullets added (01 about 45, 12 about 75 in two sittings with a marked break); Common mistakes gained wrong-folder, forgotten-.env, Docker-not-running and busy-port rows (typical message marked where not captured); Try it texts no longer give the answer away.
