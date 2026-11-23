---
track: cpp
level: 101
phase: 3
phase_name: real-programs
lesson: 09
title: "Classes and RAII"
time: 60 min
prerequisites: [101.2.05, 101.2.08]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-3-real-programs/09-classes-and-raii/
assets: []
---

# 09. Classes and RAII

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a `class` with private data, a constructor and member functions that protect a rule;
- mark member functions that only read with `const`;
- explain what a destructor is and when it runs;
- predict the order in which constructors and destructors print their messages.

## Recap
1. What does `nullptr` mean, and what must you do before dereferencing a pointer that might hold it?
   <details><summary>Answer</summary>It means "points at nothing"; check <code>pointer != nullptr</code> first.</details>
2. Which is the default choice for a function parameter that must never be "nothing": a pointer or a reference?
   <details><summary>Answer</summary>A reference (or a value).</details>
3. What does <code>struct</code> let you do that separate variables do not?
   <details><summary>Answer</summary>Bundle related values into one named type.</details>

## Why it matters
A bank does not let you scribble on the ledger; you ask a clerk, who checks the rules (no negative balance) before changing anything. A **class** is that clerk: it keeps its data private and offers a few safe operations. And think of a hotel key card that switches the room lights off when you leave, whether you remember or not. C++ has the same idea for resources such as files, memory and locks: **RAII**, "Resource Acquisition Is Initialisation": take the resource when the object is created, give it back when the object disappears. It is the most important idea in C++.

## What you will build
A bank `Account` that refuses impossible withdrawals, and a `ScopeLogger` that prints a message when it appears and when it disappears.

