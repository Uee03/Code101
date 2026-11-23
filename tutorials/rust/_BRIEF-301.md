# Rust 301 - Super Hero to Legendary

Audience: finished Rust 201 (lifetimes, traits and generics, iterators, errors, Tokio, Axum, SQLx, Tower, testing, container basics) and the [backend-rust capstone](../../capstones/backend-rust/README.md). Nine standalone lessons in three phases; numbering restarts at 01. Voice: trade-offs, failure modes, "when not to use this", measurements to take (never invented numbers), ADR-style decisions and production checklists. Every lesson follows the template (outcomes, recap, predict-before-run, three-rung exercise with starter and solution, check yourself, common mistakes, best practice with source, summary) and adds sections "When not to use", "Failure modes to review", "Measurements to take" and a production checklist where it applies.

## Delivery and honesty policy
Policy of 2026-11-23: no code, compiler, package manager, server, Docker or lab is executed while authoring. The only checks are `python scripts\verify_labs.py --static rust/301` (compares lesson text with `code/` files and expected output; parses `verify.json`; it does not parse Rust, Protocol Buffers, TOML schema or dependencies) and `python scripts\build_packs.py rust-301` (zips the sources into the ignored `dist\packs`). All lessons carry `verified: not yet run`, the verbatim draft notice under the H1 and status `written (not run)`. Expected outputs are derived by reading the code and are labelled "not yet run". Error texts are described as "typical message" unless known exactly. Lesson 06 prints and promises no timing numbers.

Edits are restricted to `tutorials/rust` and `source/rust/301-super-hero-to-legendary`, plus the generated `dist/packs` archives. No art (`assets: []`), no secrets (demo values are labelled), no `Cargo.lock`: cargo creates it on the first build. All text is UTF-8 without BOM.

## Sequence
| Phase | Lesson | Build / guided exercise | Time |
|---|---|---|---|
| phase-1-advanced-language | [01. Advanced traits and the type-state pattern](301-super-hero-to-legendary/phase-1-advanced-language/01-advanced-traits-and-type-state.md) | sealed `Invoice<Draft/Submitted/Approved>` with a `compile_fail` doc test / `Connection<Closed/Open>` with PhantomData | 55-70 min |
| phase-1-advanced-language | [02. Unsafe Rust and FFI](301-super-hero-to-legendary/phase-1-advanced-language/02-unsafe-rust-and-ffi.md) | `build.rs` + `cc` compiling C Adler-32, `unsafe extern`, safe wrappers, unsafe lint policy / safe `pair_mut` | 65-80 min |
| phase-1-advanced-language | [03. Declarative and procedural macros](301-super-hero-to-legendary/phase-1-advanced-language/03-macros.md) | workspace with four `macro_rules!` macros and a `syn`/`quote` derive / recursive `max_of!` | 70-90 min |
| phase-1-advanced-language | [04. Send, Sync and fearless concurrency](301-super-hero-to-legendary/phase-1-advanced-language/04-send-sync-and-fearless-concurrency.md) | scoped threads, channel, `Arc<Mutex>`, atomics, threads vs async table / `parallel_max` | 65-85 min |
| phase-2-architecture-and-performance | [05. Hexagonal architecture in Rust](301-super-hero-to-legendary/phase-2-architecture-and-performance/05-hexagonal-architecture.md) | domain, ports, adapters, composition root, generics vs dyn ADR, architecture test / `StepClock` fake | 70-90 min |
| phase-2-architecture-and-performance | [06. Performance and benchmarks](301-super-hero-to-legendary/phase-2-architecture-and-performance/06-performance-and-benchmarks.md) | Criterion benches, counting allocator, measurement protocol / allocation-light `csv_line` | 70-90 min |
| phase-2-architecture-and-performance | [07. gRPC with tonic](301-super-hero-to-legendary/phase-2-architecture-and-performance/07-grpc-with-tonic.md) | full `.proto`, `build.rs`, unary and streaming service, deadlines, graceful stop / `low_stock` field | 75-95 min |
| phase-3-production | [08. Supply chain and security](301-super-hero-to-legendary/phase-3-production/08-supply-chain-and-security.md) | `deny.toml`, scheduled audit CI, toolchain pin, distroless non-root `Dockerfile`, reproducibility test / `redact` | 75-95 min |
| phase-3-production | [09. WebAssembly, release engineering and the production review](301-super-hero-to-legendary/phase-3-production/09-webassembly-and-release-engineering.md) | `wasm-bindgen` slug module, CSP page, tag-driven release workflow, nine-lesson checklist / review and fix of a flawed file | 90-120 min |

## Version and API decisions
Target Rust/Cargo 1.100.0, edition 2024, as in Rust 201 (not reprobed). Direct crates are exact-pinned (`=`) in every manifest and were read from the crates.io API on 2026-11-23: cc 1.11.3, syn 3.0.10, quote 1.0.47, criterion 0.8.2 (default features, MSRV 1.86), tonic 0.14.9, tonic-prost 0.14.9, tonic-prost-build 0.14.9, prost 0.14.6, protoc-bin-vendored 3.3.0, tokio 1.54.1, tokio-stream 0.1.19, subtle 2.6.1, wasm-bindgen 0.2.130 (the CLI is pinned to the same version). These are teaching versions, not a latest-version or advisory-free claim. Transitive resolution and every build remain unverified.

