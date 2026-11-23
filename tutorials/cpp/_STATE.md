# C++ track state

Last updated: 2026-11-23 (101 written under the no-run policy).

## 101 Zero to Hero

12 lessons, three phases. C++20, CMake 3.28+, standard library only. Nothing has been built or run.

| Lesson | Phase | Status | Verified |
|---|---|---|---|
| 01-hello-cpp | phase-1-foundations | written (not run) | not yet run |
| 02-types-and-output | phase-1-foundations | written (not run) | not yet run |
| 03-input-and-decisions | phase-1-foundations | written (not run) | not yet run |
| 04-loops | phase-1-foundations | written (not run) | not yet run |
| 05-functions-and-references | phase-2-building-blocks | written (not run) | not yet run |
| 06-strings-and-vectors | phase-2-building-blocks | written (not run) | not yet run |
| 07-maps-and-algorithms | phase-2-building-blocks | written (not run) | not yet run |
| 08-pointers-and-references | phase-2-building-blocks | written (not run) | not yet run |
| 09-classes-and-raii | phase-3-real-programs | written (not run) | not yet run |
| 10-smart-pointers | phase-3-real-programs | written (not run) | not yet run |
| 11-files-and-errors | phase-3-real-programs | written (not run) | not yet run |
| 12-expense-tracker | phase-3-real-programs | written (not run) | not yet run |

## What a later verification run must check first
1. `cmake -S . -B build` and `cmake --build build` succeed for `code` and `exercise/solution` of every lesson on Windows (MSVC), Linux (GCC) and macOS (Clang).
2. The program really lands in `build/out/` (generator expression in `CMAKE_RUNTIME_OUTPUT_DIRECTORY`). If not, change that one line everywhere and the lesson text that mentions `build/out`.
3. `cmake -E env build/out/NAME` in `verify.json` starts the program with stdin and returns its exit code (lesson 03/04/12 use stdin).
4. Compare every expected output block with the real output (derived by reading only). Pay attention to lesson 12 prompts (`> ` without newline) and to lesson 02/12 number formatting.
5. Replace each "typical message" row in Common mistakes with captured text; add the install-step wording seen on real machines (winget, xcode-select, apt).
6. Then set `verified:` to the real date and remove the draft notice from each lesson.

## Evidence and scope

- Static check only was NOT run either (instruction: no checks of any kind). Lesson text was copied from the source files; run `python scripts\verify_labs.py --static cpp` when allowed.
- Packs not built (`python scripts\build_packs.py cpp-101` when allowed).
- Starters: 05, 08, 09, 10 intentionally produce an unused-parameter warning until the TODO is done.
- No art assets used (`assets: []`). No commit made.
