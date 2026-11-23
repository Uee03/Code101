---
track: cpp
level: 101
phase: 2
phase_name: building-blocks
lesson: 08
title: "Pointers and references"
time: 40 min
prerequisites: [101.2.05, 101.2.06]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-2-building-blocks/08-pointers-and-references/
assets: []
---

# 08. Pointers and references

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- read and write `&` and `*` in declarations and in expressions;
- use a pointer that may point at nothing (`nullptr`) and check it before use;
- explain how a reference differs from a pointer and which to choose;
- predict the values of variables changed through a reference and through a pointer.

## Recap
1. What does `std::map` do with keys, and how do you look a key up without adding it?
   <details><summary>Answer</summary>It keeps them sorted; use <code>contains</code> or <code>at</code>.</details>
2. What is an iterator, in one sentence?
   <details><summary>Answer</summary>A marker that points at an item in a container.</details>
3. Which function parameter lets a function change the caller's variable?
   <details><summary>Answer</summary>A non-<code>const</code> reference, for example <code>double&amp; bill</code>.</details>

## Why it matters
Every item in memory lives at an **address**, like a house on a street. A **reference** is a second name tag on the same house. A **pointer** is a card with a house address written on it: you can read the address, hand the card to someone, cross it out and write another address, or leave it blank. C++ programs use pointers when a thing may be absent ("no result") or when a library hands you one. This lesson is short on purpose: later lessons use smart pointers that keep the dangerous parts away, and most of your code will use references and values.

## What you will build
A small program that changes one variable through a reference and a pointer, and a function that returns a pointer to the first even number in a list (or "nothing").

