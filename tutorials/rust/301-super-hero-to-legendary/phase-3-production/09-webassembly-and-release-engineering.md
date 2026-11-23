---
track: rust
level: 301
phase: 3
phase_name: production
lesson: "09"
title: "WebAssembly, release engineering and the production review"
time: "90-120 min"
prerequisites: ["rust-301-06", "rust-301-08", "rust-201-10"]
versions: { rust: "1.100.0 (target)", cargo: "1.100.0 (target)", edition: "2024", wasm-bindgen: "0.2.130" }
verified: not yet run
source: source/rust/301-super-hero-to-legendary/phase-3-production/09-webassembly-and-release-engineering/
assets: []
---

# 09. WebAssembly, release engineering and the production review

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Compile a Rust library to WebAssembly, expose it to JavaScript with `wasm-bindgen` and run it in a browser.
- Design a release process: versioning, tag-driven CI, checksums and a rollback plan.
- Use a production checklist across all nine lessons to review a service.
- Review a flawed piece of Rust code, rank the findings and fix them.

## Recap
1. From lesson 08: why is `--locked` used in the release build?
   <details><summary>Answer</summary>It fails when the lockfile and manifest disagree, so a release is built from exactly the reviewed versions.</details>
2. From lesson 06: why must the build for a benchmark or a release be a release profile?
   <details><summary>Answer</summary>Debug builds are far slower and optimise differently; measurements and shipped artefacts must come from the optimised profile.</details>
3. From lesson 07: which settings does a service need before it talks to other services?
   <details><summary>Answer</summary>Deadlines, message limits, TLS and authentication, health checks, graceful shutdown.</details>

## Why it matters
Shipping is where engineering meets the world. A WebAssembly module lets you run the same Rust logic in a browser (validation, parsing, codecs) in a sandbox, but it adds a second target, a second toolchain and a size budget. A release process turns "it works on my machine" into an artefact somebody else can verify, install and roll back. The final part of this lesson ties all nine lessons together in a checklist and a review exercise, because the skill you are paid for at this level is judgement, not syntax.

## What you will build
A crate `slug_wasm` with the slug logic in a module that forbids unsafe code, a native command-line program, a WebAssembly build served to a small web page, and a tag-driven release workflow that builds, checksums and publishes the package. Then you review and repair a deliberately flawed program.

## Before you start
- **Prerequisites:** Rust 301 lessons [06, performance and benchmarks](../phase-2-architecture-and-performance/06-performance-and-benchmarks.md) and [08, supply chain and security](08-supply-chain-and-security.md); [Rust 201 lesson 10, mini project: notes API](../../201-hero-to-super-hero/phase-4-quality-and-ship/10-mini-project-notes-api.md).
- Audience: finished lessons 01-08.
- Target Rust/Cargo 1.100.0, edition 2024. Direct crate: `wasm-bindgen` 0.2.130, pinned exactly and checked on crates.io for this draft (not a claim that it is the latest or advisory-free). **The command-line tool `wasm-bindgen-cli` must be exactly the same version as the library**, or the glue step fails; the lesson pins both at 0.2.130.
- For the browser part: any current browser, Python (for a one-line static web server), and about 10 minutes of compiling for the first `cargo install wasm-bindgen-cli`.
- Time: 90-120 min in two sittings; break after Step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/301-super-hero-to-legendary/phase-3-production/09-webassembly-and-release-engineering/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Save every tab. No `Cargo.lock` is supplied: cargo creates it on the first build; commit it.

## Steps
### Step 1. Create the folders
**File: `terminal in any folder (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust301/lesson09/src", "$HOME/code101/rust301/lesson09/web", "$HOME/code101/rust301/lesson09/.github/workflows"
Set-Location "$HOME/code101/rust301/lesson09"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust301/lesson09/src" "$HOME/code101/rust301/lesson09/web" "$HOME/code101/rust301/lesson09/.github/workflows"
cd "$HOME/code101/rust301/lesson09"
```

