---
track: c
level: 101
phase: 1
phase_name: foundations
lesson: 04
title: "Loops"
time: 40 min
prerequisites: [101.1.02, 101.1.03]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-1-foundations/04-loops/
assets: []
---

# 04. Loops

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write `for`, `while` and `do ... while` loops;
- use `break` and `continue` to change a loop's course;
- predict how many times a loop runs and what it prints;
- recognise and stop an endless loop.

## Recap
1. Which operator means "and", and which means "or"? <details><summary>Answer</summary>`&&` is and; `||` is or.</details>
2. What does a `switch` need at the end of each case? <details><summary>Answer</summary>`break;`</details>

## Why it matters
Washing 30 plates means repeating "scrub, rinse, stack" 30 times. Nobody writes 30 separate sets of instructions; you say "do this for each plate". A **loop** repeats a block of statements while a condition stays true.

## What you will build
A program that asks how many numbers to add (1 to 10), then adds 1, 2, 3 and so on while printing the running sum, counts down, counts the digits in the sum, lists the odd numbers and finds the first multiple of 3.

## Before you start
- Finish lessons 02 and 03 (variables, `scanf`, `if`).
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-1-foundations/04-loops/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson04`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson04"`; macOS/Linux `cd "$HOME/code101/c/lesson04"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson04`. Open only `lesson04` in your editor and open a terminal there.

### Step 2. The three loops
- `while (condition) { ... }` checks the condition **before** each round. If it is false at the start, the body never runs.
- `do { ... } while (condition);` runs the body **once first**, then checks. Note the semicolon after the bracket.
- `for (start; condition; step) { ... }` packs the three loop parts on one line: `int i = 1` runs once at the start, `i <= count` is checked before each round, and `i++` runs after each round. `i++` means "add 1 to `i`"; `i--` subtracts 1; `sum += i` means `sum = sum + i`.

Inside a loop, `continue` skips the rest of this round and starts the next; `break` leaves the loop entirely.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

int main(void) {
    int count = 0;
    printf("How many numbers to add (1 to 10)?\n");
    if (scanf("%d", &count) != 1 || count < 1 || count > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }

    int sum = 0;
    for (int i = 1; i <= count; i++) {
        sum += i;
        printf("Added %d, sum is %d\n", i, sum);
    }

    printf("Countdown:\n");
    int n = count;
    while (n > 0) {
        printf("%d\n", n);
        n--;
    }
    printf("Liftoff!\n");

    int digits = 0;
    int value = sum;
    do {
        digits++;
        value /= 10;
    } while (value > 0);
    printf("The sum has %d digit(s)\n", digits);

    printf("Odd numbers up to %d:\n", count);
    for (int i = 1; i <= count; i++) {
        if (i % 2 == 0) {
            continue;
        }
        printf("%d\n", i);
    }

    for (int i = 1; i <= count; i++) {
        if (i % 3 == 0) {
            printf("First multiple of 3: %d\n", i);
            break;
        }
    }
    return 0;
}
```

Save it. **Predict first:** with the input `5`, what is the last "sum is" line, and how many digits does the sum have?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows). Type `5` and press Enter.

Expected output (not yet run; the `5` you typed also appears in the terminal):

```text
How many numbers to add (1 to 10)?
Added 1, sum is 1
Added 2, sum is 3
Added 3, sum is 6
Added 4, sum is 10
Added 5, sum is 15
Countdown:
5
4
3
2
1
Liftoff!
The sum has 2 digit(s)
Odd numbers up to 5:
1
3
5
First multiple of 3: 3
```

## How it works
1. The first `for` runs with `i` = 1, 2, 3, 4, 5. `i` exists only inside that loop; the later loops declare their own `i`.
2. The `while` loop keeps `n` shrinking: 5, 4, 3, 2, 1. When `n` reaches 0 the condition `n > 0` is false and the loop ends. If you forgot `n--;` the condition would never become false: an **endless loop**. Stop a runaway program with **Ctrl+C**.
3. The `do ... while` counts digits: 15 becomes 1 after one division by 10 (digits 1), then 0 after the second (digits 2). Dividing an `int` by 10 drops the last digit. A `do` loop is the right tool because even the number 0 has one digit, so the body must run at least once.
4. `i % 2 == 0` is true for even numbers; `continue` skips printing them.
5. The last loop stops at the first multiple of 3 with `break`, so 6 is never reached.
6. Misconception: `for (int i = 1; i < count; i++)` runs `count - 1` times, not `count`. Use `<=` when you want to include the end.

## Try it
**Guided.** A **multiplication table** in `try04` (see [exercise folders](../../README.md#exercise-folders)).

**File: `main.c` (starter)**
```c
#include <stdio.h>

