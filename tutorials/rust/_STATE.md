# Rust track state

Last updated: 2026-11-23. **Rust 101 reviewed and verified: 12 lessons.**

Environment: Windows 11; rustc 1.100.0 (0ef1bc386 2026-11-09), Cargo 1.100.0 (3acc79c0c 2026-11-05), stable MSVC, edition 2024. Standard library only. No installation, component removal, registry changes, global tools, formatters, linters or test suites.

| Lesson | Phase | Status |
|---|---|---|
| 01. Hello, Rust | 1 | verified |
| 02. Variables and types | 1 | verified |
| 03. Input and math | 1 | verified |
| 04. Making decisions | 1 | verified |
| 05. Loops | 2 | verified |
| 06. Functions | 2 | verified |
| 07. Vectors and HashMaps | 2 | verified |
| 08. Files | 2 | verified |
| 09. Handling errors | 3 | verified |
| 10. Ownership and borrowing basics | 3 | verified |
| 11. Structs, enums and impl blocks | 3 | verified |
| 12. Project: expense tracker | 3 | verified |

## Beginner walk-through findings applied

Review: reviews/rust-101.md (read-only). **Blocker: 1/1 fixed; Should-fix: 22/22 fixed; Nits: 12/12 fixed, none skipped.**

- Blocker: all 12 Before you start sections use the template's verbatim optional-source sentence and repository path. Every exercise has a cargo-new/typed-starter route; copying the optional starter folder has an exact destination and rename, never nesting.
- 01: captured real PowerShell Cargo-not-found text, plus a Cargo-run compile error with src/main.rs and Cargo's closing line.
- 02: warnings are defined as nonfatal; unfinished starters in 05, 07, 08 and 10 point back to this explanation.
- 03: captured Invalid/Empty ParseFloatError panics, the no-trim failure, and Each: inf; explained infinity and the harmless backtrace note.
- 06: captured E0425 for attempting to read main's bill inside show_total.
- 07: re-captured E0382 via Cargo using relative paths, omitted only optional rust-src source-location lines, explained the consumed loop in plain words and the ignorable internal note. Captured vector bounds and missing-key panics. No author's machine path remains.
- 08: literal string line breaks replaced by \n in code, starter and solution. Dropped the second file-reading approach and BufRead/BufReader; added read-only then sum/write checkpoints. Captured CSV-not-found when running inside src, distinct from Cargo.toml-not-found outside a project.
- 09: separate Option checkpoint, then a smaller Result-only reader; honest 50-60 minutes. EOF has Windows Ctrl+Z/Enter and macOS/Linux Ctrl+D instructions, actual UnexpectedEof text and exit code 1.
- 10: defined compiler immutable/mutable wording alongside shared/exclusive; captured E0502 and E0596 with concrete fixes.
- 11: captured E0004 with &Category::Books from the actual halfway exercise, plus E0308 and E0106 from the actual record; defined lifetime and kept the beginner fix as owned String.
- 12: three runnable builds (menu/Add, save/load, self-check), contextual edit regions, 100-120 minutes over two sittings with a marked break. Five exercise edit sites listed; captured halfway Count E0004, Wrong CSV header and Bad cents errors.
- All: replaced all 12 placeholder cause/fix rows, captured diagnostics via cargo run --quiet instead of loose rustc, removed learner-facing maintainer verification sections, retained wrong-folder/unsaved-file guidance.

Nits fixed: installer console/menu and native x64 scope; 01 generated-program heading; precise missing-semicolon location; deleted nonexistent shadowing suggestion; defined binding/shadowing before use; defined method/operator/owned text/standard output; explained independent checks after negative ages; captured bad-age panic; replaced list-style positions wording; 09 exercise now validates both bounds 1-99; 10 exercise chooses shared/editing references rather than filling a string; shortened identical Cargo/setup prose with explicit differing names. No exercise answer is supplied in the task text.

## Smoke verification (real captured output)

Command from repository root: `python scripts/verify_labs.py source/rust/`.