### Step 2. The manifest
**File: `Cargo.toml`**
```toml
[package]
name = "slug_wasm"
version = "0.1.0"
edition = "2024"
rust-version = "1.100"
license = "MIT"
publish = false
description = "Turns titles into URL slugs; runs natively and in WebAssembly."

[lib]
crate-type = ["cdylib", "rlib"]

[[bin]]
name = "slug-cli"
path = "src/main.rs"

[dependencies]
wasm-bindgen = "=0.2.130"

[profile.release]
opt-level = "s"
lto = true
codegen-units = 1
```
- `crate-type = ["cdylib", "rlib"]`: `cdylib` is the dynamic library form that becomes the `.wasm` file for the WebAssembly target; `rlib` is the normal Rust library form that our native program and tests use. We need both.
- `[[bin]] name = "slug-cli"` names the command-line program differently from the library so the two outputs do not collide.
- `[profile.release]` here optimises for size: `opt-level = "s"` (size), `lto = true` (full link-time optimisation), `codegen-units = 1`. Download size matters on the web; measure with and without each setting (see Measurements). There is deliberately no `strip` setting: `wasm-bindgen` reads metadata from the module, so add stripping only after testing it with your exact versions and measuring the gain.
- `publish = false` and `license`/`rust-version` as in lesson 08.

### Step 3. The logic module
All the real behaviour is ordinary, testable Rust with no WebAssembly in it.

**File: `src/slug.rs`**
```rust
/// Longest slug produced, in characters. Longer titles are cut.
pub const MAX_SLUG_LEN: usize = 60;

/// Lowercase ASCII letters and digits, with every run of anything else turned into one dash.
/// Non-ASCII characters count as separators: a deliberate, documented policy.
pub fn slugify_text(input: &str) -> String {
    let mut out = String::with_capacity(input.len().min(MAX_SLUG_LEN));
    let mut pending_dash = false;
    for ch in input.chars() {
        if ch.is_ascii_alphanumeric() {
            let separator = pending_dash && !out.is_empty();
            let needed = if separator { 2 } else { 1 };
            if out.len() + needed > MAX_SLUG_LEN {
                break;
            }
            if separator {
                out.push('-');
            }
            pending_dash = false;
            out.push(ch.to_ascii_lowercase());
        } else {
            pending_dash = true;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn punctuation_and_spaces_become_single_dashes() {
        assert_eq!(slugify_text("Hello, Rust 301!"), "hello-rust-301");
    }

    #[test]
    fn only_separators_give_an_empty_slug() {
        assert_eq!(slugify_text("  --  "), "");
        assert_eq!(slugify_text(""), "");
    }

    #[test]
    fn non_ascii_letters_act_as_separators() {
        assert_eq!(slugify_text("Crème brûlée"), "cr-me-br-l-e");
    }

    #[test]
    fn long_input_is_cut_at_the_limit() {
        assert_eq!(slugify_text(&"a".repeat(100)).len(), MAX_SLUG_LEN);
    }

    #[test]
    fn a_cut_never_leaves_a_trailing_dash() {
        let slug = slugify_text(&format!("{} b", "a".repeat(MAX_SLUG_LEN - 1)));
        assert_eq!(slug.len(), MAX_SLUG_LEN - 1);
        assert!(!slug.ends_with('-'));
    }
}
```
The output is capped (`MAX_SLUG_LEN`), because a function exposed to a browser receives whatever a user types or pastes; unbounded input and output is a denial-of-service and memory problem even inside a sandbox. The dash is added only when the next character fits, so a cut can never leave a trailing dash. The non-ASCII policy ("é" is a separator) is a **product decision** written in the doc comment and the test: if you serve French titles, you want transliteration, not this.

### Step 4. The WebAssembly boundary
**File: `src/lib.rs`**
```rust
use wasm_bindgen::prelude::*;

// The logic module forbids unsafe code. The code generated by `#[wasm_bindgen]` below
// contains unsafe, so this crate cannot use a crate-wide `forbid`.
#[forbid(unsafe_code)]
pub mod slug;

pub use slug::{MAX_SLUG_LEN, slugify_text};

/// Exported to JavaScript as `slugify`.
#[wasm_bindgen]
pub fn slugify(input: &str) -> String {
    slugify_text(input)
}

/// Exported to JavaScript as `version`: the crate version baked in at build time.
#[wasm_bindgen]
pub fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
```
`#[wasm_bindgen]` generates the glue that converts between JavaScript strings (UTF-16) and Rust `&str` (UTF-8): it copies the text into the module's linear memory, calls the function, and copies the result back. Each crossing costs a copy, so **cross the boundary few times with big messages, not many times with small ones**. `version()` embeds the Cargo version with `env!`, which the page displays: a deployed artefact must be able to say what it is.

