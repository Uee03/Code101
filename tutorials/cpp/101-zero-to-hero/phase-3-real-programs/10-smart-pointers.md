---
track: cpp
level: 101
phase: 3
phase_name: real-programs
lesson: 10
title: "Smart pointers"
time: 50 min
prerequisites: [101.2.08, 101.3.09]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-3-real-programs/10-smart-pointers/
assets: []
---

# 10. Smart pointers

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- create an object with `std::make_unique` and use it through `*` and `->`;
- hand ownership of an object to a function with `std::move`;
- explain why this removes the need to write `new` and `delete`;
- predict when an owned object is destroyed.

## Recap
1. What is RAII in one sentence?
   <details><summary>Answer</summary>An object takes a resource in its constructor and gives it back in its destructor, so clean-up happens automatically.</details>
2. When does a destructor run?
   <details><summary>Answer</summary>Automatically, at the end of the object's scope.</details>
3. Why is a raw pointer in this course "borrowed, not owned"?
   <details><summary>Answer</summary>It only looks at an object owned by something else and must not be used to create or delete objects.</details>

## Why it matters
Imagine one key to a storage locker. Only one person holds it at a time; whoever holds it is responsible for emptying the locker, and handing the key over hands the responsibility over. A `std::unique_ptr` is that key. Objects whose size or lifetime is only known while the program runs live in a part of memory called the **free store** (also called the heap). Older C++ code managed it by hand with `new` and `delete`; forgetting one `delete` leaks memory and doing it twice crashes. Modern C++ lets a smart pointer do it for you with RAII.

## What you will build
A `Document` class that announces when it opens and closes, owned by a `unique_ptr`, passed to a function and destroyed at a visible moment.

