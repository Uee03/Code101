---
track: c
level: 101
phase: 3
phase_name: real-programs
lesson: 12
title: "Project: expense tracker"
time: 90 min
prerequisites: [101.2.07, 101.2.08, 101.2.09, 101.3.10, 101.3.11]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)", cmake: "3.21 or newer", make: "GNU Make 3.81 or newer" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- design a small program as a header, a library file and a `main` file;
- store records in memory that grows with `realloc` and save and load them from a file;
- read commands typed by the user safely and reject bad input;
- build the project with `gcc`, with a Makefile and with CMake.

## Recap
1. Which call gives memory back? <details><summary>Answer</summary>`free`.</details>
2. What does mode `"w"` do to an existing file? <details><summary>Answer</summary>It empties it before writing.</details>
3. What does an include guard prevent? <details><summary>Answer</summary>Processing the same header twice.</details>

## Why it matters
Real programs are not one file of numbered steps. They are small parts with clear jobs: one part keeps the list of expenses, one part talks to the user, one part saves to disk. You built each idea in the earlier lessons; this lesson puts them together, the way a small real tool is made.

## What you will build
A console program with these commands:

| Command | What it does |
|---|---|
| `add <category> <amount>` | adds an expense, for example `add food 12.50` |
| `list` | shows all expenses with numbers |
| `total` | shows the sum |
| `help` | shows the commands |
| `quit` | saves to `expenses.csv` and exits |

It loads `expenses.csv` when it starts, so your data survives between runs.

## Before you start
- Finish lessons 07, 08, 09, 10 and 11 (pointers, structs, headers, memory, files).
- Time: 90 minutes in two sittings. **Break point: after Step 4** (the two library files exist; you cannot run the program until Step 5).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson12`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson12"`; macOS/Linux `cd "$HOME/code101/c/lesson12"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson12`. Open only `lesson12` in your editor and open a terminal there.

### Step 2. The design
- **Money as whole cents.** Decimal numbers cannot store every amount exactly, so we convert the typed amount once into an `int` number of cents (12.50 becomes 1250) and add whole numbers from then on. We print cents as `12.50` again.
- **Files.** `expense.h` and `expense.c` hold the list of expenses (the "library"); `main.c` handles typing and printing. `main.c` never touches the list's memory directly; it calls `list_add`, `list_total` and so on.
- **The saved file** `expenses.csv` has one expense per line: `category,cents`, for example `food,1250`. A category may not contain a comma or a space, which keeps the format simple. (A real CSV format has more rules; this one is deliberately restricted.)
- **Limits for safety.** A category is at most 19 characters, an amount is above 0 and at most 100000, a typed line is at most 99 characters. Every typed value is checked before it is used.

### Step 3. The header
Create `expense.h`. It defines two types: `Expense` (one record) and `ExpenseList` (a growing array: a pointer to the items, how many are used, and how many fit). `size_t` is the unsigned whole-number type C uses for sizes and counts.

**File: `expense.h`**
```c
#ifndef EXPENSE_H
#define EXPENSE_H

#include <stddef.h>

#define CATEGORY_SIZE 20

typedef struct {
    char category[CATEGORY_SIZE];
    int cents;
} Expense;

typedef struct {
    Expense *items;
    size_t count;
    size_t capacity;
} ExpenseList;

void list_init(ExpenseList *list);
void list_free(ExpenseList *list);
int list_add(ExpenseList *list, const char *category, int cents);
long list_total(const ExpenseList *list);
int list_save(const ExpenseList *list, const char *path);
int list_load(ExpenseList *list, const char *path);

#endif
```

The functions that can fail return `1` for success and `0` for failure.

### Step 4. The library file
Create `expense.c`. New idea: the **conditional operator** `condition ? a : b` gives `a` when the condition is true and `b` otherwise. `list_add` doubles the room each time the list is full (4, 8, 16, ...), so growing is rare. `realloc(NULL, n)` works like `malloc(n)`, which handles the first call when `items` is still `NULL`.

