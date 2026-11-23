---
track: c
level: 101
phase: 1
phase_name: foundations
lesson: 03
title: "Making decisions"
time: 40 min
prerequisites: [101.1.02]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-1-foundations/03-making-decisions/
assets: []
---

# 03. Making decisions

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write `if`, `else if` and `else` blocks using comparison operators;
- combine conditions with `&&`, `||` and `!`;
- choose between many fixed values with `switch`;
- predict which branch runs for a given input.

## Recap
1. What does `scanf` return, and why do we check it? <details><summary>Answer</summary>The number of values it read; checking it catches input such as `abc`.</details>
2. What do `7 / 2` and `7 % 2` give? <details><summary>Answer</summary>3 and 1.</details>

## Why it matters
A ticket office does not charge everyone the same. A clerk looks at your age and decides: child, adult or senior price. Programs make the same kind of choice. The choice always has the shape "if this is true, do that; otherwise do something else".

## What you will build
A ticket-price program. It asks for an age and a day number (1 to 7), prints the day's name, adds a weekend surcharge and prints the price.

## Before you start
- Finish lesson 02 (variables, `printf`, `scanf`).
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-1-foundations/03-making-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson03`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson03"`; macOS/Linux `cd "$HOME/code101/c/lesson03"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson03`. Open only `lesson03` in your editor and open a terminal there.

### Step 2. The ideas before the code
A **condition** is a question whose answer is true or false. In C, a comparison such as `age < 5` gives 1 when true and 0 when false.

| Operator | Meaning | Operator | Meaning |
|---|---|---|---|
| `==` | equal to | `!=` | not equal to |
| `<` | less than | `<=` | less than or equal |
| `>` | greater than | `>=` | greater than or equal |

Warning: `=` stores a value; `==` compares. `if (age = 5)` is a classic mistake.

Conditions combine: `a && b` means both are true ("and"); `a || b` means at least one is true ("or"); `!a` means the opposite ("not"). `!(age >= 18)` means the same as `age < 18`. C stops early: in `a || b`, if `a` is true it never checks `b`.

An `if` runs its braces `{ }` only when its condition is true; `else if` is tried only when the earlier ones were false; `else` catches everything left. Exactly one branch of a chain runs. A **switch** compares one whole number against fixed `case` values; `break` leaves the switch, and `default` handles all other values. Without `break`, C keeps running into the next case, which is almost never what you want.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

int main(void) {
    int age = 0;
    int day = 0;

    printf("Age:\n");
    if (scanf("%d", &age) != 1 || age < 0) {
        printf("Use a whole number of years, 0 or more.\n");
        return 1;
    }
    printf("Day number (1=Mon ... 7=Sun):\n");
    if (scanf("%d", &day) != 1) {
        printf("Use a whole number for the day.\n");
        return 1;
    }

    int price = 0;
    if (age < 5) {
        price = 0;
    } else if (age < 18) {
        price = 8;
    } else if (age < 65) {
        price = 12;
    } else {
        price = 9;
    }

    switch (day) {
        case 1: printf("Monday\n"); break;
        case 2: printf("Tuesday\n"); break;
        case 3: printf("Wednesday\n"); break;
        case 4: printf("Thursday\n"); break;
        case 5: printf("Friday\n"); break;
        case 6: printf("Saturday\n"); break;
        case 7: printf("Sunday\n"); break;
        default:
            printf("Day must be 1 to 7.\n");
            return 1;
    }

    if ((day == 6 || day == 7) && price > 0) {
        price = price + 2;
        printf("Weekend surcharge: 2\n");
    }
    printf("Ticket price: %d\n", price);
    return 0;
}
```

Save it. **Predict first:** for age 30 on day 6, which branch of the age chain runs, and what is the final price?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows). Type:

**File: keyboard input (not a saved file)**
```text
30
6
```

Expected output (not yet run; your typed numbers also appear in the terminal):

```text
Age:
Day number (1=Mon ... 7=Sun):
Saturday
Weekend surcharge: 2
Ticket price: 14
```

Run it again with `3` and `2`: the price is 0 and there is no surcharge, because the condition needs `price > 0`. Try `70` and `9` to see the `default` branch.

## How it works
1. `scanf(...) != 1 || age < 0` has two parts joined by `||`. If `scanf` failed the first part is true and the second is never checked, so `age` is never used unread.
2. The `if / else if / else` chain tests from the top and stops at the first true condition. Age 30 fails `< 5` and `< 18`, passes `< 65`, so `price` becomes 12. The order matters: `age < 18` would also be true for age 3, but `age < 5` comes first.
3. `switch (day)` jumps to the matching `case`. Each case ends with `break`. `default` runs for 8, 0 or any other value, and `return 1;` stops the program.
4. `(day == 6 || day == 7) && price > 0` needs a weekend **and** a paid ticket. The brackets make the `||` happen first; without them `&&` binds tighter and the meaning changes.
5. Misconception: a variable assigned in one branch keeps that value after the chain, because `price` was declared before the chain, not inside a branch.

## Try it
**Guided.** A **grade checker** in `try03` (see [exercise folders](../../README.md#exercise-folders)). The program reads a score from 0 to 100.

**File: `main.c` (starter)**
```c
#include <stdio.h>

