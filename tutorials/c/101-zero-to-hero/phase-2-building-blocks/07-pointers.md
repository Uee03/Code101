---
track: c
level: 101
phase: 2
phase_name: building-blocks
lesson: 07
title: "Pointers"
time: 50 min
prerequisites: [101.2.05, 101.2.06]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-2-building-blocks/07-pointers/
assets: []
---

# 07. Pointers

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- take the address of a variable with `&` and read or write through a pointer with `*`;
- write a function that changes the caller's variables;
- explain how an array name and a pointer are related;
- check a pointer for `NULL` before using it.

## Recap
1. Why does `try_to_change(n)` in lesson 05 not change `n`? <details><summary>Answer</summary>The function receives a copy of the value.</details>
2. What does `scanf("%d", &x)` need the `&` for? <details><summary>Answer</summary>It gives `scanf` the address where `x` lives.</details>

## Why it matters
Every house has an address on a card. If you hand a friend a photocopy of your house, they cannot repaint yours; if you hand them the **address**, they can walk there and repaint it. A **pointer** is a variable that holds an address. Pointers let functions change the caller's variables and are the basis of strings, arrays, memory allocation and files in C.

## What you will build
A program that reads and writes a variable through a pointer, swaps two numbers in a function, adds a bonus to a score, sums an array and shows a `NULL` pointer.

## Before you start
- Finish lessons 05 and 06 (functions and arrays).
- Time: 50 minutes. This is the idea that feels hardest; take it slowly and run the program twice.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/07-pointers/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson07`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson07"`; macOS/Linux `cd "$HOME/code101/c/lesson07"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson07`. Open only `lesson07` in your editor and open a terminal there.

### Step 2. The three symbols
Every variable lives at an **address** in memory. There are three things to learn:

| Written | Read it as | Example |
|---|---|---|
| `int *p` | "`p` is a pointer to an int" (in a declaration) | `int *p = &score;` |
| `&score` | "the address of `score`" | gives where `score` lives |
| `*p` | "the thing `p` points to" (in an expression) | `*p = 20;` changes `score` |

The star appears in two roles: in a **declaration** it says "this is a pointer"; in an **expression** it means "go to the address and use what is there" (this is called **dereferencing**). `NULL` is a special pointer value meaning "points nowhere"; dereferencing it crashes the program, so check first.

A function receives a copy of its arguments (lesson 05). If the argument is an address, the copy still points to the original, so the function can change the original. This is how `scanf` fills your variables.

An array name used in an expression turns into the address of its first item. That is why `total(values, 4)` can take `const int *values`: `const` promises the function will only read, not change, the numbers. `*(start + 1)` is the item after the first, the same as `start[1]`.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

void swap(int *a, int *b);
void add_bonus(int *points, int bonus);
int total(const int *values, int count);

