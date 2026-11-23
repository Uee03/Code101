---
track: rust
level: 101
phase: 3
phase_name: real-programs
lesson: "09"
title: "Handling errors"
time: 50-60 min
prerequisites: [101.2.08]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-3-real-programs/09-handling-errors/
assets: []
---

# 09. Handling errors

## Why it matters
A receptionist does not close the building when you give the wrong room number. They explain the problem and ask again. A friendly program distinguishes an absent value, a recoverable mistake and a failure it must report to its caller (the code that called it).

## What you will build
Two small builds: a safe missing-item lookup, then a number reader that re-asks after a nonnumeric answer. The exercise accepts only whole quantities from 1 through 99.

## Before you start
- Finish lesson 08; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 50-60 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-3-real-programs/09-handling-errors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson09` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson09`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **caller** is the code that calls a function. **Option** represents a present value (`Some(value)`) or absence (`None`). **Result** represents success (`Ok(value)`) or failure (`Err(error)`). In `Result<T, E>`, T and E are placeholders for the success and error types. **Error propagation** passes an error back to the caller; `?` is the propagation operator. A **re-ask loop** repeats after rejected input. **Validation** checks whether a successfully parsed value is allowed. **EOF** means end of input: no more input data is available.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson09`) and package name (`handling_errors`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name handling_errors lesson09
cd lesson09
```

Cargo reports project creation; the prompt should end in `lesson09`. If it already exists, keep your work and use `cd "$HOME/code101/lesson09"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson09/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson09/Cargo.toml`**
```toml
[package]
name = "handling_errors"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `handling_errors`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Handle an absent value first
An Option answers only whether a value is present, not whether an operation failed. `.get(1)` safely asks for the second element. Match Some to use a present value; match None to handle absence.

Replace src/main.rs with this complete first checkpoint:

**File: `lesson09/src/main.rs (checkpoint 1)`**
```rust
fn main() {
    let labels = vec!["Tea"];
    match labels.get(1) {
        Some(label) => println!("Second item: {label}"),
        None => println!("No second item"),
    }
}
```

In `$HOME/code101/lesson09`, save all files and run:

**File: `terminal in $HOME/code101/lesson09`**
```powershell
cargo run --quiet
```

No keyboard input is needed.

Expected output (captured; excludes keyboard echo):

**File: `terminal standard output for checkpoint 1`**
```text
No second item
```

### Step 4. Handle a failed operation without a panic
Now replace the entire file with the number reader below. This checkpoint does not need labels or Option. It concentrates on Result: a read error is returned, while a bad number is handled locally by asking again.

`Result<f64, io::Error>` promises either a decimal success or an input/output error. `?` unwraps success or returns the error from this function. `return Ok(value);` ends the function immediately. `Err(_)` matches a failure but ignores its details. main also returns a Result; `Ok(())` means successful completion with no useful result value.

The zero-byte read check handles EOF, not an empty reply: Enter still supplies a line ending. `io::ErrorKind::UnexpectedEof` labels the error we create when input is finished, so the loop cannot ask forever after EOF. You will try that separately below. Allow a short pause here before typing the second build.

**File: `lesson09/src/main.rs`**
```rust
use std::io;

fn read_number() -> Result<f64, io::Error> {
    loop {
        println!("Number:");
        let mut text = String::new();
        if io::stdin().read_line(&mut text)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
        }
        match text.trim().parse::<f64>() {
            Ok(value) => return Ok(value),
            Err(_) => println!("Please use digits, for example 12."),
        }
    }
}

fn main() -> Result<(), io::Error> {
    let value = read_number()?;
    println!("Accepted: {value:.2}");
    Ok(())
}
```

## Run it
In `$HOME/code101/lesson09`, save all files and run:

**File: `terminal in $HOME/code101/lesson09`**
```powershell
cargo run --quiet
```

Type each line below **when the program asks for it**, pressing Enter after each. These are keyboard replies, not terminal commands. The output block excludes the keyboard's echo of what you type.

**File: `keyboard input for this run`**
```text
oops
12
```

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Number:
Please use digits, for example 12.
Number:
Accepted: 12.00
```

### Try end-of-input once
Start a new `cargo run --quiet` in `$HOME/code101/lesson09`. When Number appears, do not type a number. On Windows PowerShell press **Ctrl+Z, then Enter**; on macOS/Linux press **Ctrl+D on an empty line**. This sends EOF. Pressing Enter by itself is not EOF.

Captured standard output:

**File: `terminal standard output at EOF`**
```text
Number:
```

Captured standard error:

**File: `terminal standard error`**
```text
Error: Custom { kind: UnexpectedEof, error: "Input ended" }
```

The program exits with code 1 (an unsuccessful run). This is an intentional reported I/O error, not a panic and not another re-ask. Restart the program to supply new input.

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson09/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "handling_errors"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. In Step 3, `labels.get(1)` checks for the second element. **Option<T>** represents possible absence: `Some(value)` when present or `None` when absent. match opens that wrapper safely; no unchecked indexing is needed. The T is a generic type parameter, a placeholder for the contained type.
2. **Result<T, E>** represents an operation that can fail: `Ok(value)` for success, `Err(error)` for failure. Here T is f64 and E is io::Error. parse also returns a Result, but its error describes bad numeric text rather than a failed read.
3. `read_number` loops. The line read returns a Result. The **propagation operator** `?` extracts success or immediately returns the error to the caller. It does not retry and is not the same as expect: expect panics on failure.
4. The successful read count is zero at **end of input** (EOF), meaning no more data is available. Return an explicit UnexpectedEof error instead of re-asking forever. Pressing Enter on an empty line is different: that still reads a line ending, then parsing fails normally.
5. The parse match handles `Ok(value)` by using `return Ok(value);` to leave the loop and function together. `Err(_)` ignores the detailed parse error, prints guidance and reaches the next iteration. This is a **re-ask loop**.
6. `main` returns `Result<(), io::Error>` too. Its question mark propagates a read error to Rust's program entry machinery; Rust displays it and exits unsuccessfully. On success `Ok(())` wraps unit to mean the program completed. In the exercise, an inner if checks the numeric value after parsing, because numeric text can still be unacceptable.

