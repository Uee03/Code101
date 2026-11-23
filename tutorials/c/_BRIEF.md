# C track brief - 101 Zero to Hero

## Learners and outcome
Complete beginners from any field. Start with an everyday analogy, define new words, show every folder, full file, command and expected output.
Finish with a small console expense tracker built from several files that saves a CSV file. No prior programming, external libraries, accounts,
networking or Windows-only APIs. The track is desktop-focused; level 101 uses console programs only.

## Plan (12 lessons, three packs)
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 Foundations | 01 Hello, C: install and first program | gcc/MSYS2, MSVC, Xcode tools, build-essential, CMake; terminal, editor, build and run / recipe card |
| 1 | 02 Types, printf and scanf | int, double, char, const, printf codes, scanf with result check, integer division / stock update |
| 1 | 03 Making decisions | if/else, switch, comparisons, &&, \|\|, ! / grade checker |
| 1 | 04 Loops | for, while, do-while, break, continue / multiplication table |
| 2 Building blocks | 05 Functions | parameters, return, prototypes, pass by value / is_even and average |
| 2 | 06 Arrays and strings | arrays, index 0, #define size, char arrays, fgets, strlen, strcmp / lowest score |
| 2 | 07 Pointers | &, *, NULL, swap, output parameters, array decay, const pointer / double_it, min_max |
| 2 | 08 Structs | typedef struct, ., ->, array of structs, struct copy, snprintf / book discount |
| 2 | 09 Headers and multiple files | .h/.c split, include guard, linking, Makefile / temperature library |
| 3 Real programs | 10 Memory and common bugs | malloc, realloc, free, leak, use after free, double free, ASan / sum in allocated memory |
| 3 | 11 Files | fopen modes, fprintf, fgets, sscanf, fscanf, fclose / highest score from file |
| 3 | 12 Project: expense tracker | 3 source files, growing list, CSV save/load, Makefile and CMake / count command |

Makefile is taught in 09 and used in 12; CMake is introduced in 12 (installed in 01). Pointers (07) come before structs (08) so `->` is meaningful.

## Versions and verification
C17 (`-std=c17`, MSVC `/std:c17`). gcc 11 or newer assumed for wording; any recent gcc, clang, or MSVC 2019 16.8+ works. CMake 3.21 or newer (needed for `CMAKE_C_STANDARD 17`).
Windows route A: MSYS2 UCRT64 toolchain (`mingw-w64-ucrt-x86_64-toolchain`, cmake, make), PATH entry `C:\msys64\ucrt64\bin`. Route B: Build Tools for Visual Studio, "Desktop development with C++".
macOS: `xcode-select --install`. Linux: `build-essential cmake`.
**Status: written, not yet run.** No code in this track has been compiled or executed; expected outputs were derived by reading the code (user rule of 2026-11-23, see the writing brief).
Every verify.json builds with `gcc` and runs the program through a small `python -c` wrapper (portable path-to-exe); it requires `gcc` on PATH. Makefile and CMake steps are not covered by verify.json.

## Sources (Tier 1: official; no Tier 2 required)
- GCC manual: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html and https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
- C reference: https://en.cppreference.com/w/c
- MSVC `/std`: https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version
- MSYS2 and VS Code MinGW guide: https://www.msys2.org/ and https://code.visualstudio.com/docs/cpp/config-mingw
- GNU Make: https://www.gnu.org/software/make/manual/make.html
- CMake: https://cmake.org/cmake/help/latest/guide/tutorial/index.html
- SEI CERT C: https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard

## Scope choices
- scanf with a checked return is the input path in 02 to 04, 10; fgets plus sscanf from 06 on. `gets` is never used.
- Money in the project is whole cents (integer), converted once on input. The CSV format is deliberately restricted (one-word categories, no commas).
- Output prompts end with a newline so the expected output is identical whether input is typed or piped; the project prompt `> ` has no newline and is flushed.
- Every `printf` format string is a literal. Every buffer has an explicit size.
- Starter folders compile (with unused-parameter warnings in 05, 07, 08); their TODOs state goals, not code.
- Times: 01 75 min (setup), 02 60, 03 40, 04 40, 05 40, 06 45, 07 50, 08 45, 09 50, 10 55, 11 50, 12 90 (two sittings, break after Step 4).
- Shared logistics live in README.md (working folder, build and run, exercise folders).
- No art (`assets: []`).
