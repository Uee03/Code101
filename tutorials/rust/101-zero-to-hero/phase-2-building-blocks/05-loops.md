---
track: rust
level: 101
phase: 2
phase_name: building-blocks
lesson: "05"
title: "Loops"
time: 30 min
prerequisites: [101.1.04]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-2-building-blocks/05-loops/
assets: []
---

# 05. Loops

## Why it matters
Packing ten lunch boxes does not need ten separate recipes. You repeat the same instructions while the box number changes. A loop gives a computer that same repeatable routine.

## What you will build
A short countdown, a packing routine, a running sum and two numbered loop positions (index 0 and 1).

## Before you start
- Finish lesson 04; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 30 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-2-building-blocks/05-loops/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson05` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson05`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **loop** repeats a block; an **iteration** is one pass. A **sequence** is values visited in order. A **range** describes a sequence by its start and end. An **accumulator** holds a running answer as values are added.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson05`) and package name (`loops`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name loops lesson05
cd lesson05
```

Cargo reports project creation; the prompt should end in `lesson05`. If it already exists, keep your work and use `cd "$HOME/code101/lesson05"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson05/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson05/Cargo.toml`**
```toml
[package]
name = "loops"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `loops`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
Keep the decrement and stopping check in the countdown. A loop without a reachable stop can run forever; press Ctrl+C in the terminal if that happens.

Replace src/main.rs with the full file below. Locate the plain loop and its break first, the condition-controlled while second, and the two for ranges last. All changing counters have mut.

**File: `lesson05/src/main.rs`**
```rust
fn main() {
    let mut countdown = 2;
    loop {
        println!("Countdown: {countdown}");
        countdown = countdown - 1;
        if countdown == 0 {
            break;
        }
    }
    let mut stock = 2;
    while stock > 0 {
        println!("Packing box {stock}");
        stock = stock - 1;
    }
    let mut total = 0;
    for number in 1..=3 {
        total = total + number;
    }
    println!("Total: {total}");
    for index in 0..2 {
        println!("Index: {index}");
    }
}
```

## Run it
In `$HOME/code101/lesson05`, save all files and run:

**File: `terminal in $HOME/code101/lesson05`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Countdown: 2
Countdown: 1
Packing box 2
Packing box 1
Total: 6
Index: 0
Index: 1
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson05/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "loops"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **loop** repeats a block. Plain `loop` repeats until you explicitly leave it. Each pass is an **iteration**. The countdown prints 2, subtracts 1, prints 1, subtracts 1 and then uses `break` to leave the nearest loop.
2. `while stock > 0` checks its condition before every pass; a false starting condition means zero passes. Decreasing stock makes this loop finish.
3. `for number in 1..=3` visits a **range**, a sequence of values. `..=` includes the ending value, so this is 1, 2, 3. `0..2` excludes the ending value, so it is 0, 1. The loop gives number or index a fresh value each pass; you do not have to declare that loop name beforehand.
4. total is an **accumulator**, a value updated to remember the running answer: 0 + 1, then 1 + 2, then 3 + 3. It needs mut because assignment updates the existing binding.
5. For a known range, for avoids manually changing a counter. Use while for a condition and loop when the stopping decision happens inside the work.

## Try it
Calculate the sum of all whole numbers from 1 through 5, including both endpoints. Keep just the final print so the output is one line. Use a loop, rather than typing the final answer.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson05-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name loops lesson05-exercise
cd lesson05-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-2-building-blocks/05-loops/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson05-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson05-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson05-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "loops"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson05-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "loops"
version = "0.1.0"
```

**File: `lesson05-exercise/src/main.rs (starter)`**
```rust
fn main() {
    let mut total = 0;
    // TODO: calculate the sum of the whole numbers 1 through 5.
    println!("Total: {total}");
}
```

Before completion, the starter can show the unused-mut warning explained in lesson 02, then Total: 0. That is not a failed build.

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson05-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Total: 15
```


<details><summary>Solution: complete project files</summary>

The inclusive range 1..=5 visits five values. The changing total must be declared mut.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "loops"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `exercise/solution/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "loops"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
fn main() {
    let mut total = 0;
    for number in 1..=5 {
        total = total + number;
    }
    println!("Total: {total}");
}
```

</details>

## Check yourself
1. Which values are in 1..3?
   <details><summary>Answer</summary>1 and 2, not 3.</details>
2. Which values are in 1..=3?
   <details><summary>Answer</summary>1, 2 and 3.</details>
3. How many times does while false run?
   <details><summary>Answer</summary>Zero times.</details>
4. How can you stop an accidental endless loop?
   <details><summary>Answer</summary>Press Ctrl+C in the terminal.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson05-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson05-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name loops lesson05-error
cd lesson05-error
```

**File: `lesson05-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let total = 0;
    for number in 1..=3 {
        total = total + number;
    }
    println!("{total}");
}
```

**File: `terminal in $HOME/code101/lesson05-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0384]: cannot assign twice to immutable variable `total`
 --> src\main.rs:4:9
  |
2 |     let total = 0;
  |         ----- first assignment to `total`
3 |     for number in 1..=3 {
4 |         total = total + number;
  |         ^^^^^^^^^^^^^^^^^^^^^^ cannot assign twice to immutable variable
  |
help: consider making this binding mutable
  |
2 |     let mut total = 0;
  |         +++

For more information about this error, try `rustc --explain E0384`.
error: could not compile `loops` (bin "loops") due to 1 previous error
```

The accumulator is immutable in this failing example. Add mut to let total = 0; so each iteration can store a new total.

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0384]: cannot assign twice to immutable variable `total` | The total accumulator was declared immutable. | Add `mut` to its original declaration, not a new let inside the loop. |
| The program never finishes | A changing counter or reachable break was removed. | Press Ctrl+C, then restore the decrement or stopping check. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson05"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson05 (or its exercise folder). |

## Best practice
Prefer for when visiting a known range or collection: Rust handles advancing to the next value. Source: [The Rust Book, Repetition with Loops](https://doc.rust-lang.org/book/ch03-05-control-flow.html#repetition-with-loops).

## Next lesson
**[06. Functions](06-functions.md)**: name reusable calculations with functions.
