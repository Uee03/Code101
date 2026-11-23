---
track: rust
level: 101
phase: 2
phase_name: building-blocks
lesson: "06"
title: "Functions"
time: 30 min
prerequisites: [101.2.05]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-2-building-blocks/06-functions/
assets: []
---

# 06. Functions

## Why it matters
A recipe can refer to a smaller recipe, such as making a sauce. You give the smaller recipe its ingredients and receive a result. Functions let you name and reuse one useful piece of work.

## What you will build
A reusable tip calculation and a printing helper, followed by a rectangle-area exercise.

## Before you start
- Finish lesson 05; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 30 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-2-building-blocks/06-functions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson06` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson06`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **parameter** names a function input; an **argument** is the value supplied for it. The **caller** is the code making a function call. The **body** is the code inside a function's braces. An **expression** produces a value; a **statement** performs an instruction without returning its result to the surrounding block. **Unit**, written `()`, means no useful result. **Scope** is the region where a name can be used.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson06`) and package name (`functions`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name functions lesson06
cd lesson06
```

Cargo reports project creation; the prompt should end in `lesson06`. If it already exists, keep your work and use `cd "$HOME/code101/lesson06"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson06/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson06/Cargo.toml`**
```toml
[package]
name = "functions"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `functions`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
Read the whole file before running. Rust permits helper functions above or below main; execution still starts at main.

Replace src/main.rs with the full file below. The calculation returns a value; the display helper prints it. Notice the deliberate absence of a semicolon after the final tip calculation.

**File: `lesson06/src/main.rs`**
```rust
fn tip(bill: f64, percent: f64) -> f64 {
    bill * percent / 100.0
}

fn show_total(label: &str, total: f64) {
    println!("{label}: {total:.2}");
}

fn main() {
    let bill = 80.0;
    let extra = tip(bill, 15.0);
    show_total("Tip", extra);
    show_total("Total", bill + extra);
}
```

## Run it
In `$HOME/code101/lesson06`, save all files and run:

**File: `terminal in $HOME/code101/lesson06`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Tip: 12.00
Total: 92.00
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson06/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "functions"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **parameter** is a named input in a function definition. `bill: f64` and `percent: f64` specify two decimal inputs. An **argument** is a value supplied when calling that function: 80.0 and 15.0 here.
2. `-> f64` declares the return type. The final `bill * percent / 100.0` is an **expression**, code that produces a value. It has no trailing semicolon, so that value is returned to the caller.
3. A **statement** performs an action without supplying that action's value to the surrounding block. `let extra = tip(bill, 15.0);` binds the returned result. Adding a semicolon after the final arithmetic expression would discard its value and leave unit, `()`, rather than the promised f64.
4. `show_total` takes a text view and a decimal number. It prints but has no return-type arrow; its return value is **unit**, `()`, meaning no useful result. Its println! is a statement ending in a semicolon.
5. `main` sets bill, calls tip, saves the returned extra and calls show_total twice. A name defined inside a function has local **scope**: it is available in that function's block, not automatically in another function.
6. You can also use `return value;` to leave a function early. Lesson 09 uses that when a re-ask loop finally receives good input.

## Try it
The area helper gives the wrong area for a rectangle. Correct its calculation while keeping its inputs and promised result type. A rectangle 3 units wide and 4 units high should produce the expected output below.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson06-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name functions lesson06-exercise
cd lesson06-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-2-building-blocks/06-functions/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson06-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson06-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson06-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "functions"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson06-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "functions"
version = "0.1.0"
```

**File: `lesson06-exercise/src/main.rs (starter)`**
```rust
fn area(width: f64, height: f64) -> f64 {
    // TODO: return the area of the rectangle.
    width + height
}

fn main() {
    let size = area(3.0, 4.0);
    println!("Area: {size:.2}");
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson06-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Area: 12.00
```


<details><summary>Solution: complete project files</summary>

The product is the last expression in area, so it becomes the function result and is saved as size.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "functions"
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
name = "functions"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
fn area(width: f64, height: f64) -> f64 {
    width * height
}

fn main() {
    let size = area(3.0, 4.0);
    println!("Area: {size:.2}");
}
```

</details>

## Check yourself
1. What is the difference between a parameter and an argument?
   <details><summary>Answer</summary>A parameter names an input in the definition; an argument is a supplied value in a call.</details>
2. Why no semicolon after the final multiplication?
   <details><summary>Answer</summary>Its value must be returned, not discarded.</details>
3. Where does execution begin?
   <details><summary>Answer</summary>At main, not at the first helper in the file.</details>
4. What is unit?
   <details><summary>Answer</summary>The () value, representing no useful result.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson06-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson06-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name functions lesson06-error
cd lesson06-error
```

**File: `lesson06-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn area() -> f64 {
    3.0 * 4.0;
}

fn main() {
    println!("{}", area());
}
```

**File: `terminal in $HOME/code101/lesson06-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0308]: mismatched types
 --> src\main.rs:1:14
  |
1 | fn area() -> f64 {
  |    ----      ^^^ expected `f64`, found `()`
  |    |
  |    implicitly returns `()` as its body has no tail or `return` expression
2 |     3.0 * 4.0;
  |              - help: remove this semicolon to return this value

For more information about this error, try `rustc --explain E0308`.
error: could not compile `functions` (bin "functions") due to 1 previous error
```

The compiler expected f64 but found (). Remove the semicolon after 3.0 * 4.0, or explicitly return the product. This is different from the missing-semicolon error in lesson 01: a final returned expression intentionally has no semicolon.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Adding {bill} to show_total's print even though bill is local to main:

**File: `terminal standard error (captured)`**
```text
error[E0425]: cannot find value `bill` in this scope
 --> src\main.rs:6:37
  |
6 |     println!("{label}: {total:.2}; {bill}");
  |                                     ^^^^ not found in this scope

For more information about this error, try `rustc --explain E0425`.
error: could not compile `functions` (bin "functions") due to 1 previous error
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0308]: mismatched types | A semicolon discarded the final calculation, leaving unit (). | Remove the final calculation's semicolon so the f64 is returned. |
| error[E0425]: cannot find value `bill` in this scope | show_total tried to read the bill local to main. | Pass the value as an argument and declare a corresponding parameter. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson06"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson06 (or its exercise folder). |

## Best practice
Keep calculation and display in separate functions so the same calculation can be reused without printing. Source: [The Rust Book, Functions](https://doc.rust-lang.org/book/ch03-03-how-functions-work.html).

## Next lesson
**[07. Vectors and HashMaps](07-vectors-and-hashmaps.md)**: store many values in vectors and named maps.
