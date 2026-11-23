# C 101, Phase 3: Real programs

Source pack for lessons 10 to 12 of **C 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-3-real-programs/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `10-memory-and-bugs` | Memory and common bugs | malloc, realloc, free and a broken `bug.c` / sum of numbers in allocated memory |
| `11-files` | Files | shopping list file / highest score from a file |
| `12-expense-tracker` | Project: expense tracker | console tracker with `expenses.csv`, Makefile and CMake / a `count` command |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson. |
| `exercise/starter/` | Runnable starting point with TODO comments; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer checks. Learners can ignore this file. |

## How to run any program

1. Open a terminal in the folder that holds the `.c` files.
2. Lessons 10 and 11: `gcc -std=c17 -Wall -Wextra -o app main.c`, then `./app` (macOS/Linux) or `.\app` (Windows). Lesson 10 asks for a number (type `3`); its extra file `bug.c` is broken on purpose and is built with `-o bug bug.c`. Microsoft compiler: `cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c`.
3. Lesson 12 has two source files: `gcc -std=c17 -Wall -Wextra -o app main.c expense.c`. The program reads and writes `expenses.csv` in the folder you start it from. Commands: `add food 12.50`, `list`, `total`, `quit`. The `Makefile` (a Tab starts each command line) is built with `make` or `mingw32-make`; CMake with `cmake -S . -B build` then `cmake --build build` (Windows MSYS2 adds `-G "MinGW Makefiles"`; Microsoft adds `--config Release`).
4. Copy a folder before you run it if you do not want `expenses.csv`, `shopping.txt` or `scores.txt` in the pack.

To do an exercise, copy the `starter` folder and rename it `try10` (use the corresponding try name for later lessons) next to, not inside, your lesson folder.

## Needs

A C compiler with C17 support; GNU Make and CMake 3.21 or newer for the build-tool steps in lesson 12. Standard library only.
Lesson text: `tutorials/c/101-zero-to-hero/phase-3-real-programs/` in the repository.
Status: written, not yet run.
