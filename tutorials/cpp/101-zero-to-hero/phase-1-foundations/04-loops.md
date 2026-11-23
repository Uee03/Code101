---
track: cpp
level: 101
phase: 1
phase_name: foundations
lesson: 04
title: "Loops"
time: 45 min
prerequisites: [101.1.03]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-1-foundations/04-loops/
assets: []
---

# 04. Loops

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- repeat a block of code with `for` and `while`;
- visit every character of a string with a range-based `for`;
- leave a loop early with `break` and skip one round with `continue`;
- predict how many times a loop runs and what it prints.

## Recap
1. What is the difference between `=` and `==`?
   <details><summary>Answer</summary><code>=</code> stores a value; <code>==</code> compares two values.</details>
2. How do you test that <code>std::cin &gt;&gt; age</code> failed?
   <details><summary>Answer</summary><code>if (!(std::cin &gt;&gt; age))</code>.</details>
3. In an <code>if / else if / else</code> chain, which block runs when several tests are true?
   <details><summary>Answer</summary>The first one whose test is true.</details>

## Why it matters
A baker kneads the dough 20 times; nobody writes "knead" twenty times in a recipe, the recipe says "repeat 20 times". A **loop** repeats instructions for you. Without loops, adding up a thousand numbers would need a thousand lines.

## What you will build
One program with four small loops: a times table, a countdown, a letter filter, and a running total of numbers you type.

## Before you start
- Recommended: lesson 03 (input and `if`). Compiler and CMake from lesson 01.
- Time: 45 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-1-foundations/04-loops/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson04`, full path `$HOME/code101/cpp/lesson04`. Open only `lesson04` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson04"`; macOS/Linux `cd "$HOME/code101/cpp/lesson04"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `loops`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(loops LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(loops main.cpp)
target_compile_features(loops PRIVATE cxx_std_20)
set_target_properties(loops PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(loops PRIVATE /W4 /permissive-)
else()
  target_compile_options(loops PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <iostream>
#include <string>

int main() {
    std::cout << "Times table for 3\n";
    for (int i{1}; i <= 5; ++i) {
        std::cout << "3 x " << i << " = " << 3 * i << '\n';
    }

    std::cout << "Countdown\n";
    int count{3};
    while (count > 0) {
        std::cout << count << '\n';
        --count;
    }
    std::cout << "Liftoff!\n";

    std::cout << "Letters in 'cake' that are not 'a':\n";
    const std::string word{"cake"};
    for (const char letter : word) {
        if (letter == 'a') {
            continue;
        }
        std::cout << letter << '\n';
    }

    std::cout << "Enter whole numbers to add up. Enter 0 to stop.\n";
    int total{0};
    while (true) {
        int number{};
        if (!(std::cin >> number)) {
            std::cout << "Not a number, stopping.\n";
            break;
        }
        if (number == 0) {
            break;
        }
        total += number;
    }
    std::cout << "Total: " << total << '\n';
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** how many lines does the times table print? Which letters of `cake` are printed? What is the total if you type `4`, `5`, `0`?

## Run it
In `lesson04`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\loops.exe`; macOS/Linux `./build/out/loops`. When it prints `Enter whole numbers to add up. Enter 0 to stop.`, type `4`, Enter, `5`, Enter, `0`, Enter. The last part of your screen looks like this:

**File: terminal (screen with your typing, not a saved file)**
```text
Enter whole numbers to add up. Enter 0 to stop.
4
5
0
Total: 9
```
The text the program wrote (without your typing) is:

**File: terminal output (program output only, not a saved file)**
```text
Times table for 3
3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
3 x 4 = 12
3 x 5 = 15
Countdown
3
2
1
Liftoff!
Letters in 'cake' that are not 'a':
c
k
e
Enter whole numbers to add up. Enter 0 to stop.
Total: 9
```