**File: `expense.c`**
```c
#include "expense.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void list_init(ExpenseList *list) {
    list->items = NULL;
    list->count = 0;
    list->capacity = 0;
}

void list_free(ExpenseList *list) {
    free(list->items);
    list_init(list);
}

int list_add(ExpenseList *list, const char *category, int cents) {
    if (list->count == list->capacity) {
        size_t new_capacity = list->capacity == 0 ? 4 : list->capacity * 2;
        Expense *bigger = realloc(list->items, new_capacity * sizeof *bigger);
        if (bigger == NULL) {
            return 0;
        }
        list->items = bigger;
        list->capacity = new_capacity;
    }
    Expense *slot = &list->items[list->count];
    snprintf(slot->category, sizeof slot->category, "%s", category);
    slot->cents = cents;
    list->count++;
    return 1;
}

long list_total(const ExpenseList *list) {
    long total = 0;
    for (size_t i = 0; i < list->count; i++) {
        total += list->items[i].cents;
    }
    return total;
}

int list_save(const ExpenseList *list, const char *path) {
    FILE *out = fopen(path, "w");
    if (out == NULL) {
        return 0;
    }
    for (size_t i = 0; i < list->count; i++) {
        fprintf(out, "%s,%d\n", list->items[i].category, list->items[i].cents);
    }
    fclose(out);
    return 1;
}

int list_load(ExpenseList *list, const char *path) {
    FILE *in = fopen(path, "r");
    if (in == NULL) {
        return 1;
    }
    char line[100];
    while (fgets(line, sizeof line, in) != NULL) {
        char category[CATEGORY_SIZE];
        int cents = 0;
        /* 19 is CATEGORY_SIZE minus one, leaving room for the end-of-text character. */
        if (sscanf(line, "%19[^,],%d", category, &cents) == 2 && cents > 0) {
            if (!list_add(list, category, cents)) {
                fclose(in);
                return 0;
            }
        }
    }
    fclose(in);
    return 1;
}
```

Save both files. **You can take your break here.**

### Step 5. The main file
Create `main.c`. New ideas: `static` before a function means "only this file can use it". `for (;;)` is a loop with no condition: it runs until `break`. `fflush(stdout)` pushes the prompt text to the screen immediately, because text without a newline may otherwise wait in a buffer. In `sscanf(line, "%19s %79[^\n]", command, rest)`, `%19s` reads the command word and `%79[^\n]` reads the rest of the line; `rest` starts as an empty string, so a command without arguments leaves it empty. The `?:` operator appears again in `return saved ? 0 : 1;`. The user's text is never used as a format string for `printf`; it is only ever passed as a value.

**File: `main.c`**
```c
#include <stdio.h>
#include <string.h>

#include "expense.h"

#define DATA_FILE "expenses.csv"

static void print_money(long cents) {
    printf("%ld.%02ld", cents / 100, cents % 100);
}

static void print_help(void) {
    printf("Commands:\n");
    printf("  add <category> <amount>   for example: add food 12.50\n");
    printf("  list\n");
    printf("  total\n");
    printf("  quit\n");
}

static void do_add(ExpenseList *list, const char *args) {
    char category[CATEGORY_SIZE];
    double amount = 0.0;
    if (sscanf(args, "%19s %lf", category, &amount) != 2) {
        printf("Usage: add <category> <amount>\n");
        return;
    }
    if (strchr(category, ',') != NULL) {
        printf("The category cannot contain a comma.\n");
        return;
    }
    if (amount <= 0.0 || amount > 100000.0) {
        printf("Amount must be above 0 and at most 100000.\n");
        return;
    }
    int cents = (int)(amount * 100.0 + 0.5);
    if (!list_add(list, category, cents)) {
        printf("Out of memory.\n");
        return;
    }
    printf("Added %s ", category);
    print_money(cents);
    printf("\n");
}

static void do_list(const ExpenseList *list) {
    if (list->count == 0) {
        printf("No expenses yet.\n");
        return;
    }
    for (size_t i = 0; i < list->count; i++) {
        printf("%zu. %s ", i + 1, list->items[i].category);
        print_money(list->items[i].cents);
        printf("\n");
    }
}

int main(void) {
    ExpenseList list;
    list_init(&list);
    if (!list_load(&list, DATA_FILE)) {
        printf("Could not load %s.\n", DATA_FILE);
        list_free(&list);
        return 1;
    }
    printf("Expense tracker. %zu expense(s) loaded. Type help for commands.\n", list.count);

    char line[100];
    for (;;) {
        printf("> ");
        fflush(stdout);
        if (fgets(line, sizeof line, stdin) == NULL) {
            break;
        }
        char command[20];
        char rest[80] = "";
        int parts = sscanf(line, "%19s %79[^\n]", command, rest);
        if (parts < 1) {
            continue;
        }
        if (strcmp(command, "add") == 0) {
            do_add(&list, rest);
        } else if (strcmp(command, "list") == 0) {
            do_list(&list);
        } else if (strcmp(command, "total") == 0) {
            printf("Total: ");
            print_money(list_total(&list));
            printf("\n");
        } else if (strcmp(command, "help") == 0) {
            print_help();
        } else if (strcmp(command, "quit") == 0) {
            break;
        } else {
            printf("Unknown command: %s (type help)\n", command);
        }
    }

    int saved = list_save(&list, DATA_FILE);
    if (saved) {
        printf("Saved %zu expense(s) to %s.\n", list.count, DATA_FILE);
    } else {
        printf("Could not save %s.\n", DATA_FILE);
    }
    list_free(&list);
    return saved ? 0 : 1;
}
```

