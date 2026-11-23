---
track: rust
level: 201
phase: 1
phase_name: core-skills
lesson: "03"
title: "Iterators and closures"
time: "40-50 min"
prerequisites: ["rust-201-02"]
versions: { rust: "1.100.0 (target)", cargo: "1.100.0 (target)", edition: "2024" }
verified: not yet run
source: source/rust/201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-closures/
assets: []
---

# 03. Iterators and closures

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Trace a lazy filter-map-sum pipeline.
- Explain the values and references each adapter receives.
- Choose iter, iter_mut or into_iter from ownership needs.

## Recap
1. Why may render call summary for every accepted T?
   <details><summary>Answer</summary>The trait bound guarantees that capability.</details>

2. Does borrowing a vector transfer ownership of its elements?
   <details><summary>Answer</summary>No. The caller retains its owned collection.</details>

## Why it matters
An iterator pipeline separates which items survive from how each item changes. It avoids index bookkeeping and temporary collections. Tracking the item type prevents the most common closure-reference mistakes.

## What you will build
Filter a borrowed sequence at an inclusive minimum, double retained values and sum them while keeping the vector usable.

## Before you start
- Audience: finished [Rust 101](../../101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md), with 1-2 years of practice. Finish lesson 02 first.
- Target Rust/Cargo 1.100.0, edition 2024. Reuse the Rust 101 installation and editor. No tools were installed for this draft. Exact direct crate versions/features are in the full manifest, checked in official documentation; this is not a claim they are the latest releases.
- Time: 40-50 min. Allow extra time for the first future dependency download.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-closures/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Extract a ZIP: Windows right-click **Extract All**; macOS double-click; Linux use your file manager's **Extract** action. Open the source path above. If copying instead of typing, copy code directly into `$HOME/code101/rust201`, rename the copy lesson03, and do not nest it inside an already-created destination.
- Save as UTF-8. On Windows enable **View, Show, File name extensions** so main.rs does not become main.rs.txt. Save every editor tab; a dot marks unsaved edits. Commands below are future learner instructions, not observed results.
- No Cargo.lock is supplied: Cargo creates it on the first build. Keep/review the generated application lock. Exact direct pins alone do not lock transitive dependencies.

## Steps
### Step 1. Create your project folders
Use the typed route below or the optional copy route, not both. Start in any terminal folder; these home-relative absolute paths recover from the wrong working directory. `$HOME` is your user home on all platforms.

**File: `terminal in any folder (Windows)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust201/lesson03/src"
Set-Location "$HOME/code101/rust201/lesson03"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust201/lesson03/src"
cd "$HOME/code101/rust201/lesson03"
```

Expected result: the prompt ends in lesson03; src and the listed subfolders exist. PowerShell may print directory tables, not program output. Do not overwrite existing work; choose a different local folder name if needed.

### Step 2. Create the complete manifest
In the project root create Cargo.toml in your editor.

**File: `Cargo.toml`**
```toml
[package]
name = "iterator_totals"
version = "0.1.0"
edition = "2024"

[dependencies]
```

[package] names the package; 0.1.0 is its learning-project version and edition 2024 selects language rules. Cargo discovers src/lib.rs as the library and src/main.rs as the binary. [dependencies] lists external crates; an empty table uses std only. Exact = versions pin direct crates and features enable capabilities. No cargo add command is needed.

**Predict before you run:** Cross out values below 8 in [3, 8, 12], double the retained values and add them. Will values.len() still work?

Tests below use assert_eq for exact values, assert for conditions and matches for enum patterns. #[cfg(test)] includes a child test module for tests only; #[test] marks a normal test; #[tokio::test] supplies an async runtime where used. These are taught, not executed here. Lesson 09 explains unit, documentation and integration boundaries.

### Step 3. Create `src/lib.rs`
Create this exact file under $HOME/code101/rust201/lesson03; save the entire content, not a fragment.

**File: `src/lib.rs`**
```rust
pub fn total_above(values: &[i32], minimum: i32) -> i32 {
    values.iter()
        .copied()
        .filter(|value| *value >= minimum)
        .map(|value| value * 2)
        .sum()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn includes_the_boundary() {
        assert_eq!(total_above(&[3, 8, 12], 8), 40);
        assert_eq!(total_above(&[8], 8), 16);
    }

    #[test]
    fn empty_input_is_zero() {
        assert_eq!(total_above(&[], 8), 0);
    }
}
```