## How it works
1. **`for` has three parts** in its parentheses: a start (`int i{1}`), a test (`i <= 5`) and a step (`++i`, which adds 1). The computer starts, tests, runs the block, steps, tests again, and stops when the test is false. One pass through the block is an **iteration**. Here `i` is 1, 2, 3, 4, 5: five iterations. `i` exists only inside the loop.
2. **`while`** tests first, then runs the block, then tests again. `--count` subtracts 1. If the test is false at the start, the block never runs. If nothing ever makes the test false, the loop never ends (an **infinite loop**); press **Ctrl+C** in the terminal to stop a program.
3. **Range-based `for`.** `for (const char letter : word)` means "for each character in `word`, call it `letter`". It is the simplest way to visit every item of a string, and later of a vector. You cannot run past the end by mistake.
4. **`continue`** skips the rest of the current iteration and goes to the next one: the letter `a` is skipped, so `c`, `k` and `e` print.
5. **`break`** leaves the loop immediately. `while (true)` would never stop by itself, so the program uses `break` when the user types `0` or something that is not a number.
6. `total += number;` is short for `total = total + number;`: add `number` to what is already there. The variable `total` lives outside the loop so it keeps its value between iterations; `number` is declared inside, so each iteration starts with a new one.
7. Misconception: loops count from 1. They count from whatever you write. C++ programmers usually start counting at 0 and use `i < 5`; this lesson starts at 1 so the times table looks natural. Mixing up `<` and `<=` is the classic **off-by-one** mistake: one iteration too few or too many.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try04` next to `lesson04` (see [Exercise folders](../../README.md#exercise-folders)), or create `try04` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(loops LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(loops main.cpp)
target_compile_features(loops PRIVATE cxx_std_20)
set_target_properties(loops PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(loops PRIVATE /W4 /permissive-)
else()
  target_compile_options(loops PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>

int main() {
    // TODO: use a for loop to print 10, 8, 6, 4 and 2, each number on its own line.
    std::cout << "Go!\n";
    return 0;
}
```
Replace the TODO with a loop, rebuild and run. Expected output:

**File: terminal output (not a saved file)**
```text
10
8
6
4
2
Go!
```

**Rung 2, change.** Make the countdown start at 20 and still end at 2.

**Rung 3, stretch (optional).** Print the numbers 1 to 20 but skip every number that is a multiple of 3 (hint: `%` gives the remainder of a division; look it up on cppreference).

<details><summary>Solution</summary>

Replace the TODO comment line with this loop. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <iostream>

int main() {
    for (int i{10}; i > 0; i -= 2) {
        std::cout << i << '\n';
    }
    std::cout << "Go!\n";
    return 0;
}
```

</details>

## Check yourself
1. How many times does `for (int i{0}; i < 4; ++i)` run its block?
   <details><summary>Answer</summary>Four times (i is 0, 1, 2, 3).</details>
2. Predict the output: `int n{2}; while (n < 5) { std::cout << n; ++n; }`
   <details><summary>Answer</summary><code>234</code> (no spaces or new lines were printed).</details>
3. What is the difference between `break` and `continue`?
   <details><summary>Answer</summary><code>break</code> leaves the whole loop; <code>continue</code> skips only the rest of the current iteration.</details>
4. What do you do when a program seems stuck in an endless loop?
   <details><summary>Answer</summary>Press Ctrl+C in the terminal, then find why the loop condition never becomes false.</details>

## Phase review (lessons 01 to 04)
1. Name the two commands that turn `main.cpp` and `CMakeLists.txt` into a program. <details><summary>Answer</summary><code>cmake -S . -B build</code> (configure) and <code>cmake --build build</code> (build).</details>
2. Predict: `int n{7}; if (n > 5 && n < 7) { std::cout << "A"; } else { std::cout << "B"; }` <details><summary>Answer</summary><code>B</code>: both tests must be true and <code>n &lt; 7</code> is false.</details>
3. Which loop would you choose to read numbers until the user types 0, and why? <details><summary>Answer</summary><code>while (true)</code> with a <code>break</code>, because you cannot know in advance how many numbers come.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| The program prints the same line forever | The loop's variable is never changed (for example `--count;` was left out) | Press Ctrl+C; add the step that changes the variable |
| The times table shows only 1 to 4, or 1 to 6 | `<` versus `<=` (off-by-one) | Decide the last value you want and test with `<=` for it |
| GCC: `error: expected ';' before ')' token` in a `for` line | Commas used instead of semicolons: `for (int i{1}, i <= 5, ++i)` | Separate the three parts with `;` |
| Nothing prints for the loop | A stray `;` right after `for (...)` or `while (...)` makes the loop body empty | Remove the semicolon |
| The sum stops at once | You typed a word or `0` first | Type whole numbers; `0` ends the input on purpose |

## Best practice
Prefer a range-based `for` when you visit every item, and declare the loop variable inside the `for` so it cannot leak into other code. Source: C++ Core Guidelines, ES.71 "Prefer a range-for-statement to a for-statement when there is a choice" and ES.74 "Prefer to declare a loop variable in the initializer part of a for-statement" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Loops reference: https://en.cppreference.com/w/cpp/language/for. Lesson 06 uses a range-based `for` over a `std::vector`.

## Summary
- You wrote a `for` loop, a `while` loop and a range-based `for`.
- You used `continue` to skip a letter and `break` to leave a loop.
- You kept a running total in a variable declared outside the loop.
- You predicted iteration counts and corrected an off-by-one error.

## Next lesson
**[05. Functions and references](../phase-2-building-blocks/05-functions-and-references.md):** give a block of code a name so you can reuse it.
