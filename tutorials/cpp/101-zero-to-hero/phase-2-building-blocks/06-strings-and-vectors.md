---
track: cpp
level: 101
phase: 2
phase_name: building-blocks
lesson: 06
title: "Strings and vectors"
time: 50 min
prerequisites: [101.2.05]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-2-building-blocks/06-strings-and-vectors/
assets: []
---

# 06. Strings and vectors

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- join, measure and search text with `std::string`;
- keep a list that grows with `std::vector` and visit its items by index and with a range-based `for`;
- explain what `size()`, `push_back`, `back` and `pop_back` do;
- predict the output of code that changes a vector.

## Recap
1. When does a function change the caller's variable?
   <details><summary>Answer</summary>When the parameter is a non-<code>const</code> reference, such as <code>double&amp; bill</code>.</details>
2. Why pass a <code>std::string</code> as <code>const std::string&amp;</code>?
   <details><summary>Answer</summary>It avoids copying the text, and <code>const</code> stops the function changing it.</details>
3. What does a <code>struct</code> let a function do?
   <details><summary>Answer</summary>Return several related values together.</details>

## Why it matters
A shopping list is a row of lines you can add to, cross off and count; a name tag is text you can glue pieces onto. Nearly every program handles text and lists: names, messages, prices, lines of a file. `std::string` and `std::vector` are the two tools you will use the most.

## What you will build
A program that joins and searches text and keeps a shopping list that grows and shrinks.

