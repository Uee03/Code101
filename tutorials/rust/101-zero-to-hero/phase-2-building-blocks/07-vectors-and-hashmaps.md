---
track: rust
level: 101
phase: 2
phase_name: building-blocks
lesson: "07"
title: "Vectors and HashMaps"
time: 35 min
prerequisites: [101.2.06]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-2-building-blocks/07-vectors-and-hashmaps/
assets: []
---

# 07. Vectors and HashMaps

## Why it matters
A shopping list keeps items in order. A stock ledger lets you look up a quantity by its name. Programs need both kinds of collection: a vector for ordered items and a HashMap for named lookups.

## What you will build
A three-item shopping list and a small stock lookup. The exercise totals prices and adds another product quantity.

## Before you start
- Finish lesson 06; Rust and a plain-text editor are installed using [lesson 01](../phase-1-foundations/01-hello-rust.md).
- Time: 35 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-2-building-blocks/07-vectors-and-hashmaps/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson07` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson07`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

A **vector** is a growable ordered list; each stored value is an **element**. An **index** is a position, starting at zero. A **HashMap** connects unique lookup names (**keys**) to values. **Borrowing** temporarily lends access without handing over the collection; `&items` lends read-only access.

## Steps
### Step 1. Create your project folder
Repeat lesson 01 Step 4's project-creation procedure. Only the folder (`lesson07`) and package name (`vectors_and_hashmaps`) change. The parent `$HOME/code101` already exists. In that parent folder, run these identical commands on Windows, macOS or Linux:

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name vectors_and_hashmaps lesson07
cd lesson07
```

Cargo reports project creation; the prompt should end in `lesson07`. If it already exists, keep your work and use `cd "$HOME/code101/lesson07"` instead of creating it again.

### Step 2. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson07/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson07/Cargo.toml`**
```toml
[package]
name = "vectors_and_hashmaps"
version = "0.1.0"
edition = "2024"

[dependencies]
```

The settings mean exactly the same as in lesson 01 Step 5. Only `name` changes to `vectors_and_hashmaps`; version 0.1.0, edition 2024 and the empty dependencies section stay unchanged.

### Step 3. Write and save the complete program
The example looks up only positions and names it has already inserted. Lesson 09 shows how to check for a possibly absent item.

Replace src/main.rs with the full file below. Build the vector first, then the map. The vector loop borrows &items; map output uses fixed keys, not map iteration order.

**File: `lesson07/src/main.rs`**
```rust
use std::collections::HashMap;

fn main() {
    let mut items = vec!["Tea", "Rice"];
    items.push("Apples");
    println!("First: {}", items[0]);
    println!("Items: {}", items.len());
    for item in &items {
        println!("Buy: {item}");
    }
    let mut quantities = HashMap::new();
    quantities.insert("Tea", 2);
    quantities.insert("Rice", 3);
    quantities.insert("Tea", 4);
    println!("Tea quantity: {}", quantities["Tea"]);
    println!("Rice quantity: {}", quantities["Rice"]);
}
```

## Run it
In `$HOME/code101/lesson07`, save all files and run:

**File: `terminal in $HOME/code101/lesson07`**
```powershell
cargo run --quiet
```

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
First: Tea
Items: 3
Buy: Tea
Buy: Rice
Buy: Apples
Tea quantity: 4
Rice quantity: 3
```

### Generated files: what to keep
Cargo creates the lockfile as in lesson 01; keep it, do not type it. Only the package name changes. Its full generated content is:

**File: `lesson07/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "vectors_and_hashmaps"
version = "0.1.0"
```

As in lesson 01, `target/` is generated build output, not a file to edit or copy.

## How it works
1. A **collection** stores several values. A **vector**, written `Vec<T>`, is a growable ordered list whose elements all have one type T. This is a **generic type**: T is a type parameter, a placeholder for the element type. `vec!["Tea", "Rice"]` constructs one; Rust infers its element type as &str.
2. `.push("Apples")` adds an element at the end. `.len()` returns the number of elements. An **index** is a position starting at zero, so `items[0]` is Tea. There is no position 3 in a list of length 3. Invalid indexing panics; get, introduced in lesson 09, offers a checked alternative.
3. `for item in &items` visits borrowed elements without consuming the vector. The ampersand lends the collection for reading, much like lending text in lesson 03. Lesson 10 explains the ownership rule behind this choice.
4. A **HashMap** stores **key-value pairs**: a unique lookup key and its associated value. `use std::collections::HashMap;` brings in its type. `HashMap::new()` makes an empty map. The insert calls let Rust infer text keys and integer values.
5. `.insert("Tea", 2)` adds a pair. Inserting Tea again replaces the previous quantity rather than creating a second Tea key. `quantities["Tea"]` reads the value associated with an existing key. It is not a vector position.
6. HashMap iteration order is not guaranteed. This example prints two explicit keys so its output is predictable. In the exercise, adding a borrowed integer price to total works because Rust supports that addition; no ownership of the price vector is needed.

## Try it
Display the total of all three prices while keeping prices available for the existing Number of prices line. Also record and display 3 bags of Rice after Tea. Keep prices and stock counts as separate collections; the expected output below is the goal.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson07-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name vectors_and_hashmaps lesson07-exercise
cd lesson07-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-2-building-blocks/07-vectors-and-hashmaps/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson07-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson07-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson07-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "vectors_and_hashmaps"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson07-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "vectors_and_hashmaps"
version = "0.1.0"
```

