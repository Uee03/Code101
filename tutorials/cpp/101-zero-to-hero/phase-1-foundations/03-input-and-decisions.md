---
track: cpp
level: 101
phase: 1
phase_name: foundations
lesson: 03
title: "Input and decisions"
time: 50 min
prerequisites: [101.1.02]
versions: { cmake: "3.28 or newer", cxx: "C++20" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-1-foundations/03-input-and-decisions/
assets: []
---

# 03. Input and decisions

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- read a whole number and a line of text from the keyboard with `std::cin`;
- detect that the user typed something that is not a number;
- choose between actions with `if`, `else if` and `else`, combining tests with `&&`, `||` and `!`;
- predict which branch of an `if` chain runs for a given input.

## Recap
1. Which type holds text, and which header does it need?
   <details><summary>Answer</summary><code>std::string</code>, from <code>&lt;string&gt;</code>.</details>
2. What does <code>const</code> promise?
   <details><summary>Answer</summary>The value never changes after it is set.</details>
3. What do you write to start a variable <code>count</code> at zero?
   <details><summary>Answer</summary><code>int count{};</code> or <code>int count{0};</code>.</details>

## Why it matters
A clerk at a ticket office asks your age and then applies rules: small children travel free, children pay less, seniors get a discount. A program becomes useful when it can ask a question and choose what to do with the answer. This lesson gives your program ears (input) and a brain (decisions).

## What you will build
A ticket-price program: it asks for a name and an age and prints the price.

## Before you start
- Recommended: lesson 02 (types and `const`). Compiler and CMake from lesson 01.
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-1-foundations/03-input-and-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson03`, full path `$HOME/code101/cpp/lesson03`. Open only `lesson03` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/cpp/lesson03"`; macOS/Linux `cd "$HOME/code101/cpp/lesson03"`.

### Step 2. Write the build recipe
`CMakeLists.txt` is the lesson 01 file with one difference: the program is called `ticket`.

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(ticket LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(ticket main.cpp)
target_compile_features(ticket PRIVATE cxx_std_20)
set_target_properties(ticket PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(ticket PRIVATE /W4 /permissive-)
else()
  target_compile_options(ticket PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

### Step 3. Write the program
**File: `main.cpp`**
```cpp
#include <iostream>
#include <string>

int main() {
    std::cout << "Your name: ";
    std::string name;
    std::getline(std::cin, name);

    std::cout << "Your age in years: ";
    int age{};
    if (!(std::cin >> age)) {
        std::cout << "That was not a whole number.\n";
        return 1;
    }

    if (age < 0 || age > 120) {
        std::cout << "Please enter an age from 0 to 120.\n";
        return 1;
    }

    int price{};
    if (age < 5) {
        price = 0;
    } else if (age < 18) {
        price = 6;
    } else if (age >= 65) {
        price = 7;
    } else {
        price = 12;
    }

    std::cout << "Hello, " << name << ". Your ticket costs " << price << ".\n";
    return 0;
}
```
Save both files.

### Step 4. Predict, then build and run
**Predict first:** what will the program print for the name `Ada` and age `30`? For age `10`? For age `70`? For age `200`? Write your guesses down.

## Run it
In `lesson03`:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
(MSYS2 users add `-G Ninja` to the first command.) Run it: Windows PowerShell `.\build\out\ticket.exe`; macOS/Linux `./build/out/ticket`. The program waits for you. Type `Ada` and press Enter, then type `30` and press Enter. On your screen your own typing appears between the prompts:

**File: terminal (screen with your typing, not a saved file)**
```text
Your name: Ada
Your age in years: 30
Hello, Ada. Your ticket costs 12.
```
The text the program itself wrote is the following (your typing and the Enter key presses are not part of it):

**File: terminal output (program output only, not a saved file)**
```text
Your name: Your age in years: Hello, Ada. Your ticket costs 12.
```
Run it again with other ages (10, 70, 200) and with the word `abc` as the age to check your predictions.

## How it works
1. **Input.** `std::cin` is the **standard input stream**: what you type in the terminal. `std::cin >> age` reads one whole number into `age`; it skips spaces and newlines before the number and stops at the next space. `std::getline(std::cin, name)` reads a whole line, spaces included, up to the Enter key; that is why it is used for a name such as `Ada Lovelace`.
2. **Did the reading work?** If you type `abc` where a number is expected, `std::cin >> age` fails and the stream goes into a **failed state**. Using the stream as a true/false condition asks "is it still fine?", so `!(std::cin >> age)` (the `!` means "not") reads as "if reading the age did not work". The program then prints a message and ends with `return 1;`. A result other than 0 tells the operating system "something went wrong".
3. **Decisions.** `if (condition) { ... }` runs its block only when the condition is true. The comparison operators are `<` (less), `>` (greater), `<=`, `>=`, `==` (equal) and `!=` (not equal).
4. **Combining tests.** `||` means "or": `age < 0 || age > 120` is true if either test is true. `&&` means "and" (both must be true), and `!` means "not".
5. **A chain.** In `if / else if / else`, the computer tests from the top and runs the **first** block whose test is true, then skips the rest. That is why `age < 18` needs no `age >= 5` check: a smaller age was already handled by the first branch. The last `else` catches everything that is left (ages 18 to 64).
6. Misconception: `=` and `==` are not the same. `=` stores a value; `==` asks a question. `if (age = 5)` stores 5 into `age` and is always true; compilers usually warn about it.
7. The `int price{};` line starts at 0 and every branch of the chain sets it, so it always has a meaningful value when printed.

## Try it
**Rung 1, guided.** Copy `exercise/starter` and rename it `try03` next to `lesson03` (see [Exercise folders](../../README.md#exercise-folders)), or create `try03` and type these files. `CMakeLists.txt` is the Step 2 file again.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(ticket LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(ticket main.cpp)
target_compile_features(ticket PRIVATE cxx_std_20)
set_target_properties(ticket PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(ticket PRIVATE /W4 /permissive-)
else()
  target_compile_options(ticket PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>
#include <string>

int main() {
    std::cout << "Enter a score from 0 to 100: ";
    int score{};
    if (!(std::cin >> score)) {
        std::cout << "That was not a whole number.\n";
        return 1;
    }
    if (score < 0 || score > 100) {
        std::cout << "The score must be from 0 to 100.\n";
        return 1;
    }

    std::string grade{"?"};
    // TODO: set grade to "A" for 90 or more, "B" for 75 to 89, "C" for 50 to 74
    // and "Try again" for anything below 50.

    std::cout << "Grade: " << grade << '\n';
    return 0;
}
```
Build and run, type `82` and press Enter. Before your change the grade is `?`. After your change the program output only (without your typing) is:

**File: terminal output (program output only, not a saved file)**
```text
Enter a score from 0 to 100: Grade: B
```

**Rung 2, change.** Add a top grade `Perfect` for exactly 100. Test with 100 and 99.

**Rung 3, stretch (optional).** Reject the age or score `-1` with a friendlier message that tells the user what is allowed. Decide where in the program that check belongs.

<details><summary>Solution</summary>

Replace the starter lines from `std::string grade{"?"};` through the TODO comment with the block below. Everything else, including `CMakeLists.txt`, stays as in the starter.

**File: `main.cpp (solution, replacement region)`**
```cpp
    std::string grade{"Try again"};
    if (score >= 90) {
        grade = "A";
    } else if (score >= 75) {
        grade = "B";
    } else if (score >= 50) {
        grade = "C";
    }
```

</details>

## Check yourself
1. What is the difference between `std::cin >> name` and `std::getline(std::cin, name)` for the input `Ada Lovelace`?
   <details><summary>Answer</summary><code>&gt;&gt;</code> stops at the space and stores <code>Ada</code>; <code>getline</code> stores the whole line <code>Ada Lovelace</code>.</details>
2. What does `!(std::cin >> age)` mean in words?
   <details><summary>Answer</summary>"If reading the age did not work."</details>
3. Predict: which price is printed for age 17? For age 65?
   <details><summary>Answer</summary>17 gives 6 (the <code>age &lt; 18</code> branch); 65 gives 7 (the <code>age &gt;= 65</code> branch).</details>
4. Why does the order of the branches matter in an `if / else if` chain?
   <details><summary>Answer</summary>The first true test wins and later ones are skipped, so earlier branches limit what later ones see.</details>

## Common mistakes
The messages are typical; exact wording depends on your compiler.

| Symptom or error text | Cause | Fix |
|---|---|---|
| The program prints `That was not a whole number.` | You typed letters, or nothing, where a number was expected | Type digits only, for example `30` |
| You type `15%` or `30 years` and the program accepts it | `>>` reads the digits it can use and leaves the rest unread | Type only the number |
| GCC warning: `suggest parentheses around assignment used as truth value` | You wrote `=` where you meant `==` inside an `if` | Use `==` to compare |
| If you read the age first and the name second, the name comes out empty | `>>` leaves the Enter key press in the input and `getline` reads that empty rest of the line | Ask for text with `getline` first, as this program does. (Reading text after a number needs an extra step that this course does not cover at level 101.) |
| `.\build\out\ticket.exe` not recognised | Build failed or wrong folder | Scroll up in the build output for the first `error`; use the recovery command in Step 1 |

## Best practice
Give numbers a name instead of leaving them in the middle of the code: `5`, `18`, `65` and `12` are "magic constants". For example `const int senior_age{65};` explains itself and can be changed in one place. Source: C++ Core Guidelines, ES.45 "Avoid magic constants; use symbolic constants" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
`switch` is an alternative to a long `if` chain when you compare one whole number against fixed values: https://en.cppreference.com/w/cpp/language/switch. Input streams: https://en.cppreference.com/w/cpp/io/basic_istream

## Summary
- You read a name with `std::getline` and a number with `std::cin >> age`.
- You checked that the number was really read and ended with `return 1;` when it was not.
- You wrote an `if / else if / else` chain and combined tests with `||`.
- You predicted which branch runs for ages 10, 30, 70 and 200.

## Next lesson
**[04. Loops](04-loops.md):** repeat actions with `for` and `while`.
