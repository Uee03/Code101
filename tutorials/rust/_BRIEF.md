# Rust 101 - Zero to Hero

Complete beginners from any field; no programming or command-line experience required. Twelve lessons in three downloadable phases. Analogy first, plain words, full files, exact working folders, a runnable example and an exercise with a complete answer in every lesson. Allow 30-35 minutes for most lessons, 60-90 for installation, 40-50 for lesson 08, 50-60 for lesson 09, and 100-120 for the final project in two sittings. Lesson numbers and phase boundaries stay unchanged.

## Sequence and scope
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 Foundations | 01 Hello, Rust | Open a terminal, install rustup and Windows MSVC tools, inspect every generated file, run a greeting / recipe card |
| 1 | 02 Variables and types | let, mut, shadowing; i32, f64, bool, char, String and &str / stock card |
| 1 | 03 Input and math | read_line, trim, parse::<f64>, arithmetic / tip calculator and bill splitter |
| 1 | 04 Making decisions | if/else, match, boolean operators / tickets and grades |
| 2 Building blocks | 05 Loops | loop, while, for, exclusive and inclusive ranges / running totals |
| 2 | 06 Functions | Parameters, returns, expressions and statements / tip and area functions |
| 2 | 07 Vectors and HashMaps | Ordered lists and named lookups / shopping inventory |
| 2 | 08 Files | read_to_string, lines, write; one reading approach, two runnable checkpoints; simple CSV by hand / stock summary and row count |
| 3 Real programs | 09 Handling errors | Option, Result, match, ?, re-ask loop and end-of-input / separate Option checkpoint, number reader and 1-99 quantity reader |
| 3 | 10 Ownership and borrowing basics | Library-book analogy: move, clone, &, &mut / lending notes |
| 3 | 11 Structs, enums and impl blocks | Expense records and categories / add a Books category |
| 3 | 12 Project: expense tracker | Console menu, integer cents, CSV persistence; plain assert! self-check from main / count command |

## Toolchain and delivery decisions
Author: Windows 11, rustc 1.100.0 stable MSVC, Cargo 1.100.0. Locally confirmed cargo new's default edition: 2024. Standard library only, no downloaded crates. Show Cargo.toml and Cargo.lock in full, but explain their identical settings only once in lesson 01. Source downloads are optional: every lesson also has a typed exercise route. Use cargo new --vcs none so beginners receive only project files, not a hidden Git database. No art (assets: []). CSV examples deliberately forbid commas and line breaks inside fields; they are not general CSV parsers. Input examples use decimal points. Lesson 09 replaces early expect calls with recoverable errors. Lesson 12's self-check runs from main, never cargo test.

## Sources (Tier 1: official)
- Installation: https://www.rust-lang.org/tools/install and https://rust-lang.github.io/rustup/installation/windows-msvc.html
- The Rust Book: https://doc.rust-lang.org/book/ (chapters 1-6, 8-10, 12)
- Cargo new/default edition: https://doc.rust-lang.org/cargo/commands/cargo-new.html
- Standard library: https://doc.rust-lang.org/std/ (io, fs, collections, primitive types)
Only these official source families support best-practice claims; no Tier 2 sources needed.

## Acceptance
Source first, then runnable starter and solution, then verify.json. Copy tested source into the template; capture real output and deliberately trigger E0384, E0382, E0308 and missing-semicolon diagnostics. Smoke only: one cargo run --quiet per code, solution and runnable checkpoint, requires cargo, timeout 300; no tests, fmt or clippy. Run verify_labs.py source/rust/, then build_packs.py rust-101. Mark verified only after PASS. Changes are confined to tutorials/rust and source/rust; requested pack command produces generated dist zips. No commits.
