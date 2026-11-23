---
track: rust
level: 101
phase: 3
phase_name: real-programs
lesson: "10"
title: "Ownership and borrowing basics"
time: 35 min
prerequisites: [101.3.09]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-3-real-programs/10-ownership-and-borrowing/
assets: []
---

# 10. Ownership and borrowing basics

## Why it matters
A library book has one keeper responsible for returning it. Giving it to another keeper transfers responsibility; lending it lets someone read without taking ownership. Rust tracks values in much the same way, preventing you from using a book you already handed away.

## What you will build
A library-book demonstration that moves a String, makes an independent copy, lends it for reading and then lends it for editing.

## Before you start
- Finish lesson 09; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-3-real-programs/10-ownership-and-borrowing/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson10` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson10`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A value's **owner** is responsible for its storage. A **move** transfers that responsibility; a **clone** makes an independent duplicate. A **reference** is borrowed access without ownership. A **shared borrow**, `&`, allows reading; an **exclusive borrow**, `&mut`, allows editing. The compiler calls shared borrows **immutable** and exclusive borrows **mutable**.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson10`) and package name (`ownership_and_borrowing`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name ownership_and_borrowing lesson10
cd lesson10
```

Cargo reports project creation; the prompt should end in `lesson10`. If it already exists, keep your work and use `cd "$HOME/code101/lesson10"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson10/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson10/Cargo.toml`**
```toml
[package]
name = "ownership_and_borrowing"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `ownership_and_borrowing`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
This is about who may use a value, not about physical libraries. Do not add a print of book after it moves to reader; the Common mistakes section deliberately tries that and captures the error.

Replace src/main.rs with the full file below. Follow the book from its initial owner into reader, then through an independent clone, a shared loan and an exclusive loan. Each loan finishes before the next one starts.

**File: `lesson10/src/main.rs`**
```rust
fn read_book(book: &str) {
    println!("Reading: {book}");
}

fn add_note(book: &mut String) {
    book.push_str(" [read]");
}

fn main() {
    let book = String::from("Rust stories");
    let mut reader = book;
    let backup = reader.clone();
    read_book(&reader);
    add_note(&mut reader);
    println!("Reader: {reader}");
    println!("Backup: {backup}");
}
```

## Run it
In `$HOME/code101/lesson10`, save all files and run:

**File: `terminal in $HOME/code101/lesson10`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Reading: Rust stories
Reader: Rust stories [read]
Backup: Rust stories
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson10/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "ownership_and_borrowing"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. **Ownership** is Rust's rule that each owned value has one responsible owner. When that owner leaves scope, Rust releases the value's resources; this is called **drop**. String owns its text storage.
2. `let mut reader = book;` performs a **move**: responsibility for the String transfers to reader. book is no longer usable. The text is not automatically duplicated. Small types such as i32 and bool instead support **Copy**, so assigning them copies their value and keeps the original usable.
3. `.clone()` makes a **clone**, an explicit independent duplicate. Here backup owns separate text. Copying all that text costs time and memory; it is not the same as lending the original.
4. A **reference** is a borrowed way to access a value without taking ownership. `&reader` is a **shared borrow**, allowing reading. The read_book parameter is &str, a view that can read String text too; the conversion happens automatically for this call.
5. `&mut reader` is an **exclusive borrow**, permitting changes. The String binding must be mut, and add_note receives &mut String so it can call push_str to append text. Changing reader does not alter backup.
6. At a given time you may have several shared borrows, OR one exclusive borrow, not both in overlapping use. A reference cannot outlive its owner. In this example each loan is last used inside its function call, so the later mutable loan is permitted.
7. An ampersand at a call site requests a borrow; an ampersand in a parameter type describes the kind of reference accepted. These are the same loans you used with read_line and vector loops earlier.

## Try it
The stamp and show helpers are complete, but main does not call them. Add calls that stamp Garden guide and display the stamped original without moving it. Choose the appropriate reference for each call. The cloned backup must stay unchanged; the output below is the goal.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson10-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name ownership_and_borrowing lesson10-exercise
cd lesson10-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-3-real-programs/10-ownership-and-borrowing/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson10-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson10-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson10-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "ownership_and_borrowing"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson10-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "ownership_and_borrowing"
version = "0.1.0"
```

**File: `lesson10-exercise/src/main.rs (starter)`**
```rust
fn stamp(book: &mut String) {
    book.push_str(" [library]");
}

fn show(book: &str) {
    println!("Book: {book}");
}

