---
track: cpp
level: 101
phase: 3
phase_name: real-programs
lesson: 12
title: "Project: expense tracker"
time: 90 min
prerequisites: [101.2.06, 101.2.07, 101.3.09, 101.3.11]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- split a program into a header, a source file and `main.cpp`, and list the `.cpp` files in `CMakeLists.txt`;
- build a command loop that reads a line, picks a command and keeps running after a bad command;
- save and load a list of records in a text file;
- predict what the tracker prints for a short list of commands.

## Recap
1. How do you check that a file opened, and what does the program do if it did not?
   <details><summary>Answer</summary>Test the stream (<code>if (!out)</code>) and <code>throw</code> an exception such as <code>std::runtime_error</code>.</details>
2. What keeps a class's rules safe?
   <details><summary>Answer</summary>Private data and public member functions that check the rules.</details>
3. How do you catch a standard exception?
   <details><summary>Answer</summary><code>catch (const std::exception&amp; error)</code>, and <code>error.what()</code> gives the message.</details>

## Why it matters
A household keeps a notebook of what it spent. A good notebook lets you add a line, read the list, add up the total and keep it for next month. Real programs are made of the same parts you now know: a class that protects its data, containers that hold records, files that remember, exceptions that report trouble, and a loop that talks to the user. This lesson joins them.

## What you will build
A console expense tracker. You type commands such as `add 12.50 lunch`, `list`, `total`, `save` and `quit`. The expenses are stored in a file `expenses.txt` and loaded the next time you start.

## Before you start
- Recommended: lessons 06 to 11. Compiler and CMake from lesson 01.
- Time: 90 minutes in **two sittings**. The break is after Step 4: by then the library part (`expense_book.hpp` and `expense_book.cpp`) is written, and nothing can be run yet.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson12`, full path `$HOME/code101/cpp/lesson12`. Open only `lesson12` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson12"`; macOS/Linux `cd "$HOME/code101/cpp/lesson12"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with two differences: the program is called `tracker`, and `add_executable` lists **two** source files, `main.cpp` and `expense_book.cpp`. Every `.cpp` file that is part of the program must be listed.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(tracker LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(tracker main.cpp expense_book.cpp)
target_compile_features(tracker PRIVATE cxx_std_20)
set_target_properties(tracker PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(tracker PRIVATE /W4 /permissive-)
else()
  target_compile_options(tracker PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the header: the promise
A **header** (`.hpp`) describes what a piece of code offers without the bodies. Other files `#include` it. Create `expense_book.hpp`:

**File: `expense_book.hpp`**
```cpp
#pragma once

#include <string>
#include <vector>

struct Expense {
    long long cents;
    std::string label;
};

class ExpenseBook {
public:
    void add(long long cents, const std::string& label);
    long long total_cents() const;
    const std::vector<Expense>& items() const;
    void save(const std::string& path) const;
    void load(const std::string& path);

private:
    std::vector<Expense> items_;
};

std::string format_money(long long cents);
```
`#pragma once` tells the compiler to read this file only once even if several files include it. The `struct Expense` is one record: an amount in cents and a label. `ExpenseBook` lists its operations; the bodies come next. `format_money` turns 1250 into the text `12.50`.

### Step 4. Write the source file: the bodies
Create `expense_book.cpp`. It begins by including its own header, then the standard headers it needs.

**File: `expense_book.cpp`**
```cpp
#include "expense_book.hpp"

#include <fstream>
#include <iomanip>
#include <sstream>
#include <stdexcept>

void ExpenseBook::add(long long cents, const std::string& label) {
    if (cents <= 0) {
        throw std::invalid_argument("amount must be more than zero");
    }
    if (label.empty()) {
        throw std::invalid_argument("label must not be empty");
    }
    items_.push_back(Expense{cents, label});
}

long long ExpenseBook::total_cents() const {
    long long total{0};
    for (const Expense& item : items_) {
        total += item.cents;
    }
    return total;
}

const std::vector<Expense>& ExpenseBook::items() const {
    return items_;
}

void ExpenseBook::save(const std::string& path) const {
    std::ofstream out{path};
    if (!out) {
        throw std::runtime_error("cannot open " + path + " for writing");
    }
    for (const Expense& item : items_) {
        out << item.cents << ' ' << item.label << '\n';
    }
    if (!out) {
        throw std::runtime_error("failed while writing " + path);
    }
}

void ExpenseBook::load(const std::string& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error("cannot open " + path + " for reading");
    }
    std::vector<Expense> loaded;
    long long cents{};
    while (in >> cents) {
        std::string label;
        std::getline(in >> std::ws, label);
        if (cents <= 0 || label.empty()) {
            throw std::runtime_error("bad line in " + path);
        }
        loaded.push_back(Expense{cents, label});
    }
    if (!in.eof()) {
        throw std::runtime_error("bad data in " + path);
    }
    items_ = loaded;
}

std::string format_money(long long cents) {
    std::ostringstream text;
    text << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
    return text.str();
}
```
Save all files. **Break point:** you can stop here and continue later; reopen `lesson12` in VS Code when you return.

