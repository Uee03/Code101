---
track: cpp
level: 101
phase: 2
phase_name: building-blocks
lesson: 07
title: "Maps and algorithms"
time: 60 min
prerequisites: [101.2.06]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-2-building-blocks/07-maps-and-algorithms/
assets: []
---

# 07. Maps and algorithms

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- store and look up values by key with `std::map`;
- count how often things occur and print the counts in order;
- sort a vector, add up its values and find a value with `std::sort`, `std::accumulate` and `std::find`;
- explain why `counts["x"]` can add an entry you did not mean to add.

## Recap
1. What is the index of the first item of a vector, and what does <code>size()</code> return for an empty one?
   <details><summary>Answer</summary>0, and <code>size()</code> returns 0.</details>
2. What does <code>find</code> return on a <code>std::string</code> when nothing matches?
   <details><summary>Answer</summary><code>std::string::npos</code>.</details>
3. How do you add an item to the end of a vector?
   <details><summary>Answer</summary><code>push_back</code>.</details>

## Why it matters
A paper dictionary lets you find a meaning from a word without reading every page. A **map** is the same idea: you look up a value by its **key**. A librarian sorts the shelves without you doing it book by book. The **algorithms** of the standard library sort, search and add up your data so you do not write those loops again, and the code says what it does.

## What you will build
A word counter, and a score list that is sorted, summed and searched.

