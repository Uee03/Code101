---
track: rust
level: 101
phase: 3
phase_name: real-programs
lesson: "12"
title: "Project: expense tracker"
time: 100-120 min
prerequisites: [101.3.11]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

## Why it matters
A household ledger needs more than arithmetic: it must remember entries, reject unusable amounts and let you review the total. You already know each of those small recipes. This project combines them into one useful console application.

## What you will build
An expense tracker with Add, List, Total and Quit commands, a restricted CSV file, integer-cent amounts and a tiny self-check (a known example checked during an ordinary run) using assert! (a macro that stops if a condition is false). The exercise adds a Count command. Allow 100-120 minutes in two sittings and build it in the checkpoints below.

## Before you start
- Finish lesson 11; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 100-120 min; two sittings of 50-60 minutes, with a marked break after Step 4.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson12` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson12`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

This project has three runnable checkpoints. First build a menu and Add operation; then attach file storage; finally add a self-check. New syntax is explained immediately before its checkpoint, not left for a 150-line first run.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson12`) and package name (`expense_tracker`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name expense_tracker lesson12
cd lesson12
```

Cargo reports project creation; the prompt should end in `lesson12`. If it already exists, keep your work and use `cd "$HOME/code101/lesson12"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson12/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson12/Cargo.toml`**
```toml
[package]
name = "expense_tracker"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `expense_tracker`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Create the data file beside Cargo.toml
In your editor create `$HOME/code101/lesson12/expenses.csv` as plain UTF-8 text with the full contents below. Save with the exact extension, not .txt. Keep the final line ending. This is a fresh, header-only ledger. It contains no sample expenses yet.

**File: `lesson12/expenses.csv`**
```csv
description,cents
```

### Step 4. Build a working menu and Add operation (sitting 1)
This first build keeps entries only in memory. It deliberately does not save yet. Type it in src/main.rs; every part is shown below. This is roughly 50-60 minutes including setup, reading and trying the menu.

`i64` is a signed 64-bit whole-number type; we store whole cents, not decimal money. A **slice** is a borrowed view of consecutive values; `&[Expense]` reads a list of expenses without taking it. `Vec::new()` creates an empty vector; later pushes let Rust infer its element type. `io::Result<T>` is a **type alias**, a shorter spelling for `Result<T, io::Error>`, with exactly the same behavior.

`.is_empty()` checks for no characters; `.contains(',')` checks for the forbidden comma. **continue** skips the rest of the nearest loop iteration and shows the menu again after invalid input. `ErrorKind` names kinds of input/output failures; UnexpectedEof is the end-of-input case from lesson 09. The underscores in `1_000_000_000` only make the number easier to read.

**File: `lesson12/src/main.rs (checkpoint 1)`**
```rust
use std::io;

struct Expense {
    description: String,
    cents: i64,
}

enum Command {
    Add,
    List,
    Total,
    Quit,
    Unknown,
}

fn command(text: &str) -> Command {
    match text {
        "1" => Command::Add,
        "2" => Command::List,
        "3" => Command::Total,
        "4" => Command::Quit,
        _ => Command::Unknown,
    }
}

fn total(expenses: &[Expense]) -> i64 {
    let mut sum = 0;
    for expense in expenses {
        sum = sum + expense.cents;
    }
    sum
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
    if io::stdin().read_line(&mut text)? == 0 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
    }
    Ok(text.trim().to_string())
}

