---
track: c
level: 101
phase: 3
phase_name: real-programs
lesson: 11
title: "Files"
time: 50 min
prerequisites: [101.1.02, 101.2.06, 101.2.07]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-3-real-programs/11-files/
assets: []
---

# 11. Files

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- open, write, append to, read and close a text file;
- check that `fopen` worked before using the file;
- read a file line by line with `fgets` and split a line with `sscanf`;
- predict what happens when a file does not exist.

## Recap
1. Why must the result of `scanf` be checked? <details><summary>Answer</summary>It tells how many values were read; without the check, bad input goes unnoticed.</details>
2. What does `fgets(line, sizeof line, in)` protect against? <details><summary>Answer</summary>Writing past the end of `line`: it never reads more than the size you give.</details>

## Why it matters
Variables are like a whiteboard: wiped when you leave the room. A **file** is a notebook that stays on the shelf. Programs that must remember anything between runs (a shopping list, scores, expenses) save it to a file.

## What you will build
A program that writes a small shopping list to `shopping.txt`, appends a line, reads the file back line by line, prints each item and the total cost, and shows what happens when a file is missing.

## Before you start
- Finish lessons 02, 06 and 07 (input, strings, pointers).
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-3-real-programs/11-files/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson11`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson11"`; macOS/Linux `cd "$HOME/code101/c/lesson11"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson11`. Open only `lesson11` in your editor and open a terminal there. The program creates its file in the **current folder** of the terminal, so be in `lesson11` when you run it.

### Step 2. The file tools
`FILE *` is a pointer to a **file handle**, the connection between your program and a file. All come from `<stdio.h>`:

| Call | Meaning |
|---|---|
| `fopen(path, "w")` | open for **w**riting; creates the file, or **empties** an existing one |
| `fopen(path, "a")` | open to **a**ppend: new text goes at the end, old text stays |
| `fopen(path, "r")` | open for **r**eading; returns `NULL` if the file does not exist |
| `fprintf(file, ...)` | like `printf` but into the file |
| `fgets(line, size, file)` | read one line (up to `size - 1` characters) or return `NULL` at the end |
| `sscanf(line, format, ...)` | like `scanf` but reads from a string in memory |
| `fclose(file)` | finish and release the file; data may not reach the disk before this |

Each line of our file has the form `name,quantity,price`. The `sscanf` format `"%29[^,],%d,%lf"` reads: up to 29 characters that are not a comma (`[^,]` means "anything except a comma"), then a literal comma, a whole number, a comma, a decimal. The 29 leaves room for the terminator in `name[30]`. `sscanf` returns how many values it filled, so we expect 3.

A plain text file here must not contain a comma inside a name; real CSV files need more rules.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

#define LINE_SIZE 100

int main(void) {
    const char *path = "shopping.txt";

    FILE *out = fopen(path, "w");
    if (out == NULL) {
        printf("Cannot write %s\n", path);
        return 1;
    }
    fprintf(out, "milk,2,1.20\n");
    fprintf(out, "bread,1,2.50\n");
    fclose(out);

    out = fopen(path, "a");
    if (out == NULL) {
        printf("Cannot append to %s\n", path);
        return 1;
    }
    fprintf(out, "apples,6,0.40\n");
    fclose(out);

    FILE *in = fopen(path, "r");
    if (in == NULL) {
        printf("Cannot read %s\n", path);
        return 1;
    }
    char line[LINE_SIZE];
    int lines = 0;
    double total = 0.0;
    while (fgets(line, sizeof line, in) != NULL) {
        char name[30];
        int quantity = 0;
        double price = 0.0;
        if (sscanf(line, "%29[^,],%d,%lf", name, &quantity, &price) != 3) {
            printf("Skipping bad line: %s", line);
            continue;
        }
        lines++;
        printf("%s: %d x %.2f\n", name, quantity, price);
        total += quantity * price;
    }
    fclose(in);
    printf("Lines read: %d\n", lines);
    printf("Total: %.2f\n", total);

    FILE *missing = fopen("does-not-exist.txt", "r");
    if (missing == NULL) {
        printf("Could not open does-not-exist.txt (as expected)\n");
    } else {
        fclose(missing);
    }
    return 0;
}
```

Save it. **Predict first:** how many lines does the file hold at the end, and what is the total cost?

## Run it
Build in `lesson11` (gcc/clang; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows).

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

Expected output (not yet run):

```text
milk: 2 x 1.20
bread: 1 x 2.50
apples: 6 x 0.40
Lines read: 3
Total: 7.30
Could not open does-not-exist.txt (as expected)
```

Open the new file `shopping.txt` in your editor: it holds the three lines exactly as written. Run the program again: the file is rewritten from scratch (mode `"w"` empties it) and the output is identical.

## How it works
1. The first `fopen(path, "w")` creates `shopping.txt`; two `fprintf` calls write two lines; `fclose` ends the writing.
2. Mode `"a"` adds the third line without erasing the first two.
3. In the reading loop `fgets` returns each line (including its `\n`) until the file ends, when it returns `NULL` and the loop stops.
4. `sscanf` splits the line. A line that does not match returns something other than 3 and is reported and skipped: real files are often wrong, so never trust their contents. The `%s` in "Skipping bad line" prints the line including its own newline, so the format has no `\n`.
5. `quantity * price` is an `int` times a `double`; the total is 2.40 + 2.50 + 2.40 = 7.30.
6. A missing file gives `NULL` from `fopen`; you must test for it because reading from `NULL` crashes the program. Misconception: `fopen` does not search the whole computer: a relative name like `shopping.txt` means "in the terminal's current folder".
7. A second way to read numbers is `fscanf(file, "%d", &value)`, which works like `scanf` on a file and returns 1 each time it reads a number and something else at the end. The exercise uses it.

## Try it
**Guided.** In `try11` (see [exercise folders](../../README.md#exercise-folders)) the program writes `scores.txt` for you. Read the numbers back with `fscanf` and print the highest.

**File: `main.c` (starter)**
```c
#include <stdio.h>

