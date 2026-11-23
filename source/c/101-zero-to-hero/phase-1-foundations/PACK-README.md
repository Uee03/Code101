# C 101, Phase 1: Foundations

Source pack for lessons 01 to 04 of **C 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-1-foundations/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-hello-c` | Hello, C: install and first program | two-line greeting / recipe card |
| `02-types-printf-scanf` | Types, printf and scanf | variable demo and tip calculator / stock update |
| `03-making-decisions` | Making decisions | ticket price / grade checker |
| `04-loops` | Loops | sums, countdown, digits / multiplication table |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson. |
| `exercise/starter/` | Runnable starting point with TODO comments; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer checks. Learners can ignore this file. |

## How to run any program

1. Install a C compiler and CMake (lesson 01).
2. Unzip the pack: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux `unzip` or **Extract Here**.
3. Open a terminal **in the folder that holds the `.c` file** (for example `01-hello-c/code`). Check with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Build and run. gcc or clang (Windows with MSYS2, macOS, Linux):

```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

   Then `./app` (macOS/Linux) or `.\app` (Windows PowerShell). Microsoft compiler (Developer PowerShell for VS):

```text
cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c
```

   Then `.\app`. Lesson 02 also has `types.c`: build it with `-o types types.c`.

To do an exercise, copy the `starter` folder and rename it `try01` (use the corresponding try name for later lessons) next to, not inside, your lesson folder. Without the pack, type the starter files shown in the lesson. Never put starter and solution in the same folder.

Lessons 02, 03 and 04 read from the keyboard; type the numbers named in the lesson at the prompts.

## Needs

A C compiler with C17 support (gcc 8 or newer, any recent clang, or Microsoft Visual C++ 2019 16.8 or newer) and CMake 3.21 or newer. Standard library only; no downloads at run time, art or accounts.
Lesson text: `tutorials/c/101-zero-to-hero/phase-1-foundations/` in the repository.
Status: written, not yet run.

Next: Phase 2, Building Blocks.
