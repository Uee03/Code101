---
track: rust
level: 101
phase: 1
phase_name: foundations
lesson: "04"
title: "Making decisions"
time: 35 min
prerequisites: [101.1.03]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-1-foundations/04-making-decisions/
assets: []
---

# 04. Making decisions

## Why it matters
A ticket clerk follows rules: children pay one price and adults another. A program makes the same choices by asking questions with yes/no answers. Ordered rules let you handle exceptions before ordinary cases.

## What you will build
A ticket machine with if/else prices, three boolean checks and a match that selects a weekend or weekday desk.

## Before you start
- Finish lesson 03; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-1-foundations/04-making-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson04` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson04`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **condition** is a true/false question deciding whether a block runs. A **branch** is one alternative block. A **pattern** is a value or shape to recognize; each **arm** of a match pairs a pattern with its action.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson04`) and package name (`making_decisions`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name making_decisions lesson04
cd lesson04
```

Cargo reports project creation; the prompt should end in `lesson04`. If it already exists, keep your work and use `cd "$HOME/code101/lesson04"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson04/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson04/Cargo.toml`**
```toml
[package]
name = "making_decisions"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `making_decisions`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
The age comes from the keyboard. The ticket flag and day are fixed so you can focus on the choices, not on extra input. For -5, the first branch prints Invalid age, but the independent checks below still run: they are separate demonstrations, not a complete ticket machine. Lesson 09 shows return, which can stop a function early.

Replace src/main.rs with the complete file below. Locate the invalid-age branch before the child branch, then the boolean checks, then the match. Do not write a colon after if; Rust uses braces.

**File: `lesson04/src/main.rs`**
```rust
use std::io;

fn main() {
    let mut text = String::new();
    println!("Age:");
    io::stdin().read_line(&mut text).expect("Could not read age");
    let age = text.trim().parse::<i32>().expect("Use a whole number");
    if age < 0 {
        println!("Invalid age");
    } else if age < 18 {
        println!("Ticket: child, 5.00");
    } else {
        println!("Ticket: adult, 10.00");
    }
    let has_ticket = true;
    println!("Adult with ticket: {}", age >= 18 && has_ticket);
    println!("Child or has ticket: {}", age < 18 || has_ticket);
    println!("No ticket: {}", !has_ticket);
    let day = "Sat";
    match day {
        "Sat" | "Sun" => println!("Weekend desk"),
        _ => println!("Weekday desk"),
    }
}
```

## Run it
In `$HOME/code101/lesson04`, save all files and run:

**File: `terminal in $HOME/code101/lesson04`**
```powershell
cargo run --quiet
```

Type each line below **when the program asks for it**, pressing Enter after each. These are keyboard replies, not terminal commands. The output block excludes the keyboard's echo of what you type.

**File: `keyboard input for this run`**
```text
30
```

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Age:
Ticket: adult, 10.00
Adult with ticket: true
Child or has ticket: true
No ticket: false
Weekend desk
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson04/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "making_decisions"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **comparison** asks a yes/no question. `age < 0` asks whether age is negative. The **condition** after if must be bool; Rust does not treat an integer as true or false.
2. `if`, `else if` and `else` form ordered **branches** (alternative blocks). Only the first true branch runs. Check invalid ages first, then children, then let else cover valid adults. Braces mark the blocks; the spaces simply show their nesting.
3. Comparisons are `<` less than, `>` greater than, `<=` at most, `>=` at least, `==` equal, and `!=` not equal. One `=` assigns; two `==` compare. Words are case-sensitive, so `"Sat"` and `"sat"` are different.
4. `&&` means **and** (both sides true); `||` means **or** (at least one true); `!` means **not** (flip the answer). A **boolean expression** is anything producing bool, including these combinations. `&&` skips its right side if the left is false; `||` skips it if the left is true. This is **short-circuiting**.
5. `match` compares one value against **patterns**, shapes or values to recognize. Each **arm** has a pattern, `=>` and an action. Here `"Sat" | "Sun"` accepts either spelling. A single `|` in a pattern is not the boolean operator `||`.
6. `_` is the **wildcard**, matching anything left over. A match must be **exhaustive**: every possible input must be covered. Commas separate these arms.

## Try it
Build a grade checker: outside 0-100 displays Invalid score; scores 0-49 display Fail; 50-74 display Pass; 75-100 display Merit. Keep the existing input and make the output select exactly one result. Use 60 for the example.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson04-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name making_decisions lesson04-exercise
cd lesson04-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-1-foundations/04-making-decisions/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson04-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson04-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson04-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "making_decisions"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson04-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "making_decisions"
version = "0.1.0"
```