Save it.

### Step 6. Build by hand and try it
In `lesson12`, gcc or clang:

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c expense.c
```

Microsoft `cl`:

**File: terminal (not a saved file)**
```text
cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c expense.c
```

Run `./app` (macOS/Linux) or `.\app` (Windows). **Predict first:** after you type the six lines in **Run it**, what will the total be, and what will the file `expenses.csv` contain?

## Run it
Type these lines, pressing Enter after each:

**File: keyboard input (not a saved file)**
```text
add food 12.50
add transport 3
add rent 800.1
list
total
quit
```

Expected output (not yet run; the lines you type also appear in the terminal, after each `> `):

```text
Expense tracker. 0 expense(s) loaded. Type help for commands.
> Added food 12.50
> Added transport 3.00
> Added rent 800.10
> 1. food 12.50
2. transport 3.00
3. rent 800.10
> Total: 815.60
> Saved 3 expense(s) to expenses.csv.
```

The file `expenses.csv` now exists in `lesson12`; open it in your editor:

**File: `expenses.csv` (created by the program)**
```text
food,1250
transport,300
rent,80010
```

Run the program a second time and type `list`, then `quit`. The expenses return from the file:

```text
Expense tracker. 3 expense(s) loaded. Type help for commands.
> 1. food 12.50
2. transport 3.00
3. rent 800.10
> Saved 3 expense(s) to expenses.csv.
```

Try bad input as well: `add food abc` prints the usage line, `add food -5` prints the amount message and `dance` prints `Unknown command: dance (type help)`.

### Build with a Makefile (gcc or clang; Windows MSYS2 uses `mingw32-make`)
Create `Makefile`. Every command line starts with a **Tab**, not spaces (lesson 09 explains the format). The only differences from lesson 09 are the file names `expense.c` / `expense.o` / `expense.h` in place of `rectangle`.

**File: `Makefile`**
```make
CC = gcc
CFLAGS = -std=c17 -Wall -Wextra

app: main.o expense.o
	$(CC) $(CFLAGS) -o app main.o expense.o

main.o: main.c expense.h
	$(CC) $(CFLAGS) -c main.c

expense.o: expense.c expense.h
	$(CC) $(CFLAGS) -c expense.c

.PHONY: clean
clean:
	rm -f app app.exe main.o expense.o