**File: `lesson07-exercise/src/main.rs (starter)`**
```rust
use std::collections::HashMap;

fn main() {
    let prices = vec![3, 5, 2];
    let mut total = 0;
    // TODO: total all prices while keeping prices available below.
    println!("Number of prices: {}", prices.len());
    let mut counts = HashMap::new();
    counts.insert("Tea", 2);
    // TODO: record that 3 bags of Rice are in stock, then display them.
    println!("Total: {total}");
    println!("Tea: {}", counts["Tea"]);
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson07-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Number of prices: 3
Total: 10
Tea: 2
Rice: 3
```


<details><summary>Solution: complete project files</summary>

The vector contributes 3 + 5 + 2. The HashMap keeps quantities separate from prices and retrieves each quantity by its text key.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "vectors_and_hashmaps"
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
name = "vectors_and_hashmaps"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
use std::collections::HashMap;

fn main() {
    let prices = vec![3, 5, 2];
    let mut total = 0;
    for price in &prices {
        total = total + price;
    }
    println!("Number of prices: {}", prices.len());
    let mut counts = HashMap::new();
    counts.insert("Tea", 2);
    counts.insert("Rice", 3);
    println!("Total: {total}");
    println!("Tea: {}", counts["Tea"]);
    println!("Rice: {}", counts["Rice"]);
}
```

</details>

## Check yourself
1. What is the first vector index?
   <details><summary>Answer</summary>0.</details>
2. What happens when the same map key is inserted twice?
   <details><summary>Answer</summary>The new value replaces the old value for that key.</details>
3. Does a HashMap promise insertion order?
   <details><summary>Answer</summary>No. Do not depend on its iteration order.</details>
4. Why put & before items in this loop?
   <details><summary>Answer</summary>To borrow the elements without moving the collection into the loop.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson07-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson07-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name vectors_and_hashmaps lesson07-error
cd lesson07-error
```

**File: `lesson07-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let items = vec!["Tea", "Rice"];
    for item in items {
        println!("{item}");
    }
    println!("{}", items.len());
}
```

**File: `terminal in $HOME/code101/lesson07-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error[E0382]: borrow of moved value: `items`
   --> src\main.rs:6:20
    |
  2 |     let items = vec!["Tea", "Rice"];
    |         ----- move occurs because `items` has type `Vec<&str>`, which does not implement the `Copy` trait
  3 |     for item in items {
    |                 ----- `items` moved due to this implicit call to `.into_iter()`
...
  6 |     println!("{}", items.len());
    |                    ^^^^^ value borrowed here after move
    |
note: the `for` loop is desugared into a call to `std::iter::IntoIterator::into_iter`, which takes ownership of the receiver `self`, which moves `items`
[optional standard-library source location omitted]
help: consider iterating over a slice of the `Vec<&str>`'s content to avoid moving into the `for` loop
    |
  3 |     for item in &items {
    |                 +

For more information about this error, try `rustc --explain E0382`.
error: could not compile `vectors_and_hashmaps` (bin "vectors_and_hashmaps") due to 1 previous error
```

`for item in items` hands the whole list to the loop, so it is gone afterwards. `for item in &items` lends it instead; lesson 10 explains why. You can ignore the long note about Copy, into_iter, desugaring and self for now: it describes the loop's internal translation, not extra code you need to write. The optional standard-library source-location lines have been omitted from this capture; their presence depends on the installed rust-src component, which you do not need to install.

### Other real messages you may see
Restore the working file after each experiment; make only the named change in a disposable copy. Run `cargo run --quiet` from that copy's project folder. These are captured error messages, not text to type. Panic thread numbers and line positions can vary.

Changing items[0] to items[3] in the finished project:

**File: `terminal standard error (captured)`**
```text

thread 'main' (4644) panicked at src\main.rs:6:32:
index out of bounds: the len is 3 but the index is 3
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

Changing quantities["Tea"] to quantities["tea"]:

**File: `terminal standard error (captured)`**
```text

thread 'main' (26544) panicked at src\main.rs:15:44:
no entry found for key
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

| Symptom or error text | Cause | Fix |
|---|---|---|
| error[E0382]: borrow of moved value: `items` | The loop took the vector, so items is unavailable afterwards. | Use `for item in &items` to lend it to the loop. |
| index out of bounds: the len is 3 but the index is 3 | Used items[3] although there are only positions 0, 1 and 2. | Use a valid position; lesson 09 introduces get for possibly absent positions. |
| no entry found for key | Used quantities["tea"] although the inserted key is "Tea". | Match the exact key, including capitalization; use get when absence is possible (lesson 09). |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson07"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson07 (or its exercise folder). |

## Best practice
Use a vector for ordered values and a HashMap for key-based lookup; do not treat map iteration order as meaningful. Source: [The Rust Book, Storing Keys with Associated Values in Hash Maps](https://doc.rust-lang.org/book/ch08-03-hash-maps.html).

## Next lesson
**[08. Files](08-files.md)**: keep data in files after the program exits.
