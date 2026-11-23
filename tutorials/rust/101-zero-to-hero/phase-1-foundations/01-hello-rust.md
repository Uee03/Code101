---
track: rust
level: 101
phase: 1
phase_name: foundations
lesson: "01"
title: "Hello, Rust"
time: 60-90 min
prerequisites: [none]
versions: { rustc: "1.100.0 stable MSVC", cargo: "1.100.0", edition: "2024" }
verified: "2026-11-23 on Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0"
source: source/rust/101-zero-to-hero/phase-1-foundations/01-hello-rust/
assets: []
---

# 01. Hello, Rust

## Why it matters
A recipe is useful because another person can follow it exactly. A program is a recipe for a computer; Rust checks the recipe before it runs. Today you will set up the tools and make the computer greet you.

## What you will build
A greeting printed in a terminal (a window for typed commands and text replies), followed by a three-line recipe card in the exercise. This is the only lesson that installs Rust; allow 60-90 minutes, longer if Windows needs build tools.

## Before you start
- No programming experience needed. You need internet access for installation, a browser and permission to install software.
- Time: 60-90 min.
- Author environment: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0, default edition 2024. No additional libraries to install.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/rust/101-zero-to-hero/phase-1-foundations/01-hello-rust/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- If using the repository ZIP: Windows, right-click it and choose **Extract All**; macOS, double-click it; Linux, use your file manager's **Extract** action. Open the extracted `Code101-main` folder, then the source path above. This is optional; the typed exercise route below needs no download.
- Editor paths: `$HOME` is terminal syntax. In a Windows Notepad Open/Save dialog, use `%USERPROFILE%\code101\lesson01` for the project folder (and the `src` subfolder for main.rs). In macOS dialogs press Cmd+Shift+G and enter `~/code101/lesson01`; on Linux browse to that folder under Home. The exercise folder adds `-exercise` to its name.
- Type commands in the terminal, not inside main.rs. `$HOME` means your user home folder. Forward slashes in these paths work in PowerShell too. Use Ctrl+S after every editor change; an unsaved tab dot means Cargo will still read the older file.

**Standard output** is the program's normal text output; **standard error** carries diagnostic messages. Rust's **standard library** is the set of tools shipped with Rust. You do not install extra libraries in these lessons.

## Steps
### Step 1. Open a terminal before installing anything
On Windows press the Windows key, type **PowerShell**, then press Enter. A **terminal** is a window for typing commands and seeing text replies. Its **shell** interprets those commands; use Windows PowerShell, not the Python window or a browser search box. The **prompt** is the text before your cursor; it normally shows the **current folder**, the starting location for commands. Type only the commands below, not the prompt or the Markdown fences.

On macOS open **Applications > Utilities > Terminal**. On a typical Linux desktop open **Terminal** from the applications menu (often Ctrl+Alt+T). The PowerShell commands in this course are Windows PowerShell 5.1 compatible; a separate shell block appears when macOS/Linux needs different commands.