```

Run `make` (macOS/Linux) or `mingw32-make` (Windows). Expected output (not yet run):

```text
gcc -std=c17 -Wall -Wextra -c main.c
gcc -std=c17 -Wall -Wextra -c expense.c
gcc -std=c17 -Wall -Wextra -o app main.o expense.o
```

### Build with CMake (every operating system)
**CMake** is a tool that reads a description of your project and writes the build files for whatever compiler you have (a Makefile, a Visual Studio project, ...). Create `CMakeLists.txt`:

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.21)
project(expense_tracker C)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_executable(app main.c expense.c)

if(MSVC)
  target_compile_options(app PRIVATE /W4)
  target_compile_definitions(app PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
  target_compile_options(app PRIVATE -Wall -Wextra)
endif()
```

Line by line: `cmake_minimum_required` names the oldest CMake that understands the file (C17 needs 3.21). `project(expense_tracker C)` names the project and says it is written in C. The three `set` lines ask for C17 exactly and no compiler-specific extensions. `add_executable(app main.c expense.c)` makes a program called `app` from those two files. The `if(MSVC)` block gives the Microsoft compiler its warning flag and the notice-hiding definition; every other compiler gets `-Wall -Wextra`.

Build in a separate `build` folder so generated files stay out of your source folder. macOS and Linux:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
./build/app
```

Windows with MSYS2 (PowerShell):

**File: terminal (not a saved file)**
```text
cmake -S . -B build -G "MinGW Makefiles"
cmake --build build
.\build\app
```

Windows with Microsoft (Developer PowerShell for VS):

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build --config Release
.\build\Release\app.exe
```

`-S .` means "the source is here" and `-B build` means "put the build files in `build`". CMake prints a series of configuring and building lines whose exact text depends on your version; it ends without an `error` line when it worked. Start the program from `lesson12` (as shown) so `expenses.csv` is read and written beside your sources. If you switch generator or compiler, delete the `build` folder first (`Remove-Item -Recurse build` in PowerShell, `rm -rf build` in macOS/Linux).

## How it works
1. **Layering.** `main.c` talks to the user and decides what the commands mean; `expense.c` stores and saves. Because `main.c` only includes `expense.h`, you could replace the file format without touching `main.c`.
2. **Growing memory.** `ExpenseList` is a pointer plus two counters. `list_add` doubles `capacity` when full. If `realloc` fails it returns 0 and the old data is still valid. `list_free` releases the block exactly once at the end.
3. **Parsing a command.** `fgets` reads one line safely. `sscanf` splits it into the command and the rest. `strcmp` chooses the branch. An empty line makes `sscanf` return -1, which is less than 1, so the loop continues.
4. **Validating input.** `do_add` checks that two values were read, that the category has no comma, and that the amount is in range before converting. `(int)(amount * 100.0 + 0.5)` rounds to the nearest cent.
5. **Saving and loading.** `quit` (or the end of input) calls `list_save`, which rewrites the whole file. `list_load` skips lines that do not match `category,cents` or have a non-positive amount: files can be edited by hand, so the loader must not trust them. A missing file is not an error; the list simply starts empty.
6. **Limits to know.** A line longer than 99 characters is read in pieces, so the rest is treated as a new command. Categories are one word. The program saves on `quit` or at the end of input, not if you close the terminal window or press Ctrl+C: keep a copy of data you care about.

