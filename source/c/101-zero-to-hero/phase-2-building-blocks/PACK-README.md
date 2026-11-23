# C 101, Phase 2: Building blocks

Source pack for lessons 05 to 09 of **C 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `05-functions` | Functions | bill helpers / is_even and average |
| `06-arrays-and-strings` | Arrays and strings | temperatures and a name / lowest score and pass count |
| `07-pointers` | Pointers | swap, bonus, array total / double_it and min_max |
| `08-structs` | Structs | an item shelf / book discount |
| `09-headers-and-multiple-files` | Headers and multiple files | rectangle library with a Makefile / temperature library |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished source from the lesson. |
| `exercise/starter/` | Runnable starting point with TODO comments; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently runnable. Try first. |
| `verify.json` | Maintainer checks. Learners can ignore this file. |

## How to run any program

1. Open a terminal in the folder that holds the `.c` files (for example `05-functions/code`).
2. Build and run. gcc or clang:

```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

   then `./app` (macOS/Linux) or `.\app` (Windows). Microsoft compiler: `cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c`, then `.\app`.
3. Lesson 09 has several files. List every `.c` file: `gcc -std=c17 -Wall -Wextra -o app main.c rectangle.c` in `code`, and `gcc -std=c17 -Wall -Wextra -o app main.c temperature.c` in the exercise folders. The `Makefile` in `09-headers-and-multiple-files/code` is built with `make` (macOS/Linux) or `mingw32-make` (Windows with MSYS2). Its command lines start with a Tab character.
4. Lesson 06 asks for a name: type `Ada`. Lesson 07, 08 and 09 need no typing.

To do an exercise, copy the `starter` folder and rename it `try05` (use the corresponding try name for later lessons) next to, not inside, your lesson folder. Without the pack, type the starter files shown in the lesson.

## Needs

A C compiler with C17 support and (lesson 09, optional) GNU Make. Standard library only.
Lesson text: `tutorials/c/101-zero-to-hero/phase-2-building-blocks/` in the repository.
Status: written, not yet run.

Next: Phase 3, Real programs.