int main(void) {
    FILE *out = fopen("scores.txt", "w");
    if (out == NULL) {
        printf("Cannot write scores.txt\n");
        return 1;
    }
    fprintf(out, "72\n45\n90\n");
    fclose(out);

    int highest = 0;
    /* TODO: open scores.txt for reading, read every number from it, and keep the largest one in highest. */
    printf("Highest: %d\n", highest);
    return 0;
}
```

Expected output after you finish:

```text
Highest: 90
```

**Change.** Also print how many scores were read. **Stretch (optional):** make the program ask the user for the file name, and print a friendly message when it does not exist; decide how to read the name safely.

<details><summary>Solution</summary>

Replace the TODO comment; the rest is unchanged.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int main(void) {
    FILE *out = fopen("scores.txt", "w");
    if (out == NULL) {
        printf("Cannot write scores.txt\n");
        return 1;
    }
    fprintf(out, "72\n45\n90\n");
    fclose(out);

    int highest = 0;
    FILE *in = fopen("scores.txt", "r");
    if (in == NULL) {
        printf("Cannot read scores.txt\n");
        return 1;
    }
    int value = 0;
    while (fscanf(in, "%d", &value) == 1) {
        if (value > highest) {
            highest = value;
        }
    }
    fclose(in);
    printf("Highest: %d\n", highest);
    return 0;
}
```

</details>

## Check yourself
1. What is the difference between modes `"w"` and `"a"`?
   <details><summary>Answer</summary>`"w"` empties the file first; `"a"` keeps the old text and adds to the end.</details>
2. What does `fopen` return when the file cannot be opened?
   <details><summary>Answer</summary>`NULL`, so test for it before using the handle.</details>
3. Why `fclose`?
   <details><summary>Answer</summary>It finishes the work, flushes buffered data to the disk and releases the file.</details>
4. What would `sscanf` return for the line `milk,two,1.20`?
   <details><summary>Answer</summary>1, because only the name was read before `two` failed to be a number; the program would skip the line.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot write shopping.txt` | The terminal's folder is not writable, or a program has the file locked | Run from your own `lesson11` folder and close editors that lock the file. |
| `Could not open ...` for a file that you know exists | The terminal is in a different folder, so the relative name points elsewhere | Check `Get-Location` or `pwd`. |
| The old contents vanished | Opened with `"w"` instead of `"a"` | Use `"a"` to append. |
| The last lines are missing in the file | No `fclose` before the program ended or crashed | Always close. |
| A crash when reading | Used a `FILE *` that is `NULL` | Check the result of `fopen`. |

## Best practice
Check every `fopen`, close every file, and treat the file's contents as untrusted input: validate each line before using it. Source: SEI CERT C Coding Standard, FIO42-C https://wiki.sei.cmu.edu/confluence/display/c/FIO42-C.+Close+files+when+they+are+no+longer+needed

## Going further
- File access functions: https://en.cppreference.com/w/c/io

## Summary
- You wrote, appended and read a text file.
- You checked `fopen` and handled a missing file.
- You read lines with `fgets` and split them with `sscanf`.

## Next lesson
**[12. Project: expense tracker](12-expense-tracker.md):** combine everything into a saving console program with several files and a build tool.