int main(void) {
    int score = 10;
    int *p = &score;
    printf("score is %d\n", score);
    printf("through the pointer: %d\n", *p);
    if (p == &score) {
        printf("p holds the address of score\n");
    }
    *p = 20;
    printf("score after *p = 20: %d\n", score);

    int x = 3;
    int y = 8;
    swap(&x, &y);
    printf("x=%d y=%d\n", x, y);

    add_bonus(&score, 5);
    printf("score with bonus: %d\n", score);

    int values[4] = {1, 2, 3, 4};
    printf("total: %d\n", total(values, 4));
    int *start = values;
    printf("second value: %d\n", *(start + 1));

    int *nothing = NULL;
    if (nothing == NULL) {
        printf("nothing points nowhere\n");
    }
    return 0;
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

void add_bonus(int *points, int bonus) {
    *points = *points + bonus;
}

int total(const int *values, int count) {
    int sum = 0;
    for (int i = 0; i < count; i++) {
        sum += values[i];
    }
    return sum;
}
```

Save it. **Predict first:** what do `x` and `y` print after `swap(&x, &y)`?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows).

Expected output (not yet run):

```text
score is 10
through the pointer: 10
p holds the address of score
score after *p = 20: 20
x=8 y=3
score with bonus: 25
total: 10
second value: 2
nothing points nowhere
```

To see a real address, add `printf("address: %p\n", (void *)&score);` after the first `printf` and run again. The value differs on every computer and often on every run, so no exact output is promised.

## How it works
1. `int *p = &score;` stores the address of `score` in `p`. `*p` reads the 10 stored there; `*p = 20;` writes 20 into `score` itself.
2. `swap(&x, &y)` passes two addresses. Inside, `*a` and `*b` are `x` and `y`. `temp` holds one value so that neither is lost, like swapping two drinks using a third glass.
3. `add_bonus(&score, 5)` reads `*points`, adds 5 and stores it back, which changes `score` in `main`.
4. `values[i]` inside `total` works on a pointer because `values[i]` is defined as `*(values + i)`. The function cannot know the array's length, so the caller passes `4` too.
5. `int *nothing = NULL;` is safe; `*nothing` would not be. Misconception: a pointer is not the data itself, only its address, and a pointer that was never set holds garbage. Set pointers to an address or `NULL` straight away.

## Try it
**Guided.** Two functions in `try07` (see [exercise folders](../../README.md#exercise-folders)): `double_it` doubles the number its pointer points to, and `min_max` stores the smallest and largest of an array through two output pointers. The compiler may warn about unused parameters until you use them.

**File: `main.c` (starter)**
```c
#include <stdio.h>

void double_it(int *n);
void min_max(const int *values, int count, int *min, int *max);

int main(void) {
    int n = 21;
    double_it(&n);
    printf("n is %d\n", n);

    int values[5] = {7, 3, 9, 1, 5};
    int low = 0;
    int high = 0;
    min_max(values, 5, &low, &high);
    printf("low %d high %d\n", low, high);
    return 0;
}

void double_it(int *n) {
    /* TODO: make the number that n points to twice as big. */
}

void min_max(const int *values, int count, int *min, int *max) {
    /* TODO: store the smallest value in *min and the largest value in *max. */
}
```

Expected output after you finish:

```text
n is 42
low 1 high 9
```

**Change.** Add a function `triple_it` for tripling. **Stretch (optional):** write `reset(int *a, int *b)` that sets both numbers to 0, and decide what it should do when a pointer is `NULL`.

<details><summary>Solution</summary>

Replace the two function bodies; the rest is unchanged.

**File: `main.c` (solution)**
```c
#include <stdio.h>

void double_it(int *n);
void min_max(const int *values, int count, int *min, int *max);

int main(void) {
    int n = 21;
    double_it(&n);
    printf("n is %d\n", n);

    int values[5] = {7, 3, 9, 1, 5};
    int low = 0;
    int high = 0;
    min_max(values, 5, &low, &high);
    printf("low %d high %d\n", low, high);
    return 0;
}

void double_it(int *n) {
    *n = *n * 2;
}

void min_max(const int *values, int count, int *min, int *max) {
    *min = values[0];
    *max = values[0];
    for (int i = 1; i < count; i++) {
        if (values[i] < *min) {
            *min = values[i];
        }
        if (values[i] > *max) {
            *max = values[i];
        }
    }
}
```

</details>

## Check yourself
1. What do `&x` and `*p` mean?
   <details><summary>Answer</summary>`&x` is the address of `x`; `*p` is the value stored at the address in `p`.</details>
2. Why can `swap(&x, &y)` change `x` and `y`, while `try_to_change(n)` could not change `n`?
   <details><summary>Answer</summary>`swap` receives copies of the addresses, which still point at the originals.</details>
3. What is wrong with `int *p; *p = 5;`?
   <details><summary>Answer</summary>`p` was never set, so it points at an unknown place; writing there is undefined behaviour.</details>
4. What does `const int *values` promise?
   <details><summary>Answer</summary>The function will not change the numbers it reads through `values`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| The program crashes (for Linux typically `Segmentation fault`) | Dereferenced `NULL` or an unset pointer | Set the pointer first and check for `NULL`. |
| `swap` or `add_bonus` seems to do nothing | Called `swap(x, y)` with values instead of `swap(&x, &y)` | Pass the addresses. |
| `warning: passing argument 1 of 'swap' makes pointer from integer without a cast` (typical message) | Passed a value where a pointer is expected | Add the `&`. |
| `error: assignment of read-only location` (typical message) | Tried to change a value through a `const` pointer | Remove `const` from that parameter or do not write through it. |
| `warning: unused parameter 'n'` (typical message) | The starter's function body has not used it yet | Use the parameter. |

## Best practice
Initialise every pointer (to an address or `NULL`) and test a pointer that might be `NULL` before dereferencing it. Source: SEI CERT C Coding Standard, EXP34-C https://wiki.sei.cmu.edu/confluence/display/c/EXP34-C.+Do+not+dereference+null+pointers

## Going further
- Pointer declarations: https://en.cppreference.com/w/c/language/pointer

## Summary
- You used `&` to get an address and `*` to follow it.
- You wrote functions that change the caller's variables.
- You related arrays to pointers and passed the length separately.
- You checked a pointer for `NULL`.

## Next lesson
**[08. Structs](08-structs.md):** group related values into one record.
