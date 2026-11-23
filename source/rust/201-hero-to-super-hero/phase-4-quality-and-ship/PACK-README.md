# Rust 201: Phase 4 Quality And Ship

**Written (not run).** Lesson code, feature tests, HTTP paths, SQL and container behavior have not been executed. Expected results are reasoned draft targets, not captures. Static checking checks only text/source/output parity and JSON parsing.

## Prerequisites and extraction
Finish Rust 101 and earlier Rust 201 phases. Use Rust/Cargo 1.100.0, edition 2024, and your Rust 101 editor. Windows: right-click the ZIP, Extract All. macOS: double-click. Linux: use the file manager Extract action. Open this phase folder after extraction. Every lesson has code, exercise/starter, exercise/solution and verify.json. Each package stands alone: no root Cargo workspace or earlier phase files are needed.

Source downloads are optional: the matching lessons show every source, manifest, starter, solution and configuration in full. Read them under `tutorials/rust/201-hero-to-super-hero/phase-4-quality-and-ship/` in https://github.com/Uee03/Code101 (Code, Download ZIP, or git clone). The Rust backend capstone at https://github.com/Uee03/Code101/tree/main/capstones/backend-rust owns full data/Keycloak/deployment integration.

Lesson 09 supplies unit, documentation and tests/ integration examples. Lesson 10 is a bounded in-memory API, not the backend capstone: no durability, authentication or multi-replica sharing. Its Dockerfile has dependency, build and non-root runtime stages, checked Rust 1.100.0 Bookworm and dated Debian tags, explicit placeholder targets, and a loopback-only publish command. Dockerfiles and commands are written only; no image was built or started.

## Lessons and primary future commands
Run each command from its stated folder, the same on Windows, macOS and Linux. These are instructions for a later learner run, not actions performed for this draft.

| Lesson | Working folder in this phase | Command |
|---|---|---|
| 09. Testing Rust code | `09-testing-rust-code/code` | `cargo run --quiet` |
| 10. Mini project: notes API | `10-mini-project-notes-api/code` | `cargo run --quiet -- --self-check` |

Use cargo test in that same package root to exercise the supplied feature tests later. Lesson 09 also explains --lib, --test title_contract and --doc. Tests are educational source; none ran during authoring. Cargo.lock is intentionally absent: cargo creates it on first build. Keep/review it for an application. Exact direct crate pins do not freeze transitive versions.

## Exercise route
For each lesson, copy the starter folder directly into your existing $HOME/code101/rust201 parent and rename the copy tryNN, using that lesson's two-digit number. Do not copy starter inside an already-created tryNN. The lesson also provides the full typed route. Start in tryNN next to Cargo.toml, fill the TODOs, then use that lesson's command and cargo test. The complete guided answer is in exercise/solution; Rung 2 changes and Rung 3 design choices remain learner work.

## Verification and limits
verify.json records future deterministic example/solution runs only. It does not execute feature test suites. For web lessons these commands select an in-memory no-listener branch. The SQLx spec selects --describe and does not prove SQL against Postgres. Later runtime approval must cover actual compilation, tests, database behavior, JWT acceptance/rejection and Docker behavior separately. No compiler error transcript or variable runtime log is invented.

## Stop and clean up
Primary commands exit on their own. Optional real servers stop with Ctrl+C. Lesson 07 shows start, status, logs, readiness and `docker compose -p rust201-sqlx down -v --remove-orphans` in full; that cleanup destroys only the named disposable lesson database. Lesson 10 shows build/run/status/logs, runtime uid inspection, stop and named container/image removal. Do not leave an optional server/container running. Never use broad prune commands against unrelated work.

## Assets and generated files
No art is used; every lesson has assets: []. No lockfile, private .env, compiled binary or target directory was generated for this pack. Docker's dependency stage will create its own lock on a future build; the lesson explains why this teaching image is not yet a fully reproducible release.
