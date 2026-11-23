---
track: cpp
level: 101
phase: 2
phase_name: building-blocks
lesson: 05
title: "Functions and references"
time: 50 min
prerequisites: [101.1.04]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-2-building-blocks/05-functions-and-references/
assets: []
---

# 05. Functions and references

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a function with parameters and a return value and call it;
- return two related results together in a `struct`;
- explain the difference between passing a value, a reference and a `const` reference;
- predict whether a function changes the caller's variable.

## Recap
1. What does `continue` do inside a loop?
   <details><summary>Answer</summary>It skips the rest of the current iteration and starts the next one.</details>
2. Which loop visits every character of a <code>std::string</code> most simply?
   <details><summary>Answer</summary>A range-based <code>for</code>: <code>for (const char c : text)</code>.</details>
3. What does <code>total += 5;</code> mean?
   <details><summary>Answer</summary><code>total = total + 5;</code>.</details>

## Why it matters
A blender takes ingredients, does its work and hands back a smoothie. You do not rebuild the blender each time. A **function** is a named piece of code that takes inputs, does a job and may hand back a result. Functions let you write an idea once, test it once and use it many times, and they give long programs a readable shape.

## What you will build
A rectangle measurer that returns area and perimeter, a tip adder that changes a bill in place, and a greeter.