fn main() -> io::Result<()> {
    let mut expenses = Vec::new();
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit")?;
        match command(&choice) {
            Command::Add => {
                let description = read_text("Description (no commas):")?;
                if description.is_empty() || description.contains(',') {
                    println!("Use a nonempty description without commas.");
                    continue;
                }
                let amount = read_text("Cents (0-1000000000):")?;
                let cents = match amount.parse::<i64>() {
                    Ok(value) => value,
                    Err(_) => {
                        println!("Use whole cents.");
                        continue;
                    }
                };
                if cents < 0 || cents > 1_000_000_000 {
                    println!("Cents must be from 0 to 1000000000.");
                    continue;
                }
                expenses.push(Expense { description, cents });
                println!("Added (not saved yet).");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
            Command::Total => println!("Total: {} cents", total(&expenses)),
            Command::Quit => break,
            Command::Unknown => println!("Choose 1, 2, 3 or 4."),
        }
    }
    Ok(())
}
```

In `$HOME/code101/lesson12`, save all files and run:

**File: `terminal in $HOME/code101/lesson12`**
```powershell
cargo run --quiet
```

At the prompts, type these keyboard replies, pressing Enter after each (do not type them as shell commands):

**File: `keyboard input`**
```text
1
Tea
250
2
3
4
```

Expected output (captured; excludes keyboard echo):

**File: `terminal standard output`**
```text
1 Add | 2 List | 3 Total | 4 Quit
Description (no commas):
Cents (0-1000000000):
Added (not saved yet).
1 Add | 2 List | 3 Total | 4 Quit
Tea: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
Total: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
```

No file is changed by this first build. Quit ends the process and discards these in-memory entries. The header-only expenses.csv from Step 3 is still unchanged.

**Marked break - end of sitting 1.** Save src/main.rs and stop here. On returning, start in `$HOME/code101/lesson12`; the first build must run before you add file storage. Sitting 2 adds storage, the self-check and the exercise (about 50-60 minutes).

### Step 5. Attach save and load (checkpoint 2)
**Persistence** means keeping information after exit. **Serialization** turns a record into stored text; csv_row does that for one expense. `text.lines()` visits lines; `.next()` returns an Option containing the next line, or None when finished. `io::ErrorKind::NotFound` means the file is absent; only that read error starts an empty ledger. InvalidData means a file exists but has content this program cannot accept.

Keep the menu and input code from Step 4. Make the following four edits in order, then run. They are the only differences in checkpoint 2.

**Edit 1: replace the initial imports and Expense definition** with the region below, stopping just before the existing enum Command. It adds fs and the csv_row method; the struct fields stay unchanged.

**File: `lesson12/src/main.rs (top, immediately before enum Command)`**
```rust
use std::fs;
use std::io;

struct Expense {
    description: String,
    cents: i64,
}

impl Expense {
    fn csv_row(&self) -> String {
        format!("{},{}\n", self.description, self.cents)
    }
}
```

**Edit 2: insert load and save between total and read_text.** The region below includes the unchanged total function above and the first three unchanged lines of read_text below as placement context. Keep the rest of read_text unchanged. load verifies the header, two-field rows and bounded whole cents rather than silently dropping bad entries. Save replaces the complete ledger; use disposable practice data only.

**File: `lesson12/src/main.rs (total through start of read_text)`**
```rust
fn total(expenses: &[Expense]) -> i64 {
    let mut sum = 0;
    for expense in expenses {
        sum = sum + expense.cents;
    }
    sum
}

fn load() -> io::Result<Vec<Expense>> {
    let text = match fs::read_to_string("expenses.csv") {
        Ok(text) => text,
        Err(error) => {
            if error.kind() == io::ErrorKind::NotFound {
                return Ok(Vec::new());
            }
            return Err(error);
        }
    };
    let mut expenses = Vec::new();
    let mut lines = text.lines();
    if lines.next() != Some("description,cents") {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "Wrong CSV header"));
    }
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        if fields.len() != 2 || fields[0].trim().is_empty() {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad CSV row"));
        }
        let cents = match fields[1].parse::<i64>() {
            Ok(value) => value,
            Err(_) => return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad cents")),
        };
        if cents < 0 || cents > 1_000_000_000 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Cents out of range"));
        }
        expenses.push(Expense { description: fields[0].to_string(), cents });
    }
    Ok(expenses)
}