A **closure** is an anonymous function that can capture surrounding values. The filter predicate reads minimum from its environment. An **adapter** builds a new iterator, such as filter or map; a **consumer**, such as sum, requests items to produce a final result.

iter yields &i32. copied copies these Copy numbers to i32 values. filter always borrows its current item, so value is &i32 in that predicate. map receives the owned i32. The function's return type tells sum to produce i32. Tests cover the full pipeline, the inclusive boundary and empty input.

### Step 4. Create `src/main.rs`
Create this exact file under $HOME/code101/rust201/lesson03; save the entire content, not a fragment.

**File: `src/main.rs`**
```rust
use iterator_totals::total_above;

fn main() {
    let values = vec![3, 8, 12];
    println!("doubled total: {}", total_above(&values, 8));
    println!("input count: {}", values.len());
}
```

The binary imports the library using its package name. It owns startup, demonstration output and top-level errors at the application boundary.

## Run it
Save every file. This command runs in the project root on Windows/macOS/Linux. It is for a future walk-through; no author runtime result is claimed.

**File: `terminal in $HOME/code101/rust201/lesson03`**
```powershell
cargo run --quiet
```

Expected output, not yet run (derived from source; Cargo download/build messages omitted):

**File: `terminal standard output`**
```text
doubled total: 40
input count: 3
```

### Check the supplied feature tests later
From this same project root, on all platforms:

**File: `terminal in $HOME/code101/rust201/lesson03`**
```powershell
cargo test
```

Expected result, not yet run: the finished example's assertions pass. Harness paths, timings and test order are not assumed. No test suite was run while authoring.


## How it works
**Laziness** means adapters do not process the whole sequence just because the chain was constructed. sum pulls each item through it: three is rejected, eight becomes sixteen, and twelve becomes twenty-four. Empty input sums to zero. The slice was borrowed throughout.

iter_mut lends mutable elements. into_iter consumes a collection to yield its elements by value; for Vec<String> that transfers String ownership. A closure may borrow, mutably borrow or move captured values. Fn, FnMut and FnOnce describe how it can be called. A move capture does not automatically make it callable only once.

**Why this, not that:** use a short pipeline for transformations. Use a for loop when early exits, side effects or several changing accumulators make the chain harder to read. Do not add collect just to force execution when you do not need an allocated collection.

**Misconception:** filter receives the same argument type as map. Its predicate borrows Item. Trace Item instead of adding random ampersands. Inputs here are small; unbounded arithmetic needs checked operations or documented bounds.

**Structure:**

**File: `lesson architecture diagram`**
```mermaid
flowchart LR
    A["3, 8, 12"] --> B["iter: borrowed i32"]
    B --> C["copied: owned i32"]
    C --> D["filter: 8, 12"]
    D --> E["map: 16, 24"]
    E --> F["sum: 40"]
```

## Try it
### Rung 1. Guided practice
Triple retained values instead of doubling them. Keep the inclusive threshold and input ownership. The starter assertions already specify 60 for the full input and 24 at the boundary.

Work separately in `$HOME/code101/rust201/try03`. Optional download route: from `source/rust/201-hero-to-super-hero/phase-1-core-skills/03-iterators-and-closures/exercise`, copy starter directly into `$HOME/code101/rust201`, then rename the copied folder try03. Do not first create try03 and put starter inside it. Use this route only if the destination does not exist.

Typed route without a download: create the exact directories below, then every starter file shown. Start in any terminal folder.

**File: `terminal in any folder (Windows)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101/rust201/try03/src"
Set-Location "$HOME/code101/rust201/try03"
```

**File: `terminal in any folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101/rust201/try03/src"
cd "$HOME/code101/rust201/try03"
```

Expected result: a separate exercise root, not a nested starter directory.

**File: `try03/Cargo.toml (starter)`**
```toml
[package]
name = "iterator_totals"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `try03/src/lib.rs (starter)`**
```rust
pub fn total_above(values: &[i32], minimum: i32) -> i32 {
    values.iter()
        .copied()
        .filter(|value| *value >= minimum)
        .map(|value| value) // TODO: triple each retained value.
        .sum()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn includes_the_boundary() {
        assert_eq!(total_above(&[3, 8, 12], 8), 60);
        assert_eq!(total_above(&[8], 8), 24);
    }

    #[test]
    fn empty_input_is_zero() {
        assert_eq!(total_above(&[], 8), 0);
    }
}
```

**File: `try03/src/main.rs (starter)`**
```rust
use iterator_totals::total_above;