int main(void) {
    int score = 0;
    printf("Score (0 to 100):\n");
    if (scanf("%d", &score) != 1) {
        printf("Use a whole number.\n");
        return 1;
    }
    /* TODO: print "Invalid score" and stop when the score is below 0 or above 100. */
    /* TODO: print "Grade: A" for 90 or more, "Grade: B" for 80 to 89, "Grade: C" for 70 to 79, and "Grade: F" otherwise. */
    return 0;
}
```

Build and run in `try03`. With the input `85` the output should be:

```text
Score (0 to 100):
Grade: B
```

**Change.** Add a grade D for 60 to 69. **Stretch (optional):** use a `switch` on `score / 10` instead of the chain and decide how to treat 100.

<details><summary>Solution</summary>

Replace the two TODO comment lines; all other lines stay as in the starter.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int main(void) {
    int score = 0;
    printf("Score (0 to 100):\n");
    if (scanf("%d", &score) != 1) {
        printf("Use a whole number.\n");
        return 1;
    }
    if (score < 0 || score > 100) {
        printf("Invalid score\n");
        return 1;
    }
    if (score >= 90) {
        printf("Grade: A\n");
    } else if (score >= 80) {
        printf("Grade: B\n");
    } else if (score >= 70) {
        printf("Grade: C\n");
    } else {
        printf("Grade: F\n");
    }
    return 0;
}
```

</details>

## Check yourself
1. What is the difference between `=` and `==`?
   <details><summary>Answer</summary>`=` stores a value; `==` asks whether two values are equal.</details>
2. In the ticket program, what is the price for age 70 on day 7?
   <details><summary>Answer</summary>11: age 70 gives 9, plus the weekend surcharge of 2.</details>
3. What happens in a `switch` case that has no `break`?
   <details><summary>Answer</summary>The program continues into the next case's statements.</details>
4. Is `!(5 > 3)` true or false?
   <details><summary>Answer</summary>False, because `5 > 3` is true and `!` flips it.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `warning: suggest parentheses around assignment used as truth value [-Wparentheses]` (typical message) | Wrote `if (age = 5)` with one `=` | Use `==` to compare. |
| Two day names print in a row | A `case` is missing its `break` | End every case with `break;`. |
| The branch you expect never runs | The conditions are in the wrong order, for example `age < 65` before `age < 18` | Put the most specific condition first. |
| Code after `if (x > 5);` always runs | A stray `;` right after the bracket ends the `if` early | Remove the semicolon. |
| `Use a whole number of years, 0 or more.` | Typed letters such as `abc`, or a negative age | Type a whole number, 0 or more. |
| `Use a whole number for the day.` | Typed the age as `30.5`: `scanf` took 30 for the age and then met `.5` at the day question | Type whole numbers only. |

## Best practice
Always put braces around the body of an `if`, even for one statement; it prevents errors when you add a line later. Source: SEI CERT C Coding Standard, EXP19-C https://wiki.sei.cmu.edu/confluence/display/c/EXP19-C.+Use+braces+for+the+body+of+an+if%2C+for%2C+or+while+statement

## Going further
- The `switch` statement on cppreference: https://en.cppreference.com/w/c/language/switch

## Summary
- You wrote `if / else if / else` chains and chose the right order.
- You combined conditions with `&&`, `||` and `!`.
- You used `switch` with `break` and `default`.
- You predicted the output for given inputs.

## Next lesson
**[04. Loops](04-loops.md):** repeat steps with `for`, `while` and `do ... while`.