**File: `lesson04-exercise/src/main.rs (starter)`**
```rust
use std::io;

fn main() {
    let mut text = String::new();
    println!("Score (0-100):");
    io::stdin().read_line(&mut text).expect("Could not read score");
    let score = text.trim().parse::<i32>().expect("Use a whole number");
    // TODO: replace this print with invalid, fail, pass and merit branches.
    println!("Score: {score}");
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson04-exercise`**
```powershell
cargo run --quiet
```

Supply these lines at the prompts, one per Enter:

**File: `keyboard input for the completed exercise`**
```text
60
```

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Score (0-100):
Pass
```


<details><summary>Solution: complete project files</summary>

Once the invalid branch is excluded, each later branch needs only its upper limit. The earlier branches have already excluded lower values.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "making_decisions"
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
name = "making_decisions"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::io;

fn main() {
    let mut text = String::new();
    println!("Score (0-100):");
    io::stdin().read_line(&mut text).expect("Could not read score");
    let score = text.trim().parse::<i32>().expect("Use a whole number");
    if score < 0 || score > 100 {
        println!("Invalid score");
    } else if score < 50 {
        println!("Fail");
    } else if score < 75 {
        println!("Pass");
    } else {
        println!("Merit");
    }
}
```

</details>

## Check yourself
1. What does = do that == does not?
   <details><summary>Answer</summary>= assigns a value; == asks whether two values are equal.</details>
2. What does !true produce?
   <details><summary>Answer</summary>false.</details>
3. Why put invalid scores first?
   <details><summary>Answer</summary>Otherwise a negative score would satisfy below 50 and incorrectly become Fail.</details>
4. What does _ mean in a match?
   <details><summary>Answer</summary>It matches any value not handled by earlier arms.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson04-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson04-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name making_decisions lesson04-error
cd lesson04-error
```

**File: `lesson04-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let age: i32 = "30";
    println!("{age}");
}
```

**File: `terminal in $HOME/code101/lesson04-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0308]: mismatched types
 --> src\main.rs:2:20
  |
2 |     let age: i32 = "30";
  |              ---   ^^^^ expected `i32`, found `&str`
  |              |
  |              expected due to this

For more information about this error, try `rustc --explain E0308`.
error: could not compile `making_decisions` (bin "making_decisions") due to 1 previous error
```

The age declaration expects i32, but the quoted value is text (&str). Remove the quotes for fixed numeric ages; parse keyboard text into i32 before making numeric comparisons.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Entering abc at Age:

**File: `terminal standard error (captured)`**
```text

thread 'main' (12920) panicked at src\main.rs:7:42:
Use a whole number: ParseIntError { kind: InvalidDigit }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0308]: mismatched types | The i32 age declaration was given quoted text. | Use `30` for a fixed age; parse keyboard input into i32. |
| Use a whole number: ParseIntError { kind: InvalidDigit } | Entered abc rather than a whole-number age. | Restart and enter a number such as 30; expect stops on a bad parse (lesson 03). |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson04"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson04 (or its exercise folder). |

## Best practice
Make matches exhaustive so the compiler checks that every possible case has an action. Source: [The Rust Book, The match Control Flow Construct](https://doc.rust-lang.org/book/ch06-02-match.html).

## Next lesson
**[05. Loops](../phase-2-building-blocks/05-loops.md)**: start Phase 2 by repeating work with loops.
