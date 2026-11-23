---
track: cpp
level: 101
phase: 1
phase_name: foundations
lesson: 02
title: "Types and output"
time: 40 min
prerequisites: [101.1.01]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-1-foundations/02-types-and-output/
assets: []
---

# 02. Types and output

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- declare variables of type `int`, `double`, `bool`, `char` and `std::string` with a starting value;
- mark a value that never changes with `const`;
- print several values and format a decimal number to two places;
- predict what `std::cout` prints for a `bool` and for a `double`.

## Recap
1. What is the file called that tells CMake how to build your program?
   <details><summary>Answer</summary><code>CMakeLists.txt</code>.</details>
2. After you change <code>main.cpp</code>, which command rebuilds the program?
   <details><summary>Answer</summary><code>cmake --build build</code>.</details>
3. What does <code>\n</code> inside a string do?
   <details><summary>Answer</summary>It ends the line (starts a new one).</details>

## Why it matters
In a kitchen you keep flour, sugar and salt in labelled jars. The label tells you what the jar is called, and the kind of jar tells you what may go in it. A C++ **variable** is a labelled jar in the computer's memory: it has a **name**, a **type** (what kind of value) and a **value**. Programs are mostly about keeping and changing such values.

## What you will build
A stock card for a bakery that stores a name, a count, a price, a yes/no flag and a grade, then prints them and the total value.

## Before you start
- Finish lesson 01 (a working compiler and CMake). Recommended, not required.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-1-foundations/02-types-and-output/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson02`, full path `$HOME/code101/cpp/lesson02`. Open only `lesson02` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson02"`; macOS/Linux `cd "$HOME/code101/cpp/lesson02"`. (MSYS2 users: use the folder path from lesson 01 with `lesson02`.)

