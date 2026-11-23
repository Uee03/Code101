---
track: c
level: 101
phase: 2
phase_name: building-blocks
lesson: 05
title: "Functions"
time: 40 min
prerequisites: [101.1.02, 101.1.04]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-2-building-blocks/05-functions/
assets: []
---

# 05. Functions

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a function with parameters and a return value;
- declare a function before `main` with a prototype;
- explain why changing a parameter does not change the caller's variable;
- split a program into small named steps.

## Recap
1. What does `i++` do in a `for` loop? <details><summary>Answer</summary>It adds 1 to `i` after each round.</details>
2. Which `printf` code prints a `double` with two decimals? <details><summary>Answer</summary>`%.2f`.</details>

## Why it matters
A recipe book does not repeat "how to whisk" in every recipe; it says "whisk" and you know the steps. A **function** is a named group of steps that you can use ("call") whenever you like, with different ingredients each time.

## What you will build
A bill helper with functions `add_tip`, `split` and `square`, plus a function that tries (and fails) to change its caller's variable.

## Before you start
- Finish lessons 02 and 04. Lesson 01 gave you `main`, which is itself a function.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/05-functions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson05`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson05"`; macOS/Linux `cd "$HOME/code101/c/lesson05"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson05`. Open only `lesson05` in your editor and open a terminal there.

### Step 2. The parts of a function
Read this example:

```c
int square(int x) {
    return x * x;
}
```

- `int` before the name is the **return type**: the kind of value handed back. `void` means "nothing is handed back".
- `square` is the name; `(int x)` is the **parameter list**: the inputs, each with a type and a name.
- `return x * x;` hands a value back to the **caller**, the code that called the function, and ends the function.

C reads a file from top to bottom, so a function must be known before it is used. A **prototype** is the first line of a function followed by `;`. It tells the compiler "this function exists" and lets `main` stay at the top.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

double add_tip(double bill, double percent);
double split(double total, int people);
int square(int x);
void try_to_change(int n);

int main(void) {
    double total = add_tip(80.0, 15.0);
    printf("Total with tip: %.2f\n", total);
    printf("Each of 2: %.2f\n", split(total, 2));

    int n = 5;
    try_to_change(n);
    printf("n is still %d\n", n);

    printf("Square of 7 is %d\n", square(7));
    return 0;
}

double add_tip(double bill, double percent) {
    return bill + bill * percent / 100;
}

double split(double total, int people) {
    return total / people;
}

int square(int x) {
    return x * x;
}

void try_to_change(int n) {
    n = 99;
    printf("Inside the function n is %d\n", n);
}
```

Save it. **Predict first:** `try_to_change` sets `n` to 99. After it returns, what will `main` print for `n`?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows).

Expected output (not yet run):

```text
Total with tip: 92.00
Each of 2: 46.00
Inside the function n is 99
n is still 5
Square of 7 is 49
```

## How it works
1. The four prototypes at the top tell the compiler the name, parameter types and return type of each function before `main` uses them.
2. `add_tip(80.0, 15.0)` runs the function with `bill` = 80.0 and `percent` = 15.0 and hands back 92.0, which is stored in `total`.
3. `split(total, 2)` is used directly as an argument of `printf`: a call produces a value, so it can sit anywhere a value can. The values in a call are **arguments**; the names in the definition are **parameters**.
4. **Pass by value:** when a function is called, C gives it a **copy** of each argument. `try_to_change` changes its own copy of `n` (the 99), while `main`'s `n` is untouched. Misconception: a function cannot change the caller's variable through a normal parameter. Lesson 07 shows how pointers make that possible when you want it.
5. The variables `bill`, `total` and `n` inside a function are **local**: they exist only while it runs and are invisible to other functions. Two functions may reuse the same name without interfering.
6. A function with `void` has no `return value;` (a plain `return;` is allowed).

## Try it
**Guided.** Complete two small functions in `try05` (see [exercise folders](../../README.md#exercise-folders)). Your compiler may warn `unused parameter` for the starter; the warnings disappear when you use the parameters.

**File: `main.c` (starter)**
```c
#include <stdio.h>

int is_even(int n);
double average(int a, int b, int c);

int main(void) {
    printf("4 even? %d\n", is_even(4));
    printf("7 even? %d\n", is_even(7));
    printf("Average of 4, 7, 10: %.2f\n", average(4, 7, 10));
    return 0;
}

int is_even(int n) {
    /* TODO: return 1 when n is even, otherwise return 0. */
    return 0;
}

double average(int a, int b, int c) {
    /* TODO: return the average of the three numbers, keeping the decimals. */
    return 0.0;
}
```

Expected output after you finish:

```text
4 even? 1
7 even? 0
Average of 4, 7, 10: 7.00
```

**Change.** Add a function `max_of(int a, int b)` and print `max_of(3, 9)`. **Stretch (optional):** make `average` correct for `average(1, 2, 2)`; the answer should be about 1.67, so think about integer division.

<details><summary>Solution</summary>

Replace the two function bodies; the rest of the file is unchanged.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int is_even(int n);
double average(int a, int b, int c);

int main(void) {
    printf("4 even? %d\n", is_even(4));
    printf("7 even? %d\n", is_even(7));
    printf("Average of 4, 7, 10: %.2f\n", average(4, 7, 10));
    return 0;
}

int is_even(int n) {
    return n % 2 == 0;
}

double average(int a, int b, int c) {
    return (a + b + c) / 3.0;
}
```

`n % 2 == 0` is 1 (true) or 0 (false). Dividing by `3.0` rather than `3` keeps the decimals.

</details>

## Check yourself
1. What is the difference between a parameter and an argument?
   <details><summary>Answer</summary>A parameter is the name in the function definition; an argument is the value given in a call.</details>
2. Why does `main` still print 5 after `try_to_change(n)`?
   <details><summary>Answer</summary>The function got a copy of `n`; only the copy changed.</details>
3. What is a prototype for?
   <details><summary>Answer</summary>It tells the compiler about a function before its definition so it can be called earlier in the file.</details>
4. What does `return` do?
   <details><summary>Answer</summary>It hands a value back to the caller and ends the function.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `warning: implicit declaration of function 'square'` or an error with similar words (typical message) | The function is called before its prototype or definition | Add the prototype above `main`. |
| `error: conflicting types for 'split'` (typical message) | The prototype and the definition differ in a type or name order | Make the first lines identical. |
| `warning: unused parameter 'n'` (typical message) | The starter's TODO has not used the parameter yet | Use the parameter in your answer. |
| A wrong decimal answer such as 1.00 instead of 1.67 for `average(1, 2, 2)` | Integer division: `(a + b + c) / 3` drops the fraction | Divide by `3.0`. |
| `warning: control reaches end of non-void function` (typical message) | A function with a return type has a path without `return` | Return a value on every path. |

## Best practice
Give each function one job and a name that says it (`add_tip`, not `f1`). Source: GCC manual, Warning Options (`-Wall` reports missing returns) https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html

## Going further
- Function declarations on cppreference: https://en.cppreference.com/w/c/language/function_declaration

## Summary
- You wrote functions with parameters and return values.
- You used prototypes so `main` can come first.
- You explained pass by value and local variables.

## Next lesson
**[06. Arrays and strings](06-arrays-and-strings.md):** keep many values under one name, and work with text.
