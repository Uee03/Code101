---
track: c
level: 101
phase: 1
phase_name: foundations
lesson: 02
title: "Types, printf and scanf"
time: 60 min
prerequisites: [101.1.01]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-1-foundations/02-types-printf-scanf/
assets: []
---

# 02. Types, printf and scanf

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- declare variables of type `int`, `double` and `char` and change their values;
- print values with `printf` using `%d`, `%f`, `%c` and `%.2f`;
- read numbers typed by the user with `scanf` and check that it worked;
- predict the result of integer division and the remainder operator.

## Recap
1. Which function does every C program start in? <details><summary>Answer</summary>`main`.</details>
2. What is the difference between building and running? <details><summary>Answer</summary>Building makes the program file; running starts it.</details>

## Why it matters
A shop keeps its prices on labelled shelves: a shelf for whole bottles, a shelf for money with cents, a shelf for a single grade letter. A **variable** is one labelled shelf in the computer's memory, and its **type** says what kind of thing the shelf holds. Programs need variables to remember what the user typed and to calculate with it.

## What you will build
Two small programs. First, `types.c` shows variables and `printf`. Second, `main.c` is a tip calculator: it asks for a bill, a tip percent and a number of people, then prints the tip, the total and each person's share.

## Before you start
- Finish lesson 01 (a working compiler and the build-and-run routine).
- Time: 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-1-foundations/02-types-printf-scanf/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains the working folder and the [build and run](../../README.md#build-and-run) commands for gcc/clang and Microsoft `cl`.
- Working folder: `lesson02` in `$HOME/code101/c`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson02"`; macOS/Linux `cd "$HOME/code101/c/lesson02"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson02` (full path `$HOME/code101/c/lesson02`). Open only `lesson02` in your editor and open a terminal there.

### Step 2. Variables and printf
A variable is created by a **declaration**: the type, a name, `=` and a first value. The most common types are:

| Type | Holds | Example | printf code |
|---|---|---|---|
| `int` | a whole number | `12` | `%d` |
| `double` | a number with a decimal point | `0.5` | `%f`, or `%.2f` for two decimals |
| `char` | one character in single quotes | `'A'` | `%c` |

`const` before a type means the value may never change after it is set. In the **format string** (the first text in `printf`), a `%` code is a hole that `printf` fills with the next value after the comma.

Create `types.c` and paste the complete file:

**File: `types.c`**
```c
#include <stdio.h>

int main(void) {
    int apples = 12;
    double price = 0.5;
    char grade = 'A';
    const int dozen = 12;

    printf("Apples: %d\n", apples);
    printf("Price: %.2f\n", price);
    printf("Grade: %c\n", grade);
    printf("A dozen is %d\n", dozen);
    printf("Value: %.2f\n", apples * price);
    apples = apples + 3;
    printf("Apples now: %d\n", apples);
    return 0;
}
```

Save it. **Predict first:** what will `Value:` print? Then build and run (gcc/clang shown; Microsoft `cl` row in the README table uses `/Fe:types.exe types.c`):

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o types types.c
```

macOS/Linux run `./types`; Windows PowerShell run `.\types`. Expected output (not yet run):

```text
Apples: 12
Price: 0.50
Grade: A
A dozen is 12
Value: 6.00
Apples now: 15
```

`apples * price` multiplies a whole number by a decimal number; C converts the whole number to a `double` first, so the result is 6.0, shown as `6.00`.

### Step 3. Reading input with scanf
`scanf` is the opposite of `printf`: it reads what the user types. It needs two things: a format code for the type (`%d` for `int`, `%lf` for `double`) and the **address** of the variable to fill, written with `&` in front of the name (`&bill` means "the place where bill lives"). Lesson 07 explains addresses properly; for now always write the `&` for `scanf`.

`scanf` returns how many values it managed to read. We expect 1, so we write `if (scanf("%lf", &bill) != 1) { ... }`. Read it as: "if reading a number did not work, print a message and stop". `!=` means "not equal to"; `||` means "or"; `return 1;` ends the program and reports a problem. Lesson 03 explains `if` fully. Without this check, typing `abc` would silently leave the variable unchanged.

Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

int main(void) {
    double bill = 0.0;
    double percent = 0.0;
    int people = 0;

    printf("Bill amount (e.g. 80):\n");
    if (scanf("%lf", &bill) != 1) {
        printf("Use digits for the bill.\n");
        return 1;
    }
    printf("Tip percent (e.g. 15):\n");
    if (scanf("%lf", &percent) != 1) {
        printf("Use digits for the percent.\n");
        return 1;
    }
    printf("Number of people:\n");
    if (scanf("%d", &people) != 1) {
        printf("Use a whole number of people.\n");
        return 1;
    }
    if (bill < 0 || percent < 0 || people <= 0) {
        printf("Amounts must be nonnegative; people must be positive.\n");
        return 1;
    }

    double tip = bill * percent / 100;
    double total = bill + tip;
    double each = total / people;
    printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each);
    printf("Whole division: %d Remainder: %d\n", 7 / 2, 7 % 2);
    return 0;
}
```

Save it. Type **80**, not `$80`, and **15**, not `15%`, with no extra characters.

## Run it
Build in `lesson02` (gcc/clang):

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

Microsoft `cl` instead: `cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c`. Run with `./app` (macOS/Linux) or `.\app` (Windows). Type these three lines, pressing Enter after each:

**File: keyboard input (not a saved file)**
```text
80
15
2
```

Expected output (not yet run; your terminal also shows the numbers you typed, mixed between these lines):

```text
Bill amount (e.g. 80):
Tip percent (e.g. 15):
Number of people:
Tip: 12.00
Total: 92.00
Each: 46.00
Whole division: 3 Remainder: 1
```

## How it works
1. `double bill = 0.0;` creates the variable with a safe first value. Always give a variable a value; one that is never set holds leftover garbage.
2. `scanf("%lf", &bill)` waits until you press Enter, converts the typed text to a number and stores it in `bill`. `%lf` is for `double` in `scanf` (for `printf`, `%f` is used for `double`; the two functions differ here).
3. `bill * percent / 100` follows the usual maths order: `*` and `/` before `+` and `-`; brackets change the order. `percent / 100` turns 15 into 0.15 of the bill.
4. `total / people` divides a `double` by an `int`; C turns the `int` into a `double` first, so the result keeps its decimals.
5. **Integer division** of two `int` values drops the fraction: `7 / 2` is 3. `%` is the **remainder** operator: `7 % 2` is 1. Misconception: `%` here is not a percentage.
6. `%.2f` prints a `double` with exactly two decimals. It changes only how the value is shown, not the value itself.

## Try it
**Guided.** Make a **stock update** in `try02` (a new folder next to `lesson02`; see [exercise folders](../../README.md#exercise-folders)). It starts with 24 bottles at 1.25 each. Sell 5 bottles, then print how many are left and the income from the 5 sold.

**File: `main.c` (starter)**
```c
#include <stdio.h>

int main(void) {
    int bottles = 24;
    double price = 1.25;
    printf("Shop opened with %d bottles at %.2f each\n", bottles, price);
    /* TODO: sell 5 bottles by changing the number of bottles. */
    /* TODO: print "Bottles left: " followed by the number left. */
    /* TODO: print "Income: " followed by the money earned from the 5 bottles, with 2 decimals. */
    return 0;
}
```

Build with `gcc -std=c17 -Wall -Wextra -o app main.c` in `try02` and run it. Aim for:

```text
Shop opened with 24 bottles at 1.25 each
Bottles left: 19
Income: 6.25
```

**Change.** Make the number sold typed by the user with `scanf`, checking its result as in the tip calculator. **Stretch (optional):** refuse to sell more bottles than the shop has; choose the message yourself.

<details><summary>Solution</summary>

Replace the three TODO comment lines; everything else stays as in the starter.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int main(void) {
    int bottles = 24;
    double price = 1.25;
    printf("Shop opened with %d bottles at %.2f each\n", bottles, price);
    int sold = 5;
    bottles = bottles - sold;
    printf("Bottles left: %d\n", bottles);
    printf("Income: %.2f\n", sold * price);
    return 0;
}
```

</details>

## Check yourself
1. Which printf code prints an `int`, and which prints a `double` with two decimals?
   <details><summary>Answer</summary>`%d` and `%.2f`.</details>
2. Why does `scanf("%d", &people)` need the `&`?
   <details><summary>Answer</summary>`scanf` must know where `people` lives in memory so it can store the number there.</details>
3. What do `9 / 2` and `9 % 2` give?
   <details><summary>Answer</summary>4 and 1.</details>
4. The user types `abc` at the bill prompt. What happens?
   <details><summary>Answer</summary>`scanf` returns 0 instead of 1, so the program prints "Use digits for the bill." and stops.</details>

## Common mistakes
Warnings marked "typical message" use gcc's usual wording; the exact text can differ between versions.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `warning: format '%d' expects argument of type 'int', but argument 2 has type 'double'` (typical message) | Used `%d` for a `double` | Use `%f` or `%.2f` for `double` values. |
| `warning: format '%d' expects argument of type 'int *', but argument 2 has type 'int'` (typical message) | Forgot the `&` in `scanf` | Write `scanf("%d", &people)`. |
| `Use digits for the bill.` | Typed `$80`, `80,5` or left words in the input | Type only digits, with a `.` for decimals: `80` or `80.5`. |
| `Use digits for the percent.` | Typed `15%` | Type `15`. |
| Wrong tip such as 0.00 or a strange number | Used `%f` instead of `%lf` in `scanf` for a `double` | Use `%lf` in `scanf`. |
| `.\app` shows old output | Build failed or file not saved | Save, build again, read the first error. |

## Best practice
Check the value returned by `scanf` every time before you use the variable. Source: cppreference, scanf return value https://en.cppreference.com/w/c/io/fscanf

## Going further
- All printf format codes: https://en.cppreference.com/w/c/io/fprintf

## Summary
- You declared `int`, `double`, `char` and `const` variables.
- You printed values with `%d`, `%.2f` and `%c`.
- You read numbers with `scanf` and checked its result.
- You predicted integer division (`7 / 2` is 3) and the remainder (`7 % 2` is 1).

## Next lesson
**[03. Making decisions](03-making-decisions.md):** make the program choose between actions with `if`, `else` and `switch`.