### Step 5. The native program
**File: `src/main.rs`**
```rust
use slug_wasm::slugify_text;

fn main() {
    let title = std::env::args().skip(1).collect::<Vec<_>>().join(" ");
    let title = if title.is_empty() {
        "Hello, Rust 301!".to_string()
    } else {
        title
    };
    println!("{}", slugify_text(&title));
}
```

### Step 6. The web page
**File: `web/index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'wasm-unsafe-eval'">
  <title>Slugify (Rust and WebAssembly)</title>
</head>
<body>
  <main>
    <h1>Slugify</h1>
    <label for="title">Title</label>
    <input id="title" type="text" value="Hello, Rust 301!" autocomplete="off">
    <p>Slug: <output id="slug" for="title" aria-live="polite"></output></p>
    <p>Module version: <span id="version"></span></p>
  </main>
  <script type="module" src="./main.js"></script>
</body>
</html>
```
- The **Content-Security-Policy** meta tag lets the page load only its own files and scripts. Compiling WebAssembly needs the keyword `'wasm-unsafe-eval'` in `script-src`; it does not allow JavaScript `eval`. In production send the policy as an HTTP header instead of a meta tag.
- Accessibility: the `<label for="title">` names the input for screen readers; the result is in an `<output>` element with `aria-live="polite"`, so assistive technology announces the slug as it changes; the page has a language (`lang="en"`) and works with the keyboard alone.

**File: `web/main.js`**
```js
import init, { slugify, version } from "./pkg/slug_wasm.js";

await init();

const input = document.getElementById("title");
const output = document.getElementById("slug");
document.getElementById("version").textContent = version();

function update() {
  output.textContent = slugify(input.value);
}

input.addEventListener("input", update);
update();
```
`init()` downloads and compiles the `.wasm` file next to the glue code; nothing from the module may be called before it finishes, hence `await`. The result is written with `textContent`, **never `innerHTML`**: slug output is plain text and treating it as markup would invite script injection.

**File: `.gitignore`**
```text
target
web/pkg
pkg
```
Build output (`target`, the generated `pkg` folders) is not committed.

### Step 7. Build, bind and serve
**File: `terminal in $HOME/code101/rust301/lesson09 (all platforms)`**
```powershell
rustup target add wasm32-unknown-unknown
cargo install wasm-bindgen-cli --version 0.2.130 --locked
cargo build --release --target wasm32-unknown-unknown
wasm-bindgen --target web --out-dir web/pkg target/wasm32-unknown-unknown/release/slug_wasm.wasm
python -m http.server 8080 --bind 127.0.0.1 --directory web
```
Line by line:
1. `rustup target add wasm32-unknown-unknown` installs the standard library for the browser WebAssembly target ("unknown" OS: no files, no sockets, no threads by default).
2. `cargo install wasm-bindgen-cli --version 0.2.130 --locked` installs the code generator at the **same version** as the library. A mismatch makes the next step fail with a message about schema or version mismatch.
3. `cargo build --release --target wasm32-unknown-unknown` compiles the library to `target/wasm32-unknown-unknown/release/slug_wasm.wasm`.
4. `wasm-bindgen --target web --out-dir web/pkg ...` reads that file and writes into `web/pkg` the JavaScript glue (`slug_wasm.js`), the processed module (`slug_wasm_bg.wasm`) and TypeScript declarations (`.d.ts` files). `--target web` produces an ES module that a browser loads without a bundler.
5. `python -m http.server 8080 --bind 127.0.0.1 --directory web` serves the `web` folder at `http://127.0.0.1:8080/`, only on your machine. A page cannot load a module from a `file://` address, which is why a server is needed. Stop it with Ctrl+C.

Open `http://127.0.0.1:8080/` in a browser. Expected result (described from the code, not yet observed): the page shows the title field with `Hello, Rust 301!`, the slug `hello-rust-301`, and `Module version: 0.1.0`; typing in the field updates the slug at once.