fn main() {
    let mut book = String::from("Garden guide");
    let backup = book.clone();
    // TODO: call stamp, then show, without moving book.
    // Choose the correct kind of reference for each call.
    println!("Backup: {backup}");
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson10-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Book: Garden guide [library]
Backup: Garden guide
```


<details><summary>Solution: complete project files</summary>

stamp changes only the borrowed original String. show reads it without moving it; backup retains the original un-stamped title.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "ownership_and_borrowing"
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
name = "ownership_and_borrowing"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
fn stamp(book: &mut String) {
    book.push_str(" [library]");
}

fn show(book: &str) {
    println!("Book: {book}");
}

fn main() {
    let mut book = String::from("Garden guide");
    let backup = book.clone();
    stamp(&mut book);
    show(&book);
    println!("Backup: {backup}");
}
```

</details>

## Check yourself
1. Can book be used after let reader = book for a String?
   <details><summary>Answer</summary>No. Ownership moved to reader.</details>
2. Is clone a borrow?
   <details><summary>Answer</summary>No. It duplicates the owned value.</details>
3. Can a shared borrow edit a String?
   <details><summary>Answer</summary>No. Editing needs an exclusive &mut borrow and a mutable owner.</details>
4. Can two &mut loans overlap in use?
   <details><summary>Answer</summary>No. The exclusive loan must finish before another loan uses that value.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson10-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson10-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name ownership_and_borrowing lesson10-error
cd lesson10-error
```

**File: `lesson10-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let book = String::from("Rust stories");
    let reader = book;
    println!("{book}");
    println!("{reader}");
}
```

**File: `terminal in $HOME/code101/lesson10-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0382]: borrow of moved value: `book`
 --> src\main.rs:4:16
  |
2 |     let book = String::from("Rust stories");
  |         ---- move occurs because `book` has type `String`, which does not implement the `Copy` trait
3 |     let reader = book;
  |                  ---- value moved here
4 |     println!("{book}");
  |                ^^^^ value borrowed here after move
  |
help: consider cloning the value if the performance cost is acceptable
  |
3 |     let reader = book.clone();
  |                      ++++++++

For more information about this error, try `rustc --explain E0382`.
error: could not compile `ownership_and_borrowing` (bin "ownership_and_borrowing") due to 1 previous error
```

E0382 points to the use of book after the move. Print reader instead, lend book with & when transfer is not needed, or explicitly clone if two independent owners are truly required.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Removing mut from let mut reader = book:

**File: `terminal standard error (captured)`**
```text
error[E0596]: cannot borrow `reader` as mutable, as it is not declared as mutable
  --> src\main.rs:14:14
   |
14 |     add_note(&mut reader);
   |              ^^^^^^^^^^^ cannot borrow as mutable
   |
help: consider changing this to be mutable
   |
11 |     let mut reader = book;
   |         +++

For more information about this error, try `rustc --explain E0596`.
error: could not compile `ownership_and_borrowing` (bin "ownership_and_borrowing") due to 1 previous error
```

Before add_note, binding let shared = &reader; then printing shared after add_note:

**File: `terminal standard error (captured)`**
```text
error[E0502]: cannot borrow `reader` as mutable because it is also borrowed as immutable
  --> src\main.rs:15:14
   |
14 |     let shared = &reader;
   |                  ------- immutable borrow occurs here
15 |     add_note(&mut reader);
   |              ^^^^^^^^^^^ mutable borrow occurs here
16 |     println!("{shared}");
   |                ------ immutable borrow later used here

For more information about this error, try `rustc --explain E0502`.
error: could not compile `ownership_and_borrowing` (bin "ownership_and_borrowing") due to 1 previous error
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0382]: borrow of moved value: `book` | Ownership moved from book to reader before the print. | Print reader instead; borrow when a transfer is not needed. |
| error[E0596]: cannot borrow `reader` as mutable, as it is not declared as mutable | Removed mut from the reader declaration. | Restore `let mut reader = book;` before taking an editing reference. |
| error[E0502]: cannot borrow `reader` as mutable because it is also borrowed as immutable | A shared reference is used after add_note takes an exclusive reference. | Finish the last use of the shared reference before calling add_note. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson10"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson10 (or its exercise folder). |

## Best practice
Borrow text as &str when a function only needs to read it; reserve &mut String for operations that change the owned text. Source: [The Rust Book, References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html).

## Next lesson
**[11. Structs, enums and impl blocks](11-structs-enums-and-impl.md)**: group values and behavior into your own types.
