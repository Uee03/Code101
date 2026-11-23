---
track: rust
level: 301
phase: 3
phase_name: production
lesson: "08"
title: "Supply chain and security"
time: "75-95 min"
prerequisites: ["rust-301-02", "rust-301-03", "rust-301-07"]
versions: { rust: "1.100.0 (target)", cargo: "1.100.0 (target)", edition: "2024", subtle: "2.6.1" }
verified: not yet run
source: source/rust/301-super-hero-to-legendary/phase-3-production/08-supply-chain-and-security/
assets: []
---

# 08. Supply chain and security

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain the supply-chain threats of a Rust project and which of them each tool covers.
- Run and configure `cargo audit` and `cargo deny` and wire them into CI.
- Enforce an unsafe and dependency policy, and keep secrets out of source, logs and images.
- Build a minimal non-root container image and test whether your build is reproducible.

## Recap
1. From lesson 03: why is adding a procedural-macro crate a security decision?
   <details><summary>Answer</summary>It runs arbitrary code at build time with your permissions, like a build script.</details>
2. From lesson 02: which lint makes every `unsafe` block need a `SAFETY` comment?
   <details><summary>Answer</summary>The Clippy lint `undocumented_unsafe_blocks`.</details>
3. From lesson 07: what is the supply-chain note about `protoc-bin-vendored`?
   <details><summary>Answer</summary>It ships a prebuilt executable that your build runs without you having compiled it, so it must be reviewed or replaced by a trusted install.</details>

## Why it matters
A typical Rust service has a few direct dependencies and a few hundred transitive ones, written by people you have never met, updated on their schedule, and built on your machine with code that runs during the build. The compiler's safety guarantees say nothing about whether those crates are malicious, abandoned, vulnerable or licensed in a way your company cannot use. Supply-chain security is the discipline of knowing what you build from, checking it continuously, and making the build repeatable and minimal.

## What you will build
A tiny program, `token_check`, that compares secrets in constant time using the `subtle` crate, plus everything around it that a production repository needs: a toolchain pin, a `deny.toml` policy, a CI workflow that audits dependencies daily, a multi-stage `Dockerfile` that ends in a distroless non-root image, and a `.dockerignore`.