## Before you start
- Recommended: lesson 05 (functions and references). Compiler and CMake from lesson 01.
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-2-building-blocks/06-strings-and-vectors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson06`, full path `$HOME/code101/cpp/lesson06`. Open only `lesson06` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson06"`; macOS/Linux `cd "$HOME/code101/cpp/lesson06"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `strings`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(strings LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(strings main.cpp)
target_compile_features(strings PRIVATE cxx_std_20)
set_target_properties(strings PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(strings PRIVATE /W4 /permissive-)
else()
  target_compile_options(strings PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string greeting{"Hello"};
    greeting += ", world";
    std::cout << greeting << " has " << greeting.size() << " characters\n";

    const std::size_t comma{greeting.find(',')};
    if (comma != std::string::npos) {
        std::cout << "First word: " << greeting.substr(0, comma) << '\n';
    }

    std::vector<std::string> items;
    items.push_back("bread");
    items.push_back("milk");
    items.push_back("eggs");

    std::cout << "Items: " << items.size() << '\n';
    for (std::size_t i{0}; i < items.size(); ++i) {
        std::cout << i + 1 << ". " << items[i] << '\n';
    }

    const std::vector<int> prices{3, 2, 4};
    int total{0};
    for (const int price : prices) {
        total += price;
    }
    std::cout << "Total price: " << total << '\n';

    std::cout << "Last item: " << items.back() << '\n';
    items.pop_back();
    std::cout << "After pop_back: " << items.size() << " items\n";
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** how many characters has `Hello, world`? Which word is printed as the first word? What is printed after `pop_back`?

## Run it
In `lesson06`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\strings.exe`; macOS/Linux `./build/out/strings`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Hello, world has 12 characters
First word: Hello
Items: 3
1. bread
2. milk
3. eggs
Total price: 9
Last item: eggs
After pop_back: 2 items
```

## How it works
1. **`std::string`** owns its text and grows when you add to it. `greeting += ", world"` appends. `size()` counts the characters (spaces and the comma included): `Hello, world` is 5 + 1 + 1 + 5 = 12. Text and functions that belong to a type are used with a dot: `greeting.size()`.
2. **Search.** `greeting.find(',')` returns the **position** (counting from 0) of the first comma, which is 5. If the character is missing, `find` returns the special value `std::string::npos`, meaning "not found", so always compare against it before using the position. `substr(0, comma)` takes `comma` characters starting at position 0: `Hello`.
3. **`std::size_t`** is the whole-number type the standard library uses for sizes and positions. It never holds a negative number. Using it for `i` avoids a compiler warning about comparing signed and unsigned numbers.
4. **`std::vector`** is a list of items of one type that grows on demand: `std::vector<std::string>` is a list of strings, `std::vector<int>` a list of whole numbers. `push_back` adds at the end. A vector starts empty when you declare it without values.
5. **Indexes start at 0.** `items[0]` is `bread`, `items[2]` is `eggs`. The loop prints `i + 1` so people see 1, 2, 3. The test `i < items.size()` stops before the invalid index 3.
6. `const std::vector<int> prices{3, 2, 4};` creates a list with starting values; `const` means it cannot be changed. The range-based `for` from lesson 04 works on it directly: 3 + 2 + 4 = 9.
7. `back()` is the last item; `pop_back()` removes it, so the size drops from 3 to 2.
8. Misconception: `items[10]` is checked and reports an error. It is not checked; the program may crash, print junk, or appear to work. `items.at(10)` is checked and stops the program with an error message, which you can handle (lesson 11 shows how).
9. Joining text: `std::string` plus text works (`greeting + "!"`). Two text literals do not: `"a" + "b"` does not compile because neither side is a `std::string`.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try06` next to `lesson06` (see [Exercise folders](../../README.md#exercise-folders)), or create `try06` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(strings LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(strings main.cpp)
target_compile_features(strings PRIVATE cxx_std_20)
set_target_properties(strings PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(strings PRIVATE /W4 /permissive-)
else()
  target_compile_options(strings PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> names{"Ada", "Grace", "Alan"};

    // TODO: add the name "Linus" to the end of the vector.

    std::cout << "Names: ";
    for (std::size_t i{0}; i < names.size(); ++i) {
        // TODO: print ", " before every name except the first one.
        std::cout << names[i];
    }
    std::cout << '\n';
    std::cout << "Count: " << names.size() << '\n';
    return 0;
}
```
Run the starter first: it prints `Names: AdaGraceAlan` and `Count: 3`. Complete both TODOs. Expected output after your change:

**File: terminal output (not a saved file)**
```text
Names: Ada, Grace, Alan, Linus
Count: 4
```

**Rung 2, change.** Print the names in reverse order (hint: a loop that counts down, or `back()` and `pop_back()` in a `while` loop).

**Rung 3, stretch (optional).** Print only the names that have more than three characters. Which loop style is easiest?

<details><summary>Solution</summary>

Replace the first TODO line with `names.push_back("Linus");` and the second TODO with an `if`. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> names{"Ada", "Grace", "Alan"};

    names.push_back("Linus");

    std::cout << "Names: ";
    for (std::size_t i{0}; i < names.size(); ++i) {
        if (i > 0) {
            std::cout << ", ";
        }
        std::cout << names[i];
    }
    std::cout << '\n';
    std::cout << "Count: " << names.size() << '\n';
    return 0;
}
```

</details>

## Check yourself
1. What does `find` return when the character is not in the string?
   <details><summary>Answer</summary><code>std::string::npos</code>.</details>
2. Predict: `std::vector<int> v{5, 6, 7}; v.pop_back(); std::cout << v.size() << v.back();`
   <details><summary>Answer</summary><code>26</code>: the size is 2 and the last item is now 6.</details>
3. What is the index of the first item of a vector?
   <details><summary>Answer</summary>0.</details>
4. What is the difference between `v[10]` and `v.at(10)` when `v` has 3 items?
   <details><summary>Answer</summary><code>v[10]</code> is not checked (undefined behaviour); <code>v.at(10)</code> is checked and reports an error.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC: `error: invalid operands of types 'const char [2]' and 'const char [2]' to binary 'operator+'` | Two text literals were added with `+` | Make one side a `std::string`: `std::string{"a"} + "b"` |
| GCC: `error: invalid use of member function ... (did you forget the '()' ?)` | `items.size` without parentheses | Write `items.size()` |
| GCC: `warning: comparison of integer expressions of different signedness` | `int i` compared with `items.size()` | Use `std::size_t i` as in this lesson |
| Garbage output or a crash, with no message | An index past the end, such as `items[3]` for 3 items | Keep `i < items.size()`; use `at()` while learning |
| Typical message when `at()` fails (GCC): `terminate called after throwing an instance of 'std::out_of_range'` | The index is outside the vector | Check the size before using an index |

## Best practice
Use `std::string` for text and `std::vector` as your default list: they manage their own memory and know their size. Reach for another container only with a reason. Source: C++ Core Guidelines, SL.str.1 "Use std::string to own character sequences" and SL.con.2 "Prefer using STL vector by default unless you have a reason to use a different container" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Reference pages: https://en.cppreference.com/w/cpp/string/basic_string and https://en.cppreference.com/w/cpp/container/vector

## Summary
- You joined, measured and searched text with `std::string`.
- You kept a growing list with `std::vector` and visited it by index and with a range-based `for`.
- You used `back`, `pop_back` and `size` and predicted their results.
- You explained why `[]` is not bounds-checked and `at()` is.

## Next lesson
**[07. Maps and algorithms](07-maps-and-algorithms.md):** look values up by key and let the standard library sort and search for you.