fn main() {
    let values = vec![3, 8, 12];
    println!("tripled total: {}", total_above(&values, 8));
    println!("input count: {}", values.len());
}
```

Save the TODO changes, then use these commands in the exercise root (all platforms):

**File: `terminal in $HOME/code101/rust201/try03`**
```powershell
cargo run --quiet
cargo test
```

Expected output, not yet run (derived from source; Cargo download/build messages omitted):

**File: `terminal standard output`**
```text
tripled total: 60
input count: 3
```

This is the completed guided target, not a claim the untouched starter satisfies it. The supplied assertions identify the policy to complete; do not delete them to get a green result.

### Rung 2. Change the behavior or coverage
Add tests for all values below the threshold and for negative inputs with a negative threshold. Work out each sum before writing the assertion.

### Rung 3. Stretch (optional)
Compare a loop using checked_add and checked_mul when input can overflow i32. Where should failure be returned?

<details><summary>Solution: complete guided project</summary>

These files solve Rung 1 only. Compare after attempting the TODO. Supporting files are included so no download is required. Rung 2 and the optional design question remain your work.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "iterator_totals"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `exercise/solution/src/lib.rs`**
```rust
pub fn total_above(values: &[i32], minimum: i32) -> i32 {
    values.iter()
        .copied()
        .filter(|value| *value >= minimum)
        .map(|value| value * 3)
        .sum()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn includes_the_boundary() {
        assert_eq!(total_above(&[3, 8, 12], 8), 60);
        assert_eq!(total_above(&[8], 8), 24);
    }

    #[test]
    fn empty_input_is_zero() {
        assert_eq!(total_above(&[], 8), 0);
    }
}
```

**File: `exercise/solution/src/main.rs`**
```rust
use iterator_totals::total_above;

fn main() {
    let values = vec![3, 8, 12];
    println!("tripled total: {}", total_above(&values, 8));
    println!("input count: {}", values.len());
}
```

</details>

## Check yourself
1. What makes the adapters run?
   <details><summary>Answer</summary>sum consumes the iterator and requests items.</details>

2. Why dereference value in filter but not map?
   <details><summary>Answer</summary>filter borrows its Item; map receives the owned Item, which is i32 after copied.</details>

3. Which iterator preserves a Vec<String> for later reading?
   <details><summary>Answer</summary>iter yields borrowed Strings rather than consuming them.</details>

## Common mistakes
These are symptoms and fixes, not fabricated compiler transcripts. Read your tool's actual diagnostic and file/line first.

| Symptom | Cause | Fix |
|---|---|---|
| Wrong project runs or no manifest is found. | Terminal is outside this project. | Return to `$HOME/code101/rust201/lesson03`, next to Cargo.toml. |
| Your edit changes nothing. | The buffer was not saved. | Save all tabs, then run from the project root. |
| Nothing happens after constructing map. | No consumer requested items. | Use the intended sum, loop or collect when a collection is needed. |
| The predicate has an unexpected reference. | filter borrows Item. | Trace the item type through copied and filter. |
| The vector is unavailable afterward. | into_iter consumed it. | Use iter when borrowing was intended. |

## Best practice
Make ownership and the final consumer visible; optimize for a readable transformation. Source: [The Rust Book: iterators](https://doc.rust-lang.org/book/ch13-02-iterators.html); [The Rust Book: closures](https://doc.rust-lang.org/book/ch13-01-closures.html).

## Going further
- [The Rust Book: iterators](https://doc.rust-lang.org/book/ch13-02-iterators.html) (official; version checked where applicable).
- [The Rust Book: closures](https://doc.rust-lang.org/book/ch13-01-closures.html) (official; version checked where applicable).
## Summary
- You practiced how to trace a lazy filter-map-sum pipeline.
- You practiced how to explain the values and references each adapter receives.
- You practiced how to choose iter, iter_mut or into_iter from ownership needs.
- You distinguished expected draft behavior from observed runtime evidence.

## Next lesson
[04. Error handling in libraries and apps](04-errors-in-libraries-and-apps.md): keep reusable failures typed while adding context.
