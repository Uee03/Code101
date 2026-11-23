---
track: rust
level: 101
phase: 3
phase_name: real-programs
lesson: "11"
title: "Structs, enums and impl blocks"
time: 35 min
prerequisites: [101.3.10]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-3-real-programs/11-structs-enums-and-impl/
assets: []
---

# 11. Structs, enums and impl blocks

## Why it matters
An expense form keeps a description, amount and category together. A category list limits the choices so a form cannot say both food and travel at once. Rust gives those ideas names: structs hold related fields, enums choose one variant, and impl blocks keep behavior beside the data.

## What you will build
Two categorized expense records with a constructor and a display method. The exercise extends the categories with Books.

## Before you start
- Finish lesson 10; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-3-real-programs/11-structs-enums-and-impl/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson11` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson11`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **struct** is a named record of related fields. An **enum** offers a fixed set of alternative **variants**. An **impl block** attaches behavior to a type. A **constructor** creates a value (new is a conventional name). An **associated function** is called through the type; a **method** is called on an existing value. A method's **receiver** is that existing value, written self or a reference to it.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson11`) and package name (`structs_enums_and_impl`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name structs_enums_and_impl lesson11
cd lesson11
```

Cargo reports project creation; the prompt should end in `lesson11`. If it already exists, keep your work and use `cd "$HOME/code101/lesson11"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson11/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson11/Cargo.toml`**
```toml
[package]
name = "structs_enums_and_impl"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `structs_enums_and_impl`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
Amounts are whole cents, not approximate decimal prices: 250 means 2.50 in the chosen currency. This lesson stores fixed examples; lesson 12 adds input and persistence (keeping records in a file after exit).

Replace src/main.rs with the full file below. Read the category choices, the record fields, the constructor, the read-only method and finally main. The method matches a borrowed category.

**File: `lesson11/src/main.rs`**
```rust
enum Category {
    Food,
    Travel,
}

struct Expense {
    name: String,
    cents: i32,
    category: Category,
}

impl Expense {
    fn new(name: &str, cents: i32, category: Category) -> Self {
        Self { name: name.to_string(), cents, category }
    }

    fn show(&self) {
        let label = match &self.category {
            Category::Food => "food",
            Category::Travel => "travel",
        };
        println!("{}: {} cents ({label})", self.name, self.cents);
    }
}

fn main() {
    let tea = Expense::new("Tea", 250, Category::Food);
    let bus = Expense::new("Bus", 400, Category::Travel);
    tea.show();
    bus.show();
}
```

## Run it
In `$HOME/code101/lesson11`, save all files and run:

**File: `terminal in $HOME/code101/lesson11`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Tea: 250 cents (food)
Bus: 400 cents (travel)
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson11/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "structs_enums_and_impl"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **struct** is a named record of fields. Expense keeps owned name text, an integer cents amount and a Category together. Fields use name: Type in the definition and name: value when constructing a value.
2. An **enum** is a type with a fixed set of alternative **variants**. Category has Food and Travel. One Category value is one of those variants, written Category::Food or Category::Travel. Option and Result from lesson 09 are also enums; their variants carry values.
3. An **impl block** attaches behavior to a type. `new` is an **associated function**, called Expense::new rather than on an existing expense. It has no self input. Rust does not require the name new; it is a useful convention for creating a value.
4. `Self` refers to the type of this impl, Expense. `Self { name: name.to_string(), cents, category }` constructs the record. to_string copies the borrowed input text into an owned String. A bare field name such as cents is **field shorthand** for cents: cents.
5. `show(&self)` is a method borrowing the existing record. `self.name` and `self.cents` access its fields. A **receiver**, self or a reference to it, is the input that lets a method act on a value. `&self` reads without taking ownership.
6. `match &self.category` borrows the enum, chooses a text label and returns that label as an expression. The trailing semicolon ends the let statement, not the inner match arms. A match with no wildcard must list every variant, so adding a new category makes forgotten handling a compiler error.
7. main calls the constructor twice and then calls each record's show method. The records own their Strings; their read-only methods do not move those Strings out.

## Try it
Extend the expense model to support book purchases. Keep the two existing records, then display a Guide purchase costing 900 cents with the label books. Use the existing constructor and display method. Adding the enum variant before updating show temporarily gives E0004; finish both changes before running. Common mistakes shows that exact halfway diagnostic.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson11-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name structs_enums_and_impl lesson11-exercise
cd lesson11-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-3-real-programs/11-structs-enums-and-impl/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson11-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson11-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson11-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "structs_enums_and_impl"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson11-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "structs_enums_and_impl"
version = "0.1.0"
```

**File: `lesson11-exercise/src/main.rs (starter)`**
```rust
enum Category {
    Food,
    Travel,
}

struct Expense {
    name: String,
    cents: i32,
    category: Category,
}

impl Expense {
    fn new(name: &str, cents: i32, category: Category) -> Self {
        Self { name: name.to_string(), cents, category }
    }

    fn show(&self) {
        let label = match &self.category {
            Category::Food => "food",
            Category::Travel => "travel",
        };
        println!("{}: {} cents ({label})", self.name, self.cents);
    }
}

