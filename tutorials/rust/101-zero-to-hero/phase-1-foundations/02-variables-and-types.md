---
track: rust
level: 101
phase: 1
phase_name: foundations
lesson: "02"
title: "Variables and types"
time: 35 min
prerequisites: [101.1.01]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-1-foundations/02-variables-and-types/
assets: []
---

# 02. Variables and types

## Why it matters
Labels on pantry jars tell you what is inside. Variables label values inside a program. Rust also checks the kind of value in each jar so you do not accidentally add a word to a price.

## What you will build
A stock card that prints a name, whole-number counts, a decimal price, a yes/no fact and an aisle letter.

## Before you start
- Finish lesson 01; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-1-foundations/02-variables-and-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson02` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson02`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **variable** names a value; a **binding** is that association. A **type** says what kind of value is allowed. **Immutable** means a binding cannot be assigned again; **mutable** means it can. **Shadowing** means creating a new binding with the same name. A String is an owned, growable text container: it is responsible for keeping its own text storage alive. A string slice (`&str`) is a borrowed view of existing text, not its own editable container.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson02`) and package name (`variables_and_types`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name variables_and_types lesson02
cd lesson02
```

Cargo reports project creation; the prompt should end in `lesson02`. If it already exists, keep your work and use `cd "$HOME/code101/lesson02"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson02/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson02/Cargo.toml`**
```toml
[package]
name = "variables_and_types"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `variables_and_types`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
Make the card with the values shown below. This lesson uses fixed facts rather than asking the person running it to type anything.

Open src/main.rs, select all existing text, and replace it with the file below. Work from the fixed facts at the top to the changing sold and servings variables, then the four print lines.

**File: `lesson02/src/main.rs`**
```rust
fn main() {
    let boxes: i32 = 4;
    let price: f64 = 2.5;
    let in_stock: bool = true;
    let aisle: char = 'B';
    let label: &str = "Tea";
    let description: String = String::from("Green tea");
    let mut sold: i32 = 1;
    sold = sold + 1;
    let servings = 2;
    let servings = servings + 1;
    println!("Item: {label}; description: {description}");
    println!("Boxes: {boxes}; price: {price:.2}");
    println!("In stock: {in_stock}; aisle: {aisle}");
    println!("Sold: {sold}; servings: {servings}");
}
```

## Run it
In `$HOME/code101/lesson02`, save all files and run:

**File: `terminal in $HOME/code101/lesson02`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Item: Tea; description: Green tea
Boxes: 4; price: 2.50
In stock: true; aisle: B
Sold: 2; servings: 3
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson02/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "variables_and_types"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **variable** is a name bound to a value. `let boxes: i32 = 4;` creates a binding: `let` declares it, `boxes` is the name, `: i32` selects its **type** (kind of value), `=` sets its initial value, and `;` finishes the instruction.
2. `i32` is a signed 32-bit **integer** (whole number, including negatives). `f64` is a 64-bit **floating-point number**, suitable for approximate decimals. `bool` is a **boolean**: `true` or `false`. `char` is one Unicode scalar value, such as `'B'`, in single quotes. Unicode is the numbering system Rust uses for text characters.
3. `&str` is a **string slice**, a borrowed view of text; `"Tea"` provides such a view without building an editable text container. `String` owns a growable text container. `String::from` constructs one from a literal. Use double quotes for either text form. Lesson 10 explains owning and borrowing with a library book.
4. Ordinary bindings are **immutable**: you cannot assign to them again. `mut` makes `sold` **mutable**. `sold = sold + 1` reads its old value, adds one and assigns the answer back. Rust can infer omitted types from their values and uses; this is **type inference**.
5. A second `let servings` creates a new binding with the same name: **shadowing**. It is not assignment to the old immutable binding; the old name is hidden from that point onward.
6. In println!, `{label}` inserts that variable. `{price:.2}` prints two digits after the decimal point. Formatting changes the display, not the stored number.

## Try it
The stock card starts with 10 bags of Rice and sells 3. Make it display the remaining stock by updating the existing variable, not by creating another binding. The expected output below is your goal.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson02-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name variables_and_types lesson02-exercise
cd lesson02-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-1-foundations/02-variables-and-types/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson02-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson02-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson02-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "variables_and_types"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson02-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "variables_and_types"
version = "0.1.0"
```

**File: `lesson02-exercise/src/main.rs (starter)`**
```rust
fn main() {
    let mut stock: i32 = 10;
    // TODO: update stock after selling 3 bags.
    let label: &str = "Rice";
    println!("{label}: {stock} left");
}
```

A **warning** is advice, not a failure: the program still runs. Running the unfinished starter prints `warning: variable does not need to be mutable` before `Rice: 10 left`. It disappears once the TODO update uses mut. The unfinished starters in lessons 05, 07, 08 and 10 can show the same warning.

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson02-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Rice: 7 left
```


<details><summary>Solution: complete project files</summary>

The right-hand stock is read first; subtraction produces 7, which is stored back in stock.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "variables_and_types"
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
name = "variables_and_types"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
fn main() {
    let mut stock: i32 = 10;
    stock = stock - 3;
    let label: &str = "Rice";
    println!("{label}: {stock} left");
}
```

</details>

## Check yourself
1. Can a plain let binding be assigned again?
   <details><summary>Answer</summary>No. Declare it with mut when you need reassignment.</details>
2. What makes shadowing different?
   <details><summary>Answer</summary>Shadowing uses another let to create a new binding.</details>
3. Which quotes hold one char?
   <details><summary>Answer</summary>Single quotes, such as 'B'. Double quotes make text.</details>
4. Does :.2 change the stored price?
   <details><summary>Answer</summary>No. It changes only how the value is printed.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson02-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson02-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name variables_and_types lesson02-error
cd lesson02-error
```

**File: `lesson02-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let stock = 10;
    stock = stock - 3;
    println!("{stock}");
}
```

**File: `terminal in $HOME/code101/lesson02-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0384]: cannot assign twice to immutable variable `stock`
 --> src\main.rs:3:5
  |
2 |     let stock = 10;
  |         ----- first assignment to `stock`
3 |     stock = stock - 3;
  |     ^^^^^^^^^^^^^^^^^ cannot assign twice to immutable variable
  |
help: consider making this binding mutable
  |
2 |     let mut stock = 10;
  |         +++

For more information about this error, try `rustc --explain E0384`.
error: could not compile `variables_and_types` (bin "variables_and_types") due to 1 previous error
```

E0384 points to the second assignment. Change the declaration to let mut stock = 10; when the same stock value must change. 

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0384]: cannot assign twice to immutable variable `stock` | stock was declared without mut but is assigned again. | Declare it with `let mut stock = 10;`. |
| warning: variable does not need to be mutable | The starter declares mut before you have written the update. | Finish the exercise; the warning is advice, not a failed build. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson02"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson02 (or its exercise folder). |

## Best practice
Leave bindings immutable until they genuinely need to change; make the changing ones visibly mut. Source: [The Rust Book, Variables and Mutability](https://doc.rust-lang.org/book/ch03-01-variables-and-mutability.html).

## Next lesson
**[03. Input and math](03-input-and-math.md)**: ask for values and calculate with them.
