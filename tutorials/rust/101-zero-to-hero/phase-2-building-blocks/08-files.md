---
track: rust
level: 101
phase: 2
phase_name: building-blocks
lesson: "08"
title: "Files"
time: 40-50 min
prerequisites: [101.2.07]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-2-building-blocks/08-files/
assets: []
---

# 08. Files

## Why it matters
A notebook remembers a shopping list after you go home. A running program forgets its variables when it exits, so it needs files to remember information. Text files also let another person inspect the data without special software.

## What you will build
A stock summary read from a tiny CSV (comma-separated values: rows of fields separated by commas) file and written to summary.txt. You will also count product rows in a separate exercise.

## Before you start
- Finish lesson 07; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 40-50 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-2-building-blocks/08-files/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson08` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson08`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

The **file system** stores files and folders. A **relative path** starts from the current folder. **UTF-8** is a rule for storing text characters as bytes. A **header** is the first row naming columns; a **field** is one value between separators. An **iterator** yields values one at a time. A **newline** is a line-ending character, written `\n` inside a Rust string.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson08`) and package name (`files`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name files lesson08
cd lesson08
```

Cargo reports project creation; the prompt should end in `lesson08`. If it already exists, keep your work and use `cd "$HOME/code101/lesson08"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson08/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson08/Cargo.toml`**
```toml
[package]
name = "files"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `files`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Create the data file beside Cargo.toml
In your editor create `$HOME/code101/lesson08/supplies.csv` as plain UTF-8 text with the full contents below. Save with the exact extension, not .txt. Keep the final line ending. The first row names the columns; the remaining rows are the data.

**File: `lesson08/supplies.csv`**
```csv
item,quantity
Tea,2
Rice,3
```

### Step 4. Read the file first
Replace src/main.rs with this first runnable build. `fs::read_to_string` opens a UTF-8 file and returns all its text; expect stops if opening or reading fails. `print!` prints without adding another line ending.

**File: `lesson08/src/main.rs (checkpoint 1)`**
```rust
use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    print!("{text}");
}
```

In `$HOME/code101/lesson08`, save all files and run:

**File: `terminal in $HOME/code101/lesson08`**
```powershell
cargo run --quiet
```

No keyboard input is needed.

Expected output (captured; excludes keyboard echo):

**File: `terminal standard output for checkpoint 1`**
```text
item,quantity
Tea,2
Rice,3
```

### Step 5. Sum the product quantities and write a report
We will use the same text, not open the file a second way. `text.lines()` yields each line; `.skip(1)` skips the header. `.split(',')` visits the fields and `.collect()` gathers them into a vector. `Vec<&str>` says this is a vector of borrowed text views. `format!` builds text using placeholders instead of printing it; `fs::write` creates or replaces a file. Here `&report` lends the report text so it can also be printed afterwards.

Replace src/main.rs with the complete second build below. The only new work is the sum and report; keep supplies.csv beside Cargo.toml, never inside src. The literal `\n` is two characters you type inside the string: Rust turns them into a newline in the report.

**File: `lesson08/src/main.rs`**
```rust
use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    print!("{text}");
    let mut total = 0;
    for line in text.lines().skip(1) {
        let fields: Vec<&str> = line.split(',').collect();
        let quantity = fields[1].parse::<i32>().expect("Use a whole quantity");
        total = total + quantity;
    }
    let report = format!("Total items: {total}\n");
    fs::write("summary.txt", &report).expect("Could not write summary.txt");
    print!("{report}");
}
```

## Run it
In `$HOME/code101/lesson08`, save all files and run:

**File: `terminal in $HOME/code101/lesson08`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
item,quantity
Tea,2
Rice,3
Total items: 5
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson08/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "files"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

The program creates or replaces `summary.txt` in the project folder. Its content after this one run is:

**File: `lesson08/summary.txt`**
```text
Total items: 5
```

## How it works
1. `std::fs` supplies file-system operations. read_to_string opens the small UTF-8 file and loads it into one String. This lesson uses only that reading approach.
2. A relative path such as supplies.csv is resolved from the terminal's current folder, not from src. Run in the folder containing Cargo.toml and supplies.csv.
3. `.lines()` produces an iterator over borrowed line text, with the line endings removed. `.skip(1)` omits the header. Because the complete file was already read successfully, these lines need no separate expect call.
4. `.split(',').collect()` makes a `Vec<&str>` of fields. Index 1 is the quantity column; parse converts it into an i32 to add to total. These views refer to text, which remains available through the loop.
5. format! returns a String. `\n` creates a newline, and fs::write saves the report to summary.txt, replacing any previous report. Lending &report keeps it available for the final print.
6. This restricted CSV accepts no quoted fields, embedded commas or blank product rows. Use only the trusted fixture here; lesson 12 validates its own equally restricted format.

## Try it
Count product rows, not their quantities. The expected report is Product rows: 2, even though the quantities sum to 5. Keep the existing row display and output file; the source CSV must stay unchanged.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson08-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name files lesson08-exercise
cd lesson08-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-2-building-blocks/08-files/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson08-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson08-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson08-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "files"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson08-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "files"
version = "0.1.0"
```

