# Rust 101, Phase 3: Real Programs

| Folder | Lesson | You build / exercise |
|---|---|---|
| `09-handling-errors` | Handling errors | re-asking reader / quantity from 1 through 99 |
| `10-ownership-and-borrowing` | Ownership and borrowing basics | library-book loans / choose shared/editing references |
| `11-structs-enums-and-impl` | Structs, enums and impl blocks | expense records / Books category |
| `12-expense-tracker` | Project: expense tracker | persistent expense tracker / Count command |

## Get the optional source
Every file and starter is shown in the matching lesson, so no download is required. The repository is https://github.com/Uee03/Code101; choose **Code > Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`. Source for this phase is under `source/rust/101-zero-to-hero/phase-3-real-programs/`; lessons are under `tutorials/rust/101-zero-to-hero/phase-3-real-programs/`.

For the repository ZIP: Windows, right-click and choose **Extract All**; macOS, double-click; Linux, use the file manager's **Extract** action. Open `Code101-main`, then the source path above. If you already have a generated `rust-101-phase-3-real-programs.zip`, extract it the same way: its top-level folder is `rust-101-phase-3-real-programs` and contains this README. There is no required download into Downloads.

## Needs and timing
Rust and Cargo installed using lesson 01, a plain-text editor, and the platform linker (Windows: MSVC C++ build tools and Windows SDK). Verified environment: Windows 11, rustc/Cargo 1.100.0 stable MSVC, edition 2024. Standard library only, no external crates. Finish lessons 01-08 first.

Most lessons take 30-35 minutes; installation is 60-90, lesson 08 is 40-50, lesson 09 is 50-60, and project 12 is 100-120 in two sittings with a marked break after Step 4. No lessons were renumbered or split.

## Inside a lesson folder
- `code/`: the finished Cargo project with manifest, lockfile and src/main.rs; data files where needed.
- `exercise/starter/`: an intentionally unfinished but runnable exercise. Copy this folder, not only main.rs.
- `exercise/solution/`: the completed answer; try the task before opening it.
- `stages/` (08, 09 and 12 only): runnable checkpoints shown in the lesson. Their manifests and lockfiles are identical to code. Start in the checkpoint folder, not src.
- `diagnostics/`: deliberately broken source and real Cargo output, plus captured runs in captures.json. Not a runnable project. For 07 only the optional standard-library source-location lines are omitted; no personal paths are included.
- `verify.json`: maintenance metadata, not a prerequisite for following a lesson.

## Run the finished example
Open PowerShell (Windows) or Terminal (macOS/Linux). In your file manager, locate `09-handling-errors/code` inside this phase. Copy its full folder path. In the terminal, type cd followed by that path in double quotes, and press Enter. The prompt must now end in code; Cargo.toml must be directly in that folder. Then run:

**File: terminal in the selected lesson's code folder (all platforms)**
```powershell
cargo run --quiet
```

Supply the keyboard replies and compare the expected output shown in the matching lesson. Save editor edits first; a dot/star on a tab means unsaved. Run in code, not src: Cargo searches upwards for Cargo.toml, but relative data paths start in the terminal's current folder. Cargo creates target locally; it is not shipped and can be recreated.

## Do an exercise without overwriting the example
In your file manager open the lesson's exercise folder. Copy the starter folder into your existing home/code101 folder and rename the copied folder phase3-practice. Do not create phase3-practice first or copy starter inside it. If that name already exists, keep your edits and choose a new destination name. Change the terminal to the renamed folder, edit the TODO goals following the lesson, save, then use the same cargo command above. Or use the lesson's typed starter route with no download. Compiler unused-mut warnings in unfinished starters are advice, not a failed build; lesson 02 explains them.

## Verification record
Status: verified on 2026-11-23, Windows 11, rustc/Cargo 1.100.0. Track smoke result: 12 passed, 0 failed, 0 unverified (missing tools). Code, solutions and four checkpoints use 300-second cold-build timeouts. No test suites, linters or formatters. Maintainer commands and real verifier output live in tutorials/rust/_STATE.md, not the lessons.

CSV is deliberately restricted: no quoted fields, embedded commas or line breaks inside a field. Lesson 08 uses a trusted fixture; lesson 12 validates its own header, field count and cents. Output files are replaced in the project folder. Use only disposable practice data.

Lesson 09 separates the Option lookup from the Result reader. Exercise input is -2, 100, 3. Lesson 12 builds menu/Add, file save/load, then the self-check. For a fresh finished-source run, enter 1, Tea, 250, 2, 3, 4 on separate lines; solution input is 1, Tea, 250, 5, 4. If continuing the lesson after its save/load checkpoint, choose 2, 3, 4 instead of adding Tea twice. Saved entries persist. Never reset data you want to keep.