fn save(expenses: &[Expense]) -> io::Result<()> {
    let mut text = String::from("description,cents\n");
    for expense in expenses {
        text.push_str(&expense.csv_row());
    }
    fs::write("expenses.csv", text)
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
```

**Edit 3: replace the beginning of main through the Command::Add opening line** with this region. Only the initial expenses value changes: it comes from load instead of Vec::new. Keep the existing match arms below it.

**File: `lesson12/src/main.rs (start of main)`**
```rust
fn main() -> io::Result<()> {
    let mut expenses = load()?;
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit")?;
        match command(&choice) {
            Command::Add => {
```

**Edit 4: replace the tail of Add through the List arm** with this region. The new save call writes the ledger before reporting Saved. The List arm is unchanged and supplies placement context; leave Total, Quit, Unknown and the closing lines below it unchanged.

**File: `lesson12/src/main.rs (end of Add and unchanged List arm)`**
```rust
                expenses.push(Expense { description, cents });
                save(&expenses)?;
                println!("Saved.");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
```

Save every edit. The CSV should still contain only the header, because checkpoint 1 never saved. For this disposable practice run, add Tea once:

In `$HOME/code101/lesson12`, save all files and run:

**File: `terminal in $HOME/code101/lesson12`**
```powershell
cargo run --quiet
```

At the prompts, type these keyboard replies, pressing Enter after each (do not type them as shell commands):

**File: `keyboard input`**
```text
1
Tea
250
2
3
4
```

Expected output (captured; excludes keyboard echo):

**File: `terminal standard output`**
```text
1 Add | 2 List | 3 Total | 4 Quit
Description (no commas):
Cents (0-1000000000):
Saved.
1 Add | 2 List | 3 Total | 4 Quit
Tea: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
Total: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
```

The file beside Cargo.toml now contains:

**File: `lesson12/expenses.csv`**
```csv
description,cents
Tea,250
```

Start `cargo run --quiet` again in the same lesson12 folder. Type 3 then 4, pressing Enter after each. Do not add Tea again. This shows that the saved entry survives restarting:

**File: `terminal standard output`**
```text
1 Add | 2 List | 3 Total | 4 Quit
Total: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
```

### Step 6. Add the self-check (checkpoint 3)
An **assert!** is a macro that panics if its condition is false. A **self-check** uses small known in-memory examples during an ordinary run. It does not write sample entries to the ledger. Add the function below between read_text and main. The last three unchanged lines of read_text and the first lines of main show the placement. In main, add the single call self_check() before load; leave the menu loop and all its arms unchanged.

**File: `lesson12/src/main.rs (end of read_text, new self_check, start of main)`**
```rust
    }
    Ok(text.trim().to_string())
}

fn self_check() {
    let sample = vec![
        Expense { description: String::from("Tea"), cents: 250 },
        Expense { description: String::from("Bus"), cents: 400 },
    ];
    assert!(total(&sample) == 650);
    assert!(sample[0].csv_row() == "Tea,250\n");
    println!("Self-check: OK");
}

fn main() -> io::Result<()> {
    self_check();
    let mut expenses = load()?;
    loop {
```

## Run it
Continuing after Step 5, your disposable ledger already has one Tea entry. Do not add it again. In `$HOME/code101/lesson12`, save the checkpoint-3 changes and run:

**File: `terminal in $HOME/code101/lesson12`**
```powershell
cargo run --quiet
```

**File: `keyboard input, one line per Enter`**
```text
2
3
4
```

Expected output with the Tea entry saved in Step 5:

**File: `terminal standard output`**
```text
Self-check: OK
1 Add | 2 List | 3 Total | 4 Quit
Tea: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
Total: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
```

**If starting from a fresh finished-source copy instead:** its expenses.csv contains only the header. Run the same command in that copy's project folder and type 1, Tea, 250, 2, 3, 4, pressing Enter after each. The captured output is:

**File: `terminal standard output`**
```text
Self-check: OK
1 Add | 2 List | 3 Total | 4 Quit
Description (no commas):
Cents (0-1000000000):
Saved.
1 Add | 2 List | 3 Total | 4 Quit
Tea: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
Total: 250 cents
1 Add | 2 List | 3 Total | 4 Quit
```

On later runs, saved entries remain and the total is cumulative. Never reset a ledger containing data you want to keep. If expenses.csv is missing, load starts empty; other read errors are not treated as an empty ledger.

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson12/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "expense_tracker"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

The program replaces `expenses.csv` in the project folder. Its content after this one run is:

**File: `lesson12/expenses.csv`**
```csv
description,cents
Tea,250
```

## How it works
1. Expense owns a description String and an `i64`, a signed 64-bit integer storing whole cents. The larger integer also stores the total. Numeric underscores in `1_000_000_000` are visual separators; they do not change the value. This small ledger assumes its total fits in i64.
2. csv_row builds one comma-separated line with format! and a newline. Command is an enum, and command maps keyboard text to its variants. Unknown input becomes Unknown rather than a panic.
3. A **slice** is a borrowed view of a contiguous sequence; `&[Expense]` reads a list of expenses without taking ownership or requiring a particular vector. Passing &expenses or &sample supplies that view. total adds each cents field and returns the accumulator.
4. `io::Result<T>` is a **type alias**, a shorter name for Result<T, io::Error>. load accepts a missing file as an empty vector, but returns permission or other read errors. It uses an if inside the Err arm rather than treating every read error as an empty ledger.
5. `text.lines()` supplies rows. `.next()` returns an Option containing the next row or None; checking it against Some("description,cents") verifies the header. Each row must have exactly two fields, a nonblank description and a valid bounded integer amount. `||` short-circuits, so fields[0] is not accessed when the field count is wrong. InvalidData errors identify a file that cannot be trusted; they are returned rather than silently deleting rows.
6. save creates a complete header plus rows and replaces expenses.csv using fs::write. read_text prints a prompt, reads one line, handles EOF, trims and returns owned text. `.is_empty()` asks whether text has no characters; `.contains(',')` checks for the forbidden separator.
7. **assert!** is a macro that panics if a condition is false. self_check builds two in-memory sample records, checks their sum and one serialized row, then reports success. It touches no files. main calls it on every ordinary run; this is not cargo test and is not a test suite.
8. main loads saved entries once, then repeats the menu. Add reads and validates a description and cents before pushing a new Expense. `continue` skips the rest of the nearest loop iteration and shows the menu again after invalid input. A bad add is discarded, so you must select Add again. After a successful add, save writes all entries. List borrows the entries; Total calls the calculation; Quit breaks the loop.
9. Errors from reading or writing travel through ? and end main with an error, rather than pretending an entry was saved. Successful Quit ends with Ok(()). A failed save can leave the on-disk file incomplete; robust atomic saving and backups are beyond this beginner project.

## Try it
Add a menu choice 5 named Count that reports how many entries are stored, in the form Entries: 1. Keep Quit on 4. In a fresh exercise copy, add Tea at 250 cents, select 5, then 4.

Complete these five edit sites before running:
- The Command enum: represent the new choice.
- The command function: recognize the text 5.
- The menu prompt: advertise 5 Count.
- The match in main: handle the new command without moving or changing expenses.
- The Unknown message: include the new valid choice.

Adding the enum variant first temporarily produces E0004 until the main match covers it. This is expected midway; Common mistakes includes the captured message. The starter TODO points here because the work spans all five sites.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson12-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name expense_tracker lesson12-exercise
cd lesson12-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson12-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson12-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson12-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "expense_tracker"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson12-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "expense_tracker"
version = "0.1.0"
```

**File: `lesson12-exercise/expenses.csv (starter)`**
```csv
description,cents
```

**File: `lesson12-exercise/src/main.rs (starter)`**
```rust
use std::fs;
use std::io;

struct Expense {
    description: String,
    cents: i64,
}

impl Expense {
    fn csv_row(&self) -> String {
        format!("{},{}\n", self.description, self.cents)
    }
}

enum Command {
    Add,
    List,
    Total,
    Quit,
    Unknown,
}

fn command(text: &str) -> Command {
    match text {
        "1" => Command::Add,
        "2" => Command::List,
        "3" => Command::Total,
        "4" => Command::Quit,
        _ => Command::Unknown,
    }
}

fn total(expenses: &[Expense]) -> i64 {
    let mut sum = 0;
    for expense in expenses {
        sum = sum + expense.cents;
    }
    sum
}

fn load() -> io::Result<Vec<Expense>> {
    let text = match fs::read_to_string("expenses.csv") {
        Ok(text) => text,
        Err(error) => {
            if error.kind() == io::ErrorKind::NotFound {
                return Ok(Vec::new());
            }
            return Err(error);
        }
    };
    let mut expenses = Vec::new();
    let mut lines = text.lines();
    if lines.next() != Some("description,cents") {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "Wrong CSV header"));
    }
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        if fields.len() != 2 || fields[0].trim().is_empty() {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad CSV row"));
        }
        let cents = match fields[1].parse::<i64>() {
            Ok(value) => value,
            Err(_) => return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad cents")),
        };
        if cents < 0 || cents > 1_000_000_000 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Cents out of range"));
        }
        expenses.push(Expense { description: fields[0].to_string(), cents });
    }
    Ok(expenses)
}

fn save(expenses: &[Expense]) -> io::Result<()> {
    let mut text = String::from("description,cents\n");
    for expense in expenses {
        text.push_str(&expense.csv_row());
    }
    fs::write("expenses.csv", text)
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
    if io::stdin().read_line(&mut text)? == 0 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
    }
    Ok(text.trim().to_string())
}

fn self_check() {
    let sample = vec![
        Expense { description: String::from("Tea"), cents: 250 },
        Expense { description: String::from("Bus"), cents: 400 },
    ];
    assert!(total(&sample) == 650);
    assert!(sample[0].csv_row() == "Tea,250\n");
    println!("Self-check: OK");
}

// TODO: complete the five Count-command edit sites listed in the lesson.
fn main() -> io::Result<()> {
    self_check();
    let mut expenses = load()?;
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit")?;
        match command(&choice) {
            Command::Add => {
                let description = read_text("Description (no commas):")?;
                if description.is_empty() || description.contains(',') {
                    println!("Use a nonempty description without commas.");
                    continue;
                }
                let amount = read_text("Cents (0-1000000000):")?;
                let cents = match amount.parse::<i64>() {
                    Ok(value) => value,
                    Err(_) => {
                        println!("Use whole cents.");
                        continue;
                    }
                };
                if cents < 0 || cents > 1_000_000_000 {
                    println!("Cents must be from 0 to 1000000000.");
                    continue;
                }
                expenses.push(Expense { description, cents });
                save(&expenses)?;
                println!("Saved.");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
            Command::Total => println!("Total: {} cents", total(&expenses)),
            Command::Quit => break,
            Command::Unknown => println!("Choose 1, 2, 3 or 4."),
        }
    }
    Ok(())
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson12-exercise`**
```powershell
cargo run --quiet
```

Supply these lines at the prompts, one per Enter:

**File: `keyboard input for the completed exercise`**
```text
1
Tea
250
5
4
```

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Self-check: OK
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
Description (no commas):
Cents (0-1000000000):
Saved.
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
Entries: 1
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
```


<details><summary>Solution: complete project files</summary>

The new enum variant requires a new main match arm. The count reads vector metadata with len; it does not reread or rewrite the CSV. The complete solution below includes every changed region.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "expense_tracker"
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
name = "expense_tracker"
version = "0.1.0"
```

**File: `exercise/solution/expenses.csv`**
```csv
description,cents
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::fs;
use std::io;

struct Expense {
    description: String,
    cents: i64,
}

impl Expense {
    fn csv_row(&self) -> String {
        format!("{},{}\n", self.description, self.cents)
    }
}

enum Command {
    Add,
    List,
    Total,
    Count,
    Quit,
    Unknown,
}

fn command(text: &str) -> Command {
    match text {
        "1" => Command::Add,
        "2" => Command::List,
        "3" => Command::Total,
        "4" => Command::Quit,
        "5" => Command::Count,
        _ => Command::Unknown,
    }
}

fn total(expenses: &[Expense]) -> i64 {
    let mut sum = 0;
    for expense in expenses {
        sum = sum + expense.cents;
    }
    sum
}

fn load() -> io::Result<Vec<Expense>> {
    let text = match fs::read_to_string("expenses.csv") {
        Ok(text) => text,
        Err(error) => {
            if error.kind() == io::ErrorKind::NotFound {
                return Ok(Vec::new());
            }
            return Err(error);
        }
    };
    let mut expenses = Vec::new();
    let mut lines = text.lines();
    if lines.next() != Some("description,cents") {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "Wrong CSV header"));
    }
    for line in lines {
        let fields: Vec<&str> = line.split(',').collect();
        if fields.len() != 2 || fields[0].trim().is_empty() {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad CSV row"));
        }
        let cents = match fields[1].parse::<i64>() {
            Ok(value) => value,
            Err(_) => return Err(io::Error::new(io::ErrorKind::InvalidData, "Bad cents")),
        };
        if cents < 0 || cents > 1_000_000_000 {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Cents out of range"));
        }
        expenses.push(Expense { description: fields[0].to_string(), cents });
    }
    Ok(expenses)
}

fn save(expenses: &[Expense]) -> io::Result<()> {
    let mut text = String::from("description,cents\n");
    for expense in expenses {
        text.push_str(&expense.csv_row());
    }
    fs::write("expenses.csv", text)
}

fn read_text(prompt: &str) -> io::Result<String> {
    println!("{prompt}");
    let mut text = String::new();
    if io::stdin().read_line(&mut text)? == 0 {
        return Err(io::Error::new(io::ErrorKind::UnexpectedEof, "Input ended"));
    }
    Ok(text.trim().to_string())
}

fn self_check() {
    let sample = vec![
        Expense { description: String::from("Tea"), cents: 250 },
        Expense { description: String::from("Bus"), cents: 400 },
    ];
    assert!(total(&sample) == 650);
    assert!(sample[0].csv_row() == "Tea,250\n");
    println!("Self-check: OK");
}

fn main() -> io::Result<()> {
    self_check();
    let mut expenses = load()?;
    loop {
        let choice = read_text("1 Add | 2 List | 3 Total | 4 Quit | 5 Count")?;
        match command(&choice) {
            Command::Add => {
                let description = read_text("Description (no commas):")?;
                if description.is_empty() || description.contains(',') {
                    println!("Use a nonempty description without commas.");
                    continue;
                }
                let amount = read_text("Cents (0-1000000000):")?;
                let cents = match amount.parse::<i64>() {
                    Ok(value) => value,
                    Err(_) => {
                        println!("Use whole cents.");
                        continue;
                    }
                };
                if cents < 0 || cents > 1_000_000_000 {
                    println!("Cents must be from 0 to 1000000000.");
                    continue;
                }
                expenses.push(Expense { description, cents });
                save(&expenses)?;
                println!("Saved.");
            }
            Command::List => {
                for expense in &expenses {
                    println!("{}: {} cents", expense.description, expense.cents);
                }
            }
            Command::Total => println!("Total: {} cents", total(&expenses)),
            Command::Count => println!("Entries: {}", expenses.len()),
            Command::Quit => break,
            Command::Unknown => println!("Choose 1, 2, 3, 4 or 5."),
        }
    }
    Ok(())
}
```

After the captured exercise run, the generated output file contains:

**File: `lesson12-exercise/expenses.csv`**
```csv
description,cents
Tea,250
```

</details>

## Check yourself
1. Why not use f64 for saved cents?
   <details><summary>Answer</summary>Whole cents have an exact integer representation; floating-point decimals may be approximate.</details>
2. Does self_check write fake expenses into the ledger?
   <details><summary>Answer</summary>No. Its sample vector exists only in memory.</details>
3. What happens if the CSV is missing?
   <details><summary>Answer</summary>load starts with an empty vector. Other read errors are propagated.</details>
4. Why is a malformed row an error rather than skipped?
   <details><summary>Answer</summary>Silently skipping it could lose entries when the next save replaces the file.</details>
5. What does continue do after invalid input?
   <details><summary>Answer</summary>It restarts the menu loop; the rejected entry is not added.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson12-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson12-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name expense_tracker lesson12-error
cd lesson12-error
```

**File: `lesson12-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
struct Expense { cents: i64 }

fn main() {
    let tea = Expense { cents: 2.50 };
    println!("{}", tea.cents);
}
```

**File: `terminal in $HOME/code101/lesson12-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0308]: mismatched types
 --> src\main.rs:4:32
  |
4 |     let tea = Expense { cents: 2.50 };
  |                                ^^^^ expected `i64`, found floating-point number

For more information about this error, try `rustc --explain E0308`.
error: could not compile `expense_tracker` (bin "expense_tracker") due to 1 previous error
```

E0308 says the cents field requires i64 but 2.50 is a floating-point literal. Store 250 for two-and-a-half currency units; the interface always asks for whole cents.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

In a disposable ledger, replacing the first line with wrong,header:

**File: `terminal standard error (captured)`**
```text
Error: Custom { kind: InvalidData, error: "Wrong CSV header" }
```

In a disposable ledger, keeping the correct header but adding Tea,oops:

**File: `terminal standard error (captured)`**
```text
Error: Custom { kind: InvalidData, error: "Bad cents" }
```

In the exercise starter, adding only Count to Command before its main arm:

**File: `terminal standard error (captured)`**
```text
error[E0004]: non-exhaustive patterns: `Command::Count` not covered
   --> src\main.rs:107:15
    |
107 |         match command(&choice) {
    |               ^^^^^^^^^^^^^^^^ pattern `Command::Count` not covered
    |
note: `Command` defined here
   --> src\main.rs:15:6
    |
 15 | enum Command {
    |      ^^^^^^^
...
 19 |     Count,
    |     ----- not covered
    = note: the matched value is of type `Command`
help: ensure that all possible cases are being handled by adding a match arm with a wildcard pattern or an explicit pattern as shown
    |
137 ~             Command::Unknown => println!("Choose 1, 2, 3 or 4."),
138 ~             Command::Count => todo!(),
    |

For more information about this error, try `rustc --explain E0004`.
error: could not compile `expense_tracker` (bin "expense_tracker") due to 1 previous error
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0308]: mismatched types | The i64 cents field was given a decimal literal. | Use whole cents: `250`, not `2.50`. |
| Use whole cents. | Entered 2.50 at the cents prompt; parsing an integer failed. | Enter 250; invalid input returns to the menu, so select Add again. |
| Error: Custom { kind: InvalidData, error: "Wrong CSV header" } | The saved file's first line does not match the required header. | Back up the file, then restore description,cents as the first line. |
| Error: Custom { kind: InvalidData, error: "Bad cents" } | A saved amount contains non-integer text such as Tea,oops. | Back up the file and repair the amount to whole cents; do not erase real entries. |
| error[E0004]: non-exhaustive patterns: `Command::Count` not covered | The Count variant was added before its handling in main. | Finish all five exercise edit sites before running again. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson12"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson12 (or its exercise folder). |

## Best practice
Distinguish a missing optional data file from other I/O failures, and propagate errors instead of replacing unreadable data with an empty ledger. Source: [The Rust Book, Recoverable Errors with Result (matching on different errors)](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html#matching-on-different-errors).

## Next lesson
**Rust 101 complete.** Revisit lesson 12 with a fresh disposable ledger, then explain each function aloud. There is no lesson 13 in this level; keep these packs as working examples.
