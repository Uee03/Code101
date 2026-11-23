---
track: c
level: 101
phase: 3
phase_name: real-programs
lesson: 10
title: "Memory and common bugs"
time: 55 min
prerequisites: [101.2.06, 101.2.07]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-3-real-programs/10-memory-and-bugs/
assets: []
---

# 10. Memory and common bugs

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- allocate memory with `malloc`, check the result, resize it with `realloc` and release it with `free`;
- explain the difference between memory made by a declaration and memory made by `malloc`;
- recognise a memory leak, use after free, double free and an out-of-range write;
- use a compiler option that finds some of these bugs.

## Recap
1. What does `int *p = NULL;` mean? <details><summary>Answer</summary>`p` is a pointer that points nowhere.</details>
2. Why is writing past the end of an array dangerous? <details><summary>Answer</summary>It is undefined behaviour: it may crash, corrupt other data or seem to work.</details>

## Why it matters
Renting a storage unit: you ask the owner for a unit of the size you need, use it, and hand the key back. If you forget to hand the key back, the unit stays blocked; if you keep using the unit after handing the key back, you may be in someone else's space. C lets your program rent memory while it runs (**dynamic memory**) with `malloc` and return it with `free`. C never does either for you, which is why these are the source of the classic C bugs.

## What you will build
A program that asks how many squares to calculate, stores them in memory rented with `malloc`, grows that memory with `realloc`, makes a copy of a word, and frees everything. Then you will look at a deliberately broken program and the tool that catches it.

## Before you start
- Finish lessons 06 and 07 (arrays and pointers).
- Time: 55 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-3-real-programs/10-memory-and-bugs/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson10`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson10"`; macOS/Linux `cd "$HOME/code101/c/lesson10"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson10`. Open only `lesson10` in your editor and open a terminal there.

### Step 2. The four tools
These come from `<stdlib.h>`:

| Call | What it does |
|---|---|
| `malloc(bytes)` | Asks for that many bytes and returns a pointer to them, or `NULL` if there is no memory. The bytes hold leftover garbage until you fill them. |
| `realloc(ptr, bytes)` | Resizes a block, possibly moving it. Returns the new pointer or `NULL` (then the old block is still yours). |
| `free(ptr)` | Gives the block back. Afterwards the pointer is a **dangling pointer**: it still holds the old address, but the memory is no longer yours. |
| `sizeof` | The size in bytes of a type or value. `malloc(count * sizeof *squares)` means "room for `count` items of whatever `squares` points to". |

Variables declared in a function live on the **stack**, memory that C creates and removes automatically when the function ends. `malloc` memory lives on the **heap**, memory that stays yours until you call `free`. A string written in quotes, such as `"memory"`, is stored read-only; `const char *word` points at it and promises not to change it. To get a changeable copy you allocate `strlen(word) + 1` bytes (the `+ 1` is for the `'\0'` terminator) and `strcpy` into them.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    int count = 0;
    printf("How many squares (1 to 20)?\n");
    if (scanf("%d", &count) != 1 || count < 1 || count > 20) {
        printf("Use a whole number from 1 to 20.\n");
        return 1;
    }

    int *squares = malloc((size_t)count * sizeof *squares);
    if (squares == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    for (int i = 0; i < count; i++) {
        squares[i] = (i + 1) * (i + 1);
    }
    for (int i = 0; i < count; i++) {
        printf("%d squared is %d\n", i + 1, squares[i]);
    }

    int *bigger = realloc(squares, (size_t)(count + 2) * sizeof *bigger);
    if (bigger == NULL) {
        free(squares);
        printf("Out of memory.\n");
        return 1;
    }
    squares = bigger;
    squares[count] = (count + 1) * (count + 1);
    squares[count + 1] = (count + 2) * (count + 2);
    printf("After growing: last is %d\n", squares[count + 1]);
    free(squares);
    squares = NULL;

    const char *word = "memory";
    char *copy = malloc(strlen(word) + 1);
    if (copy == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    strcpy(copy, word);
    copy[0] = 'M';
    printf("Copy: %s, original: %s\n", copy, word);
    free(copy);
    return 0;
}
```

Save it. **Predict first:** with the input `3`, what is the "After growing" value? (Items 4 and 5 are added after the first three.)

### Step 4. A deliberately broken program
Create `bug.c` in the same folder. It frees memory and then reads it. Do not copy this style into real programs.

**File: `bug.c`**
```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *numbers = malloc(3 * sizeof *numbers);
    if (numbers == NULL) {
        return 1;
    }
    numbers[0] = 10;
    numbers[1] = 20;
    numbers[2] = 30;
    free(numbers);
    printf("First number: %d\n", numbers[0]);
    return 0;
}
```

## Run it
Build the main program (gcc/clang; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows). Type `3` and press Enter.

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

Expected output (not yet run; the `3` you typed also appears in the terminal):

```text
How many squares (1 to 20)?
1 squared is 1
2 squared is 4
3 squared is 9
After growing: last is 25
Copy: Memory, original: memory
```

Now the broken program. A recent gcc may already warn at build time that the pointer is used after `free` (typical message: `pointer 'numbers' used after 'free'`):

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o bug bug.c
```

