---
track: rust
level: 101
phase: 1
phase_name: foundations
lesson: "03"
title: "Input and math"
time: 35 min
prerequisites: [101.1.02]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-1-foundations/03-input-and-math/
assets: []
---

# 03. Input and math

## Why it matters
A waiter asks for the bill and tip rate before calculating a total. A useful program also needs a way to receive facts rather than having every fact fixed in the recipe. Reading a line turns a keyboard reply into data the program can use.

## What you will build
A tip calculator. Enter 80 and 15 on separate lines to see the tip, total, change from 100 and an example of a remainder.

## Before you start
- Finish lesson 02; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-1-foundations/03-input-and-math/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson03` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson03`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **method** is a function called on a value with a dot; a **method chain** links such calls. An **operator** is a symbol acting on values, such as + or /. **Standard input** is the input stream, usually your keyboard. A **panic** stops a program after an unrecovered failure. Empty **owned text** is a String responsible for its own text storage, initially containing no characters.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson03`) and package name (`input_and_math`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name input_and_math lesson03
cd lesson03
```

Cargo reports project creation; the prompt should end in `lesson03`. If it already exists, keep your work and use `cd "$HOME/code101/lesson03"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson03/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson03/Cargo.toml`**
```toml
[package]
name = "input_and_math"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `input_and_math`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
Use decimal points, not decimal commas. For this first input program use nonnegative numeric values; do not type a currency symbol or a percent sign. Lesson 09 replaces the deliberate stop-on-bad-input behavior with a re-ask loop.

Replace src/main.rs with the full file below. First it asks for the bill, then it asks for a tip percentage. Each read needs its own empty String; both are trimmed before numeric conversion.

**File: `lesson03/src/main.rs`**
```rust
use std::io;

fn main() {
    let mut bill_text = String::new();
    println!("Bill amount (for example 80):");
    io::stdin().read_line(&mut bill_text).expect("Could not read bill");
    let bill = bill_text.trim().parse::<f64>().expect("Use a number");
    let mut tip_text = String::new();
    println!("Tip percent (for example 15):");
    io::stdin().read_line(&mut tip_text).expect("Could not read tip");
    let percent = tip_text.trim().parse::<f64>().expect("Use a number");
    let tip = bill * percent / 100.0;
    let total = bill + tip;
    println!("Tip: {tip:.2}");
    println!("Total: {total:.2}");
    println!("Change from 100: {:.2}", 100.0 - total);
    println!("7 % 3 = {}", 7 % 3);
}
```

## Run it
In `$HOME/code101/lesson03`, save all files and run:

**File: `terminal in $HOME/code101/lesson03`**
```powershell
cargo run --quiet
```

Type each line below **when the program asks for it**, pressing Enter after each. These are keyboard replies, not terminal commands. The output block excludes the keyboard's echo of what you type.

**File: `keyboard input for this run`**
```text
80
15
```

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Bill amount (for example 80):
Tip percent (for example 15):
Tip: 12.00
Total: 92.00
Change from 100: 8.00
7 % 3 = 1
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson03/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "input_and_math"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. `std` is Rust's **standard library**, tools shipped with Rust. `io` is its input/output **module** (a group of related tools). `use std::io;` brings the short name `io` into this file; `::` separates parts of a path.
2. `String::new()` makes empty owned text. `stdin()` is **standard input**, normally your keyboard. `.read_line(...)` waits until you press Enter and appends the line, including its line ending, to the String.
3. `&mut bill_text` temporarily lends the String for editing: read_line needs permission to write into it. The binding itself also needs `mut`. This is a first borrowed reference; lesson 10 explains the full rules.
4. `.trim()` views the text without leading or trailing whitespace (spaces or line endings). `.parse::<f64>()` attempts to convert that text to a decimal number. The `::<f64>` explicitly selects the output type. Calls linked with dots form a **method chain**: each uses the previous call's result.
5. Both reading and parsing can fail. `.expect("...")` takes the successful value or stops with that message, a **panic**. This is a deliberate shortcut for controlled inputs, not a friendly final interface. Lesson 09 explains Result and handles failures.
6. `*` multiplies, `/` divides, `+` adds and `-` subtracts. Multiplication and division happen before addition and subtraction; parentheses override that order. `bill * percent / 100.0` converts a percentage to money. With whole numbers, division discards the fractional part; these values are f64 instead.
7. `%` is the **remainder** operator: 7 divided by 3 leaves 1. It is not a percent sign. The bare `{}` takes the next value after the comma in println!, while `{:.2}` prints that value to two decimal places.

## Try it
Split a total bill equally. Read 90 for the total and 3 for the people count (greater than zero). The starter currently gives the wrong share; correct its calculation. This small exercise assumes valid positive inputs.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson03-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name input_and_math lesson03-exercise
cd lesson03-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-1-foundations/03-input-and-math/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson03-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson03-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson03-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "input_and_math"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson03-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "input_and_math"
version = "0.1.0"
```