### Step 5. Write the program that talks to the user
Create `main.cpp`:

**File: `main.cpp`**
```cpp
#include <cmath>
#include <exception>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <string>

#include "expense_book.hpp"

namespace {

void print_help() {
    std::cout << "Commands:\n"
              << "  add <amount> <label>   example: add 12.50 lunch\n"
              << "  list                   show every expense\n"
              << "  total                  show the sum\n"
              << "  save                   write expenses.txt now\n"
              << "  help                   show this list\n"
              << "  quit                   save and leave\n";
}

void handle_add(ExpenseBook& book, std::istringstream& args) {
    double amount{};
    if (!(args >> amount) || amount <= 0.0 || amount > 1000000.0) {
        std::cout << "Amount must be a number from 0.01 to 1000000.\n";
        return;
    }
    std::string label;
    std::getline(args >> std::ws, label);
    const long long cents{std::llround(amount * 100.0)};
    book.add(cents, label);
    std::cout << "Added " << format_money(cents) << " for " << label << '\n';
}

void print_list(const ExpenseBook& book) {
    if (book.items().empty()) {
        std::cout << "No expenses yet.\n";
        return;
    }
    int number{1};
    for (const Expense& item : book.items()) {
        std::cout << number << ". " << format_money(item.cents) << "  " << item.label << '\n';
        ++number;
    }
}

}  // namespace

int main() {
    const std::string data_file{"expenses.txt"};
    ExpenseBook book;

    try {
        if (std::filesystem::exists(data_file)) {
            book.load(data_file);
            std::cout << "Loaded " << book.items().size() << " expense(s) from " << data_file << '\n';
        }
    } catch (const std::exception& error) {
        std::cout << "Could not load " << data_file << ": " << error.what() << '\n';
        return 1;
    }

    std::cout << "Expense tracker. Type help for commands.\n";
    std::string line;
    while (true) {
        std::cout << "> ";
        if (!std::getline(std::cin, line)) {
            break;
        }
        std::istringstream args{line};
        std::string command;
        args >> command;

        try {
            if (command.empty()) {
                continue;
            }
            if (command == "add") {
                handle_add(book, args);
            } else if (command == "list") {
                print_list(book);
            } else if (command == "total") {
                std::cout << "Total: " << format_money(book.total_cents()) << '\n';
            } else if (command == "save") {
                book.save(data_file);
                std::cout << "Saved to " << data_file << '\n';
            } else if (command == "help") {
                print_help();
            } else if (command == "quit") {
                break;
            } else {
                std::cout << "Unknown command. Type help.\n";
            }
        } catch (const std::exception& error) {
            std::cout << "Error: " << error.what() << '\n';
        }
    }

    try {
        book.save(data_file);
    } catch (const std::exception& error) {
        std::cout << "Could not save: " << error.what() << '\n';
        return 1;
    }
    std::cout << "Saved " << book.items().size() << " expense(s) to " << data_file << '\n';
    return 0;
}
```
Save all four files.

### Step 6. Predict, then build and run
**Predict first:** you will type `add 12.50 lunch`, `add 3.20 tea with milk`, `list`, `total` and `quit`. What will the total be, and what will `list` show?

## Run it
In `lesson12`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it from `lesson12`: Windows PowerShell `.\build\out\tracker.exe`; macOS/Linux `./build/out/tracker`. At each `> ` prompt type one of the commands above and press Enter. The program output only (without your typing) is:

**File: terminal output (program output only, not a saved file)**
```text
Expense tracker. Type help for commands.
> Added 12.50 for lunch
> Added 3.20 for tea with milk
> 1. 12.50  lunch
2. 3.20  tea with milk
> Total: 15.70
> Saved 2 expense(s) to expenses.txt
```
On your screen your typed commands appear after each `> `. A new file `expenses.txt` is now in `lesson12`. Its content is one expense per line, the amount in cents, a space and the label:

