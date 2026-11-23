---
track: cpp
level: 101
phase: 3
phase_name: real-programs
lesson: 11
title: "Files and errors"
time: 60 min
prerequisites: [101.2.06, 101.3.09]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-3-real-programs/11-files-and-errors/
assets: []
---

# 11. Files and errors

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write lines of text to a file with `std::ofstream` and read them back with `std::ifstream`;
- check that a file really opened;
- signal a problem with `throw` and handle it with `try` and `catch`;
- predict which lines a program prints when a file is missing.

## Recap
1. What does RAII promise about clean-up?
   <details><summary>Answer</summary>An object gives its resource back in its destructor, so clean-up happens automatically when it goes out of scope.</details>
2. How do you add an item to the end of a <code>std::vector</code>?
   <details><summary>Answer</summary><code>push_back</code>.</details>
3. What does <code>std::getline(std::cin, line)</code> read?
   <details><summary>Answer</summary>One whole line of input, spaces included.</details>

## Why it matters
Variables vanish when a program ends. A notebook keeps what you write. Files are the program's notebook: they let a program remember between runs. But notebooks can be missing, locked or full, so a careful program expects trouble and reports it clearly instead of crashing. C++ signals trouble with **exceptions**.

## What you will build
A program that saves three lines to `notes.txt`, reads them back, then tries to read a file that does not exist and reports the problem calmly.

