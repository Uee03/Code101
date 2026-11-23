# Rust 201 - Hero to Super Hero

Audience: completed Rust 101, with 1-2 years of experience. Ten standalone lessons in four phases; numbering restarts at 01. Assume ownership, Result, structs and CLI work; explain why each new abstraction earns its cost. Teach alternatives with Why this, not that, measurable outcomes, recap answers, predict-before-run, Mermaid structure, three-rung exercises, answers and summary. Times include reading, typing and practice, not just running the sample.

## Delivery and honesty policy
No cargo/rustc, builds, tests, servers or Docker are executed while authoring. The only check is `python scripts/verify_labs.py --static rust/201`; it compares lesson/source lines and expected output and parses verify.json, not Rust syntax, dependencies or runtime behavior. The separately requested `python scripts/build_packs.py rust-201` packages text/source into ignored dist/packs archives. All lessons use `verified: not yet run`, status is `written (not run)`, and every H1 is followed by the owner's verbatim draft notice. Outputs are derived from source and labeled expected output, not yet run; changing logs/status messages are described, not fabricated.

Edits are restricted to tutorials/rust and source/rust/201-hero-to-super-hero, plus the explicitly allowed generated dist/packs archives. Rust 101 state and shared context/curriculum/tooling stay unchanged. No art, no real secrets, no Cargo.lock: cargo creates the lock on first build. All text is UTF-8 without BOM.

## Sequence
| Phase | Lesson | Build / guided exercise | Time |
|---|---|---|---|
| phase-1-core-skills | [01. Lifetimes demystified](201-hero-to-super-hero/phase-1-core-skills/01-lifetimes-demystified.md) | borrowed longer/first-line helpers / shorter with an explicit tie policy | 40-50 min |
| phase-1-core-skills | [02. Traits and generics](201-hero-to-super-hero/phase-1-core-skills/02-traits-and-generics.md) | Summary implementations with a bounded generic renderer / shared entry prefix | 40-50 min |
| phase-1-core-skills | [03. Iterators and closures](201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-closures.md) | borrowed filter-map-sum / triple retained items | 40-50 min |
| phase-1-core-skills | [04. Error handling in libraries and apps](201-hero-to-super-hero/phase-1-core-skills/04-errors-in-libraries-and-apps.md) | typed thiserror library errors plus anyhow context / minimum two | 45-55 min |
| phase-2-async-and-web | [05. Async Rust and Tokio](201-hero-to-super-hero/phase-2-async-and-web/05-async-rust-and-tokio.md) | joined waits, owned spawn and timeout / uppercase names | 50-65 min |
| phase-2-async-and-web | [06. A web API with Axum](201-hero-to-super-hero/phase-2-async-and-web/06-a-web-api-with-axum.md) | Axum typed routes and DTO/error responses / 40-character title policy | 65-80 min |
| phase-3-data-and-security | [07. Postgres with SQLx](201-hero-to-super-hero/phase-3-data-and-security/07-postgres-with-sqlx.md) | bound runtime SQLx queries and rollback / control-character rejection | 65-85 min |
| phase-3-data-and-security | [08. Authentication middleware with Tower](201-hero-to-super-hero/phase-3-data-and-security/08-authentication-middleware-with-tower.md) | Tower auth layer and explicit JWT claims / fixed subject policy | 70-90 min |
| phase-4-quality-and-ship | [09. Testing Rust code](201-hero-to-super-hero/phase-4-quality-and-ship/09-testing-rust-code.md) | unit, doc and integration tests / Unicode boundary assertions | 50-65 min |
| phase-4-quality-and-ship | [10. Mini project: notes API](201-hero-to-super-hero/phase-4-quality-and-ship/10-mini-project-notes-api.md) | bounded notes lifecycle and cached non-root image / version route | 100-130 min, two sittings |

## Version and API decisions
Target Rust/Cargo 1.100.0, edition 2024, selected from the existing 101 environment; not reprobed. Direct crates are exact-pinned in every manifest: thiserror 2.0.17, anyhow 1.0.100, Tokio 1.48.0, Axum 0.8.6, Serde 1.0.228, serde_json 1.0.145, SQLx 0.8.6, Tower 0.5.2, jsonwebtoken 10.1.0, tracing 0.1.41 and tracing-subscriber 0.3.20. Version-specific docs were fetched before writing the examples. These are checked teaching versions, not a latest-version or vulnerability-free claim. Transitive resolution and builds remain unverified.

