# Rust 301: Phase 2 Architecture and Performance

**Written (not run).** The code, the tests and the expected output of these lessons were prepared by reading the code and the official documentation. Nothing has been compiled or executed yet. If a result differs, trust your tool's real output and report it. Lesson 06 deliberately prints no timing numbers: you take them on your own machine.

## Prerequisites and extraction
Finish phase 1 of this level and Rust 201 lessons 03, 05 and 06. Use Rust/Cargo 1.100.0, edition 2024. Windows: right-click the ZIP, Extract All. macOS: double-click. Linux: use the file manager Extract action. Every lesson folder has `code`, `exercise/starter`, `exercise/solution` and `verify.json`; each package stands alone.

Downloading is optional: each lesson at `tutorials/rust/301-super-hero-to-legendary/phase-2-architecture-and-performance/` shows every file in full, including the `.proto` file and `build.rs`. Read it in https://github.com/Uee03/Code101 (Code, Download ZIP, or git clone).

## Lessons and primary future commands
| Lesson | Working folder in this phase | Command | Needs |
|---|---|---|---|
| 05. Hexagonal architecture in Rust | `05-hexagonal-architecture/code` | `cargo run --quiet` (and `cargo run --quiet -- failing`) | `std` only |
| 06. Performance and benchmarks | `06-performance-and-benchmarks/code` | `cargo run --release --quiet`, then `cargo bench` | crate `criterion` (dev-dependency) |
| 07. gRPC with tonic | `07-grpc-with-tonic/code` | `cargo run --quiet` | crates `tonic`, `prost`, `tokio`; the first build is slow; `protoc` comes from `protoc-bin-vendored` |

`cargo test` in the same folder runs the unit tests. Lesson 07's program opens a TCP port on `127.0.0.1` only, on a free port chosen by the operating system, and closes it before it exits; a firewall prompt may appear and can be denied. `Cargo.lock` is intentionally absent: cargo creates it on the first build; keep it for an application. Exact `=` pins fix only direct dependencies.

## Exercise route
For each lesson, copy the `starter` folder from its `exercise` folder directly into `$HOME/code101/rust301` and rename the copy `tryNN` (the lesson's two-digit number). Do not create `tryNN` first and copy into it. Lesson 07's exercise folder is a complete crate (`Cargo.toml`, `build.rs`, `proto/`, `src/`).

## Verification and limits
`verify.json` lists future deterministic runs. It does not run `cargo bench` (timings vary by machine). Static checking compares lesson text with the `code` files and does not parse Rust, Protocol Buffers or dependencies. The tonic, prost and Criterion versions were read from the registry and docs, not built.

## Stop and clean up
Every command here ends by itself; `cargo bench` takes a few minutes and writes reports into `target/criterion`. Delete the `try` and `lesson` folders and their `target` folders when you finish.

## Assets and generated files
No art is used (`assets: []`). Generated protobuf code is created by `build.rs` inside Cargo's build output folder and is not part of this pack. No lockfile, `.env` file or compiled binary is included.