int main(void) {
    int n = 0;
    printf("Table for which number (1 to 12)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 12) {
        printf("Use a whole number from 1 to 12.\n");
        return 1;
    }
    /* TODO: print the rows of the table for rows 1 to 10, one per line, in the form 3 x 1 = 3. */
    return 0;
}
```

Build and run in `try04`. With the input `3` the output should be:

```text
Table for which number (1 to 12)?
3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
3 x 4 = 12
3 x 5 = 15
3 x 6 = 18
3 x 7 = 21
3 x 8 = 24
3 x 9 = 27
3 x 10 = 30
```

**Change.** Print only the rows whose result is even. **Stretch (optional):** let the user choose how many rows to print; decide what limits make sense.

<details><summary>Solution</summary>

Replace the TODO comment line; all other lines stay as in the starter.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int main(void) {
    int n = 0;
    printf("Table for which number (1 to 12)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 12) {
        printf("Use a whole number from 1 to 12.\n");
        return 1;
    }
    for (int row = 1; row <= 10; row++) {
        printf("%d x %d = %d\n", n, row, n * row);
    }
    return 0;
}
```

</details>

## Check yourself
1. How many times does `for (int i = 0; i < 4; i++)` run its body?
   <details><summary>Answer</summary>4 times, with `i` = 0, 1, 2, 3.</details>
2. What is the difference between `while` and `do ... while`?
   <details><summary>Answer</summary>`while` may run zero times; `do ... while` always runs at least once.</details>
3. What does `continue` do, and what does `break` do?
   <details><summary>Answer</summary>`continue` skips to the next round; `break` leaves the loop.</details>
4. Find the bug: `int n = 3; while (n > 0) { printf("%d\n", n); }`
   <details><summary>Answer</summary>`n` never changes, so it loops forever. Add `n--;` inside the loop.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| The program prints the same line forever | The loop variable is never changed (missing `n--;` or `i++`) | Press Ctrl+C, then change the loop variable inside the loop. |
| One round too few or too many | `<` used instead of `<=`, or the other way round | Decide whether the end value is included and choose the operator to match. |
| The loop body runs once, or never, although it looks right | A `;` directly after `for (...)` or `while (...)` ends the loop with an empty body | Remove the semicolon. |
| `Use a whole number from 1 to 10.` | The input was text or outside the limits | Type a number from 1 to 10. |
| `error: expected ';' before ...` (typical message) | A missing semicolon, for example after `} while (value > 0)` | Add the `;`. |

## Best practice
Keep each loop short and give its variable a clear start, test and step. Declare the loop variable in the `for` header so it cannot be used by accident later. Source: cppreference, for loop https://en.cppreference.com/w/c/language/for

## Going further
- Loop statements on cppreference: https://en.cppreference.com/w/c/language/for

## Summary
- You wrote `for`, `while` and `do ... while` loops.
- You used `continue` and `break`.
- You predicted the output of loops and spotted an endless loop.

## Next lesson
**[05. Functions](../phase-2-building-blocks/05-functions.md):** give a group of steps a name and reuse it.