**File: `expenses.txt (created by the program)`**
```text
1250 lunch
320 tea with milk
```
Run the program a second time and type `list` then `quit`. The program loads the file first:

**File: terminal output (program output only, second run)**
```text
Loaded 2 expense(s) from expenses.txt
Expense tracker. Type help for commands.
> 1. 12.50  lunch
2. 3.20  tea with milk
> Saved 2 expense(s) to expenses.txt
```
Try a few mistakes on purpose: `add abc` prints `Amount must be a number from 0.01 to 1000000.`, `add 5` prints `Error: label must not be empty`, and `dance` prints `Unknown command. Type help.` The program keeps running after each of them. To end input without `quit`, press Ctrl+Z then Enter (Windows) or Ctrl+D (macOS/Linux); the program saves and leaves too.

## How it works
1. **Three files, three jobs.** `expense_book.hpp` is the interface (what exists), `expense_book.cpp` holds the bodies, and `main.cpp` is the user interface. `main.cpp` writes `#include "expense_book.hpp"` with **quotes** because it is your own file next to it; standard headers use `< >`. `ExpenseBook::add` means "the function `add` that belongs to the class `ExpenseBook`". CMake compiles each `.cpp` file separately and the linker joins them, which is why both are listed in `add_executable`.
2. **The class protects the rules.** `add` throws `std::invalid_argument` for zero or negative amounts and empty labels, so the book can never hold a bad record. The vector `items_` is private; `items()` returns a `const` reference so other code can read but not change it.
3. **Money in cents.** The user types `12.50` as a `double`. `std::llround(amount * 100.0)` rounds to the nearest whole number of cents (1250) once, at the edge of the program; everything after that, including the file, uses whole cents. `format_money` turns the cents back into text with an `std::ostringstream` (a stream that writes into a string instead of the screen).
4. **Saving and loading.** `save` writes `cents label` per line, with the same stream code as lesson 11. `load` reads the number with `>>`, skips the space with `std::ws`, and reads the rest of the line as the label with `getline`. It reads into a temporary vector `loaded` and replaces `items_` only at the end, so a damaged file cannot leave the book half-filled. A file that does not parse throws, and `main` reports `Could not load ...` and returns 1.
5. **First run.** `std::filesystem::exists` (from `<filesystem>`) tells `main` whether `expenses.txt` is there, so a missing file is not an error: the book simply starts empty.
6. **The command loop.** Each round prints the prompt `> `, reads a line with `std::getline`, and stops if reading fails (the end of the input). `std::istringstream args{line}` turns the line into a stream you can read words from; `args >> command` takes the first word. An `if / else if` chain picks the action. For `add`, `handle_add` reads the amount and then the rest of the line as the label, so labels may contain spaces.
7. **Bad commands do not kill the program.** The `try` inside the loop catches any exception from a command, prints `Error: ...` and goes on to the next round. After the loop, `quit` or the end of input leads to a final save.
8. **`namespace { ... }`** wraps helper functions so they are private to `main.cpp`. It is the modern way to say "only this file uses these".
9. **Limits (kept simple on purpose).** Labels must not be empty and should not contain line breaks; if you edit `expenses.txt` by hand and break the format, the program refuses to load it and prints the reason. Delete or fix the file to continue. Amounts are limited to 1000000. There is no command to delete an expense yet: that is the stretch exercise.