SQLx disables defaults and selects Postgres, runtime-tokio and tls-rustls. It uses query/query_as functions and tuple FromRow, never query! or query_as!, so a live DB is not needed at compile time. Docker Postgres uses a disposable loopback-only bootstrap superuser and is not production identity/privilege guidance. The production boundary is the capstone. JWT uses an explicit rust_crypto provider, fixed HS256 policy, required exp/nbf/iss/aud/sub, trusted audience/issuer, no signature bypass, and no server fallback secret. Fixed test keys are public fixtures only.

The notes project is deliberately in-memory and unauthenticated, with bounded state, body/title limits, deterministic ordering, metadata-only structured logs and graceful SIGINT shutdown. Its three-stage Dockerfile caches dependencies with explicit minimal targets, rebuilds real src, and runs uid 10001. The stage-local lock is created only on a future build. Promote real releases with reviewed lockfiles, runtime checks and image digests.

## Tier 1 sources checked
- [The Rust Book: lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)
- [The Rust Book: traits and trait bounds](https://doc.rust-lang.org/book/ch10-02-traits.html)
- [The Rust Book: iterators](https://doc.rust-lang.org/book/ch13-02-iterators.html)
- [The Rust Book: closures](https://doc.rust-lang.org/book/ch13-01-closures.html)
- [thiserror 2.0.17](https://docs.rs/thiserror/2.0.17/thiserror/)
- [anyhow 1.0.100](https://docs.rs/anyhow/1.0.100/anyhow/)
- [Tokio tutorial](https://tokio.rs/tokio/tutorial)
- [Tokio join](https://docs.rs/tokio/1.48.0/tokio/macro.join.html)
- [Tokio spawn](https://docs.rs/tokio/1.48.0/tokio/task/fn.spawn.html)
- [Tokio timeout](https://docs.rs/tokio/1.48.0/tokio/time/fn.timeout.html)
- [Axum 0.8.6 routing, extraction and responses](https://docs.rs/axum/0.8.6/axum/)
- [Serde 1.0.228](https://docs.rs/serde/1.0.228/serde/)
- [serde_json 1.0.145](https://docs.rs/serde_json/1.0.145/serde_json/)
- [DefaultBodyLimit](https://docs.rs/axum/0.8.6/axum/extract/struct.DefaultBodyLimit.html)
- [Tower ServiceExt](https://docs.rs/tower/0.5.2/tower/trait.ServiceExt.html)
- [SQLx 0.8.6 runtime and TLS features](https://docs.rs/sqlx/0.8.6/sqlx/)
- [SQLx query_as and tuple mapping](https://docs.rs/sqlx/0.8.6/sqlx/fn.query_as.html)
- [SQLx transactions](https://docs.rs/sqlx/0.8.6/sqlx/struct.Transaction.html)
- [Postgres official image](https://hub.docker.com/_/postgres)
- [jsonwebtoken Validation 10.1.0](https://docs.rs/jsonwebtoken/10.1.0/jsonwebtoken/struct.Validation.html)
- [jsonwebtoken crypto features](https://docs.rs/crate/jsonwebtoken/10.1.0/features)
- [Axum stateful middleware](https://docs.rs/axum/0.8.6/axum/middleware/fn.from_fn_with_state.html)
- [Tower services and layers](https://docs.rs/tower/0.5.2/tower/)
- [The Rust Book: test organization](https://doc.rust-lang.org/book/ch11-03-test-organization.html)
- [rustdoc: documentation tests](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html)
- [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker cache optimization](https://docs.docker.com/build/cache/optimize/)
- [Dockerfile USER](https://docs.docker.com/reference/dockerfile/#user)
- [tracing 0.1.41](https://docs.rs/tracing/0.1.41/tracing/)
- [tracing-subscriber 0.3.20](https://docs.rs/tracing-subscriber/0.3.20/tracing_subscriber/)
- [Cargo manifests versus locks](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html)
- [Axum Json extractor order and rejection](https://docs.rs/axum/0.8.6/axum/struct.Json.html)
- [Tokio mutex trade-offs](https://docs.rs/tokio/1.48.0/tokio/sync/struct.Mutex.html)
- [Arc shared ownership](https://doc.rust-lang.org/std/sync/struct.Arc.html)
- [Python random-secret helper](https://docs.python.org/3/library/secrets.html)
- [Official Rust image tags](https://raw.githubusercontent.com/docker-library/official-images/master/library/rust)
- [Official Debian image tags](https://hub.docker.com/_/debian)

## Scope boundary
[capstones/backend-rust](../../capstones/backend-rust/README.md) owns the full service, Postgres role/migration design, Keycloak/JWKS, scopes/roles, production API craft and hardening. Lessons 07, 08 and 10 point there rather than duplicating that project. The capstone uses its own independently versioned stack; do not combine manifests blindly.