## Try it
The quantity reader accepts values outside the permitted range. Make it accept only whole quantities from 1 through 99, including both endpoints. Keep separate messages for text that is not a whole number and numbers outside that range. In one run, reject -2 and 100 before accepting 3.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson09-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name handling_errors lesson09-exercise
cd lesson09-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-3-real-programs/09-handling-errors/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson09-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson09-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson09-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "handling_errors"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson09-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "handling_errors"
version = "0.1.0"
```

**File: `lesson09-exercise/src/main.rs (starter)`**
```rust
use std::io;

fn read_quantity() -> Result<i32, io::Error> {
    loop {
        println!("Quantity (1-99):");
        let mut text = String::new();
        if io::stdin().read_line(&mut text)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
        }
        match text.trim().parse::<i32>() {
            Ok(value) => {
                // TODO: accept only the permitted quantity range.
                if value >= -100 {
                    return Ok(value);
                }
                println!("Use a quantity from 1 to 99.");
            }
            Err(_) => println!("Please use a whole number."),
        }
    }
}

fn main() -> Result<(), io::Error> {
    let quantity = read_quantity()?;
    println!("Accepted quantity: {quantity}");
    Ok(())
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson09-exercise`**
```powershell
cargo run --quiet
```

Supply these lines at the prompts, one per Enter:

**File: `keyboard input for the completed exercise`**
```text
-2
100
3
```

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Quantity (1-99):
Use a quantity from 1 to 99.
Quantity (1-99):
Use a quantity from 1 to 99.
Quantity (1-99):
Accepted quantity: 3
```


<details><summary>Solution: complete project files</summary>

Parsing answers whether the text is an i32; validation answers whether that number is allowed. Keeping those checks separate makes their messages useful.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "handling_errors"
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
name = "handling_errors"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::io;

fn read_quantity() -> Result<i32, io::Error> {
    loop {
        println!("Quantity (1-99):");
        let mut text = String::new();
        if io::stdin().read_line(&mut text)? == 0 {
            return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
        }
        match text.trim().parse::<i32>() {
            Ok(value) => {
                if value >= 1 && value <= 99 {
                    return Ok(value);
                }
                println!("Use a quantity from 1 to 99.");
            }
            Err(_) => println!("Please use a whole number."),
        }
    }
}

fn main() -> Result<(), io::Error> {
    let quantity = read_quantity()?;
    println!("Accepted quantity: {quantity}");
    Ok(())
}
```

</details>

## Check yourself
1. What is None?
   <details><summary>Answer</summary>An Option with no contained value, not a failed Result.</details>
2. Does ? ask again?
   <details><summary>Answer</summary>No. It returns an error to the caller; the explicit loop does the re-asking.</details>
3. Why check a zero read count?
   <details><summary>Answer</summary>Otherwise EOF could cause an endless re-ask loop.</details>
4. How is Err(_) used here?
   <details><summary>Answer</summary>It handles the failure while deliberately ignoring the detailed error value.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson09-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson09-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name handling_errors lesson09-error
cd lesson09-error
```

**File: `lesson09-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let mut text = String::new();
    std::io::stdin().read_line(&mut text)?;
}
```

**File: `terminal in $HOME/code101/lesson09-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` (or another type that implements `FromResidual`)
 --> src\main.rs:3:42
  |
1 | fn main() {
  | --------- this function should return `Result` or `Option` to accept `?`
2 |     let mut text = String::new();
3 |     std::io::stdin().read_line(&mut text)?;
  |                                          ^ cannot use the `?` operator in a function that returns `()`
  |
help: consider adding return type
  |
1 ~ fn main() -> Result<(), Box<dyn std::error::Error>> {
2 |     let mut text = String::new();
3 |     std::io::stdin().read_line(&mut text)?;
4 +     Ok(())
  |

For more information about this error, try `rustc --explain E0277`.
error: could not compile `handling_errors` (bin "handling_errors") due to 1 previous error
```

E0277 points to ? inside a function that returns unit. Restore the Result return type and end the success path with Ok(()), as in the working source. Ignore the advanced Box suggestion here; the shown io::Error return type is sufficient.

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` (or another type that implements `FromResidual`) | The function using ? returns unit, not a compatible Result. | Restore the shown Result return type and the success value `Ok(())`. |
| Error: Custom { kind: UnexpectedEof, error: "Input ended" } | Input ended instead of supplying another line. | Restart to enter more data; this is a reported I/O error, not a parse retry. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson09"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson09 (or its exercise folder). |

## Best practice
Return Result for failures callers should handle, and use ? to propagate failures rather than hiding them or forcing a panic. Source: [The Rust Book, Recoverable Errors with Result](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html).

## Next lesson
**[10. Ownership and borrowing basics](10-ownership-and-borrowing.md)**: understand who owns a value and how borrowing works.
