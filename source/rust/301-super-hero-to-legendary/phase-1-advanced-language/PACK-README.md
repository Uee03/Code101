# Rust 301: Phase 1 Advanced Language

**Written (not run).** The code, the tests and the expected output of these lessons were prepared by reading the code and the official documentation. Nothing has been compiled or executed yet. If a result differs, trust your tool's real output and report it.

## Prerequisites and extraction
Finish Rust 201 (at least lessons 02, 04 and 05) and the Rust 101 setup. Use Rust/Cargo 1.100.0, edition 2024. Windows: right-click the ZIP, Extract All. macOS: double-click. Linux: use the file manager Extract action. Every lesson folder has `code`, `exercise/starter`, `exercise/solution` and `verify.json`; each package stands alone, so no root workspace and no earlier phase files are needed.

Downloading is optional: each lesson at `tutorials/rust/301-super-hero-to-legendary/phase-1-advanced-language/` shows every file in full. Read it in https://github.com/Uee03/Code101 (Code, Download ZIP, or git clone).

## Lessons and primary future commands
Run each command in the stated folder; the commands are the same on Windows, macOS and Linux.

| Lesson | Working folder in this phase | Command | Needs |
|---|---|---|---|
| 01. Advanced traits and the type-state pattern | `01-advanced-traits-and-type-state/code` | `cargo run --quiet` | `std` only |
| 02. Unsafe Rust and FFI | `02-unsafe-rust-and-ffi/code` | `cargo run --quiet` | a C compiler (MSVC Build Tools, Xcode tools or gcc/clang); crate `cc` |
| 03. Declarative and procedural macros | `03-macros/code` | `cargo run --quiet -p macro_demo` | crates `syn` and `quote` |
| 04. Send, Sync and fearless concurrency | `04-send-sync-and-fearless-concurrency/code` | `cargo run --quiet` | `std` only |

`cargo test` in the same folder runs the unit tests and doc tests (lessons 01 and 04 contain `compile_fail` doc tests). Lesson 03 uses a Cargo workspace: `cargo test --workspace`. `Cargo.lock` is intentionally absent: cargo creates it on the first build. Exact `=` pins fix only direct dependencies.

## Exercise route
For each lesson, copy the `starter` folder from its `exercise` folder directly into `$HOME/code101/rust301` and rename the copy `tryNN` (the lesson's two-digit number). Do not create `tryNN` first and copy into it. The lesson also gives the typed route with every starter file in full. Fill the TODOs, run the lesson's command, then compare with `exercise/solution`.

## Verification and limits
`verify.json` lists future deterministic runs of the example and the solution, and the unit tests. It does not claim any run happened. Compilation, the C build script, the proc-macro crate and the compile-fail doc tests are all unverified until a later approved run.

## Stop and clean up
Every command here ends by itself. Nothing in this phase starts a server or a container. The folders you create under `$HOME/code101/rust301` can be deleted when you finish; Cargo's `target` folders are the only large output.

## Assets and generated files
No art is used (`assets: []`). No lockfile, `.env` file, compiled binary or `target` directory is part of this pack.