## Before you start
- **Prerequisites:** Rust 301 lessons [02, unsafe Rust and FFI](../phase-1-advanced-language/02-unsafe-rust-and-ffi.md), [03, macros](../phase-1-advanced-language/03-macros.md) and [07, gRPC with tonic](../phase-2-architecture-and-performance/07-grpc-with-tonic.md).
- Audience: finished lessons 02, 03 and 07.
- Target Rust/Cargo 1.100.0, edition 2024. Direct crate: `subtle` 2.6.1, pinned exactly and checked on crates.io for this draft (not a claim that it is the latest or advisory-free; checking that is this lesson's job).
- Tools installed later in the lesson: `cargo install --locked cargo-audit cargo-deny` (each takes minutes to compile) and Docker (Docker Desktop on Windows/macOS or Docker Engine on Linux) for the image steps. Docker use is temporary and cleaned up at the end.
- Time: 75-95 min. Two sittings are fine; break after Step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/301-super-hero-to-legendary/phase-3-production/08-supply-chain-and-security/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Save every tab. **No `Cargo.lock` is supplied** because it can only be created by Cargo. You will create it in Step 7 with `cargo generate-lockfile` and, for an application, commit it.

## Steps
### Step 1. Create the folders
**File: `terminal in any folder (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust301/lesson08/src", "$HOME/code101/rust301/lesson08/.github/workflows"
Set-Location "$HOME/code101/rust301/lesson08"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust301/lesson08/src" "$HOME/code101/rust301/lesson08/.github/workflows"
cd "$HOME/code101/rust301/lesson08"
```

### Step 2. The manifest
**File: `Cargo.toml`**
```toml
[package]
name = "token_check"
version = "0.1.0"
edition = "2024"
rust-version = "1.100"
license = "MIT"
publish = false

[dependencies]
subtle = "=2.6.1"

[lints.rust]
unsafe_code = "forbid"

[profile.release]
lto = "thin"
codegen-units = 1
strip = "symbols"
```
- `rust-version = "1.100"` is the minimum Rust version (MSRV): Cargo refuses to build with an older compiler and tells you why, instead of failing with obscure errors.
- `license = "MIT"` states the project's license so that policy tools have something to check; `publish = false` makes `cargo publish` fail, so an internal service cannot be uploaded to crates.io by accident.
- `subtle = "=2.6.1"`: the `=` pins this direct dependency exactly. **A pin in `Cargo.toml` does not pin transitive dependencies; the lockfile does.**
- `unsafe_code = "forbid"` is the policy for this crate (lesson 02).
- `strip = "symbols"` removes symbol names from the release binary: smaller file, but crash backtraces become unreadable unless you keep the unstripped build or debug files. Decide per project.

### Step 3. Pin the toolchain
**File: `rust-toolchain.toml`**
```toml
[toolchain]
channel = "1.100.0"
profile = "minimal"
components = ["clippy", "rustfmt"]
```
With this file in the repository root, `rustup` picks exactly this compiler for the project on every machine (it downloads it if missing). `profile = "minimal"` installs only the compiler, `cargo` and the standard library; `components` adds linting and formatting. Without a pin, "works on my machine" can simply mean "my compiler is newer".

### Step 4. The program
**Predict before you run:** three attempts are made against one expected token. Which are accepted? Why does the program print the attempt number instead of the token?

**File: `src/main.rs`**
```rust
use std::process::ExitCode;

use subtle::ConstantTimeEq;

/// Compares two secrets without stopping at the first different byte.
/// Different lengths are rejected at once: the length of a token is not treated as secret.
fn tokens_match(expected: &str, given: &str) -> bool {
    expected.as_bytes().ct_eq(given.as_bytes()).into()
}

fn main() -> ExitCode {
    // Demo values only. Real secrets come from the environment or a secret store, never from
    // source code, and are never printed or logged.
    let expected = "demo-token-0001";
    let attempts = ["demo-token-0001", "demo-token-0002", "short"];

    let mut accepted = 0;
    for (index, given) in attempts.iter().enumerate() {
        let ok = tokens_match(expected, given);
        println!("attempt {}: {}", index + 1, if ok { "accepted" } else { "rejected" });
        if ok {
            accepted += 1;
        }
    }

    if accepted == 1 {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn equal_tokens_match() {
        assert!(tokens_match("abc", "abc"));
    }

    #[test]
    fn different_tokens_do_not_match() {
        assert!(!tokens_match("abc", "abd"));
        assert!(!tokens_match("abc", "ab"));
        assert!(!tokens_match("abc", ""));
    }
}
```
A normal `==` on strings stops at the first difference, so the time it takes leaks how many leading bytes were right; an attacker can use that **timing side channel** to guess a token one byte at a time. `ct_eq` from the `subtle` crate always looks at every byte. The `Choice` it returns converts to `bool` with `.into()` only at the end. (In real code, compare hashes or MACs of secrets, and use a vetted authentication library; this is the smallest demonstration of the idea.)

### Step 5. The dependency policy
`cargo deny` reads `deny.toml` and fails the build when the dependency graph breaks your rules.

**File: `deny.toml`**
```toml
[graph]
targets = [
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-pc-windows-msvc",
    "aarch64-apple-darwin",
]
all-features = true

[advisories]
unmaintained = "all"
unsound = "all"
yanked = "deny"
ignore = []

[licenses]
confidence-threshold = 0.93
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
    "ISC",
    "Unicode-3.0",
]

[bans]
multiple-versions = "warn"
wildcards = "deny"
deny = [
    { crate = "openssl", use-instead = "rustls" },
    { crate = "openssl-sys", use-instead = "rustls" },
]

[sources]
unknown-registry = "deny"
unknown-git = "deny"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
```
- `[graph] targets` limits the checks to platforms you really build for, so a Windows-only dependency does not matter to a Linux-only service. `all-features = true` checks the largest possible graph.
- `[advisories]` checks the RustSec database (see below). `unmaintained = "all"` and `unsound = "all"` make advisories about abandoned or unsound crates fail the check, including transitive ones; `yanked = "deny"` fails when a locked version has been withdrawn by its author; `ignore = []` is where you list advisories you have *consciously* accepted, each with a reason and an expiry date in a comment.
- `[licenses] allow` is an allow-list: any dependency whose license is not on it fails. Your legal team decides this list; the one here is an example. `confidence-threshold` is how sure the license detector must be about a license it infers from text.
- `[bans]`: `multiple-versions = "warn"` reports crates that appear twice at different versions (bigger binaries, longer builds); `wildcards = "deny"` forbids `*` version requirements; `deny` lists crates you refuse, here the `openssl` family in favour of `rustls` (a policy choice, not a universal rule).
- `[sources]` fail on any registry other than crates.io and on any git dependency. A git dependency has no checksum review path and can change under you; if you need one, allow that single repository by name.
- The exact keys can change between versions of cargo-deny. After installing, run `cargo deny init` in a scratch folder to see the commented template for *your* version and compare, and read the [cargo-deny book](https://embarkstudios.github.io/cargo-deny/).

### Step 6. The CI workflow
**File: `.github/workflows/supply-chain.yml`**
```yaml
name: supply-chain

on:
  pull_request:
  push:
    branches: [main]
  schedule:
    - cron: "17 4 * * *"

permissions:
  contents: read

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install the audit tools
        run: cargo install --locked cargo-audit cargo-deny
      - name: Check that the committed lockfile is complete
        run: cargo metadata --locked --format-version 1 > /dev/null
      - name: Known vulnerabilities (RustSec advisory database)
        run: cargo audit
      - name: Policy (advisories, licenses, bans, sources)
        run: cargo deny check
      - name: Build exactly what the lockfile says
        run: cargo build --release --locked
```
- `on:` runs on every pull request, on pushes to `main`, and **daily on a schedule** (04:17 UTC). The schedule matters: a new vulnerability can be published tomorrow about a crate you did not touch today.
- `permissions: contents: read` gives the workflow's token only read access: least privilege for a job that executes third-party code.
- `cargo install --locked` installs the tools with their own lockfiles. This is slow on every run; in a real pipeline cache the installed binaries or use a prebuilt-binary installer you have reviewed.
- `cargo metadata --locked` fails if `Cargo.lock` is missing or would need changes, which catches "forgot to commit the lockfile".
- `cargo build --locked` builds exactly the locked versions. `uses: actions/checkout@v4` is pinned by tag here for readability; **in production pin third-party actions to a full commit SHA**, because tags can be moved.

### Step 7. Create the lockfile and run the checks
**File: `terminal in $HOME/code101/rust301/lesson08 (all platforms)`**
```powershell
cargo generate-lockfile
cargo install --locked cargo-audit cargo-deny
cargo audit
cargo deny check
```
`cargo generate-lockfile` writes `Cargo.lock` with the exact version and checksum of every crate in the graph; **commit it** for applications (libraries often do not, so that downstream users resolve their own graph). Expected result, not yet run: `cargo audit` downloads the RustSec advisory database, scans `Cargo.lock` and reports either no vulnerabilities or a list of advisories with an id such as `RUSTSEC-YYYY-NNNN`, the crate, the fixed versions and a URL. `cargo deny check` runs the four check groups and reports `ok` or errors per group. Both results depend on the day you run them; nothing is claimed here.

### Step 8. The container image
**File: `Dockerfile`**
```dockerfile
FROM rust:1.100.0-slim-trixie AS build
WORKDIR /app
ENV RUSTFLAGS="--remap-path-prefix=/app=/src --remap-path-prefix=/usr/local/cargo=/cargo"
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release --locked

# distroless "cc" has the C runtime libraries and nothing else: no shell, no package manager.
FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /app/target/release/token_check /app/token_check
USER nonroot:nonroot
ENTRYPOINT ["/app/token_check"]
```
- `FROM rust:1.100.0-slim-trixie AS build`: stage 1, pinned to an exact compiler version and Debian 13 ("trixie") slim variant (the same tags the backend-rust capstone uses). A floating tag such as `rust:latest` changes under you.
- `ENV RUSTFLAGS=...--remap-path-prefix`: rewrites build-machine paths inside the binary (panic messages, debug info) so that the same source built in `/app` or `/home/ana/work` yields the same bytes, and the binary does not leak your directory layout.
- `COPY Cargo.toml Cargo.lock ./` and `COPY src ./src`: only the files the build needs. `Cargo.lock` is required because the next line uses `--locked`.
- `RUN cargo build --release --locked`: **`--locked` makes the build fail if the lockfile does not match the manifest**, instead of silently updating dependencies.
- Stage 2: `gcr.io/distroless/cc-debian13:nonroot` contains the C runtime libraries (our binary uses glibc dynamically) and a non-root user, and nothing else: no shell, no package manager, nothing for an attacker to use after a compromise. `USER nonroot:nonroot` runs the process as an unprivileged user (uid 65532). `ENTRYPOINT` in exec form makes the program process 1, so it receives signals directly.
- The build stage and the run stage use the same Debian release so the glibc the program was linked against matches the one it runs on.

**File: `.dockerignore`**
```text
target
.git
.github
.env
.env.*
*.md
```
`.dockerignore` keeps the **build context** (the files sent to Docker) small and keeps secrets out of it: `target` is huge build output, `.git` holds history, `.env` files hold secrets. A secret that enters the context can end up in an image layer, and layers are forever.

Build, run, inspect and clean up (Docker must be running):

**File: `terminal in $HOME/code101/rust301/lesson08 (all platforms)`**
```powershell
docker build -t code101/token-check:local .
docker run --rm code101/token-check:local
docker image inspect --format "{{.Config.User}}" code101/token-check:local
```
Expected result, not yet run: the build succeeds; the run prints the three lines below and exits with code 0 (`echo $?` on Linux/macOS, `$LASTEXITCODE` in PowerShell); the inspect command prints `nonroot:nonroot`.
```text
attempt 1: accepted
attempt 2: rejected
attempt 3: rejected
```

### Step 9. Test reproducibility
A build is **reproducible** if the same inputs give a bit-for-bit identical output. Test it instead of assuming it. Build twice with no cache, copy the binary out each time and compare hashes.

**File: `terminal in $HOME/code101/rust301/lesson08 (macOS/Linux)`**
```bash
docker build --no-cache --target build -t code101/token-check:build-a .
docker build --no-cache --target build -t code101/token-check:build-b .
docker create --name tc-a code101/token-check:build-a
docker create --name tc-b code101/token-check:build-b
docker cp tc-a:/app/target/release/token_check ./token_check_a
docker cp tc-b:/app/target/release/token_check ./token_check_b
sha256sum token_check_a token_check_b
```

**File: `terminal in $HOME/code101/rust301/lesson08 (Windows PowerShell)`**
```powershell
docker build --no-cache --target build -t code101/token-check:build-a .
docker build --no-cache --target build -t code101/token-check:build-b .
docker create --name tc-a code101/token-check:build-a
docker create --name tc-b code101/token-check:build-b
docker cp tc-a:/app/target/release/token_check ./token_check_a
docker cp tc-b:/app/target/release/token_check ./token_check_b
Get-FileHash token_check_a, token_check_b -Algorithm SHA256
```
Expected result, not yet run: either the two hashes are equal (reproducible for this program and toolchain) or they differ. If they differ, the cause is in the build (embedded timestamps, paths, differing dependency versions, a build script reading the environment); investigate rather than shrug. Do not claim reproducibility without having run this test on your own machine.

Clean up everything this lesson created:

**File: `terminal in $HOME/code101/rust301/lesson08 (macOS/Linux)`**
```bash
docker rm tc-a tc-b
docker image rm code101/token-check:local code101/token-check:build-a code101/token-check:build-b
rm token_check_a token_check_b
```

**File: `terminal in $HOME/code101/rust301/lesson08 (Windows PowerShell)`**
```powershell
docker rm tc-a tc-b
docker image rm code101/token-check:local code101/token-check:build-a code101/token-check:build-b
Remove-Item token_check_a, token_check_b
```
Base images (`rust`, `distroless`) stay in Docker's cache; remove them with `docker image rm` if you need the disk space. Never run a broad `docker system prune` on a machine with other work.

## Run it
The program itself, and its tests:

**File: `terminal in $HOME/code101/rust301/lesson08 (all platforms)`**
```powershell
cargo run --quiet
cargo test
```
Expected output of `cargo run --quiet`, not yet run (and exit code 0):
```text
attempt 1: accepted
attempt 2: rejected
attempt 3: rejected
```
`cargo test` is expected to pass two unit tests.

## How it works
### The threat map
| Threat | Example | What helps |
|---|---|---|
| Known vulnerability in a dependency | A parsing bug with a CVE or RUSTSEC id | `cargo audit`, `cargo deny` advisories, daily CI, `cargo update -p crate` |
| Abandoned or unsound crate | No maintainer, memory-safety bug in unsafe code | `unmaintained`/`unsound` policy, replace or vendor and own it |
| Typosquatting, dependency confusion | `serde_jsonn`, an internal name taken on the public registry | Review every new dependency, `[sources]` allow-list, a private registry for internal crates |
| Malicious or compromised release | A maintainer account is taken over and a patch release steals tokens | `Cargo.lock` plus review of updates, delay adopting brand-new versions, `cargo vet`/`cargo crev` for audited crates, least-privilege CI |
| Build-time code execution | `build.rs`, proc macros, `protoc` binaries | Review them, build in a container with no secrets and restricted network, minimise such crates |
| Unsafe code in dependencies | Memory-safety bugs behind `unsafe` | `cargo geiger` to count, prefer crates that `forbid(unsafe_code)`, Miri on your own unsafe |
| Licence risk | A copyleft dependency in a proprietary product | `[licenses]` allow-list in `cargo deny` |
| Leaked secrets | `.env` in the repository, a token in a log line or image layer | `.dockerignore`, secret scanners, redaction (exercise), BuildKit secrets, never `ENV SECRET=...` |
| Tampered artefact | Someone swaps the binary or image after the build | Signed images and provenance attestations (Sigstore `cosign`, SLSA provenance), verify before deploy |

**RustSec** ([rustsec.org](https://rustsec.org/)) is the advisory database for crates; `cargo audit` and `cargo deny` both read it. An audit tells you what is *known*. It cannot tell you that a crate is safe. A clean report means "no published advisory matches", not "no vulnerability".

**Lockfile discipline.** `Cargo.lock` records every crate's exact version and checksum; Cargo verifies the checksum of each download. Commit it for applications, use `--locked` in CI and in images, and update on purpose (`cargo update`, then review the diff, then run the checks). `cargo tree` shows who depends on whom, `cargo tree -d` lists duplicates, and `cargo tree -i some-crate` answers "why is this in my build?".

**Reduce the attack surface.** `default-features = false` on dependencies and enabling only the features you use removes crates from the graph. Every dependency is a long-term commitment: prefer the standard library for something small.

### Unsafe policy (team level)
1. `forbid(unsafe_code)` by default; unsafe lives in one reviewed crate or module (lesson 02).
2. A dependency allow-list for crates that contain unsafe or build scripts, reviewed when versions change.
3. Run `cargo geiger` (installed separately) or an equivalent report on each release and compare the count to the last one.
4. Miri and fuzzing for the unsafe you own.

### Minimal images: trade-offs
| Choice | Gains | Costs |
|---|---|---|
| `distroless/cc` (this lesson) | No shell or package manager; small; glibc compatible | Cannot `exec` into it to debug; use logs and a debug image built on purpose |
| `scratch` with a static musl binary | Smallest possible; nothing else exists | Needs the musl target and care with C dependencies; the musl allocator and DNS behaviour differ from glibc: measure performance and test name resolution |
| `debian:slim` | Shell and tools for debugging | Larger; more packages that need patching |
| Non-root user, read-only root filesystem, dropped capabilities | A compromise gets less | Needs writable volumes for any file the program writes |

Also scan the final image for known vulnerabilities with a scanner of your choice (such as Trivy or Grype; separate tools), rebuild on a schedule to pick up base-image fixes, and pin base images by **digest** (`FROM rust:1.100.0-slim-trixie@sha256:...`) once you have chosen a tested one: a tag can be moved, a digest cannot. To get the digest after pulling: `docker image inspect --format "{{index .RepoDigests 0}}" rust:1.100.0-slim-trixie`.

### When not to do this
- Do not mirror, vendor and review every crate by hand for a prototype: use `cargo audit` and `cargo deny` first, escalate with risk.
- Do not use `ignore` entries in `deny.toml` to make the pipeline green without a written reason and an end date.
- Do not claim "reproducible builds" without the two-build hash test above.
- Do not publish a binary built on a developer laptop.

### Failure modes to review
- **Alert fatigue:** if the pipeline is red every day for advisories nobody can fix, people ignore it. Triage: fix, ignore with expiry, or replace the crate.
- **A passing audit on a stale lockfile:** it audits what is *locked*; a lockfile that nobody updates audits old versions.
- **Cache poisoning and tag moves** in CI actions and base images (pin by digest and SHA).
- **Secrets in build arguments or layers:** `ARG TOKEN` and `ENV TOKEN` are visible in image history. Use BuildKit secret mounts for build-time secrets and runtime secret injection for run-time ones.
- **Policy drift:** `deny.toml` changes should be reviewed like code.

### Production checklist: supply chain
- [ ] `Cargo.lock` committed; CI uses `--locked`; images build with `--locked`.
- [ ] Toolchain pinned (`rust-toolchain.toml`) and MSRV declared.
- [ ] `cargo audit` and `cargo deny check` run on every pull request and daily; failures have an owner.
- [ ] `deny.toml` reviewed: licences, bans, sources, advisories, no unexplained `ignore`.
- [ ] New dependency checklist: purpose, maintainers, release history, `unsafe` and `build.rs` presence, licence, features.
- [ ] `forbid(unsafe_code)` or documented unsafe policy; Miri/fuzz where unsafe exists.
- [ ] Image: pinned base by digest, multi-stage, non-root, no shell, no secrets in layers or context, scanned.
- [ ] Reproducibility tested (two builds, same hash) or its absence documented.
- [ ] Release artefacts signed and provenance recorded.

### Measurements to take
- Number of crates in your graph (`cargo tree --prefix none | sort -u | wc -l` on Linux/macOS) before and after removing default features.
- Count of `unsafe` and `build.rs` crates in the graph, per release.
- Image size and the number of packages in the final image, per release.
- Time from advisory publication to your fix (a real process metric).

## Try it
### Rung 1. Guided practice
Write `redact`, which masks a secret for logs: tokens of 9 or more characters keep only their last four characters, shorter tokens are masked completely.

**File: `terminal in any folder (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust301/try08/src"
Set-Location "$HOME/code101/rust301/try08"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust301/try08/src"
cd "$HOME/code101/rust301/try08"
```
Optional download route: copy the `starter` folder from `exercise` directly into `$HOME/code101/rust301` and rename the copy `try08`.

**File: `try08/Cargo.toml (starter)`**
```toml
[package]
name = "redact"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `try08/src/main.rs (starter)`**
```rust
/// Masks a secret for logs: tokens of 9 or more characters keep only their last 4 characters,
/// shorter tokens are masked completely. The result always has the same number of characters.
pub fn redact(token: &str) -> String {
    // TODO: count the characters (not the bytes), return all stars for fewer than 9,
    // otherwise stars for all but the last 4 characters, then those last 4 characters.
    token.to_string()
}

fn main() {
    println!("{}", redact("demo-token-0001"));
    println!("{}", redact("short"));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn long_tokens_keep_the_last_four() {
        assert_eq!(redact("abcdefghi"), "*****fghi");
    }

    #[test]
    fn short_tokens_are_fully_masked() {
        assert_eq!(redact("12345678"), "********");
        assert_eq!(redact(""), "");
    }

    #[test]
    fn counts_characters_not_bytes() {
        assert_eq!(redact("ééééééééé"), "*****éééé");
    }
}
```
The untouched starter prints the secrets unmasked, which is exactly the bug you are fixing, and its tests fail. Target output after your edit:
```text
***********0001
*****
```

### Rung 2. Change the behaviour
Add a `[bans]` entry to `deny.toml` that forbids a crate you consider unacceptable for your team (name the crate and the replacement in `use-instead`), and add a second `[licenses]` rule: explain in one sentence how you would allow *one* exceptional crate with a different licence without widening the global allow-list (see the cargo-deny book for `exceptions`).

### Rung 3. Stretch (optional): review exercise
You are asked to approve a pull request that adds a crate `fast-json-lite 0.1.3` with a `build.rs`, 40 stars, one maintainer, last release 14 months ago. Write the review comment you would leave: which five facts you checked (and how), which of the checklist boxes it fails, and what you would accept as a fix.

<details><summary>Solution for Rung 1</summary>

`Cargo.toml` is identical to the starter.

**File: `exercise/solution/src/main.rs`**
```rust
/// Masks a secret for logs: tokens of 9 or more characters keep only their last 4 characters,
/// shorter tokens are masked completely. The result always has the same number of characters.
pub fn redact(token: &str) -> String {
    let count = token.chars().count();
    if count < 9 {
        return "*".repeat(count);
    }
    let tail: String = token.chars().skip(count - 4).collect();
    format!("{}{}", "*".repeat(count - 4), tail)
}

fn main() {
    println!("{}", redact("demo-token-0001"));
    println!("{}", redact("short"));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn long_tokens_keep_the_last_four() {
        assert_eq!(redact("abcdefghi"), "*****fghi");
    }

    #[test]
    fn short_tokens_are_fully_masked() {
        assert_eq!(redact("12345678"), "********");
        assert_eq!(redact(""), "");
    }

    #[test]
    fn counts_characters_not_bytes() {
        assert_eq!(redact("ééééééééé"), "*****éééé");
    }
}
```
`"demo-token-0001"` has 15 characters, so 11 stars and the last four characters `0001`.
</details>

## Check yourself
1. What is the difference between pinning `subtle = "=2.6.1"` and committing `Cargo.lock`?
   <details><summary>Answer</summary>The pin fixes one direct dependency; the lockfile fixes every crate in the graph, direct and transitive, with checksums.</details>
2. Why does CI run `cargo audit` on a schedule and not only on pull requests?
   <details><summary>Answer</summary>New advisories appear for code you have not changed.</details>
3. Predict: what does `cargo build --locked` do when `Cargo.toml` adds a dependency but `Cargo.lock` is not updated?
   <details><summary>Answer</summary>It fails instead of silently updating the lockfile.</details>
4. Why can a clean `cargo audit` not prove a crate is safe?
   <details><summary>Answer</summary>It only reports published advisories; unknown or unreported problems do not appear.</details>
5. Name two reasons to prefer a distroless non-root runtime image to `debian:slim`.
   <details><summary>Answer</summary>Fewer packages and no shell reduce what an attacker can use; non-root limits the damage of a compromise.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| `cargo build --locked` fails; typical message: the lock file needs to be updated but `--locked` was passed to prevent this | `Cargo.toml` and `Cargo.lock` disagree | Run `cargo update` or `cargo generate-lockfile` on purpose, review the diff, commit both |
| `docker build` fails at `COPY Cargo.lock` (typical: file not found in the build context) | The lockfile was never generated, or `.dockerignore` excludes it | Run `cargo generate-lockfile`; keep `Cargo.lock` out of `.dockerignore` |
| `cargo audit` cannot find `Cargo.lock` (typical message) | No lockfile yet | `cargo generate-lockfile` |
| `cargo deny check` reports a licence error for your own crate | The root package has no `license` field or one not on the allow-list | Set `license` in `Cargo.toml` and keep it on the list |
| `cargo deny` reports an unknown key or section after an upgrade | `deny.toml` schema changed between versions | Compare with `cargo deny init` output for your version |
| `exec` into the container fails (typical: no such executable) | Distroless has no shell | Read logs, or build a temporary debug image on purpose |
| Two builds give different hashes | Timestamps, paths, differing dependency versions, host environment | Use `--locked`, pin the toolchain and images, remap paths, then investigate remaining differences |
| Wrong project runs | Terminal not in `lesson08` | `cd "$HOME/code101/rust301/lesson08"` |

## Best practice
Commit `Cargo.lock`, build with `--locked`, audit on every change and on a schedule, enforce a written policy with `cargo deny`, forbid unsafe by default, ship a minimal non-root image pinned by digest, and test reproducibility instead of asserting it. Source: [RustSec advisory database](https://rustsec.org/), [The Cargo Book: Cargo.toml vs Cargo.lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) and [cargo-deny book](https://embarkstudios.github.io/cargo-deny/).

## Going further
- [Microsoft Rust guidelines](https://microsoft.github.io/rust-guidelines/) (safety and dependency guidance).
- [The Cargo Book: build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html) and [`cargo vendor`](https://doc.rust-lang.org/cargo/commands/cargo-vendor.html).
- [subtle crate documentation](https://docs.rs/subtle/2.6.1/subtle/).
- [Docker: multi-stage builds](https://docs.docker.com/build/building/multi-stage/) and [Dockerfile USER](https://docs.docker.com/reference/dockerfile/#user).
- The capstone chapter [Hardening and OWASP](../../../../capstones/backend-rust/tutorials/phase-5-hardening/05-hardening-and-owasp.md) for the application-level counterpart.

## Summary
- You mapped supply-chain threats to the tools that cover them and to the ones nobody covers for you.
- You wrote a `deny.toml`, a scheduled CI workflow and a locked, multi-stage build.
- You applied an unsafe and secrets policy, including constant-time comparison and log redaction.
- You built a minimal non-root image and tested reproducibility with two builds and a hash.

## Next lesson
[09. WebAssembly and release engineering](09-webassembly-and-release-engineering.md): compile to WebAssembly, ship a versioned release, and finish with a production checklist and a review exercise.