## Before you start
- Recommended: lessons 05 (references) and 06 (vectors). Compiler and CMake from lesson 01.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-2-building-blocks/08-pointers-and-references/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson08`, full path `$HOME/code101/cpp/lesson08`. Open only `lesson08` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson08"`; macOS/Linux `cd "$HOME/code101/cpp/lesson08"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `pointers`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(pointers LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(pointers main.cpp)
target_compile_features(pointers PRIVATE cxx_std_20)
set_target_properties(pointers PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(pointers PRIVATE /W4 /permissive-)
else()
  target_compile_options(pointers PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <cstddef>
#include <iostream>
#include <vector>

int* find_first_even(std::vector<int>& numbers) {
    for (int& n : numbers) {
        if (n % 2 == 0) {
            return &n;
        }
    }
    return nullptr;
}

void print_numbers(const std::vector<int>& numbers) {
    for (std::size_t i{0}; i < numbers.size(); ++i) {
        if (i > 0) {
            std::cout << ", ";
        }
        std::cout << numbers[i];
    }
    std::cout << '\n';
}

int main() {
    int age{30};
    int& alias{age};
    int* pointer{&age};

    alias = 31;
    std::cout << "age after alias = 31: " << age << '\n';
    *pointer = 32;
    std::cout << "age after *pointer = 32: " << age << '\n';

    int other{100};
    pointer = &other;
    std::cout << "pointer now reads: " << *pointer << '\n';
    std::cout << "alias still reads: " << alias << '\n';

    std::vector<int> numbers{7, 9, 4, 11};
    int* even{find_first_even(numbers)};
    if (even != nullptr) {
        *even = 0;
    }
    print_numbers(numbers);

    std::vector<int> odds{1, 3, 5};
    if (find_first_even(odds) == nullptr) {
        std::cout << "no even number in odds\n";
    }
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** what do the first four lines print? After `find_first_even` runs, which number in `{7, 9, 4, 11}` has been replaced by 0?

## Run it
In `lesson08`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\pointers.exe`; macOS/Linux `./build/out/pointers`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
age after alias = 31: 31
age after *pointer = 32: 32
pointer now reads: 100
alias still reads: 32
7, 9, 0, 11
no even number in odds
```

## How it works
1. **Two meanings for `&` and `*`.** In a **declaration** (a type is written before the name), `int&` means "reference to int" and `int*` means "pointer to int". In an **expression** (a value is being used), `&age` means "the address of `age`" and `*pointer` means "the value that `pointer` points at" (this is called **dereferencing**).
2. **Reference.** `int& alias{age};` makes `alias` another name for `age`. A reference must be set when it is created, can never be null and can never be pointed at something else. So `alias = 31;` changes `age`.
3. **Pointer.** `int* pointer{&age};` stores the address of `age`. `*pointer = 32;` changes the variable at that address. A pointer can be re-aimed: `pointer = &other;` stores a different address, and `age` is not touched. Meanwhile `alias` still names `age` (32): a reference cannot be re-aimed.
4. **`nullptr`** is the "points at nothing" value. `find_first_even` returns a pointer to the first even element, or `nullptr` if there is none. The caller **must check** `even != nullptr` before using `*even`, because dereferencing `nullptr` is a bug that usually crashes the program.
5. In `for (int& n : numbers)` the loop variable is a reference, so `&n` is the address of the real element in the vector and not of a copy. That is why `*even = 0;` changes the vector: `4` becomes `0`.
6. **Who owns the object?** The pointer from `find_first_even` only *looks at* an element that the vector owns. It must not be used after the vector is gone or after items are added (the vector may move its items to new memory). Such a pointer is called **dangling**. This course uses raw pointers only to look at things owned by someone else, never to create or delete things.
7. **Which to choose?** Default to values and references. Use a pointer when "nothing" is a valid answer (like `nullptr` above) or when you must be able to re-aim.
8. Misconception: "a pointer holds the object". It holds only the address; the object lives elsewhere.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try08` next to `lesson08` (see [Exercise folders](../../README.md#exercise-folders)), or create `try08` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(pointers LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(pointers main.cpp)
target_compile_features(pointers PRIVATE cxx_std_20)
set_target_properties(pointers PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(pointers PRIVATE /W4 /permissive-)
else()
  target_compile_options(pointers PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>
#include <vector>

const int* find_cheapest(const std::vector<int>& prices) {
    // TODO: return a pointer to the smallest price, or nullptr when the vector is empty.
    return nullptr;
}

void report(const std::vector<int>& prices) {
    const int* cheapest{find_cheapest(prices)};
    if (cheapest != nullptr) {
        std::cout << "Cheapest: " << *cheapest << '\n';
    } else {
        std::cout << "No prices\n";
    }
}

int main() {
    report({5, 3, 8});
    report({});
    return 0;
}
```
`const int*` means "pointer to an int that may be read but not changed". The starter prints `No prices` twice (and the compiler warns that `prices` is unused until you finish). Complete the function. Expected output after your change:

**File: terminal output (not a saved file)**
```text
Cheapest: 3
No prices
```

**Rung 2, change.** Write `find_most_expensive` the same way and report both.

**Rung 3, stretch (optional).** Instead of a pointer, could the function return the price itself? What would you return for an empty vector? Write down the trade-off.

<details><summary>Solution</summary>

Replace the TODO comment and the `return nullptr;` line inside `find_cheapest` with the body below. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <iostream>
#include <vector>

const int* find_cheapest(const std::vector<int>& prices) {
    if (prices.empty()) {
        return nullptr;
    }
    const int* cheapest{&prices[0]};
    for (const int& price : prices) {
        if (price < *cheapest) {
            cheapest = &price;
        }
    }
    return cheapest;
}

void report(const std::vector<int>& prices) {
    const int* cheapest{find_cheapest(prices)};
    if (cheapest != nullptr) {
        std::cout << "Cheapest: " << *cheapest << '\n';
    } else {
        std::cout << "No prices\n";
    }
}

int main() {
    report({5, 3, 8});
    report({});
    return 0;
}
```

</details>

## Check yourself
1. What does `*pointer = 32;` do?
   <details><summary>Answer</summary>It stores 32 in the variable the pointer points at.</details>
2. Predict: `int a{1}; int b{2}; int& r{a}; r = b; b = 5;`. What are `a` and `b` now?
   <details><summary>Answer</summary><code>a</code> is 2 (the assignment copied <code>b</code>'s value into <code>a</code> through the reference) and <code>b</code> is 5.</details>
3. What must you do with a pointer that might be `nullptr` before you use `*pointer`?
   <details><summary>Answer</summary>Check <code>pointer != nullptr</code>.</details>
4. Why is a reference safer than a pointer when you always expect a value?
   <details><summary>Answer</summary>It can never be null and never re-aimed, so a whole class of mistakes cannot happen.</details>

## Phase review (lessons 05 to 08)
1. Which parameter type do you use for a long `std::string` that a function only reads? <details><summary>Answer</summary><code>const std::string&amp;</code>.</details>
2. Predict: `std::vector<int> v{4, 8}; v.push_back(6); std::cout << v.size() << v[2];` <details><summary>Answer</summary><code>36</code>: three items, and index 2 holds 6.</details>
3. You need a count per word. Which container fits, and how do you add 1 for a word? <details><summary>Answer</summary><code>std::map&lt;std::string, int&gt;</code> and <code>++counts[word];</code>.</details>
4. When is a pointer a better choice than a reference? <details><summary>Answer</summary>When "no object" is a valid answer (<code>nullptr</code>) or the target must change.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| Program stops at once; Linux/macOS typically print `Segmentation fault` | A `nullptr` was dereferenced | Check `!= nullptr` first |
| GCC: `error: 'r' declared as reference but not initialized` | A reference was declared without a variable to name | Write `int& r{a};` |
| GCC: `warning: address of local variable 'x' returned` | A function returned `&x` for a variable that disappears when the function ends | Return a value, or a pointer into something that outlives the function |
| `*pointer = 5;` changed nothing visible, or `pointer = 5;` does not compile | `*` and plain pointer confused | `*pointer` is the value; `pointer` is the address |
| A pointer to a vector item gives strange values after `push_back` | The vector moved its items; the pointer is dangling | Fetch the pointer again after changing the vector |

## Best practice
Treat a raw pointer as "borrowed, not owned", and write `nullptr` (not `0` or `NULL`). Source: C++ Core Guidelines, R.3 "A raw pointer (a T*) is non-owning" and ES.47 "Use nullptr rather than 0 or NULL" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Pointers: https://en.cppreference.com/w/cpp/language/pointer and references: https://en.cppreference.com/w/cpp/language/reference. Lesson 10 shows the safe way to own an object.

## Summary
- You read and wrote `&` and `*` in declarations and expressions.
- You changed one variable through a reference and through a pointer.
- You returned and checked a `nullptr`.
- You explained why references are the default and pointers are for "maybe nothing".

## Next lesson
**[09. Classes and RAII](../phase-3-real-programs/09-classes-and-raii.md):** bundle data and behaviour in your own type and let it clean up after itself.