## Before you start
- Recommended: lessons 05 (functions and references) and 08 (pointers and references). Compiler and CMake from lesson 01.
- Time: 60 minutes. Take a break after Step 3 if you like.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-3-real-programs/09-classes-and-raii/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson09`, full path `$HOME/code101/cpp/lesson09`. Open only `lesson09` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson09"`; macOS/Linux `cd "$HOME/code101/cpp/lesson09"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `account`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(account LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(account main.cpp)
target_compile_features(account PRIVATE cxx_std_20)
set_target_properties(account PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(account PRIVATE /W4 /permissive-)
else()
  target_compile_options(account PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <iomanip>
#include <iostream>
#include <string>

class Account {
public:
    explicit Account(const std::string& owner) : owner_{owner} {}

    bool deposit(long long cents) {
        if (cents <= 0) {
            return false;
        }
        balance_cents_ += cents;
        return true;
    }

    bool withdraw(long long cents) {
        if (cents <= 0 || cents > balance_cents_) {
            return false;
        }
        balance_cents_ -= cents;
        return true;
    }

    long long balance_cents() const { return balance_cents_; }
    const std::string& owner() const { return owner_; }

private:
    std::string owner_;
    long long balance_cents_{0};
};

class ScopeLogger {
public:
    explicit ScopeLogger(const std::string& name) : name_{name} {
        std::cout << "enter " << name_ << '\n';
    }

    ~ScopeLogger() {
        std::cout << "leave " << name_ << '\n';
    }

    ScopeLogger(const ScopeLogger&) = delete;
    ScopeLogger& operator=(const ScopeLogger&) = delete;

private:
    std::string name_;
};

void print_money(long long cents) {
    std::cout << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
}

int main() {
    ScopeLogger outer{"main"};

    Account account{"Ada"};
    account.deposit(5000);
    const bool ok{account.withdraw(1250)};
    std::cout << "Withdraw 12.50 worked: " << std::boolalpha << ok << '\n';
    const bool too_much{account.withdraw(100000)};
    std::cout << "Withdraw 1000.00 worked: " << too_much << '\n';
    std::cout << account.owner() << " has ";
    print_money(account.balance_cents());
    std::cout << '\n';

    {
        ScopeLogger inner{"inner block"};
        std::cout << "working inside the block\n";
    }
    std::cout << "after the block\n";
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** in what order will `enter` and `leave` lines appear? Will `leave main` be the very first or the very last line? Will the 1000.00 withdrawal work if the balance is 37.50?

## Run it
In `lesson09`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\account.exe`; macOS/Linux `./build/out/account`. Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
enter main
Withdraw 12.50 worked: true
Withdraw 1000.00 worked: false
Ada has 37.50
enter inner block
working inside the block
leave inner block
after the block
leave main
```

## How it works
1. **`class`** defines your own type. Everything after `public:` can be used by anyone; everything after `private:` can only be used by the class's own functions. The data (`owner_`, `balance_cents_`) is private, so the only way to change the balance is `deposit` or `withdraw`. Those functions check the rule (no zero or negative amounts, no overdraft), so the balance can never become invalid. A rule that must always hold is an **invariant**. By convention private data members end in `_`.
2. **Money as whole cents.** The balance is a `long long` number of cents, so 37.50 is stored as 3750. Whole numbers do not drift the way `double` can, which matters for money. `print_money` splits the cents back into units and two padded digits with `std::setw(2)` (width 2) and `std::setfill('0')` (pad with zeros).
3. **Constructor.** `Account(const std::string& owner)` has the class's name and no return type; it runs when you write `Account account{"Ada"};`. `: owner_{owner}` is the **member initialiser list**: it sets `owner_` while the object is being built. `balance_cents_{0}` gives the balance a starting value. `explicit` stops accidental conversions, for example a plain string quietly becoming an `Account`; make one-argument constructors `explicit` by default.
4. **`const` member functions.** `long long balance_cents() const` promises not to change the object, so it can be used on constant objects and tells the reader "this only looks".
5. **Destructor.** `~ScopeLogger()` (a tilde and the class name) runs **automatically** when the object's **scope** ends (the closing brace of the block where it was created). You never call it yourself. Objects are destroyed in the reverse order they were created, which is why `leave main` comes last: `outer` was created first.
6. **RAII.** `ScopeLogger` shows the pattern with a harmless resource, a printed message. Real classes do the same with real resources: a file is opened in the constructor and closed in the destructor, so the file is closed on every path out of the block, even on an early `return` or an error. You cannot forget to clean up because you never write the clean-up call.
7. `ScopeLogger(const ScopeLogger&) = delete;` and the next line forbid copying a logger; a copy would later print a second `leave` for one `enter`. You may ignore the exact spelling for now: it says "this type must not be copied".
8. Misconception: "the destructor is a function I call to delete the object". It is not; the compiler calls it for you at the end of the scope.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try09` next to `lesson09` (see [Exercise folders](../../README.md#exercise-folders)), or create `try09` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(account LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(account main.cpp)
target_compile_features(account PRIVATE cxx_std_20)
set_target_properties(account PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(account PRIVATE /W4 /permissive-)
else()
  target_compile_options(account PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iomanip>
#include <iostream>

class Wallet {
public:
    explicit Wallet(long long cents) : balance_cents_{cents} {}

    bool spend(long long cents) {
        // TODO: return false when cents is zero or less, or more than the balance.
        // Otherwise subtract cents from the balance and return true.
        return false;
    }

    long long balance_cents() const { return balance_cents_; }

private:
    long long balance_cents_;
};

void print_money(long long cents) {
    std::cout << cents / 100 << '.' << std::setw(2) << std::setfill('0') << cents % 100;
}

int main() {
    Wallet wallet{2000};
    const bool first{wallet.spend(500)};
    const bool second{wallet.spend(5000)};
    std::cout << std::boolalpha;
    std::cout << "Spent 5.00: " << first << '\n';
    std::cout << "Spent 50.00: " << second << '\n';
    std::cout << "Left: ";
    print_money(wallet.balance_cents());
    std::cout << '\n';
    return 0;
}
```
The starter prints `false` twice and `Left: 20.00`; the compiler warns that `cents` is unused until you finish. Complete `spend`. Expected output after your change:

**File: terminal output (not a saved file)**
```text
Spent 5.00: true
Spent 50.00: false
Left: 15.00
```

**Rung 2, change.** Add a `bool add(long long cents)` function that refuses zero or negative amounts, and use it to add 10.00 before the first spend.

**Rung 3, stretch (optional).** Add a `const` member function `bool can_afford(long long cents) const` and use it inside `spend`. Why is it good that it is `const`?

<details><summary>Solution</summary>

Replace the two TODO comment lines and the `return false;` line inside `spend` with the lines below. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution, the spend function)`**
```cpp
    bool spend(long long cents) {
        if (cents <= 0 || cents > balance_cents_) {
            return false;
        }
        balance_cents_ -= cents;
        return true;
    }
```

</details>

## Check yourself
1. Why is the balance `private`?
   <details><summary>Answer</summary>So the only way to change it is through functions that check the rules, keeping the balance valid.</details>
2. When does a destructor run?
   <details><summary>Answer</summary>Automatically, when the object's scope ends (or the object is otherwise destroyed).</details>
3. Predict: two loggers `a` then `b` are created in one block. In which order do their `leave` lines print?
   <details><summary>Answer</summary><code>b</code> first, then <code>a</code> (reverse order of creation).</details>
4. What does `const` after a member function's parentheses promise?
   <details><summary>Answer</summary>The function does not change the object.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| GCC: `error: 'long long Account::balance_cents_' is private within this context` (MSVC: `error C2248: ... cannot access private member`) | Code outside the class touched private data | Use a public member function |
| GCC: `error: expected ';' after class definition` | The `;` after the closing `}` of a class is missing | Write `};` |
| GCC: `error: use of deleted function 'ScopeLogger::ScopeLogger(const ScopeLogger&)'` | A `ScopeLogger` was copied | Pass it by reference, or do not copy |
| GCC: `error: passing 'const Account' as 'this' argument discards qualifiers` | A non-`const` member function was called on a `const` object | Mark read-only member functions `const` |
| The `leave` line is missing | The program stopped early, or the object was never created in that scope | Check where the object is declared |

## Best practice
Make a type a `class` when it has a rule to protect, keep its data private, and let constructors and destructors manage resources so clean-up cannot be forgotten. Source: C++ Core Guidelines, C.2 "Use class if the class has an invariant; use struct if the data members can vary independently" and R.1 "Manage resources automatically using resource handles and RAII" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
Classes: https://en.cppreference.com/w/cpp/language/classes. Lesson 10 uses RAII to own memory safely; lesson 12 uses a class in a real program.

## Summary
- You wrote a class with private data, a constructor and `const` member functions.
- You kept an invariant (no overdraft) inside `withdraw`.
- You saw a destructor run automatically at the end of a scope and predicted the order of messages.
- You explained RAII in one sentence.

## Next lesson
**[10. Smart pointers](10-smart-pointers.md):** own an object on the free store with `std::unique_ptr` and never write `delete`.