### Step 8. The release workflow
**File: `.github/workflows/release.yml`**
```yaml
name: release

on:
  push:
    tags: ["v*.*.*"]

permissions:
  contents: write

jobs:
  wasm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check that the tag matches the crate version
        run: |
          VERSION=$(grep -m1 '^version' Cargo.toml | cut -d'"' -f2)
          test "v${VERSION}" = "${GITHUB_REF_NAME}"
      - name: Add the WebAssembly target
        run: rustup target add wasm32-unknown-unknown
      - name: Install the bindgen tool at the version the crate uses
        run: cargo install wasm-bindgen-cli --version 0.2.130 --locked
      - name: Build
        run: cargo build --release --locked --target wasm32-unknown-unknown
      - name: Generate the JavaScript glue
        run: wasm-bindgen --target web --out-dir pkg target/wasm32-unknown-unknown/release/slug_wasm.wasm
      - name: Package and checksum
        run: |
          tar -czf "slug-wasm-${GITHUB_REF_NAME}.tar.gz" pkg
          sha256sum "slug-wasm-${GITHUB_REF_NAME}.tar.gz" > "slug-wasm-${GITHUB_REF_NAME}.tar.gz.sha256"
      - name: Create the GitHub release
        env:
          GH_TOKEN: ${{ github.token }}
        run: gh release create "${GITHUB_REF_NAME}" "slug-wasm-${GITHUB_REF_NAME}.tar.gz" "slug-wasm-${GITHUB_REF_NAME}.tar.gz.sha256" --title "${GITHUB_REF_NAME}" --generate-notes
```
- Trigger: pushing a tag such as `v0.1.0`. **The tag is the release decision;** a person creates it after review (`git tag -s v0.1.0` for a signed tag, then `git push origin v0.1.0`).
- The first step compares the tag with the version in `Cargo.toml` and fails on a mismatch, so a tag cannot publish a different version than the code says.
- `permissions: contents: write` is needed only to create the release; no other permission is requested.
- `--locked` builds from the committed lockfile. The `wasm-bindgen` CLI version is pinned in the workflow; a comment or a check should keep it equal to the `Cargo.toml` pin (a mismatch is the classic failure here).
- The checksum file lets a downloader verify the archive with `sha256sum -c`. Checksums prove the file was not corrupted; they do not prove who made it. For that, add **signing and build provenance** (for example GitHub's artifact attestations or Sigstore `cosign`; read their current documentation before adopting) and verify them where the artefact is deployed. They are not in this workflow because they depend on your hosting.

## Run it
The native program and the tests need only the normal toolchain:

**File: `terminal in $HOME/code101/rust301/lesson09 (all platforms)`**
```powershell
cargo run --quiet --bin slug-cli
cargo test
```
Expected output of the first command, not yet run:
```text
hello-rust-301
```
With arguments (a title with non-ASCII letters), the policy shows: `cargo run --quiet --bin slug-cli -- Crème brûlée` is expected to print `cr-me-br-l-e`. `cargo test` is expected to pass five unit tests. The WebAssembly steps in Step 7 are separate and need the extra tools.

## How it works
**What WebAssembly is.** A compact binary instruction format that runs in a sandbox: a virtual machine with its own linear memory and no access to files, network or the DOM except through functions the host (the browser, or a runtime such as Wasmtime) hands in. Rust targets it as `wasm32-unknown-unknown` (browser, via `wasm-bindgen`) or `wasm32-wasip1` (runtimes that offer the WASI system interface).

**Boundaries.** Only numbers cross natively; strings, arrays and objects are copied into linear memory by generated glue. Design coarse functions. A panic in WebAssembly becomes a trap (the module stops); the page must be able to recover, and you should return `Result` values at the boundary instead of panicking on bad input.

**Sandboxed is not secure.** The sandbox protects the host from the module; it does not protect your module from bad input. All the lesson 02 rules about unsafe and all the input-limit rules still apply, and any secret that you put into a browser module is public.

### WebAssembly: when to use it and when not to
| Use it when | Do not use it when |
|---|---|
| The same validation, parsing or codec logic must run in the browser and on the server | The work is mostly DOM manipulation (JavaScript is the right tool; calls across the boundary cost) |
| A CPU-heavy kernel (image or audio processing, compression) dominates and you have measured JavaScript as too slow | The logic is a few lines; the download and the extra build step cost more than they save |
| You need a sandboxed plug-in system (WASI components, edge runtimes) | The team cannot maintain a second toolchain and debugging flow |
| Size and start-up are measured and acceptable | You have no budget for the module size (measure) |

### Release engineering
**Versioning.** Follow **SemVer**: a breaking change to the public API raises the major version (before 1.0, the minor), a feature the minor, a fix the patch. For libraries, a tool such as `cargo semver-checks` (installed separately) compares your API with the previous release and flags accidental breaking changes. Public surface includes the WebAssembly exports and the JavaScript names, the CLI flags and output formats, the protobuf contract from lesson 07 and Cargo feature names.

**Release steps (a repeatable checklist).**
1. Merge only green changes (tests, lints, `cargo deny`, `cargo audit`).
2. Update the version in `Cargo.toml` and the changelog (what changed, breaking changes, migration notes, security fixes).
3. Run `cargo publish --dry-run` for a crate you publish; build the release artefacts locally once.
4. Create a signed tag; CI builds from the tag with `--locked` in a clean environment.
5. Publish artefacts with checksums, provenance and an SBOM if your customers need one.
6. Roll out gradually (canary, a fraction of traffic), watch the metrics you chose in advance, then continue or roll back.
7. Keep the previous artefact available and **rehearse the rollback**: an untested rollback is a hope. For a crate on crates.io, a broken release can be *yanked* (existing lockfiles keep working, new resolutions avoid it) but not deleted.
8. Record the release: version, commit, toolchain, dependency lockfile hash, who approved.

**MSRV and toolchain policy.** Declare `rust-version`; decide how many Rust releases back you support and test that in CI; bump it deliberately and note it in the changelog.

**Binary distribution.** For command-line tools, build per platform in CI (Linux, macOS, Windows; x86-64 and ARM), name artefacts with target triples, publish checksums, and consider a release tool such as `cargo-dist` (separate) after reading its documentation. Cross-compiling C dependencies (lesson 02) is where this becomes hard.

### Failure modes to review
- Version mismatch between `wasm-bindgen` and its CLI.
- A tag that does not match the manifest version (the workflow's first step guards this).
- Floating tool versions in CI (`@latest`, unpinned actions) that change the build between a tag and a re-run.
- Releases without a rollback path or without a health check after deploy.
- Secrets in release logs or artefacts; the release job has write access and runs third-party actions.
- Shipping source maps or debug info you did not mean to publish, or stripping the info you need for crash analysis.

### Measurements to take
- `.wasm` size after each profile change (`opt-level = "s"` versus `"z"` versus `3`, `lto`), in bytes with `Get-Item` (PowerShell) or `ls -l`, and the size after compression (`gzip`/`brotli`), because the network transfers the compressed file.
- Start-up cost in the browser: time from page load to the first slug (the browser's performance panel).
- Call overhead: time for 1,000 calls with short strings versus one call with a long one.
- Release lead time (tag to published artefact) and rollback time in a rehearsal.

## The production checklist (all nine lessons)
Use it for every service you ship. A box is checked only when you can point to evidence (a test, a CI job, a file).

| Area | Check | Lesson |
|---|---|---|
| Design | Illegal states are unrepresentable where the compiler can enforce it; sealed traits protect invariants; enums where state is runtime data | 01 |
| Unsafe | `forbid(unsafe_code)` by default; each unsafe block has a SAFETY argument; Miri/fuzzing for owned unsafe; FFI declarations tested against the C header | 02 |
| Macros | Macros justified over functions; proc-macro and build-script dependencies reviewed; expansion size and compile time measured | 03 |
| Concurrency | Shared state minimal; lock order documented; no lock held across `.await` or slow work; bounded queues and pools; atomics' orderings justified | 04 |
| Architecture | Dependencies point inward; ports in the core's language; composition root only; fitness test or crate boundaries; adapters swapped in tests | 05 |
| Performance | Budgets stated; release profile measured; hot paths benchmarked with baselines; allocations reviewed; no `target-cpu=native` in shipped artefacts | 06 |
| Service API | Versioned contract; backward-compatible evolution; deadlines, size limits, TLS, authentication, health, graceful shutdown; errors mapped without leaking internals | 07 |
| Supply chain | Lockfile committed; `--locked` builds; toolchain pinned; audit and deny on every change and daily; no unexplained ignores | 08 |
| Containers | Multi-stage, pinned by digest, non-root, no shell, no secrets in context or layers, scanned; reproducibility tested | 08 |
| Secrets and logs | No secrets in source, logs, images or browser modules; tokens compared in constant time; user input escaped in logs | 08, 09 |
| WebAssembly | Input and output bounded; panics handled at the boundary; CSP set; DOM written with `textContent`; size budget measured | 09 |
| Release | SemVer and changelog; signed tag; CI builds from the tag; checksum and provenance; canary and metrics; rehearsed rollback | 09 |
| Operations | Structured logs without personal data; metrics and alerts per budget; runbook; owner for advisories | all |

For the full-stack version of these concerns (data access, identity, hardening, OWASP) read the [backend-rust capstone](../../../../capstones/backend-rust/README.md) chapters 02-05 with this checklist next to you.

## Try it
### Rung 1. Guided practice: the review
The starter below compiles and runs, and it contains seven problems a production review should catch. **Do not edit it yet.** Create the folder and copy the file, read it as a reviewer, and write a list: line or function, problem, why it matters (what an attacker or an outage would do), severity (high, medium, low) and the fix you propose.

**File: `terminal in any folder (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust301/try09/src"
Set-Location "$HOME/code101/rust301/try09"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust301/try09/src"
cd "$HOME/code101/rust301/try09"
```
Optional download route: copy the `starter` folder from `exercise` directly into `$HOME/code101/rust301` and rename the copy `try09`.

**File: `try09/Cargo.toml (starter)`**
```toml
[package]
name = "review_me"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `try09/src/main.rs (starter)`**
```rust
use std::collections::HashMap;
use std::sync::Mutex;

const FALLBACK_TOKEN: &str = "admin-secret-123";

pub struct Cache {
    entries: Mutex<HashMap<String, String>>,
}

impl Cache {
    pub fn new() -> Self {
        Cache {
            entries: Mutex::new(HashMap::new()),
        }
    }

    pub fn put(&self, key: &str, value: &str) {
        self.entries
            .lock()
            .unwrap()
            .insert(key.to_string(), value.to_string());
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.entries.lock().unwrap().get(key).cloned()
    }
}

pub fn is_admin(given: &str) -> bool {
    given == FALLBACK_TOKEN
}

pub fn first_word(line: &str) -> &str {
    &line[..line.find(' ').unwrap()]
}

pub fn parse_port(text: &str) -> u16 {
    text.parse().unwrap_or(0)
}

pub fn log_login(user: &str, token: &str) {
    println!("login user={user} token={token}");
}

fn main() {
    let cache = Cache::new();
    cache.put("a", "1");
    println!("{:?}", cache.get("a"));
    println!("{}", first_word("hello world"));
    println!("{}", parse_port("8080"));
    println!("admin: {}", is_admin("admin-secret-123"));
    log_login("ana", "admin-secret-123");
}
```
(`admin-secret-123` is a made-up demo value, not a real secret; printing it in `main` is part of the flaw being reviewed.) Expected output of the starter, not yet run:
```text
Some("1")
hello
8080
admin: true
login user=ana token=admin-secret-123
```
Write your findings **before** opening the solution. Use the checklist table above to find them: this file touches the Concurrency, Service API, Secrets and logs, and Design rows.

### Rung 2. Change the behaviour: fix it
Rewrite the file so that each finding is fixed and each fix is visible in the output: the cache refuses new keys beyond a limit (return a `Result`), `first_word` returns an `Option`, `parse_port` returns a `Result` and rejects 0, `is_admin` takes the expected secret as an argument, and `log_login` no longer receives the token. Then add unit tests for each function.

### Rung 3. Stretch (optional)
Pick one function of the [backend-rust capstone](../../../../capstones/backend-rust/README.md) (for example a handler from chapter 02 or 05) and review it against the production checklist. Write one finding per row that applies and one row that does not apply with the reason.

<details><summary>Solution for Rung 1 and Rung 2: findings and fixed file</summary>

**Findings**

| # | Where | Problem | Why it matters | Severity | Fix |
|---|---|---|---|---|---|
| 1 | `FALLBACK_TOKEN`, `is_admin` | A hard-coded default secret compiled into the binary | Anyone with the binary or repository has admin access; it cannot be rotated without a release | High | Load the expected secret from configuration or a secret store at start-up and fail if it is missing; no fallback |
| 2 | `is_admin` | `==` on secrets stops at the first different byte | Timing side channel lets an attacker guess a token progressively | Medium | Compare every byte (a vetted constant-time comparison, such as the `subtle` crate) |
| 3 | `log_login` | Writes the token to the log | Logs are copied to many systems and kept for long; a leaked log leaks the credential | High | Never log secrets; log the user and the outcome, escape the user name |
| 4 | `Cache::put` | Unbounded growth | A caller can fill memory (denial of service) | High | A maximum size and an explicit refusal (`Result`), plus eviction if needed |
| 5 | `Cache` `lock().unwrap()` | A panic in one thread poisons the lock and every later call panics | One bug becomes a total outage | Medium | Decide a poisoning policy: here recover with `into_inner()` because each update is one insert |
| 6 | `first_word` | `unwrap()` on `find` panics when the line has no space; also only splits on one space | A user-supplied line crashes the thread or process | High | Return `Option<&str>` and split on whitespace |
| 7 | `parse_port` | `unwrap_or(0)` turns invalid input into port 0 silently | A bad configuration binds an arbitrary port or hides an error | Medium | Return `Result`, reject 0, include the offending text (escaped) in the error |

**Fixed file** (expected output below, not yet run)

**File: `exercise/solution/src/main.rs`**
```rust
use std::collections::HashMap;
use std::sync::Mutex;

#[derive(Debug, PartialEq, Eq)]
pub struct CacheFull;

pub struct Cache {
    max_entries: usize,
    entries: Mutex<HashMap<String, String>>,
}

impl Cache {
    pub fn new(max_entries: usize) -> Self {
        Cache {
            max_entries,
            entries: Mutex::new(HashMap::new()),
        }
    }

    /// Stores a value. A new key is refused when the cache is full; an existing key is replaced.
    pub fn put(&self, key: &str, value: &str) -> Result<(), CacheFull> {
        let mut entries = self.lock();
        if !entries.contains_key(key) && entries.len() >= self.max_entries {
            return Err(CacheFull);
        }
        entries.insert(key.to_string(), value.to_string());
        Ok(())
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.lock().get(key).cloned()
    }

    // The map holds plain strings and every update is a single insert, so it is consistent
    // even if another thread panicked while holding the lock: recover instead of cascading.
    fn lock(&self) -> std::sync::MutexGuard<'_, HashMap<String, String>> {
        self.entries
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }
}

/// Compares the expected secret (from configuration, never from source) with the given one,
/// looking at every byte. Prefer a vetted crate such as `subtle` in real code.
pub fn is_admin(expected: &str, given: &str) -> bool {
    let a = expected.as_bytes();
    let b = given.as_bytes();
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |diff, (x, y)| diff | (x ^ y)) == 0
}

pub fn first_word(line: &str) -> Option<&str> {
    line.split_whitespace().next()
}

pub fn parse_port(text: &str) -> Result<u16, String> {
    match text.trim().parse::<u16>() {
        Ok(port) if port != 0 => Ok(port),
        _ => Err(format!("invalid port: {text:?}")),
    }
}

/// Logs who logged in, never the secret. `{user:?}` escapes control characters and quotes.
pub fn log_login(user: &str) {
    println!("login user={user:?}");
}

fn main() {
    let cache = Cache::new(2);
    println!("{:?}", cache.put("a", "1"));
    println!("{:?}", cache.put("b", "2"));
    println!("{:?}", cache.put("c", "3"));
    println!("{:?}", cache.get("a"));
    println!("{:?}", first_word("hello world"));
    println!("{:?}", first_word(""));
    println!("{:?}", parse_port("8080"));
    println!("{:?}", parse_port("80x"));
    println!("{}", is_admin("s3cret-from-config", "s3cret-from-config"));
    println!("{}", is_admin("s3cret-from-config", "guess"));
    log_login("ana");
}
```
Expected output of the fixed file, not yet run:
```text
Ok(())
Ok(())
Err(CacheFull)
Some("1")
Some("hello")
None
Ok(8080)
Err("invalid port: \"80x\"")
true
false
login user="ana"
```
The hand-written comparison in `is_admin` is a teaching device: an optimiser is allowed to rewrite code, so for real secrets use a crate designed and reviewed for constant-time behaviour, as lesson 08 did with `subtle`. Also still open in this fix: the secret `s3cret-from-config` is again a literal in `main`; in a real program it comes from the environment or a secret store.
</details>

## Check yourself
1. Why must `wasm-bindgen-cli` have the same version as the `wasm-bindgen` crate?
   <details><summary>Answer</summary>The generated glue and the metadata the library embeds in the module must agree; different versions use different formats.</details>
2. Why does the page set `textContent` and not `innerHTML`?
   <details><summary>Answer</summary>Text is not interpreted as markup, so input cannot inject script into the page.</details>
3. Predict: what does `slugify("Crème brûlée")` return, and what product decision does that show?
   <details><summary>Answer</summary>`cr-me-br-l-e`; non-ASCII letters are treated as separators, a policy you may need to replace with transliteration.</details>
4. Name three checks the release workflow performs before publishing.
   <details><summary>Answer</summary>Tag equals crate version; build with `--locked` from a clean runner; checksum generated (and, if added, provenance and signatures).</details>
5. Give two reasons not to use WebAssembly for a feature.
   <details><summary>Answer</summary>The work is mostly DOM manipulation, or the logic is small and the module size and extra toolchain cost more than they save.</details>

## Common mistakes
| Symptom | Cause | Fix |
|---|---|---|
| `wasm-bindgen` fails with a message about a version or schema mismatch (typical wording) | CLI and library versions differ | Install the CLI with `--version 0.2.130` (the version in `Cargo.toml`) |
| `can't find crate for std` or target not installed (typical) | `rustup target add wasm32-unknown-unknown` was skipped | Add the target |
| The page is blank and the browser console shows a MIME type or module error (typical) | Opened via `file://`, or a server that does not send `application/wasm` | Use the Python server command from Step 7 |
| The console shows a Content Security Policy violation | `'wasm-unsafe-eval'` missing from `script-src`, or scripts loaded from another origin | Fix the policy as in Step 6 |
| `cargo run` asks which binary to run, or runs nothing useful | The package has a library and a named binary | Use `cargo run --bin slug-cli` |
| Release workflow stops at the first step | Tag and `Cargo.toml` version differ | Fix the version or retag |
| Wrong project runs | Terminal not in `lesson09` | `cd "$HOME/code101/rust301/lesson09"` |

## Best practice
Keep logic in plain, tested Rust and make the WebAssembly layer a thin, bounded boundary; release from a tag, with locked builds, checksums and a rehearsed rollback; review services with a written checklist and evidence. Source: [Rust and WebAssembly book](https://rustwasm.github.io/docs/book/) and [wasm-bindgen guide](https://rustwasm.github.io/docs/wasm-bindgen/), [The Cargo Book: publishing and SemVer compatibility](https://doc.rust-lang.org/cargo/reference/semver.html).

## Going further
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) (necessities, future proofing, documentation).
- [Microsoft Rust guidelines](https://microsoft.github.io/rust-guidelines/): production-readiness guidance for Rust code.
- [The Rust Reference: conditional compilation and targets](https://doc.rust-lang.org/reference/conditional-compilation.html) and the [Rust platform support list](https://doc.rust-lang.org/nightly/rustc/platform-support.html).
- [Tokio tutorial](https://tokio.rs/tokio/tutorial) and the [capstone backend-rust](../../../../capstones/backend-rust/README.md) for the service side of release and operations.

## Summary
- You built a Rust library for two targets, bound it to JavaScript and served it with a restrictive Content-Security-Policy.
- You designed a tag-driven release with a version check, locked build, checksum and a rollback plan.
- You applied the production checklist of all nine lessons to a service.
- You reviewed flawed code, ranked seven findings by severity and fixed them.

## Next lesson
This is the last lesson of Rust 301. Continue with the [backend-rust capstone](../../../../capstones/backend-rust/README.md) as a full production-grade service, or choose a [practice capstone](../../../../capstones/_practice/README.md) and build it with this checklist.