### Step 2. Write the build recipe
Create `CMakeLists.txt`. It is the file from lesson 01 with one difference: the program is called `types` instead of `hello` (and it builds `main.cpp`).

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(types LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(types main.cpp)
target_compile_features(types PRIVATE cxx_std_20)
set_target_properties(types PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(types PRIVATE /W4 /permissive-)
else()
  target_compile_options(types PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
Create `main.cpp` and paste the complete file:

**File: `main.cpp`**
```cpp
#include <iomanip>
#include <iostream>
#include <string>

int main() {
    const std::string item{"Sourdough loaf"};
    int quantity{12};
    const double price{4.5};
    const bool in_stock{true};
    const char grade{'A'};

    quantity = quantity - 2;
    const double total{quantity * price};

    std::cout << "Item: " << item << '\n';
    std::cout << "Quantity: " << quantity << '\n';
    std::cout << "Price: " << price << '\n';
    std::cout << "In stock: " << in_stock << '\n';
    std::cout << std::boolalpha << "In stock (words): " << in_stock << '\n';
    std::cout << "Grade: " << grade << '\n';
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Total value: " << total << '\n';
    return 0;
}
```
Save both files (a dot on a tab means unsaved).

### Step 4. Predict, then build and run
**Predict first:** will `Price:` show `4.5` or `4.50`? And what will the first `In stock:` line show: the word `true`, or something else? Write your guesses down.

## Run it
In `lesson02`, on every OS:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
MSYS2 users add `-G Ninja` to the first command. Then run the program: Windows PowerShell `.\build\out\types.exe`; macOS/Linux `./build/out/types`.

Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Item: Sourdough loaf
Quantity: 10
Price: 4.5
In stock: 1
In stock (words): true
Grade: A
Total value: 45.00
```

## How it works
1. A **variable** is declared with `type name{value};`. `std::string item{"Sourdough loaf"};` creates a text variable called `item`. The braces `{}` give the starting value. This is called **brace initialisation**; it also refuses to silently lose information (see the misconception below).
2. **Types.** `int` holds whole numbers. `double` holds numbers with a decimal point (approximate, like a calculator display). `bool` holds `true` or `false`. `char` holds one character in **single** quotes. `std::string` holds text in **double** quotes and needs `#include <string>`.
3. **`const`** means "this value never changes after it is set". Trying to change it is a compile error. `quantity` is not `const` because the next line changes it.
4. `quantity = quantity - 2;` is **assignment**, not algebra: the computer first works out the right side (12 - 2 = 10), then stores the result in `quantity`.
5. `quantity * price` multiplies an `int` by a `double`; C++ converts the `int` to `double` and the result is a `double`, 45.
6. **Output.** `std::cout` can print every type. Strings and numbers use the same `<<`. A `bool` prints as `1` or `0` unless you switch on `std::boolalpha`, which prints `true` or `false` from that point on. A `double` prints in its shortest natural form: `4.5`, not `4.50`.
7. `std::fixed` and `std::setprecision(2)` (from `<iomanip>`) are **sticky**: they stay switched on for every later `double` printed through `std::cout`. Together they print exactly two digits after the decimal point, so 45 appears as `45.00`. Because they come after the `Price:` line, that line was not affected.
8. Misconception: "`int count{2.5};` rounds to 2." It does not compile: braces refuse a **narrowing conversion** (a conversion that could lose information, such as `double` to `int`). If you really want to drop the decimals, C++ lets you ask for it explicitly with a cast; this course does not need one.
9. Always give a variable a starting value. `int count;` with no value contains leftover junk, and reading it is a bug. `int count{};` starts at 0.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try02` next to `lesson02` (see [Exercise folders](../../README.md#exercise-folders)); or create `try02` and type these two files. `CMakeLists.txt` is identical to the one in Step 2.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(types LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(types main.cpp)
target_compile_features(types PRIVATE cxx_std_20)
set_target_properties(types PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(types PRIVATE /W4 /permissive-)
else()
  target_compile_options(types PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iomanip>
#include <iostream>

int main() {
    const int slices_per_pizza{8};
    const int pizzas{3};
    const double price_per_pizza{9.5};

    // TODO: replace 0 with the total number of slices (pizzas times slices per pizza).
    const int total_slices{0};
    // TODO: replace 0.0 with the total cost (pizzas times the price of one pizza).
    const double cost{0.0};

    std::cout << "Pizzas: " << pizzas << '\n';
    std::cout << "Slices: " << total_slices << '\n';
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Cost: " << cost << '\n';
    return 0;
}
```
Run it first: it prints `Slices: 0` and `Cost: 0.00`. Fix both TODOs, rebuild and run. Expected output after your change:

**File: terminal output (not a saved file)**
```text
Pizzas: 3
Slices: 24
Cost: 28.50
```

**Rung 2, change.** Add a `bool vegetarian{true};` and print it as a word. Add a `char size{'L'};` and print it.

**Rung 3, stretch (optional).** Add a second price (a drink) and print the grand total. Decide what names make the program easiest to read.

<details><summary>Solution</summary>

Replace the four lines from the first TODO comment to `const double cost{0.0};` with these two lines. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution, replacement for starter lines 9-12)`**
```cpp
    const int total_slices{pizzas * slices_per_pizza};
    const double cost{pizzas * price_per_pizza};
```

</details>

## Check yourself
1. Which type holds `true` or `false`?
   <details><summary>Answer</summary><code>bool</code>.</details>
2. What does `const` promise?
   <details><summary>Answer</summary>The value is set once and never changes afterwards.</details>
3. Predict: after `std::cout << std::fixed << std::setprecision(2);`, what does `std::cout << 3.14159;` print?
   <details><summary>Answer</summary><code>3.14</code>.</details>
4. Why is `int count{3.5};` a compile error?
   <details><summary>Answer</summary>It would silently lose the decimals; brace initialisation refuses such narrowing conversions.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error: narrowing conversion of ... from 'double' to 'int'` (MSVC: `error C2397: conversion from 'double' to 'int' requires a narrowing conversion`) | A decimal value was put into an `int` with braces | Use `double`, or write a whole number |
| GCC: `error: assignment of read-only variable 'price'` (MSVC: `error C3892: 'price': you cannot assign to a variable that is const`) | You changed a `const` variable | Remove `const` or do not change the value |
| GCC: `error: 'setprecision' is not a member of 'std'` | `#include <iomanip>` is missing | Add the include |
| GCC: `error: invalid conversion from 'const char*' to 'char'` | `"A"` (double quotes, text) used for a `char` | Use single quotes: `'A'` |
| `In stock: 1` instead of `true` | `bool` prints as a number by default | Use `std::boolalpha` |

## Best practice
Initialise every variable when you declare it, and make it `const` when it will not change. Source: C++ Core Guidelines, ES.20 "Always initialize an object" and Con.4 "Use const to define objects with values that do not change after construction" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Browse the fundamental types: https://en.cppreference.com/w/cpp/language/types and the formatting tools in `<iomanip>`: https://en.cppreference.com/w/cpp/io/manip

## Summary
- You declared variables of five types with brace initialisation.
- You used `const` for values that never change.
- You printed values, switched `bool` to words and printed money-style decimals.
- You explained why braces reject a narrowing conversion.

## Next lesson
**[03. Input and decisions](03-input-and-decisions.md):** read what the user types and choose between actions with `if`.