Run it. The result is **undefined**: it may print `First number: 10`, garbage, or crash. That unpredictability is exactly what makes these bugs hard.

**Optional: let a tool find it (Linux, macOS, or gcc/clang builds that include the sanitizer).** AddressSanitizer inserts checks when you compile:

**File: terminal (not a saved file)**
```text
gcc -std=c17 -g -fsanitize=address -o bug bug.c
```

Then run `./bug`. Typically the program stops and prints a report beginning with `ERROR: AddressSanitizer: heap-use-after-free` and the line of `bug.c` that used the memory; the exact text and numbers vary. If the compiler says it cannot find the sanitizer library (common with the MSYS2 gcc on Windows), skip this step; Microsoft `cl` has its own `/fsanitize=address` option described in Microsoft's documentation.

## How it works
1. `malloc((size_t)count * sizeof *squares)` asks for `count` ints. `size_t` is the unsigned type used for sizes; the cast makes the multiplication happen in that type. We immediately compare with `NULL`: on a full machine `malloc` can fail, and using a `NULL` pointer would crash.
2. `squares[i]` works like an array because the pointer points at the first of the rented items.
3. `realloc` asks for room for two more items. We store its result in a **different** pointer first: if it fails it returns `NULL`, and writing `squares = realloc(squares, ...)` directly would lose the old block (a leak).
4. Every successful `malloc` needs exactly one `free`. We set `squares = NULL;` afterwards so a later accident would be a clean crash, not a silent use of a dangling pointer.
5. `strcpy(copy, word)` copies the text and the terminator. It is safe here only because we allocated `strlen(word) + 1` bytes ourselves.
6. The bugs to know:

| Bug | Example | Effect |
|---|---|---|
| **Memory leak** | Forgetting `free`, or overwriting the only pointer | Memory is lost until the program ends; long programs grow and slow down. |
| **Use after free** | Reading or writing a block after `free` (`bug.c`) | Undefined behaviour. |
| **Double free** | Calling `free` twice on the same pointer | Undefined behaviour, often a crash. (`free(NULL)` is safe and does nothing.) |
| **Out-of-range write** | `squares[count + 5] = 1;` on a block that holds `count` items | Corrupts other memory (a **buffer overflow**), a classic security hole. |
| **Uninitialised read** | Using `malloc` memory before filling it | Garbage values. |

Misconception: when a program ends, the operating system reclaims its memory, so leaks do not matter. For a short exercise that is true; for a program that runs for hours, or a function called many times, a leak is a real bug.

