---
track: c
level: 101
phase: 2
phase_name: building-blocks
lesson: 06
title: "Arrays and strings"
time: 45 min
prerequisites: [101.1.04, 101.2.05]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-2-building-blocks/06-arrays-and-strings/
assets: []
---

# 06. Arrays and strings

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- declare an array and visit every item with a `for` loop;
- explain why the first item is index 0 and why an index past the end is dangerous;
- store text in a `char` array and explain the ending `'\0'`;
- read a line safely with `fgets` and compare text with `strcmp`.

## Recap
1. What does `i < count` do in `for (int i = 0; i < count; i++)`? <details><summary>Answer</summary>It stops the loop when `i` reaches `count`, so the loop runs `count` times.</details>
2. Why does a function receive a copy of its arguments? <details><summary>Answer</summary>C passes by value, so the function works on copies.</details>

## Why it matters
A week of temperatures is not seven unrelated numbers; it is a row of seven numbered boxes. An **array** is a row of boxes of the same type under one name. Text is a row of character boxes, so the same idea gives us **strings**.

## What you will build
A program that stores five temperatures, prints their average and highest, then asks for your name, reads it safely, greets you, compares it with "Ada" and counts the letter `a`.

## Before you start
- Finish lessons 04 and 05 (loops and functions).
- Time: 45 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/06-arrays-and-strings/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson06`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson06"`; macOS/Linux `cd "$HOME/code101/c/lesson06"`.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson06`. Open only `lesson06` in your editor and open a terminal there.

### Step 2. Ideas before the code
- `int temps[5] = {18, 21, 19, 25, 22};` creates five `int` boxes. The boxes are numbered from **0**: `temps[0]` is 18 and `temps[4]` is 22. The number in brackets is the **index**.
- **Danger:** `temps[5]` does not exist. C does not stop you: reading or writing outside the array is **undefined behaviour**, meaning the language promises nothing (it may crash, print garbage or appear to work). Always keep the index below the array's size.
- `#define DAYS 5` gives the number 5 a name before compiling; every `DAYS` is replaced by 5. We use it because in C a `const int` variable is not a true constant: using it as an array size would create a variable-length array, which cannot be filled with a `{...}` list.
- A **string** is a `char` array whose last item is the **terminator** `'\0'` (the character with code 0). `"Ada"` occupies 4 boxes: `A`, `d`, `a`, `\0`. `strlen` counts characters before the terminator. `strcmp(a, b)` returns 0 when two strings are equal, which is why we write `strcmp(...) == 0`; never compare strings with `==`.
- `fgets(buffer, size, stdin)` reads a whole line (including spaces) but never more than `size - 1` characters, so it cannot overflow the array. It keeps the final newline, which we remove with `buffer[strcspn(buffer, "\r\n")] = '\0';`: `strcspn` finds the position of the first newline character and we overwrite it with the terminator.
- `(double)DAYS` is a **cast**: it converts a value to another type on purpose. `%zu` prints the type `size_t` that `strlen` returns.

### Step 3. Write the program
Create `main.c` and paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>
#include <string.h>

#define DAYS 5

int main(void) {
    int temps[DAYS] = {18, 21, 19, 25, 22};
    int sum = 0;
    int highest = temps[0];
    for (int i = 0; i < DAYS; i++) {
        sum += temps[i];
        if (temps[i] > highest) {
            highest = temps[i];
        }
    }
    printf("Average: %.1f\n", sum / (double)DAYS);
    printf("Highest: %d\n", highest);

    char name[32];
    printf("Your name:\n");
    if (fgets(name, sizeof name, stdin) == NULL) {
        printf("No name read.\n");
        return 1;
    }
    name[strcspn(name, "\r\n")] = '\0';
    printf("Hello, %s! Your name has %zu letters.\n", name, strlen(name));

    if (strcmp(name, "Ada") == 0) {
        printf("Welcome back, Ada.\n");
    }

    int count_a = 0;
    for (int i = 0; name[i] != '\0'; i++) {
        if (name[i] == 'a' || name[i] == 'A') {
            count_a++;
        }
    }
    printf("The letter a appears %d time(s).\n", count_a);
    return 0;
}
```

Save it. **Predict first:** what are the average and the highest temperature?

## Run it
Build (`gcc -std=c17 -Wall -Wextra -o app main.c`; Microsoft `cl`: see the README table) and run `./app` (macOS/Linux) or `.\app` (Windows). Type `Ada` and press Enter when asked for your name.

Expected output (not yet run; your typed name also appears in the terminal):

```text
Average: 21.0
Highest: 25
Your name:
Hello, Ada! Your name has 3 letters.
Welcome back, Ada.
The letter a appears 2 time(s).
```

## How it works
1. The first loop visits indexes 0 to 4, adds each temperature to `sum` and remembers the biggest in `highest`. 105 divided by 5.0 is 21.0.
2. `sizeof name` is the size of the whole array in bytes (32 here), so `fgets` is told the true limit. Typing 100 letters cannot overflow `name`: `fgets` stops after 31 and the rest stays unread.
3. `name[strcspn(name, "\r\n")] = '\0';` cuts the text at the line ending so `Ada\n` becomes `Ada`; without it the `strcmp` with `"Ada"` would be false.
4. `name[i] != '\0'` walks the string until the terminator. Single quotes mean one character (`'a'`); double quotes mean a string (`"a"`). Misconception: `"a"` and `'a'` are not the same thing.
5. Arrays do not know their own length once passed to a function, so you always pass the count too. Lesson 07 explains why.

## Try it
**Guided.** Analyse six scores in `try06` (see [exercise folders](../../README.md#exercise-folders)): find the lowest and count how many are 50 or more.

**File: `main.c` (starter)**
```c
#include <stdio.h>