**File: `lesson08-exercise/supplies.csv (starter)`**
```csv
item,quantity
Tea,2
Rice,3
```

**File: `lesson08-exercise/src/main.rs (starter)`**
```rust
use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    let mut rows = 0;
    for line in text.lines().skip(1) {
        println!("Row: {line}");
        // TODO: record that another product row was visited.
    }
    let report = format!("Product rows: {rows}\n");
    fs::write("rows.txt", &report).expect("Could not write rows.txt");
    print!("{report}");
}
```

The unfinished starter can print the unused-mut warning from lesson 02, then Product rows: 0. Complete the row-counting goal before comparing with the expected output.

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson08-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Row: Tea,2
Row: Rice,3
Product rows: 2
```


<details><summary>Solution: complete project files</summary>

Two product lines mean two increments even though their quantities sum to five. fs::write saves the finished report in the exercise project's current folder.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "files"
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
name = "files"
version = "0.1.0"
```

**File: `exercise/solution/supplies.csv`**
```csv
item,quantity
Tea,2
Rice,3
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::fs;

fn main() {
    let text = fs::read_to_string("supplies.csv").expect("Could not read supplies.csv");
    let mut rows = 0;
    for line in text.lines().skip(1) {
        println!("Row: {line}");
        rows = rows + 1;
    }
    let report = format!("Product rows: {rows}\n");
    fs::write("rows.txt", &report).expect("Could not write rows.txt");
    print!("{report}");
}
```

After the captured exercise run, the generated output file contains:

**File: `lesson08-exercise/rows.txt`**
```text
Product rows: 2
```

</details>

## Check yourself
1. Where is supplies.csv looked up?
   <details><summary>Answer</summary>In the current working folder, not automatically beside main.rs.</details>
2. Why skip one line?
   <details><summary>Answer</summary>The first line names the columns and is not a product.</details>
3. Does fs::write append?
   <details><summary>Answer</summary>No. It creates or replaces the file.</details>
4. Can split handle a comma inside a quoted product name?
   <details><summary>Answer</summary>Not with this simple reader. Such data is outside this lesson's restricted format.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson08-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson08-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name files lesson08-error
cd lesson08-error
```

**File: `lesson08-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let report = "Total items: 5"
    println!("{report}");
}
```

**File: `terminal in $HOME/code101/lesson08-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error: expected `;`, found `println`
 --> src\main.rs:2:34
  |
2 |     let report = "Total items: 5"
  |                                  ^ help: add `;` here
3 |     println!("{report}");
  |     ------- unexpected token

error: could not compile `files` (bin "files") due to 1 previous error
```

The missing semicolon is on the let report line, above the println! that reveals it. Add ; after the closing quote. A compiler often notices a missing separator only when it reaches the next instruction.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Running cargo run --quiet inside lesson08/src:

**File: `terminal standard error (captured)`**
```text

thread 'main' (28064) panicked at src\main.rs:4:51:
Could not read supplies.csv: Os { code: 2, kind: NotFound, message: "The system cannot find the file specified." }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error: expected `;`, found `println` | The let report declaration is missing its semicolon. | End that declaration with `;` before the next print. |
| Could not read supplies.csv: Os { code: 2, kind: NotFound, message: "The system cannot find the file specified." } | Ran inside src: Cargo found the parent manifest, but the app looks for the CSV in the current folder. | Run `cd "$HOME/code101/lesson08"`; keep supplies.csv beside Cargo.toml. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson08"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson08 (or its exercise folder). |

## Best practice
Use read_to_string for a small complete UTF-8 text file, and keep relative data paths anchored to a clearly stated current folder. Source: [Rust standard library, read_to_string](https://doc.rust-lang.org/std/fs/fn.read_to_string.html).

## Next lesson
**[09. Handling errors](../phase-3-real-programs/09-handling-errors.md)**: start Phase 3 by handling missing values and failed operations.