## Try it
**Guided.** In `try10` (see [exercise folders](../../README.md#exercise-folders)) finish a program that reads `n` numbers into memory from `malloc` and prints their sum.

**File: `main.c` (starter)**
```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n = 0;
    printf("How many numbers (1 to 10)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }
    /* TODO: allocate room for n ints, stop with a message if that fails, and free the memory before the program ends. */
    int sum = 0;
    /* TODO: read n numbers into that memory with scanf and add them to sum. */
    printf("Sum: %d\n", sum);
    return 0;
}
```

With the input `3`, `4`, `5`, `6` on separate lines the output should be:

```text
How many numbers (1 to 10)?
Sum: 15
```

**Change.** Make the program also print the largest number. **Stretch (optional):** allow up to 1000 numbers by changing the limit, and decide what the program should do if `malloc` fails.

<details><summary>Solution</summary>

Replace the two TODO comments; the rest is unchanged. Note that `free` is called on every path that leaves after the allocation.

**File: `main.c` (solution)**
```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n = 0;
    printf("How many numbers (1 to 10)?\n");
    if (scanf("%d", &n) != 1 || n < 1 || n > 10) {
        printf("Use a whole number from 1 to 10.\n");
        return 1;
    }
    int *numbers = malloc((size_t)n * sizeof *numbers);
    if (numbers == NULL) {
        printf("Out of memory.\n");
        return 1;
    }
    int sum = 0;
    for (int i = 0; i < n; i++) {
        if (scanf("%d", &numbers[i]) != 1) {
            printf("Use whole numbers.\n");
            free(numbers);
            return 1;
        }
        sum += numbers[i];
    }
    printf("Sum: %d\n", sum);
    free(numbers);
    return 0;
}
```

</details>

## Check yourself
1. What must you check right after `malloc`, and what must you do for every successful `malloc`?
   <details><summary>Answer</summary>Check the result is not `NULL`; call `free` exactly once.</details>
2. Why is `p = realloc(p, size)` risky?
   <details><summary>Answer</summary>If `realloc` fails it returns `NULL`, and `p` is overwritten, so the old block can no longer be freed (a leak).</details>
3. What is wrong with `char *copy = malloc(strlen(word)); strcpy(copy, word);`?
   <details><summary>Answer</summary>No room for the terminator `'\0'`: it writes one byte past the block. Allocate `strlen(word) + 1`.</details>
4. What is a dangling pointer?
   <details><summary>Answer</summary>A pointer that still holds the address of memory that has been freed.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `implicit declaration of function 'malloc'` (typical message) | Missing `#include <stdlib.h>` | Add the include. |
| A crash (typically `Segmentation fault` on Linux) right after `malloc` | Used the result without checking for `NULL`, or wrote past the end | Check for `NULL` and keep indexes below the allocated count. |
| `free(): double free detected` or `free(): invalid pointer` (typical glibc messages on Linux) | Freed twice, or freed something not from `malloc` | Free each block once; set the pointer to `NULL` afterwards. |
| The program works but slows down or grows when repeated | A leak: a `malloc` without `free` on some path | Check every `return` after an allocation. |
| Strange letters at the end of a copied string | The `'\0'` terminator was not copied or not allocated | Allocate `strlen(text) + 1`. |

## Best practice
Pair every allocation with one `free`, check every `malloc` result, and set freed pointers to `NULL`. Compile test builds with `-fsanitize=address` where available. Source: SEI CERT C Coding Standard, MEM00-C https://wiki.sei.cmu.edu/confluence/display/c/MEM00-C.+Allocate+and+free+memory+in+the+same+module+at+the+same+level+of+abstraction

## Going further
- AddressSanitizer in the GCC manual: https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
- Memory management functions: https://en.cppreference.com/w/c/memory

## Summary
- You allocated, resized and freed memory and checked each result.
- You explained the stack and the heap in plain words.
- You named five classic memory bugs and saw one on purpose.

## Next lesson
**[11. Files](11-files.md):** save data to a file and read it back.