API facts checked in documentation: `tonic::include_proto!`, `tonic_prost_build::compile_protos`, `serve_with_incoming_shutdown` and `#[tonic::async_trait]` follow the examples in the tonic repository (edition 2024); `syn` 3 `DeriveInput`, `Fields` and `Field.ident` were read on docs.rs (syn 3 renames some type variants but not those used); cargo-deny keys follow the cargo-deny book's own example configuration; criterion 0.8's default features include the pure-Rust plotters backend. `unsafe extern`, `#[unsafe(no_mangle)]` and `unsafe { std::env::set_var }` follow edition 2024 rules. `strip` is not used for the WebAssembly profile because its interaction with `wasm-bindgen` was not verified.

Known uncertainties for the first real run: exact `deny.toml` schema for the installed cargo-deny version; `tonic_prost_build::compile_protos` include-path behaviour with a single proto; `protoc-bin-vendored` availability on each platform; whether the two `Dockerfile` base tags are still current; the exact `Err` text of lints and linker errors (all labelled "typical").

## Tier 1 sources checked
- [The Rust Book: advanced traits](https://doc.rust-lang.org/book/ch20-02-advanced-traits.html)
- [The Rust Book: unsafe Rust](https://doc.rust-lang.org/book/ch20-01-unsafe-rust.html)
- [The Rust Book: macros](https://doc.rust-lang.org/book/ch20-05-macros.html)
- [The Rust Book: fearless concurrency](https://doc.rust-lang.org/book/ch16-00-concurrency.html)
- [The Rust Book: trait objects](https://doc.rust-lang.org/book/ch18-02-trait-objects.html)
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) (meet safe and unsafe, Send and Sync, atomics)
- [Rust Reference: macros by example](https://doc.rust-lang.org/reference/macros-by-example.html) and [procedural macros](https://doc.rust-lang.org/reference/procedural-macros.html)
- [Rust Reference: traits and dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) (future proofing, macros, flexibility)
- [Microsoft Rust guidelines](https://microsoft.github.io/rust-guidelines/)
- [std::thread::scope](https://doc.rust-lang.org/std/thread/fn.scope.html) and [atomic Ordering](https://doc.rust-lang.org/std/sync/atomic/enum.Ordering.html)
- [GlobalAlloc](https://doc.rust-lang.org/std/alloc/trait.GlobalAlloc.html) and [the global_allocator attribute](https://doc.rust-lang.org/reference/runtime.html#the-global_allocator-attribute)
- [The Cargo Book: build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html), [profiles](https://doc.rust-lang.org/cargo/reference/profiles.html), [Cargo.toml vs Cargo.lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html), [SemVer compatibility](https://doc.rust-lang.org/cargo/reference/semver.html)
- [cc 1.11.3](https://docs.rs/cc/1.11.3/cc/), [syn 3.0.10](https://docs.rs/syn/3.0.10/syn/), [quote 1.0.47](https://docs.rs/quote/1.0.47/quote/)
- [criterion 0.8.2](https://docs.rs/criterion/0.8.2/criterion/) and the [Criterion.rs user guide](https://criterion-rs.github.io/book/index.html)
- [tonic 0.14.9](https://docs.rs/tonic/0.14.9/tonic/) and [tonic-prost-build 0.14.9](https://docs.rs/tonic-prost-build/0.14.9/tonic_prost_build/); [tonic examples](https://github.com/hyperium/tonic/tree/master/examples)
- [Protocol Buffers proto3 guide](https://protobuf.dev/programming-guides/proto3/) and [gRPC status codes](https://grpc.io/docs/guides/status-codes/)
- [Tokio tutorial](https://tokio.rs/tokio/tutorial) and [tokio spawn_blocking](https://docs.rs/tokio/1.54.1/tokio/task/fn.spawn_blocking.html)
- [RustSec advisory database](https://rustsec.org/) and the [cargo-deny book](https://embarkstudios.github.io/cargo-deny/)
- [subtle 2.6.1](https://docs.rs/subtle/2.6.1/subtle/)
- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/) and [Dockerfile USER](https://docs.docker.com/reference/dockerfile/#user)
- [Rust and WebAssembly book](https://rustwasm.github.io/docs/book/) and [wasm-bindgen guide](https://rustwasm.github.io/docs/wasm-bindgen/)
- [The Rust Performance Book: benchmarking](https://nnethercote.github.io/perf-book/benchmarking.html) (secondary, widely used)

## Scope boundary
[capstones/backend-rust](../../capstones/backend-rust/README.md) owns the full service, Postgres role and migration design, Keycloak/JWKS, scopes and roles, API craft and OWASP hardening; lessons 05, 07, 08 and 09 point there instead of duplicating it. Lesson 09's production checklist is the review tool to use against that capstone. The capstone uses its own independently versioned stack; do not combine manifests blindly.