```text
[PASS      ] source/rust/101-zero-to-hero/phase-1-foundations/01-hello-rust
[PASS      ] source/rust/101-zero-to-hero/phase-1-foundations/02-variables-and-types
[PASS      ] source/rust/101-zero-to-hero/phase-1-foundations/03-input-and-math
[PASS      ] source/rust/101-zero-to-hero/phase-1-foundations/04-making-decisions
[PASS      ] source/rust/101-zero-to-hero/phase-2-building-blocks/05-loops
[PASS      ] source/rust/101-zero-to-hero/phase-2-building-blocks/06-functions
[PASS      ] source/rust/101-zero-to-hero/phase-2-building-blocks/07-vectors-and-hashmaps
[PASS      ] source/rust/101-zero-to-hero/phase-2-building-blocks/08-files
[PASS      ] source/rust/101-zero-to-hero/phase-3-real-programs/09-handling-errors
[PASS      ] source/rust/101-zero-to-hero/phase-3-real-programs/10-ownership-and-borrowing
[PASS      ] source/rust/101-zero-to-hero/phase-3-real-programs/11-structs-enums-and-impl
[PASS      ] source/rust/101-zero-to-hero/phase-3-real-programs/12-expense-tracker

12 passed, 0 failed, 0 unverified (missing tools)
```

All original 300-second cold-build timeouts retained. There are 28 smoke commands: code and solution for each lesson, plus four checkpoint builds. Starters and deliberate failing examples were also run separately before copying their code/output into text. captures.json records observed stdout/stderr and exit codes; compiler-output.txt contains the primary real Cargo diagnostic. Optional rust-src location lines are explicitly omitted only in 07; no toolchain component was removed.

Lessons 01 and 12 were replayed from Markdown in clean sandbox projects, not copied from code/: project creation, manifests, typed files, all three project builds, persisted reload, and the no-download exercise starter. The contextual edits reconstruct the finished project. typed-walkthrough.json records those actual outputs. Only Windows runs are claimed; installer dialogs and macOS/Linux alternatives remain documented, not executed. Official Rust/rustup installation pages were fetched again; no installer was run.

## Decisions and boundaries

- No lessons renumbered or split. Most lessons 30-35 minutes; 01 60-90, 08 40-50, 09 50-60, 12 100-120 (two sittings).
- No icons or other art; every lesson has assets: [].
- CSV remains deliberately restricted; disposable practice data only. The project still distinguishes a missing file from corrupt/unreadable data and avoids erasing records to hide errors.
- Full manifests and lockfiles remain visible, but identical settings are explained once. Checkpoint manifests/lockfiles are identical to the finished project's; only main.rs and the presence of the file fixture differ.
- Source and exercise blocks were copied from executed files, never retyped; lesson code/output parity and UTF-8 no BOM checks passed. Final editorial audit also confirmed every template section, verbatim optional-source sentence, valid local links, matching diagnostic files, and no learner maintenance commands or author paths. There are no target folders under source/rust.
- Authored edits confined to tutorials/rust and source/rust; requested packaging generates ignored dist/packs archives. No review, shared context, docs, skills, scripts or other track edited; no commit.

## Packaging

`python scripts/build_packs.py rust-101` completed after the final smoke PASS. Actual output:

```text
built rust-101-phase-1-foundations.zip (54 files)
built rust-101-phase-2-building-blocks.zip (60 files)
built rust-101-phase-3-real-programs.zip (67 files)
built rust-101-all.zip (3 phases)
```

All four archives passed ZIP integrity checks; no target directories or compiled executables/debug libraries are shipped. Every phase is below 25 MB. Final source check: zero target folders under source/rust.

| Built archive | Entries | Size |
|---|---|---|
| `rust-101-all.zip` | 181 | 88,462 bytes |
| `rust-101-phase-1-foundations.zip` | 54 | 23,331 bytes |
| `rust-101-phase-2-building-blocks.zip` | 60 | 25,448 bytes |
| `rust-101-phase-3-real-programs.zip` | 67 | 36,469 bytes |

## Blockers / decisions

UNVERIFIED: none. Decisions needed: none. Nits skipped: none.