**File: `lesson03-exercise/src/main.rs (starter)`**
```rust
use std::io;

fn main() {
    let mut total_text = String::new();
    println!("Total bill:");
    io::stdin().read_line(&mut total_text).expect("Could not read total");
    let total = total_text.trim().parse::<f64>().expect("Use a number");
    let mut people_text = String::new();
    println!("People (greater than zero):");
    io::stdin().read_line(&mut people_text).expect("Could not read people");
    let people = people_text.trim().parse::<f64>().expect("Use a number");
    // TODO: calculate each person's equal share.
    let each = total + people;
    println!("Each: {each:.2}");
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson03-exercise`**
```powershell
cargo run --quiet
```

Supply these lines at the prompts, one per Enter:

**File: `keyboard input for the completed exercise`**
```text
90
3
```

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Total bill:
People (greater than zero):
Each: 30.00
```


<details><summary>Solution: complete project files</summary>

Divide total by people. Using f64 allows fractional shares. Real payment software must define rounding and remainder-sharing rules; lesson 12 stores money as whole cents instead.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "input_and_math"
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
name = "input_and_math"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::io;

fn main() {
    let mut total_text = String::new();
    println!("Total bill:");
    io::stdin().read_line(&mut total_text).expect("Could not read total");
    let total = total_text.trim().parse::<f64>().expect("Use a number");
    let mut people_text = String::new();
    println!("People (greater than zero):");
    io::stdin().read_line(&mut people_text).expect("Could not read people");
    let people = people_text.trim().parse::<f64>().expect("Use a number");
    let each = total / people;
    println!("Each: {each:.2}");
}
```

</details>

## Check yourself
1. Why trim before parsing?
   <details><summary>Answer</summary>read_line retains the line ending, which should not be part of the number.</details>
2. Does % calculate a tip percent?
   <details><summary>Answer</summary>No. It finds a division remainder. Divide the percentage by 100.0 for a tip.</details>
3. Why use &mut with read_line?
   <details><summary>Answer</summary>The function must be able to write into the existing String.</details>
4. What happens if expect receives a failed parse?
   <details><summary>Answer</summary>The program panics and stops with the supplied message.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson03-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson03-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name input_and_math lesson03-error
cd lesson03-error
```

**File: `lesson03-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let bill: f64 = "80";
    println!("{bill}");
}
```

**File: `terminal in $HOME/code101/lesson03-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0308]: mismatched types
 --> src\main.rs:2:21
  |
2 |     let bill: f64 = "80";
  |               ---   ^^^^ expected `f64`, found `&str`
  |               |
  |               expected due to this

For more information about this error, try `rustc --explain E0308`.
error: could not compile `input_and_math` (bin "input_and_math") due to 1 previous error
```

E0308 says the declared f64 and the supplied &str do not agree. For a fixed number remove the quotes; for typed input keep the text and use trim().parse::<f64>() to convert it.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Typing $80 at the bill prompt (15% and 80,50 produce the same Invalid error):

**File: `terminal standard error (captured)`**
```text

thread 'main' (24420) panicked at src\main.rs:7:48:
Use a number: ParseFloatError { kind: Invalid }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

Pressing Enter without a number:

**File: `terminal standard error (captured)`**
```text

thread 'main' (5336) panicked at src\main.rs:7:48:
Use a number: ParseFloatError { kind: Empty }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

Removing .trim() from bill_text, then entering 80:

**File: `terminal standard error (captured)`**
```text

thread 'main' (13544) panicked at src\main.rs:7:41:
Use a number: ParseFloatError { kind: Invalid }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

The RUST_BACKTRACE note only offers extra debugging detail; it does not ask you to run another command. Restart and correct the input or restore trim(). In the completed exercise, entering 90 then 0 prints `Each: inf`; inf means infinity, the floating-point result of dividing a positive number by zero. Use a people count greater than zero.

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0308]: mismatched types | The f64 declaration was given quoted text. | Use `80.0` for a fixed number; parse keyboard text into f64. |
| Use a number: ParseFloatError { kind: Invalid } | Typed $80, 15% or 80,50; these are not plain decimal numbers. | Enter 80, 15 or 80.50 without a currency or percent symbol. |
| Use a number: ParseFloatError { kind: Invalid } | Removed trim(), so the Enter key's line ending reaches parse. | Restore trim() before parse; even typing 80 includes a line ending. |
| Use a number: ParseFloatError { kind: Empty } | Pressed Enter without a number. | Enter a numeric value before pressing Enter. |
| Each: inf | The exercise divided a positive bill by zero people; inf means infinity. | Use a people count greater than zero; lesson 09 teaches validation. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson03"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson03 (or its exercise folder). |

## Best practice
Convert input explicitly at the program boundary, and keep the original text separate from the parsed number. Source: [The Rust Book, Programming a Guessing Game (processing input)](https://doc.rust-lang.org/book/ch02-00-guessing-game-tutorial.html).

## Next lesson
**[04. Making decisions](04-making-decisions.md)**: choose an action with if and match.