## Before you start
- Recommended: lessons 08 (pointers) and 09 (classes and RAII). Compiler and CMake from lesson 01.
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-3-real-programs/10-smart-pointers/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson10`, full path `$HOME/code101/cpp/lesson10`. Open only `lesson10` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson10"`; macOS/Linux `cd "$HOME/code101/cpp/lesson10"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `smartptr`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(smartptr LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(smartptr main.cpp)
target_compile_features(smartptr PRIVATE cxx_std_20)
set_target_properties(smartptr PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(smartptr PRIVATE /W4 /permissive-)
else()
  target_compile_options(smartptr PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Document {
public:
    explicit Document(const std::string& title) : title_{title} {
        std::cout << "open " << title_ << '\n';
    }

    ~Document() {
        std::cout << "close " << title_ << '\n';
    }

    Document(const Document&) = delete;
    Document& operator=(const Document&) = delete;

    const std::string& title() const { return title_; }

private:
    std::string title_;
};

std::unique_ptr<Document> make_document(const std::string& title) {
    return std::make_unique<Document>(title);
}

void print_title(const Document& doc) {
    std::cout << "title: " << doc.title() << '\n';
}

void take_and_finish(std::unique_ptr<Document> doc) {
    std::cout << "finishing " << doc->title() << '\n';
}

int main() {
    std::unique_ptr<Document> report{make_document("report")};
    print_title(*report);

    take_and_finish(std::move(report));
    if (report == nullptr) {
        std::cout << "report was handed over\n";
    }

    {
        const auto note{std::make_unique<Document>("note")};
        print_title(*note);
    }
    std::cout << "end of main\n";
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** on which line does `close report` appear: before `report was handed over`, or at the end of `main`? And when does `close note` appear?

## Run it
In `lesson10`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\smartptr.exe`; macOS/Linux `./build/out/smartptr`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
open report
title: report
finishing report
close report
report was handed over
open note
title: note
close note
end of main
```

## How it works
1. **The old way, shown so you recognise it (do not write this).** `Document* d = new Document("x"); ... delete d;` creates the object on the free store and promises to delete it exactly once. An early `return` or an error between the two lines leaks the object, and a second `delete` crashes. This course never uses `new` or `delete` directly.
2. **`std::unique_ptr<Document>`** is a small object that **owns** one `Document`. Its destructor deletes the document, so when the `unique_ptr` is destroyed the document closes. That is RAII from lesson 09 applied to memory.
3. **`std::make_unique<Document>(title)`** creates the object and returns the `unique_ptr` that owns it. It is the standard way to create one; the arguments go to the constructor. The header is `<memory>`.
4. **Using it.** `*report` gives the object itself (as a reference), `report->title()` calls a member function (the arrow is a shortcut for `(*report).title()`). `print_title(*report)` passes the document by `const` reference, so the function only looks and ownership stays in `main`.
5. **Single owner.** A `unique_ptr` cannot be copied: two owners would both delete. To pass the object to a function that takes over, you **move** it: `std::move(report)` means "I no longer need `report`; take it". After the move, `report` is empty (it equals `nullptr`) and `take_and_finish` owns the document.
6. **When it closes.** `take_and_finish` takes the `unique_ptr` by value, so when the function ends its parameter `doc` is destroyed and the document closes at that moment. That is why `close report` comes before `report was handed over`. The `note` is owned by a `const auto` variable inside a block; it closes at the block's closing brace.
7. **Which pointer to use.** Default to a plain object or a `std::vector` (they already manage memory). When you need an object on the free store, use `unique_ptr`. `std::shared_ptr` (several owners) exists but is rarely needed; the Core Guidelines prefer `unique_ptr`.
8. Misconception: "after `std::move(report)` the variable still holds the document". It is empty; do not use `*report` afterwards without checking it.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try10` next to `lesson10` (see [Exercise folders](../../README.md#exercise-folders)), or create `try10` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(smartptr LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(smartptr main.cpp)
target_compile_features(smartptr PRIVATE cxx_std_20)
set_target_properties(smartptr PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(smartptr PRIVATE /W4 /permissive-)
else()
  target_compile_options(smartptr PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>
#include <memory>

class Ticket {
public:
    explicit Ticket(int number) : number_{number} {
        std::cout << "issue " << number_ << '\n';
    }

    ~Ticket() {
        std::cout << "void " << number_ << '\n';
    }

    Ticket(const Ticket&) = delete;
    Ticket& operator=(const Ticket&) = delete;

    int number() const { return number_; }

private:
    int number_;
};

std::unique_ptr<Ticket> make_ticket(int number) {
    // TODO: create a Ticket with this number and return the unique_ptr that owns it.
    return nullptr;
}

int main() {
    const std::unique_ptr<Ticket> ticket{make_ticket(7)};
    if (ticket == nullptr) {
        std::cout << "no ticket\n";
        return 0;
    }
    std::cout << "using ticket " << ticket->number() << '\n';
    return 0;
}
```
The starter prints `no ticket` (and the compiler warns that `number` is unused). Complete `make_ticket`. Expected output after your change:

**File: terminal output (not a saved file)**
```text
issue 7
using ticket 7
void 7
```

**Rung 2, change.** Create a second ticket with number 8 inside an inner block `{ ... }` and predict where `void 8` appears before you run it.

**Rung 3, stretch (optional).** Write a function `void redeem(std::unique_ptr<Ticket> ticket)` that prints a line and takes ownership. Predict when `void` prints for a ticket you pass with `std::move`.

<details><summary>Solution</summary>

Replace the TODO comment and the `return nullptr;` line with the single line below. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution, the make_ticket function)`**
```cpp
std::unique_ptr<Ticket> make_ticket(int number) {
    return std::make_unique<Ticket>(number);
}
```

</details>

## Check yourself
1. What does a `std::unique_ptr` do when it is destroyed?
   <details><summary>Answer</summary>It deletes the object it owns.</details>
2. Why can a `unique_ptr` not be copied?
   <details><summary>Answer</summary>Two owners would both delete the same object; there must be exactly one owner.</details>
3. Predict: after `auto b{std::move(a)};` where `a` is a `unique_ptr` that owned an object, what does `a == nullptr` give?
   <details><summary>Answer</summary><code>true</code>; <code>b</code> now owns the object.</details>
4. Predict: in this lesson's program, does `close note` print before or after `end of main`?
   <details><summary>Answer</summary>Before: <code>note</code> is destroyed at the closing brace of its block, which comes before the last line of <code>main</code>.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC: `error: use of deleted function 'std::unique_ptr<...>::unique_ptr(const std::unique_ptr<...>&)'` | A `unique_ptr` was copied | Pass `std::move(p)` to give it away, or pass `*p` as a reference to just look |
| GCC: `error: 'unique_ptr' is not a member of 'std'` (or `make_unique`) | `#include <memory>` is missing | Add the include |
| The program crashes after `std::move(p)` | `*p` was used after the move, when `p` is empty | Do not use a moved-from pointer; check it against `nullptr` |
| A `delete` or `new` shows up in your code | Old style | Use `std::make_unique` instead |
| The object closes earlier than expected | The owner went out of scope, or ownership moved into a function | Look at where the `unique_ptr` is destroyed |

## Best practice
Do not write `new` and `delete`; own free-store objects with `std::unique_ptr` created by `std::make_unique`. Source: C++ Core Guidelines, R.11 "Avoid calling new and delete explicitly", R.20 "Use unique_ptr or shared_ptr to represent ownership" and R.23 "Use make_unique() to make unique_ptrs" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
`unique_ptr`: https://en.cppreference.com/w/cpp/memory/unique_ptr. Level 201 covers `shared_ptr` and move semantics in depth.

## Summary
- You created an owned object with `std::make_unique` and used it with `*` and `->`.
- You moved ownership into a function with `std::move`.
- You predicted the exact moment each object closed.
- You explained why smart pointers replace `new` and `delete`.

## Next lesson
**[11. Files and errors](11-files-and-errors.md):** read and write text files and handle problems with exceptions.