fn main() {
    let tea = Expense::new("Tea", 250, Category::Food);
    let bus = Expense::new("Bus", 400, Category::Travel);
    tea.show();
    bus.show();
    // TODO: support a Guide book purchase costing 900 cents.
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson11-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Tea: 250 cents (food)
Bus: 400 cents (travel)
Guide: 900 cents (books)
```


<details><summary>Solution: complete project files</summary>

Changing the enum changes the legal category choices. Updating the exhaustive match makes the new choice printable without falling back to an unrelated label.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "structs_enums_and_impl"
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
name = "structs_enums_and_impl"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
enum Category {
    Food,
    Travel,
    Books,
}

struct Expense {
    name: String,
    cents: i32,
    category: Category,
}

impl Expense {
    fn new(name: &str, cents: i32, category: Category) -> Self {
        Self { name: name.to_string(), cents, category }
    }

    fn show(&self) {
        let label = match &self.category {
            Category::Food => "food",
            Category::Travel => "travel",
            Category::Books => "books",
        };
        println!("{}: {} cents ({label})", self.name, self.cents);
    }
}

fn main() {
    let tea = Expense::new("Tea", 250, Category::Food);
    let bus = Expense::new("Bus", 400, Category::Travel);
    tea.show();
    bus.show();
    let book = Expense::new("Guide", 900, Category::Books);
    book.show();
}
```

</details>

## Check yourself
1. What keeps the fields of one expense together?
   <details><summary>Answer</summary>A struct value.</details>
2. How many Category variants does one value hold?
   <details><summary>Answer</summary>Exactly one.</details>
3. Why call Expense::new but tea.show()?
   <details><summary>Answer</summary>new is an associated function creating a value; show is a method borrowing an existing value.</details>
4. What does &self promise?
   <details><summary>Answer</summary>The method borrows the record for reading instead of taking ownership.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson11-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson11-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name structs_enums_and_impl lesson11-error
cd lesson11-error
```

**File: `lesson11-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
enum Category {
    Food,
    Travel,
    Books,
}

struct Expense {
    name: String,
    cents: i32,
    category: Category,
}

impl Expense {
    fn new(name: &str, cents: i32, category: Category) -> Self {
        Self { name: name.to_string(), cents, category }
    }

    fn show(&self) {
        let label = match &self.category {
            Category::Food => "food",
            Category::Travel => "travel",
        };
        println!("{}: {} cents ({label})", self.name, self.cents);
    }
}

fn main() {
    let tea = Expense::new("Tea", 250, Category::Food);
    let bus = Expense::new("Bus", 400, Category::Travel);
    tea.show();
    bus.show();
    // TODO: support a Guide book purchase costing 900 cents.
}
```

**File: `terminal in $HOME/code101/lesson11-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0004]: non-exhaustive patterns: `&Category::Books` not covered
  --> src\main.rs:19:27
   |
19 |         let label = match &self.category {
   |                           ^^^^^^^^^^^^^^ pattern `&Category::Books` not covered
   |
note: `Category` defined here
  --> src\main.rs:1:6
   |
 1 | enum Category {
   |      ^^^^^^^^
...
 4 |     Books,
   |     ----- not covered
   = note: the matched value is of type `&Category`
help: ensure that all possible cases are being handled by adding a match arm with a wildcard pattern or an explicit pattern as shown
   |
21 ~             Category::Travel => "travel",
22 ~             &Category::Books => todo!(),
   |

For more information about this error, try `rustc --explain E0004`.
error: could not compile `structs_enums_and_impl` (bin "structs_enums_and_impl") due to 1 previous error
```

This is the actual exercise starter with only Books added to the enum. E0004 is expected midway: the match in show still lacks the new case. The diagnostic says `&Category::Books` because show matches a borrowed category. Finish the Books case before running again; do not hide it behind an unrelated default.

A **lifetime** is the period during which a borrowed reference may safely be used. This lesson avoids storing borrowed text in Expense: its String owns a copy. The E0106 suggestion below is not a change you need to make.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Removing to_string() from name: name.to_string() in the constructor:

**File: `terminal standard error (captured)`**
```text
error[E0308]: mismatched types
  --> src\main.rs:14:16
   |
14 |         Self { name, cents, category }
   |                ^^^^ expected `String`, found `&str`
   |
help: try using a conversion method
   |
14 |         Self { name: name.to_string(), cents, category }
   |                +++++     ++++++++++++

For more information about this error, try `rustc --explain E0308`.
error: could not compile `structs_enums_and_impl` (bin "structs_enums_and_impl") due to 1 previous error
```

Changing the struct field from name: String to name: &str:

**File: `terminal standard error (captured)`**
```text
error[E0106]: missing lifetime specifier
 --> src\main.rs:7:11
  |
7 |     name: &str,
  |           ^ expected named lifetime parameter
  |
help: consider introducing a named lifetime parameter
  |
6 ~ struct Expense<'a> {
7 ~     name: &'a str,
  |

For more information about this error, try `rustc --explain E0106`.
error: could not compile `structs_enums_and_impl` (bin "structs_enums_and_impl") due to 1 previous error
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0004]: non-exhaustive patterns: `&Category::Books` not covered | Books was added to the enum but not the borrowed match. | Complete the Books arm in show before running again. |
| error[E0308]: mismatched types; expected `String`, found `&str` | Removed to_string() while the name field still needs owned String text. | Restore `name: name.to_string()` in the constructor. |
| error[E0106]: missing lifetime specifier | Changed the struct field from String to &str, a stored borrowed reference. | Keep the String field in this lesson; do not introduce a stored borrow or the suggested lifetime parameters. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson11"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson11 (or its exercise folder). |

## Best practice
Use methods with &self for read-only behavior, and let exhaustive enum matches reveal missing cases when your model grows. Source: [The Rust Book, Method Syntax](https://doc.rust-lang.org/book/ch05-03-method-syntax.html).

## Next lesson
**[12. Project: expense tracker](12-expense-tracker.md)**: combine your skills into a persistent expense tracker.