## Before you start
- Recommended: lessons 06 (strings and vectors) and 09 (classes and RAII). Compiler and CMake from lesson 01.
- Time: 60 minutes (files and exceptions are two ideas; break after Step 3 if you like).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-3-real-programs/11-files-and-errors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson11`, full path `$HOME/code101/cpp/lesson11`. Open only `lesson11` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson11"`; macOS/Linux `cd "$HOME/code101/cpp/lesson11"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `files`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(files LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(files main.cpp)
target_compile_features(files PRIVATE cxx_std_20)
set_target_properties(files PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(files PRIVATE /W4 /permissive-)
else()
  target_compile_options(files PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <exception>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

void save_lines(const std::string& path, const std::vector<std::string>& lines) {
    std::ofstream out{path};
    if (!out) {
        throw std::runtime_error("cannot open " + path + " for writing");
    }
    for (const std::string& line : lines) {
        out << line << '\n';
    }
}

std::vector<std::string> load_lines(const std::string& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error("cannot open " + path + " for reading");
    }
    std::vector<std::string> lines;
    std::string line;
    while (std::getline(in, line)) {
        lines.push_back(line);
    }
    return lines;
}

int main() {
    try {
        save_lines("notes.txt", {"buy bread", "call Sam", "read chapter 11"});
        const std::vector<std::string> lines{load_lines("notes.txt")};
        std::cout << "Read " << lines.size() << " lines:\n";
        for (const std::string& line : lines) {
            std::cout << "- " << line << '\n';
        }
    } catch (const std::exception& error) {
        std::cout << "Error: " << error.what() << '\n';
        return 1;
    }

    try {
        load_lines("missing-file.txt");
    } catch (const std::exception& error) {
        std::cout << "Error: " << error.what() << '\n';
    }
    std::cout << "Done\n";
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** how many lines will `notes.txt` contain? What will the program print for the missing file, and will `Done` still appear?

## Run it
In `lesson11`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it **from the `lesson11` folder**: Windows PowerShell `.\build\out\files.exe`; macOS/Linux `./build/out/files`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Read 3 lines:
- buy bread
- call Sam
- read chapter 11
Error: cannot open missing-file.txt for reading
Done
```
Now look in the `lesson11` folder: a new file `notes.txt` has appeared (in VS Code's Explorer, or with `Get-ChildItem` / `ls`). Opening it shows:

**File: `notes.txt (created by the program)`**
```text
buy bread
call Sam
read chapter 11
```

## How it works
1. **Where is the file?** A name like `"notes.txt"` without a folder is a **relative path**: it is looked up in the **current folder** of the terminal when you start the program. That is why you run from `lesson11`. Run from elsewhere and the file appears (or is searched for) there.
2. **Writing.** `std::ofstream out{path};` opens (and creates or empties) the file for writing. `out << line << '\n';` works exactly like `std::cout`. The headers are `<fstream>` for files. The file is closed automatically at the end of the function when `out` is destroyed: RAII again.
3. **Did it open?** If the folder is read-only or the name is invalid, the stream is in a failed state, and `!out` is true (as with `std::cin` in lesson 03). Always check.
4. **Reading.** `std::ifstream in{path};` opens for reading. `while (std::getline(in, line))` reads one line at a time until there are no more; the loop condition is the success of the read. Each line is added to a vector which the function returns.
5. **Exceptions.** A function that cannot do its job should not carry on silently. `throw std::runtime_error("...")` creates an error object carrying a message and **throws** it: the function stops at once, and C++ looks outward through the calling functions for a matching `catch`. `std::runtime_error` is the standard type for "something went wrong while running".
6. **`try` and `catch`.** Code that might throw goes in a `try { }` block. `catch (const std::exception& error)` handles any standard exception: `error.what()` is the message. The `const` reference follows lesson 05: catch by `const` reference, no copy. Because the second `catch` does not `return`, the program continues with `Done`.
7. The first `catch` in `main` returns 1: a failure of the main job should be visible to whoever started the program. The missing-file demo is expected, so the program carries on.
8. Misconception: "an exception is a crash". An exception that is caught is just a controlled way to report a problem; only an uncaught one ends the program.
9. `"cannot open " + path + " for reading"` works because `path` is a `std::string`; a literal plus a `std::string` gives a `std::string`.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try11` next to `lesson11` (see [Exercise folders](../../README.md#exercise-folders)), or create `try11` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(files LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(files main.cpp)
target_compile_features(files PRIVATE cxx_std_20)
set_target_properties(files PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(files PRIVATE /W4 /permissive-)
else()
  target_compile_options(files PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <cstddef>
#include <exception>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

void save_lines(const std::string& path, const std::vector<std::string>& lines) {
    std::ofstream out{path};
    if (!out) {
        throw std::runtime_error("cannot open " + path + " for writing");
    }
    for (const std::string& line : lines) {
        out << line << '\n';
    }
}

std::vector<std::string> load_lines(const std::string& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error("cannot open " + path + " for reading");
    }
    std::vector<std::string> lines;
    std::string line;
    while (std::getline(in, line)) {
        lines.push_back(line);
    }
    return lines;
}

int main() {
    save_lines("todo.txt", {"wash car", "pay rent"});
    const std::vector<std::string> todo{load_lines("todo.txt")};
    for (std::size_t i{0}; i < todo.size(); ++i) {
        std::cout << i + 1 << ". " << todo[i] << '\n';
    }

    // TODO: call load_lines("archive.txt"). That file does not exist, so it throws.
    // Catch the error and print "Could not read: " followed by the error text, then carry on.

    std::cout << "Done\n";
    return 0;
}
```
The two functions are exactly the ones from Step 3. Run the starter from `try11`: it prints the two numbered lines and `Done`. Complete the TODO. Expected output after your change:

**File: terminal output (not a saved file)**
```text
1. wash car
2. pay rent
Could not read: cannot open archive.txt for reading
Done
```

**Rung 2, change.** After the numbered list, save a third line to `todo.txt` by passing three lines to `save_lines`, and check that the numbering reaches 3.

**Rung 3, stretch (optional).** Write a function `void append_line(const std::string& path, const std::string& line)` that adds one line to the end of an existing file (hint: look up `std::ios::app` on cppreference). Decide when it should throw.

<details><summary>Solution</summary>

Replace the two TODO comment lines with the `try` / `catch` block below. Everything else, including the two functions and `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution, the end of main)`**
```cpp
    try {
        load_lines("archive.txt");
    } catch (const std::exception& error) {
        std::cout << "Could not read: " << error.what() << '\n';
    }

    std::cout << "Done\n";
    return 0;
}
```

</details>

## Check yourself
1. Why does the program not call a `close` function?
   <details><summary>Answer</summary>The stream closes the file in its destructor when it leaves scope (RAII).</details>
2. In which folder does `"notes.txt"` end up?
   <details><summary>Answer</summary>The terminal's current folder at the moment you start the program.</details>
3. Predict: what is printed if the `try` block contains `std::cout << "A"; throw std::runtime_error("x"); std::cout << "B";` and the `catch` prints `C`?
   <details><summary>Answer</summary><code>AC</code>: the code after <code>throw</code> never runs.</details>
4. What happens to an exception that no `catch` handles?
   <details><summary>Answer</summary>The program ends abnormally (it terminates).</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler and system.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Error: cannot open missing-file.txt for reading` | Expected: the demo file does not exist | Nothing to fix; this is the lesson's example |
| You cannot find `notes.txt` | The program was started from another folder | Run it from `lesson11`, check with `Get-Location` or `pwd` |
| `Error: cannot open notes.txt for writing` | The folder is read-only or not allowed | Use a folder you own, such as `$HOME/code101/cpp/lesson11` |
| GCC: `error: 'ofstream' is not a member of 'std'` | `#include <fstream>` is missing | Add the include |
| Typical GCC runtime text: `terminate called after throwing an instance of 'std::runtime_error'` | A `throw` has no matching `catch` | Wrap the call in `try { }` with a `catch` |

## Best practice
When a function cannot do its job, throw an exception instead of returning a made-up value, and catch standard exceptions by `const` reference. Source: C++ Core Guidelines, E.2 "Throw an exception to signal that a function can't perform its assigned task" and E.15 "Throw by value, catch exceptions from a hierarchy by reference" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
File streams: https://en.cppreference.com/w/cpp/io/basic_fstream and exceptions: https://en.cppreference.com/w/cpp/language/exceptions. Lesson 12 uses both in a complete program.

## Summary
- You wrote lines to a file and read them back.
- You checked that streams opened and learned that file names are relative to the current folder.
- You threw a `std::runtime_error` and caught it by `const` reference.
- You predicted which lines print when a file is missing.

## Next lesson
**[12. Project: expense tracker](12-expense-tracker.md):** combine classes, vectors, files and error handling in one program.