#define COUNT 6

int main(void) {
    int scores[COUNT] = {72, 45, 90, 38, 66, 51};
    int lowest = scores[0];
    int passed = 0;
    /* TODO: loop over the array to find the lowest score and to count the scores that are 50 or more. */
    printf("Lowest: %d\n", lowest);
    printf("Passed: %d\n", passed);
    return 0;
}
```

Expected output after you finish:

```text
Lowest: 38
Passed: 4
```

**Change.** Also print the highest score. **Stretch (optional):** ask the user for a name and print it backwards; decide how to find its length.

<details><summary>Solution</summary>

Replace the TODO comment line with this loop; the rest is unchanged.

**File: `main.c` (solution)**
```c
#include <stdio.h>

#define COUNT 6

int main(void) {
    int scores[COUNT] = {72, 45, 90, 38, 66, 51};
    int lowest = scores[0];
    int passed = 0;
    for (int i = 0; i < COUNT; i++) {
        if (scores[i] < lowest) {
            lowest = scores[i];
        }
        if (scores[i] >= 50) {
            passed++;
        }
    }
    printf("Lowest: %d\n", lowest);
    printf("Passed: %d\n", passed);
    return 0;
}
```

</details>

## Check yourself
1. What is the index of the last item in `int a[10];`?
   <details><summary>Answer</summary>9.</details>
2. How many boxes does `char word[] = "hi";` use?
   <details><summary>Answer</summary>3: `h`, `i` and the terminator `'\0'`.</details>
3. Why do we write `strcmp(a, b) == 0` and not `a == b`?
   <details><summary>Answer</summary>`==` would compare where the arrays live, not their letters; `strcmp` compares the letters and returns 0 when they match.</details>
4. What goes wrong with `temps[5]` for an array of size 5?
   <details><summary>Answer</summary>It is outside the array; the behaviour is undefined and may crash or give garbage.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| The "Welcome back" line never appears although you typed `Ada` | The newline was not removed, so the text is `Ada\n` | Keep the `strcspn` line. |
| Garbage values or a crash | An index outside `0` to `size - 1` | Make the loop condition `i < size`. |
| `warning: comparison between pointer and integer` (typical message) | Compared a string with `'a'` (single quotes) or a character with `"a"` (double quotes) | Single quotes for one character, double quotes for text. |
| Typing a name with spaces shows only the first word | You used `scanf("%s")`, which stops at a space | Use `fgets`, as in the lesson. |
| `warning: format '%d' expects argument of type 'int', but argument 3 has type 'size_t'` (typical message) | Used `%d` for `strlen` | Use `%zu`. |

## Best practice
Always give a buffer size to the function that fills it (`fgets` with `sizeof name`). Never use `gets`, which was removed from the language because it cannot be made safe. Source: cppreference, gets (removed in C11) https://en.cppreference.com/w/c/io/gets

## Going further
- String functions: https://en.cppreference.com/w/c/string/byte

## Summary
- You created an array and looped over it with indexes from 0.
- You explained why an out-of-range index is dangerous.
- You stored text as a `char` array ending in `'\0'`.
- You read a line safely and compared strings with `strcmp`.

## Next lesson
**[07. Pointers](07-pointers.md):** learn what an address is and let functions change the caller's variables.