### Step 2. Install Rust with rustup
If Rust is already installed, go to Step 3. **rustup** installs and manages the **toolchain**, the compiler and supporting tools. Follow the [official Rust installation page](https://www.rust-lang.org/tools/install); these routes were checked against it on 2026-11-23.

**Windows (64-bit Intel/AMD, the author machine):**
For a 64-bit Intel/AMD PC choose x64; ARM64 is for ARM hardware. This walkthrough uses native 64-bit Windows, not WSL (Windows Subsystem for Linux). For 32-bit Windows or WSL, use the alternatives on the official installation page.
1. Open that page in a browser. In its Windows section click **Download rustup-init.exe (x64)**. If the site shows only the Unix command, use this [official x64 Windows download](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe). For ARM64 hardware choose the matching ARM64 download instead.
2. Open the downloaded rustup-init.exe from your Downloads folder. If Windows asks whether to run it, confirm only after checking that you downloaded it from rust-lang.org.
3. Rust's Windows MSVC toolchain also needs Microsoft C++ build tools and a Windows SDK. **MSVC** means Microsoft Visual C++; its **linker** combines compiled pieces with system libraries. An **SDK** is a platform's software development kit. If rustup offers to install the Visual Studio prerequisites, follow that setup. In the Visual Studio Installer select **Desktop development with C++**, keep the MSVC C++ x64/x86 tools and Windows SDK selected, select English under **Language packs**, then click **Install**. Wait until installation finishes, then continue rustup (or reopen rustup-init.exe if it closed). Organizations should check which Visual Studio license is appropriate before accepting the automatic Community installation. [Official prerequisites and Build Tools alternative](https://rust-lang.github.io/rustup/installation/windows-msvc.html).
4. rustup-init opens a console window (often black) with numbered choices. At the Rust installation menu choose **1) Proceed with standard installation**: type `1` and press Enter, or press Enter for that default. Keep the stable MSVC toolchain. Wait for the success message and follow any final Enter prompt; the installer window may then close. Open your own new PowerShell window for Step 3.
5. Close **all** terminal windows and open a **new PowerShell window**. The installer updates **PATH**, the list of folders searched for commands; an old terminal may not see the change.

**macOS/Linux:** in your terminal, in your home folder, run the official rustup command below. Read the installer and choose its default standard installation. On macOS, if prompted for Apple command-line development tools, click **Install** and complete that dialog. Linux also needs a C linker; on Ubuntu/Debian install build-essential using the second block if it is missing. Other distributions need their equivalent development-tools package. Close the terminal and open a new one after installation. These installation commands are not part of the smoke check and may download large files.

**File: `terminal in your home folder (macOS/Linux)`**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**File: `terminal in your home folder (Ubuntu/Debian only, if a linker is missing)`**
```bash
sudo apt update
sudo apt install build-essential
```

### Step 3. Check the tools and choose an editor
A **compiler** translates **source code** (the text you write) into an **executable** (a program your computer can run). `rustc` is the compiler. **Cargo** manages the project, asks rustc to build it and can run the result. In the newly opened terminal, any current folder is fine:

**File: `terminal in any folder`**
```powershell
rustc --version
cargo --version
```

The author captured the version lines below. A newer stable patch or release may show different dates; the examples use the locally confirmed default **edition 2024**, a named set of language rules selected by the manifest.

**File: `terminal version output`**
```text
rustc 1.100.0 (0ef1bc386 2026-11-09)
cargo 1.100.0 (3acc79c0c 2026-11-05)
```

Use a plain-text editor. On Windows, open **Notepad** from Start. To edit an existing file choose **File > Open**, select **All files**, and open the exact file path named in the lesson. To create a file choose **File > Save as**, set **Save as type: All files**, use the exact filename (not main.rs.txt), and choose **UTF-8**. Save with Ctrl+S. A dot or star on an editor tab means unsaved changes; Cargo cannot read those until you save. On macOS use TextEdit with **Format > Make Plain Text** and disable automatically adding .txt; on Linux use your desktop's plain-text editor. Never use a word processor or rich-text format. In Windows 11 File Explorer choose **View > Show > File name extensions** (Windows 10: **View > File name extensions**) so main.rs.txt cannot hide behind main.rs.

### Step 4. Create your project folder
Start in your home folder. Create `code101` if it is missing, then make a new Cargo project in `lesson01`. If that lesson folder already exists, keep your work: use it instead of rerunning cargo new. Do not run these commands inside another lesson.

**File: `terminal in your home folder (Windows)`**
```powershell
New-Item -ItemType Directory -Force "$HOME/code101"
cd "$HOME/code101"
cargo new --vcs none --name hello_rust lesson01
cd lesson01
```

**File: `terminal in your home folder (macOS/Linux)`**
```bash
mkdir -p "$HOME/code101"
cd "$HOME/code101"
cargo new --vcs none --name hello_rust lesson01
cd lesson01
```

Check the prompt ends in `lesson01`. To recover from a wrong folder later, run `cd "$HOME/code101/lesson01"` in either shell. On Windows the directory-creation command may print a folder table; Cargo prints creation notes. The project is created before the final cd.

`cargo new` creates a **package**, a project with a **manifest** (Cargo.toml, its configuration) and src/main.rs (the program). `--name` fixes the package name regardless of the folder name. `--vcs none` avoids creating a hidden version-control database or .gitignore file; there are exactly two initial files here. A version-control system records changes, but is not needed in this track.

### Step 5. Inspect the complete Cargo.toml
In your editor open `$HOME/code101/lesson01/Cargo.toml`. Leave it exactly as shown. **TOML** is the configuration format Cargo reads. This is the locally generated manifest, including the default edition, not a guessed configuration.

**File: `lesson01/Cargo.toml`**
```toml
[package]
name = "hello_rust"
version = "0.1.0"
edition = "2024"

[dependencies]
```

- `[package]` begins the package settings.
- `name` gives Cargo's package name (and here the executable name); changing it would also update the generated lockfile on the next build.
- `version = "0.1.0"` is your own program's initial version, not the Rust compiler version.
- `edition = "2024"` selects the Rust language edition. Keep it unchanged for these examples.
- `[dependencies]` starts the list of external packages. It is empty because every tool used here comes with Rust's standard library. A **dependency** is another package your code uses.

### Step 6. Read the generated program
The project will contain a recipe file for Cargo and one Rust source file. Do not create a second main.rs beside Cargo.toml: the source belongs in src/main.rs.

Open the generated src/main.rs. It already contains the full greeting below; no replacement is needed. Read it, then save it without changing the punctuation.

**File: `lesson01/src/main.rs`**
```rust
fn main() {
    println!("Hello, world!");
}
```

## Run it
In `$HOME/code101/lesson01`, save all files and run:

**File: `terminal in $HOME/code101/lesson01`**
```powershell
cargo run
```

Cargo first reports its build and run steps (paths and timings vary). The program itself prints the exact captured output below. Later lessons use `cargo run --quiet` to hide Cargo progress, not the program output.

This example does not ask for keyboard input.

Expected program output (captured from this source):

**File: `terminal standard output`**
```text
Hello, world!
```

### Generated files: what to keep
The first successful Cargo build creates Cargo.lock. This **lockfile** records exact resolved package versions. Keep it with this application; do not type or hand-edit it. There are no external packages here, but the file still records your package. Its complete content is:

**File: `lesson01/Cargo.lock`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "hello_rust"
version = "0.1.0"
```

Cargo also creates `target/` with platform-specific compiled build artifacts (the generated executable and supporting files). You do not edit or copy those binary files; Cargo recreates them. The downloadable pack includes Cargo.lock but needs no prebuilt target folder.

## How it works
1. `fn` introduces a **function**, a named set of instructions. `main` is the function Rust starts with. Empty `()` means it takes no inputs here. A `//` **comment** is a note for people; Rust ignores the rest of that line. The exercise starter uses one.
2. `{` and `}` enclose a **block**, a group of instructions. Four spaces of **indentation** make nesting readable; Rust uses braces, not spaces, to find the block.
3. `println!` is a **macro**, a tool that expands into Rust code. Here it prints the text between double quotes, then moves to a new line. The exclamation mark is part of its name.
4. A quoted piece of text is a **string literal**. The semicolon `;` ends this instruction.
5. A **compiler** translates source code (the text you write) into an executable (a program the operating system can run). `rustc` is Rust's compiler; **Cargo** manages a project and invokes that compiler for you.
6. `cargo run` builds and runs. It rebuilds when saved source changes. The `target` folder is replaceable build output, not a source file to type or ship.

## Try it
Print a recipe card with the recipe name Tea and two numbered instructions: Boil water. and Add tea. Match the three-line expected output below; do not display TODO.

### 1. Create a separate exercise project
No download is needed. From `$HOME/code101`, create a new project with the commands below (identical on Windows, macOS and Linux). If `lesson01-exercise` already exists, keep your edits and only change into that folder.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name hello_rust lesson01-exercise
cd lesson01-exercise
```

Cargo reports creation of the exercise project. Open its generated Cargo.toml and src/main.rs, then use the complete starter files in the next section. Cargo.lock is generated on the first run; it is shown for reference, not for typing.

**Optional copy route instead:** in the downloaded/cloned repository, open `source/rust/101-zero-to-hero/phase-1-foundations/01-hello-rust/exercise`. Copy the `starter` folder into your existing `$HOME/code101` folder and rename the copied folder `lesson01-exercise`. Do not create the destination first or put starter *inside* it. Use this route only if that destination does not already exist. Then run `cd "$HOME/code101/lesson01-exercise"`.

### 2. Open the full starter files
The starter files are shown below. The manifest is identical to the lesson project. Save the shown src/main.rs (and any data file) in this exercise folder; do not hand-edit Cargo.lock. Work on the TODO goals before opening the solution.

**File: `lesson01-exercise/Cargo.toml (starter)`**
```toml
[package]
name = "hello_rust"
version = "0.1.0"
edition = "2024"

[dependencies]
```

**File: `lesson01-exercise/Cargo.lock (starter)`**
```toml
# This file is automatically @generated by Cargo.
# It is not intended for manual editing.
version = 4

[[package]]
name = "hello_rust"
version = "0.1.0"
```

**File: `lesson01-exercise/src/main.rs (starter)`**
```rust
fn main() {
    // TODO: print the recipe name, then the two steps.
    println!("Recipe: TODO");
}
```

### 3. Complete, save and run
Apply the task above and press Ctrl+S. In the exercise project folder, run:

**File: `terminal in $HOME/code101/lesson01-exercise`**
```powershell
cargo run --quiet
```

No keyboard reply is needed.

Expected output after your fix (captured from the solution):

**File: `terminal standard output for the completed exercise`**
```text
Recipe: Tea
1. Boil water.
2. Add tea.
```


<details><summary>Solution: complete project files</summary>

Each println! writes one line. The // comment in the starter is a note for people; Rust ignores everything after // on that line.

**File: `exercise/solution/Cargo.toml`**
```toml
[package]
name = "hello_rust"
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
name = "hello_rust"
version = "0.1.0"
```

**File: `exercise/solution/src/main.rs`**
```rust
fn main() {
    println!("Recipe: Tea");
    println!("1. Boil water.");
    println!("2. Add tea.");
}
```

</details>

## Check yourself
1. What starts the program?
   <details><summary>Answer</summary>The main function.</details>
2. Why save before running?
   <details><summary>Answer</summary>Cargo reads the file on disk, not unsaved editor text.</details>
3. Is target a folder you must copy to share this program?
   <details><summary>Answer</summary>No. Cargo recreates it from the source and manifest.</details>

## Common mistakes
### Read a real Cargo diagnostic
This file is deliberately broken, separate from your working project. To reproduce it safely, start in `$HOME/code101` and create `lesson01-error` with the commands below (all platforms). Use a new disposable folder if that name already exists. Replace that project's src/main.rs with the shown file, save it, then run `cargo run --quiet` **inside `lesson01-error`**. Do not overwrite your working lesson.

**File: `terminal in $HOME/code101 (all platforms)`**
```powershell
cd "$HOME/code101"
cargo new --vcs none --name hello_rust lesson01-error
cd lesson01-error
```

**File: `lesson01-error/src/main.rs (repository copy: diagnostics/error.rs)`**
```rust
fn main() {
    let name = "Tea"
    println!("{name}");
}
```

**File: `terminal in $HOME/code101/lesson01-error`**
```powershell
cargo run --quiet
```

Actual captured Cargo output (line numbers follow this broken file, not the finished program; operating-system path separators may differ):

**File: `diagnostics/compiler-output.txt`**
```text
error: expected `;`, found `println`
 --> src\main.rs:2:21
  |
2 |     let name = "Tea"
  |                     ^ help: add `;` here
3 |     println!("{name}");
  |     ------- unexpected token

error: could not compile `hello_rust` (bin "hello_rust") due to 1 previous error
```

The `let name = "Tea"` line shown at line 2 has no semicolon. Here let gives a name to a value; lesson 02 calls that a variable. Add `;` after the closing quote. Read the first error and its file:line:column location before later messages. `src\main.rs` is the project file; a separate rustc run would instead name error.rs and end with "aborting" rather than Cargo's "could not compile".

| Symptom or error text | Cause | Fix |
|---|---|---|
| error: expected `;`, found `println` | The let declaration for name is missing its semicolon. | Add `;` after the closing quote on line 2. |
| cargo : The term 'cargo' is not recognized as the name of a cmdlet, function, script file, or operable program. | This terminal cannot find the installed Cargo command. | Close all terminals and open a new PowerShell window; check the installation in Step 2 if it still fails. |
| error: could not find `Cargo.toml` in `<project>` or any parent directory | The terminal is outside any Cargo project. | Run `cd "$HOME/code101/lesson01"`, then cargo run again. |
| Old output still appears after an edit | The source was not saved, or another project is running. | Save src/main.rs with Ctrl+S; check the prompt ends in lesson01 (or its exercise folder). |

## Best practice
Keep source under src and let Cargo manage the build directory instead of compiling project files by hand. Source: [The Rust Book, Hello, Cargo!](https://doc.rust-lang.org/book/ch01-03-hello-cargo.html).

## Next lesson
**[02. Variables and types](02-variables-and-types.md)**: store and update facts with named values.