## Before you start
- Recommended: lesson 06 (strings and vectors). Compiler and CMake from lesson 01.
- Time: 60 minutes (several new ideas; take a break after Step 4 if you like).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-2-building-blocks/07-maps-and-algorithms/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson07`, full path `$HOME/code101/cpp/lesson07`. Open only `lesson07` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson07"`; macOS/Linux `cd "$HOME/code101/cpp/lesson07"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `maps`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(maps LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(maps main.cpp)
target_compile_features(maps PRIVATE cxx_std_20)
set_target_properties(maps PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(maps PRIVATE /W4 /permissive-)
else()
  target_compile_options(maps PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <algorithm>
#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <vector>

int main() {
    const std::vector<std::string> words{"tea", "cake", "tea", "jam", "tea", "cake"};

    std::map<std::string, int> counts;
    for (const std::string& word : words) {
        ++counts[word];
    }

    std::cout << "Word counts:\n";
    for (const auto& [word, count] : counts) {
        std::cout << word << ": " << count << '\n';
    }

    if (counts.contains("jam")) {
        std::cout << "jam appears " << counts.at("jam") << " time(s)\n";
    }
    if (!counts.contains("scone")) {
        std::cout << "no scones today\n";
    }

    std::vector<int> scores{72, 95, 60, 88};
    std::sort(scores.begin(), scores.end());
    std::cout << "Lowest: " << scores.front() << '\n';
    std::cout << "Highest: " << scores.back() << '\n';

    const int total{std::accumulate(scores.begin(), scores.end(), 0)};
    std::cout << "Total: " << total << '\n';

    const auto found{std::find(scores.begin(), scores.end(), 88)};
    if (found != scores.end()) {
        std::cout << "88 is at position " << (found - scores.begin()) << '\n';
    }
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** in which order will the three words be printed? What will the lowest and the highest score be? At which position (counting from 0) will 88 be found after sorting?

## Run it
In `lesson07`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\maps.exe`; macOS/Linux `./build/out/maps`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Word counts:
cake: 2
jam: 1
tea: 3
jam appears 1 time(s)
no scones today
Lowest: 60
Highest: 95
Total: 315
88 is at position 2
```

## How it works
1. **`std::map<std::string, int>`** holds pairs: a **key** (here a word) and a **value** (here a number). Keys are unique and the map keeps them **sorted**, which is why `cake`, `jam`, `tea` print in alphabetical order, not in the order they appeared.
2. **`++counts[word]`.** The square brackets look up the key. If the key is new, the map first creates it with value 0 (for numbers), then `++` adds 1. So the first `tea` becomes 1, the second 2, the third 3. Counting words takes one line.
3. **Looping a map.** `for (const auto& [word, count] : counts)` visits each pair. `auto` lets the compiler work out the type. `[word, count]` is a **structured binding**: it names the two parts of the pair. `const auto&` avoids copying.
4. **Look up safely.** `counts.contains("jam")` answers yes or no without changing the map. `counts.at("jam")` returns the value and reports an error if the key is missing.
5. **Misconception:** `counts["scone"]` as a mere look-up would add the key `scone` with value 0. Use `contains` or `at` when you only want to ask. (Requires C++20 for `contains`, which our `CMakeLists.txt` requests.)
6. **Algorithms** live in `<algorithm>` and `<numeric>`. They work on a **range** given by two **iterators**: an iterator is a marker pointing at an item. `scores.begin()` points at the first item, `scores.end()` points just past the last item.
7. `std::sort(scores.begin(), scores.end())` puts the numbers in increasing order: 60, 72, 88, 95. After that `front()` is the lowest and `back()` the highest.
8. `std::accumulate(scores.begin(), scores.end(), 0)` adds all values to the starting value 0: 60 + 72 + 88 + 95 = 315.
9. `std::find(..., 88)` returns an iterator to the first 88, or `end()` if there is none, so compare with `scores.end()` before using it. `found - scores.begin()` is the number of steps from the start: position 2 in the sorted list.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try07` next to `lesson07` (see [Exercise folders](../../README.md#exercise-folders)), or create `try07` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(maps LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(maps main.cpp)
target_compile_features(maps PRIVATE cxx_std_20)
set_target_properties(maps PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(maps PRIVATE /W4 /permissive-)
else()
  target_compile_options(maps PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<std::string, int> stock{{"apples", 5}, {"plums", 2}};

    // TODO: add 3 more apples to the stock of "apples".
    // TODO: add a new entry "pears" with a stock of 7.

    for (const auto& [name, amount] : stock) {
        std::cout << name << ": " << amount << '\n';
    }
    return 0;
}
```
The starter prints `apples: 5` and `plums: 2`. Complete both TODOs. Expected output after your change:

**File: terminal output (not a saved file)**
```text
apples: 8
pears: 7
plums: 2
```

**Rung 2, change.** After the loop print how many kinds of fruit there are with `stock.size()`, then use `stock.contains("kiwi")` to print whether kiwis are in stock (use `std::boolalpha` to see a word).

**Rung 3, stretch (optional).** Put the fruit names into a `std::vector<std::string>`, sort it with `std::sort` and print it. Which is better for a fixed alphabetical listing: the sorted vector or the map? Write a comment with your reason.

<details><summary>Solution</summary>

Replace the two TODO comment lines with these two statements. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<std::string, int> stock{{"apples", 5}, {"plums", 2}};

    stock["apples"] += 3;
    stock["pears"] = 7;

    for (const auto& [name, amount] : stock) {
        std::cout << name << ": " << amount << '\n';
    }
    return 0;
}
```

</details>

## Check yourself
1. In what order does a `std::map` list its keys?
   <details><summary>Answer</summary>Sorted by key (for strings, alphabetical), not in the order they were added.</details>
2. What happens when you write `counts["scone"]` for a missing key in a `map<std::string, int>`?
   <details><summary>Answer</summary>The key is added with value 0.</details>
3. Predict: after `std::sort` on `{3, 1, 2}`, what does `std::accumulate(v.begin(), v.end(), 10)` return?
   <details><summary>Answer</summary>16 (10 + 1 + 2 + 3).</details>
4. What does `std::find` return when the value is not in the range?
   <details><summary>Answer</summary>The end iterator, <code>v.end()</code>.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC: `error: 'map' in namespace 'std' does not name a template type` | `#include <map>` is missing | Add the include |
| GCC: `error: 'sort' is not a member of 'std'` | `#include <algorithm>` is missing | Add the include |
| `error: ... has no member named 'contains'` | The file was compiled without C++20 (for example by hand with `g++ main.cpp`) | Build with CMake as in this course, or add `-std=c++20` |
| A key you never added shows up with value 0 | `counts["key"]` was used just to look something up | Use `contains` or `at` for look-ups |
| The words print in alphabetical order, not insertion order | `std::map` keeps keys sorted | That is expected; use a vector of pairs if insertion order matters |

## Best practice
Prefer a standard algorithm to a hand-written loop for common jobs such as sorting, summing and searching: it is shorter, tested and says what you mean. Source: C++ Core Guidelines, ES.1 "Prefer the standard library to other libraries and to 'handcrafted code'" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Algorithms reference: https://en.cppreference.com/w/cpp/algorithm and the map type: https://en.cppreference.com/w/cpp/container/map

## Summary
- You counted words with a `std::map` and printed them in key order.
- You looked up keys safely with `contains` and `at`.
- You sorted a vector, added up its values and found a value with standard algorithms.
- You explained why `counts["x"]` can insert a new entry.

## Next lesson
**[08. Pointers and references](08-pointers-and-references.md):** see what a pointer is, how it differs from a reference, and when each is used.