## Before you start
- Recommended: lesson 04 (loops). Compiler and CMake from lesson 01.
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-2-building-blocks/05-functions-and-references/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson05`, full path `$HOME/code101/cpp/lesson05`. Open only `lesson05` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson05"`; macOS/Linux `cd "$HOME/code101/cpp/lesson05"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `functions`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(functions LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(functions main.cpp)
target_compile_features(functions PRIVATE cxx_std_20)
set_target_properties(functions PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(functions PRIVATE /W4 /permissive-)
else()
  target_compile_options(functions PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <iostream>
#include <string>

struct Dimensions {
    int area;
    int perimeter;
};

Dimensions measure(int width, int height) {
    return Dimensions{width * height, 2 * (width + height)};
}

void add_tip(double& bill, double percent) {
    bill += bill * percent / 100.0;
}

void print_greeting(const std::string& name) {
    std::cout << "Hello, " << name << "!\n";
}

int main() {
    const Dimensions room{measure(3, 4)};
    std::cout << "Area: " << room.area << " Perimeter: " << room.perimeter << '\n';

    double bill{80.0};
    add_tip(bill, 10.0);
    std::cout << "Bill with tip: " << bill << '\n';

    print_greeting("Ada");
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** what will `Bill with tip:` print? Does the variable `bill` in `main` change when `add_tip` runs?

## Run it
In `lesson05`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\functions.exe`; macOS/Linux `./build/out/functions`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Area: 12 Perimeter: 14
Bill with tip: 88
Hello, Ada!
```

## How it works
1. **Anatomy of a function.** `Dimensions measure(int width, int height) { ... }` has a **return type** (`Dimensions`, what comes back), a **name** (`measure`), **parameters** in parentheses (the inputs it expects) and a **body** in braces. The values you give in a call, `measure(3, 4)`, are the **arguments**; here 3 and 4 are copied into `width` and `height`. This copying is **passing by value**: the function works with its own copies.
2. **`struct`.** `struct Dimensions { int area; int perimeter; };` creates a new type: a named bundle of values (its **members**). `Dimensions{width * height, 2 * (width + height)}` builds one, and `room.area` reads a member with a dot. A struct is a tidy way to return two results at once.
3. **`return`** hands the value back and ends the function. A function whose return type is **`void`** returns nothing, like `add_tip` and `print_greeting`.
4. **Reference.** `double& bill` means "`bill` is another name for the caller's variable", not a copy. So `add_tip(bill, 10.0)` changes the `bill` in `main`: 80 plus 10 percent (8) is 88. Without the `&` the function would change a copy and `main` would still see 80. The `double percent` parameter is an ordinary copy.
5. **`const` reference.** `const std::string& name` also avoids a copy, but `const` forbids changing it. Copying a long string is wasteful; a read-only reference costs nothing. `print_greeting("Ada")` works because the text `"Ada"` is turned into a temporary `std::string` that the reference can look at.
6. **Rule of thumb for parameters:** small cheap types (`int`, `double`, `char`, `bool`) by value; large types (`std::string`, later `std::vector`) by `const` reference; use a plain reference only when the function must change the caller's variable.
7. A function must be defined (or declared) **before** the line that calls it. That is why `measure`, `add_tip` and `print_greeting` come before `main`.
8. Misconception: "passing a variable to a function lets the function change it". Only a non-`const` reference parameter can.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try05` next to `lesson05` (see [Exercise folders](../../README.md#exercise-folders)), or create `try05` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(functions LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(functions main.cpp)
target_compile_features(functions PRIVATE cxx_std_20)
set_target_properties(functions PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(functions PRIVATE /W4 /permissive-)
else()
  target_compile_options(functions PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>

void apply_discount(double& price, double percent) {
    // TODO: lower price by percent percent. For example 20 percent off 50 gives 40.
}

int main() {
    double price{50.0};
    apply_discount(price, 20.0);
    std::cout << "Price after discount: " << price << '\n';
    return 0;
}
```
The compiler warns that `percent` is not used: that is the compiler telling you the function is unfinished, and the warning disappears when you use the parameter. Fix the TODO, rebuild and run. Expected output after your change:

**File: terminal output (not a saved file)**
```text
Price after discount: 40
```

**Rung 2, change.** Add a function `double add_vat(double price, double percent)` that returns the new price instead of changing the original, and print `add_vat(40.0, 10.0)`.

**Rung 3, stretch (optional).** Decide which of the two styles (change in place, or return a new value) you find easier to read and write two sentences in a comment explaining why.

<details><summary>Solution</summary>

Replace the TODO comment line inside `apply_discount` with the line below. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <iostream>

void apply_discount(double& price, double percent) {
    price -= price * percent / 100.0;
}

int main() {
    double price{50.0};
    apply_discount(price, 20.0);
    std::cout << "Price after discount: " << price << '\n';
    return 0;
}
```

</details>

## Check yourself
1. What is the difference between a parameter and an argument?
   <details><summary>Answer</summary>A parameter is the named input in the function definition (<code>width</code>); an argument is the actual value in a call (<code>3</code>).</details>
2. Predict: `void f(int n) { n = 99; }` called as `int x{1}; f(x);`. What is `x` afterwards?
   <details><summary>Answer</summary>Still 1: <code>n</code> is a copy.</details>
3. What changes if you write `void f(int& n)` instead?
   <details><summary>Answer</summary><code>x</code> becomes 99, because <code>n</code> is another name for <code>x</code>.</details>
4. Why is a long string passed as `const std::string&`?
   <details><summary>Answer</summary>It avoids copying the text, and <code>const</code> stops the function from changing it.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC: `error: 'measure' was not declared in this scope` (MSVC: `error C3861: 'measure': identifier not found`) | The function is written after the line that calls it | Move the function above `main` |
| `Price after discount: 50` | The `&` is missing, so the function changed a copy | Write `double& price` |
| GCC: `error: cannot bind non-const lvalue reference of type 'double&' to an rvalue of type 'double'` | A plain value such as `80.0` was passed where a changeable variable is needed | Pass a variable: `add_tip(bill, 10.0)` |
| GCC: `warning: no return statement in function returning non-void` | A function with a return type forgot `return` | Add `return value;` |
| GCC: `warning: unused parameter 'percent'` | A parameter is never used (the starter does this on purpose) | Use it in the body |

## Best practice
Pass cheap types by value and big types by `const` reference, and prefer returning a result to changing a parameter: the call then shows what goes in and what comes out. `add_tip` uses a reference only to teach how references work. Source: C++ Core Guidelines, F.16 "For 'in' parameters, pass cheaply-copied types by value and others by reference to const" and F.20 "For 'out' output values, prefer return values to output parameters" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Functions in detail: https://en.cppreference.com/w/cpp/language/functions. Lesson 08 returns to references and compares them with pointers.

## Summary
- You wrote functions with parameters and return values and called them.
- You returned two results at once with a `struct`.
- You changed a caller's variable through a reference and avoided a copy with a `const` reference.
- You predicted when a function sees a copy and when it sees the original.

## Next lesson
**[06. Strings and vectors](06-strings-and-vectors.md):** work with text and lists that grow.