## Try it
**Rung 1, guided.** Add a `count` command that prints how many expenses there are. All four files stay the same except `main.cpp`, where the starter has a TODO comment inside the `save` branch. To get the starter, copy `exercise/starter` and rename it `try12` next to `lesson12` (see [Exercise folders](../../README.md#exercise-folders)). Without the source, copy your finished `lesson12` folder, rename the copy `try12`, delete its `build` and `expenses.txt`, and add the two comment lines shown below. The region in the starter looks like this:

**File: `main.cpp (starter, the save branch)`**
```cpp
            } else if (command == "save") {
                book.save(data_file);
                std::cout << "Saved to " << data_file << '\n';
                // TODO: after this branch, add a branch for the command "count" that
                // prints  Count: 2  when the book holds two expenses.
            } else if (command == "help") {
```
Before your change, `count` answers `Unknown command. Type help.`. Build in `try12` and run it with the commands `add 5 coffee`, `count`, `quit`. Expected program output after your change:

**File: terminal output (program output only, not a saved file)**
```text
Expense tracker. Type help for commands.
> Added 5.00 for coffee
> Count: 1
> Saved 1 expense(s) to expenses.txt
```

**Rung 2, change.** Show the count in the `help` text by adding a `count` line to `print_help`.

**Rung 3, stretch (optional).** Add a `remove <number>` command that deletes the numbered expense from the list. Decide where the work belongs (in `ExpenseBook` or in `main.cpp`) and what should happen for a number that does not exist. Look up `std::vector::erase` on cppreference.

<details><summary>Solution</summary>

Only `main.cpp` changes; the other three files are identical to the starter. Replace the starter's two TODO comment lines with a new branch, so that the region reads:

**File: `main.cpp (solution, the save and count branches)`**
```cpp
            } else if (command == "save") {
                book.save(data_file);
                std::cout << "Saved to " << data_file << '\n';
            } else if (command == "count") {
                std::cout << "Count: " << book.items().size() << '\n';
            } else if (command == "help") {
```

</details>

## Check yourself
1. Why is `expense_book.cpp` listed in `add_executable`?
   <details><summary>Answer</summary>Every <code>.cpp</code> file that belongs to the program must be compiled and linked; CMake only knows the files you list.</details>
2. Why is money stored in cents as a whole number?
   <details><summary>Answer</summary>Whole numbers do not accumulate the tiny rounding errors that <code>double</code> can, so totals are exact.</details>
3. Predict: what does the tracker print for the command `add -5 rent`?
   <details><summary>Answer</summary><code>Amount must be a number from 0.01 to 1000000.</code>, because the amount is not greater than zero; nothing is added.</details>
4. Why does a wrong command not end the program?
   <details><summary>Answer</summary>The command is run inside a <code>try</code> in the loop whose <code>catch</code> prints the error and lets the loop continue.</details>
5. What does `load` do when the file contains a line that is not a number?
   <details><summary>Answer</summary>It throws a <code>std::runtime_error</code> ("bad data in ..."), so <code>main</code> prints <code>Could not load ...</code> and ends with 1.</details>

## Phase review (lessons 09 to 12)
1. Which two C++ features make sure a file is closed even if an error is thrown halfway through writing? <details><summary>Answer</summary>RAII (the stream's destructor closes the file) and exceptions that unwind the scope.</details>
2. A function should only look at a <code>std::vector</code> that belongs to someone else. How do you declare the parameter? <details><summary>Answer</summary><code>const std::vector&lt;T&gt;&amp;</code>.</details>
3. When would you choose `std::unique_ptr` for something in this tracker? <details><summary>Answer</summary>Only if an object had to live on the free store; the tracker needs none, since vectors and strings manage their own memory.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler and system.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC/Clang linker: `undefined reference to 'ExpenseBook::add(...)'`; MSVC: `error LNK2019: unresolved external symbol` | `expense_book.cpp` is missing from `add_executable` | List both `.cpp` files in `CMakeLists.txt` |
| `fatal error: expense_book.hpp: No such file or directory` | The header is in another folder or misspelt | Keep all four files in the project folder |
| GCC: `error: 'filesystem' is not a member of 'std'` | `#include <filesystem>` is missing | Add the include |
| `Could not load expenses.txt: bad data in expenses.txt` | `expenses.txt` was edited and no longer follows `cents label` | Fix the file, or delete it to start again |
| `Unknown command. Type help.` after typing `Add 5 tea` | Command names are case-sensitive | Type `add` in lower case |
| `expenses.txt` not found next to the code | The program was started from another folder | Run it from `lesson12` |

## Best practice
Give every header an include guard (`#pragma once` is the common modern form), keep bodies in `.cpp` files, and let `main` only wire the pieces together. Source: C++ Core Guidelines, SF.8 "Use #include guards for all .h files" and SF.1 "Use a .cpp suffix for code files and .h for interface files if your project doesn't already follow another convention" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Level 201 builds on this: modern C++ features, templates, tests with a test framework and desktop windows with Qt or Dear ImGui. Until then: `std::filesystem` https://en.cppreference.com/w/cpp/filesystem and string streams https://en.cppreference.com/w/cpp/io/basic_istringstream

## Summary
- You split a program into a header, a source file and `main.cpp` and built all three with CMake.
- You kept money as whole cents and protected the data with a class.
- You saved and loaded records in a text file and reported problems with exceptions.
- You ran a command loop that survives bad input and predicted its output.

## Next lesson
You have finished C++ 101. The C++ 201 track (modern C++, templates, tests, desktop windows) is the next level; it is planned and not yet written. Meanwhile repeat lessons 09 to 11 by adding a `remove` command.
