# Rust 301 state

Last updated: 2026-11-23. **9 lessons written (not run), three phases.**

No Rust compiler, Cargo, build, test, server, `protoc`, Docker, browser, `cargo audit`, `cargo deny` or CI command was executed. Official documentation and the crates.io API were read, and expected outputs were derived from the source. Every lesson carries the mandatory draft notice and `verified: not yet run`. Rust 101 and 201 state is unchanged.

| Lesson | Phase | Status |
|---|---|---|
| [01. Advanced traits and the type-state pattern](301-super-hero-to-legendary/phase-1-advanced-language/01-advanced-traits-and-type-state.md) | phase-1-advanced-language | written (not run) |
| [02. Unsafe Rust and FFI](301-super-hero-to-legendary/phase-1-advanced-language/02-unsafe-rust-and-ffi.md) | phase-1-advanced-language | written (not run) |
| [03. Declarative and procedural macros](301-super-hero-to-legendary/phase-1-advanced-language/03-macros.md) | phase-1-advanced-language | written (not run) |
| [04. Send, Sync and fearless concurrency](301-super-hero-to-legendary/phase-1-advanced-language/04-send-sync-and-fearless-concurrency.md) | phase-1-advanced-language | written (not run) |
| [05. Hexagonal architecture in Rust](301-super-hero-to-legendary/phase-2-architecture-and-performance/05-hexagonal-architecture.md) | phase-2-architecture-and-performance | written (not run) |
| [06. Performance and benchmarks](301-super-hero-to-legendary/phase-2-architecture-and-performance/06-performance-and-benchmarks.md) | phase-2-architecture-and-performance | written (not run) |
| [07. gRPC with tonic](301-super-hero-to-legendary/phase-2-architecture-and-performance/07-grpc-with-tonic.md) | phase-2-architecture-and-performance | written (not run) |
| [08. Supply chain and security](301-super-hero-to-legendary/phase-3-production/08-supply-chain-and-security.md) | phase-3-production | written (not run) |
| [09. WebAssembly, release engineering and the production review](301-super-hero-to-legendary/phase-3-production/09-webassembly-and-release-engineering.md) | phase-3-production | written (not run) |

## Static gate and packs
Command from the repository root: `python scripts\verify_labs.py --static rust/301`. Actual output (no lesson code executed): nine lines `[STATIC    ] source/rust/301-super-hero-to-legendary/<phase>/<lesson>` and `0 passed, 9 static-checked (not run), 0 failed, 0 unverified (missing tools)`.

Command: `python scripts\build_packs.py rust-301`. Actual output: `rust-301-phase-1-advanced-language.zip (39 files)`, `rust-301-phase-2-architecture-and-performance.zip (38 files)`, `rust-301-phase-3-production.zip (26 files)` and `rust-301-all.zip (3 phases)`, written to the git-ignored `dist\packs`.

The static check covers only `code/` files with known text extensions; `.proto`, `.dockerignore` and `.gitignore` files are shown in the lessons but not machine-compared.

## What a first real run must check (in this order)
1. Lessons 01, 04, 05, 08 (native program), 09 (native program): `cargo run`, `cargo test` (std-only or one tiny crate); confirm the two `compile_fail` doc tests really fail to compile.
2. Lesson 02: needs a C compiler; confirm Adler-32 values `0x024d0127` and `0x11e60398`; run `cargo clippy` with a SAFETY comment removed.
3. Lesson 03: confirm `syn` 3.0.10 API usage compiles (`Fields::Named`, `Error::new_spanned`), workspace resolver "3".
4. Lesson 06: confirm the allocator-call booleans; run `cargo bench` and read the real report.
5. Lesson 07: confirm `tonic-prost-build` 0.14.9 with `protoc-bin-vendored`, the generated names (`inventory_server`, `inventory_client`) and clean shutdown.
6. Lesson 08: install `cargo-audit` and `cargo-deny`, check the `deny.toml` schema against `cargo deny init`, build the image, run the two-build hash test.
7. Lesson 09: `wasm32-unknown-unknown` build, `wasm-bindgen` 0.2.130 CLI, the page in a browser; dry-run the release workflow on a fork.
After a real run, set `verified:` to the real date, remove the draft notice (`python scripts\add_draft_notice.py --remove`) and update this file.

## Open items
- Persona walk-through (senior learner) not yet done for Rust 301.
- No capstone chapter links back to this level yet; lesson 09's production checklist is meant to be used on backend-rust.
- Rust track `README.md` still lists only level 101 (not edited here).