## Try it
**Guided.** Add a `count` command that prints how many expenses there are, in `try12` (see [exercise folders](../../README.md#exercise-folders)). The starter has the same three files as this lesson: `expense.h` and `expense.c` are identical to Steps 3 and 4. In `main.c` the only difference is one extra comment line in `main`, shown here with its surrounding lines:

**File: `main.c` (starter, region around the TODO)**
```c
        int parts = sscanf(line, "%19s %79[^\n]", command, rest);
        if (parts < 1) {
            continue;
        }
        /* TODO: add a count command that prints "Expenses: " followed by how many expenses are in the list. */
        if (strcmp(command, "add") == 0) {
            do_add(&list, rest);
```

Build with `gcc -std=c17 -Wall -Wextra -o app main.c expense.c` in `try12`. With a fresh folder (no `expenses.csv`) and the input below, aim for the output shown:

**File: keyboard input (not a saved file)**
```text
add food 12.50
add rent 800.10
count
quit
```

```text
Expense tracker. 0 expense(s) loaded. Type help for commands.
> Added food 12.50
> Added rent 800.10
> Expenses: 2
> Saved 2 expense(s) to expenses.csv.
```

**Change.** Add a `largest` command that prints the biggest expense with its category. **Stretch (optional):** add `remove <number>`, deciding how to shift the items and what to print for an invalid number.

<details><summary>Solution</summary>

In `main.c` delete the TODO comment and add a branch for `count` in the `else if` chain, placed between `total` and `help`. Also add a line `printf("  count\n");` to `print_help` after the `total` line. Both changed regions with their context:

**File: `main.c` (solution, `print_help`)**
```c
static void print_help(void) {
    printf("Commands:\n");
    printf("  add <category> <amount>   for example: add food 12.50\n");
    printf("  list\n");
    printf("  total\n");
    printf("  count\n");
    printf("  quit\n");
}
```

**File: `main.c` (solution, command chain)**
```c
        } else if (strcmp(command, "total") == 0) {
            printf("Total: ");
            print_money(list_total(&list));
            printf("\n");
        } else if (strcmp(command, "count") == 0) {
            printf("Expenses: %zu\n", list.count);
        } else if (strcmp(command, "help") == 0) {
            print_help();
```

Everything else in `main.c`, and the files `expense.h` and `expense.c`, is unchanged. (The solution's `print_help` also lists `count`; the `help` text for `list` and `total` is unchanged.)

</details>

## Check yourself
1. Why store money as whole cents?
   <details><summary>Answer</summary>Whole numbers are exact when added; decimal numbers can carry tiny rounding errors.</details>
2. What happens in `list_add` when `count == capacity`?
   <details><summary>Answer</summary>The block is resized to double the capacity with `realloc`; if that fails the function returns 0.</details>
3. The file contains the line `rent,abc`. What does `list_load` do with it?
   <details><summary>Answer</summary>`sscanf` does not return 2, so the line is skipped.</details>
4. Why is the file only written on `quit`, and what is the risk?
   <details><summary>Answer</summary>Saving once keeps the code simple; the risk is that closing the window or pressing Ctrl+C loses new expenses.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `undefined reference to 'list_add'` (typical linker message) | The build command lacks `expense.c` | Build with `main.c expense.c`. |
| `fatal error: expense.h: No such file or directory` (typical message) | The header is not beside `main.c`, or is misspelled | Keep all `.c` and `.h` files in `lesson12`. |
| `Usage: add <category> <amount>` | The amount is missing or is not a number, e.g. `add food $5` | Type `add food 5`. |
| `Amount must be above 0 and at most 100000.` | Typed 0, a negative number or a huge number | Use an amount in range. |
| `Unknown command: add12 (type help)` | No space between the command and its arguments | Type `add food 12`. |
| `Makefile:4: *** missing separator.  Stop.` (typical message) | Spaces instead of a Tab on a command line | Use a Tab. |
| `CMake Error: ... generator ... does not match the generator used previously` (typical wording) | An old `build` folder from another compiler or generator | Delete `build` and run `cmake -S . -B build` again. |
| Expenses are gone after a run | The program was closed without `quit`, or started from another folder so it read a different `expenses.csv` | Type `quit`; run from `lesson12`. |

## Best practice
Validate every value that comes from outside the program (the keyboard and the file) before you use it, and keep the code that stores data separate from the code that talks to the user. Source: SEI CERT C Coding Standard, STR31-C https://wiki.sei.cmu.edu/confluence/display/c/STR31-C.+Guarantee+that+storage+for+strings+has+sufficient+space+for+character+data+and+the+null+terminator

## Going further
- The official CMake tutorial: https://cmake.org/cmake/help/latest/guide/tutorial/index.html

## Summary
- You designed a program as a header, a library file and a main file.
- You stored growing data in `realloc`ed memory and freed it.
- You saved and loaded a text file and validated its lines.
- You built the same project by hand, with a Makefile and with CMake.

## Next lesson
You have finished C 101. Repeat any lesson you found hard, then extend the tracker with your own commands: the exercise above is a good start.
