---
track: cpp
level: 101
phase: 1
phase_name: foundations
lesson: 01
title: "Hello, C++"
time: 90 min
prerequisites: [none]
versions: { cmake: "3.28 or newer", cxx: "C++20 (GCC 11+, Clang 14+, MSVC from Visual Studio 2022)" }
verified: not yet run
source: source/cpp/101-zero-to-hero/phase-1-foundations/01-hello-cpp/
assets: []
---

# 01. Hello, C++

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- install a C++ compiler and CMake on your own computer and check that both work;
- create a two-file project (`main.cpp` and `CMakeLists.txt`) and build it with two commands;
- run your first program and explain each line of it;
- change the text it prints, rebuild and see the new result.

## Recap
None, this is the start. You need no earlier lesson and no programming experience.

## Why it matters
Think of a recipe written in your own language and a chef who only understands a very different one. A **compiler** is the translator: it turns the text you write into instructions the processor can follow. C++ is used where speed and control matter (games, desktop applications, tools, embedded devices), and every C++ program starts with this same translate-and-run cycle. Once the cycle works on your machine, every later lesson is just "write, build, run".

## What you will build
A tiny program that prints one line of text, built the way real C++ projects are built (with CMake). Its output:

```text
Hello, C++!
```

## Before you start
- A computer running Windows 10 or 11, macOS, or Linux, and an internet connection for downloads.
- Time: about 90 minutes for a first-timer. Most of it is downloading and installing; the program itself takes 15 minutes. You may stop after Step 6 and continue later.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-1-foundations/01-hello-cpp/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains folders, saving, building and running supplied examples.
- No art and no libraries: only the C++ standard library that comes with the compiler.

## Steps

### Step 1. Open a terminal
A **terminal** is a window where you type a command and press Enter; the computer prints the answer as text. The text just before your cursor (for example `PS C:\Users\you>` or `you@computer:~$`) is the **prompt**. It shows where you are and is not part of the command.

- **Windows:** press the Windows key, type `PowerShell`, press Enter.
- **macOS:** press Cmd+Space, type `Terminal`, press Enter.
- **Linux:** press Ctrl+Alt+T, or find **Terminal** in the application menu.

Type this and press Enter to see your **current folder** (the folder a command works in):

**File: terminal (not a saved file)**
```text
Get-Location
```
On macOS and Linux type `pwd` instead. Expected result: one line with a folder path such as your user folder.

### Step 2. Install a compiler and CMake
**CMake** is a build tool: it reads a recipe file called `CMakeLists.txt`, works out which files to compile, and calls your compiler with the right options. It works the same on every operating system, which is why this course uses it.

You need a **C++20 compiler** and **CMake 3.28 or newer**. Pick your system. After any install, **close the terminal and open a new one** so it sees the new programs.

#### Windows (recommended route: Microsoft C++ Build Tools)
In PowerShell run the two commands one after the other. Windows may ask "Do you want to allow this app to make changes?": choose **Yes**. The second command downloads several gigabytes and can take 10 to 30 minutes.

**File: terminal (not a saved file)**
```powershell
winget install --id Kitware.CMake -e
winget install --id Microsoft.VisualStudio.BuildTools -e --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```
`winget` is Windows' package installer; `-e` means "exact match of the id"; `--override` passes options to the Visual Studio installer: `--passive` shows progress without questions, `--wait` keeps the command running until it is done, and `--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended` chooses the "Desktop development with C++" tools.

If `winget` is not available, install both by hand: download CMake from https://cmake.org/download/ (choose the Windows x64 installer and tick **Add CMake to the system PATH**), and **Build Tools for Visual Studio** from https://visualstudio.microsoft.com/downloads/ (in the installer tick **Desktop development with C++**). Microsoft's page: https://learn.microsoft.com/en-us/cpp/overview/acquire-msvc

#### Windows (alternative route: MSYS2 with GCC)
Use this if you prefer GCC. Download the installer from https://www.msys2.org/, run it with the default choices, and finish. From the Start menu open **MSYS2 UCRT64** (not the other MSYS2 icons), then run:

**File: terminal (not a saved file)**
```bash
pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
```
Answer `Y` when asked. In this route you work inside the MSYS2 UCRT64 window, add `-G Ninja` to the configure command, and run programs as `./build/out/NAME.exe`. Create your lesson folders under your Windows user folder so VS Code can open them:

**File: terminal (not a saved file)**
```bash
mkdir -p "$(cygpath "$USERPROFILE")/code101/cpp/lesson01"
cd "$(cygpath "$USERPROFILE")/code101/cpp/lesson01"
```

#### macOS
In Terminal run:

**File: terminal (not a saved file)**
```bash
xcode-select --install
```
A window asks you to install the command line developer tools: choose **Install**, accept the licence and wait a few minutes. (If the command says the tools are already installed, that is fine.) Then install CMake. With Homebrew (https://brew.sh) run `brew install cmake`. Without Homebrew, download the macOS `.dmg` from https://cmake.org/download/, drag **CMake** to Applications, open it once, and use its menu **Tools > How to Install For Command Line Use**.

#### Linux
In a terminal on Debian or Ubuntu (Ubuntu 24.04 ships CMake 3.28):

**File: terminal (not a saved file)**
```bash
sudo apt update
sudo apt install build-essential cmake
```
`sudo` runs one command as the administrator and asks for your password (nothing appears while you type it). On Fedora use `sudo dnf install gcc-c++ make cmake`; on Arch use `sudo pacman -S base-devel cmake`. If your distribution has a CMake older than 3.28 (Debian 12 does), install a newer one from https://cmake.org/download/ or with `sudo snap install cmake --classic`.

### Step 3. Check the tools
Open a **new** terminal (on MSYS2 the UCRT64 window) and check CMake:

**File: terminal (not a saved file)**
```text
cmake --version
```
Expected result: a first line like `cmake version 3.28.3` or a higher number. The exact number on your machine will differ; it must be 3.28 or higher.

Now check the compiler:
- **Linux and MSYS2:** run `g++ --version`. Typical first line: `g++ (some text) 13.2.0`. You need 11 or higher.
- **macOS:** run `clang++ --version`. Typical first line: `Apple clang version 15.0.0 ...`.
- **Windows with Build Tools:** open the Start menu, search for **Developer PowerShell for VS**, open it and type `cl`. Typical first line: `Microsoft (R) C/C++ Optimizing Compiler Version 19.xx.xxxxx for x64`. You only need this special window for this check; builds in a normal PowerShell work because CMake finds Visual Studio by itself.

### Step 4. Install an editor (recommended)
An **editor** is a program for writing and saving text files. Any plain-text editor works; this course uses Visual Studio Code (VS Code), which is free. Install it from https://code.visualstudio.com/download (Windows: `winget install --id Microsoft.VisualStudioCode -e`; macOS with Homebrew: `brew install --cask visual-studio-code`). Open it and, in the **Extensions** view (the square icon on the left), search for **C/C++** by Microsoft and choose **Install**; it colours your code and shows hints. If VS Code asks "Do you trust the authors of the files in this folder?", choose **Yes** for your own folders only. More: https://code.visualstudio.com/docs/languages/cpp

### Step 5. Create the lesson folder
Follow the [working folder steps](../../README.md#working-folder) exactly: folder `lesson01`, full path `$HOME/code101/cpp/lesson01`. Then in VS Code choose **File > Open Folder**, select `lesson01`, and open **Terminal > New Terminal**. All commands below run in that terminal.

To recover if you are in the wrong folder: PowerShell `Set-Location "$HOME/code101/cpp/lesson01"`; macOS/Linux `cd "$HOME/code101/cpp/lesson01"`. Confirm with `Get-Location` or `pwd`.

### Step 6. Write the program
In the Explorer (the file list on the left), click the **New File** icon beside the folder name, type `main.cpp` and press Enter. Paste or type this complete file:

**File: `main.cpp`**
```cpp
#include <iostream>

int main() {
    std::cout << "Hello, C++!\n";
    return 0;
}
```
Save with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on the editor tab means "not saved yet". Make sure the name really is `main.cpp` and not `main.cpp.txt`.

### Step 7. Write the build recipe
Create a second new file named exactly `CMakeLists.txt` (capital C, M, L) in the same folder and paste:

**File: `CMakeLists.txt`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(hello LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(hello main.cpp)
target_compile_features(hello PRIVATE cxx_std_20)
set_target_properties(hello PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(hello PRIVATE /W4 /permissive-)
else()
  target_compile_options(hello PRIVATE -Wall -Wextra -Wpedantic)
endif()
```
Save it. Later lessons use the same file with only the program name (`hello`) and the list of `.cpp` files changed.

### Step 8. Predict, then build and run
**Predict first:** how many lines will the program print, and what will they say? Write your guess down, then continue.

Build with the two commands from [Build and run](../../README.md#build-and-run). In the `lesson01` terminal (MSYS2 users add `-G Ninja` to the first command):

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```
Expected result of the first command: several lines starting with `--`, ending with a line like `-- Build files have been written to: <your folder>/build`. Expected result of the second: compiler progress lines and no line containing the word `error`. Wording differs between compilers and systems.

## Run it
Windows PowerShell, in `lesson01`:

**File: terminal (not a saved file)**
```text
.\build\out\hello.exe
```
macOS and Linux (and MSYS2, where you add `.exe`: `./build/out/hello.exe`), in `lesson01`:

**File: terminal (not a saved file)**
```text
./build/out/hello
```
Expected output (not yet run):

**File: terminal output (not a saved file)**
```text
Hello, C++!
```
Was your prediction right? One line, as the program contains one `\n`.

## How it works
1. **Source file.** `main.cpp` is a plain text file of instructions. C++ source files usually end in `.cpp`.
2. `#include <iostream>` tells the compiler to bring in the standard library's input and output tools. A line starting with `#` is an instruction to the compiler's first stage, not to the running program. `<iostream>` is a **header**: a file of ready-made descriptions you can use.
3. `int main() { ... }` is a **function**: a named block of instructions. Every C++ program starts running at `main`. `int` says it hands back a whole number when it ends; the braces `{ }` mark where its body begins and ends.
4. `std::cout` is the **standard output stream**, usually your terminal window. `std::` is a **namespace** (a family name) that says "this belongs to the standard library". `<<` means "send what follows into the stream".
5. `"Hello, C++!\n"` is a **string literal**: text between double quotes. `\n` is the special code for "new line". Each instruction ends with a semicolon `;`. An instruction ending in a semicolon is a **statement**.
6. `return 0;` ends `main` and reports success (0) to the operating system. C++ also accepts a `main` without it, but writing it makes the intention visible while you learn.
7. **CMake file, line by line.** `cmake_minimum_required` names the oldest CMake that understands the file. `project(hello LANGUAGES CXX)` names the project and says it uses C++ (`CXX`). The `set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ...)` line puts the finished program in `build/out`, whichever compiler you use; without it Visual Studio would put it in `build/Debug`. The odd-looking `$<1:out>` is a CMake expression that simply means `out`; writing it this way stops Visual Studio from adding its own `Debug` folder. `add_executable(hello main.cpp)` says "build a program called hello from main.cpp". `target_compile_features(... cxx_std_20)` asks for the C++20 language rules. `CXX_EXTENSIONS OFF` keeps to the standard language without compiler-specific extras. The `if(MSVC)` block turns on warnings: `/W4` for the Microsoft compiler, `-Wall -Wextra -Wpedantic` for GCC and Clang.
8. **Two commands, two jobs.** *Configure* (`cmake -S . -B build`) reads the recipe and prepares the `build` folder. *Build* (`cmake --build build`) runs the compiler and the **linker** (the step that joins compiled pieces into one program). Your own files stay in the project folder; `build` can be deleted and recreated at any time.

A common misconception: "the compiler runs my program". It does not. The compiler produces a separate program file; you then run that file yourself.

## Try it
**Rung 1, guided.** Copy the exercise starter as described in [Exercise folders](../../README.md#exercise-folders): copy `exercise/starter` and rename it `try01` next to `lesson01`. Without the source, create a folder `try01`, open it alone in VS Code and create these two files.

**File: `CMakeLists.txt (starter)`**
```cmake
cmake_minimum_required(VERSION 3.28)
project(hello LANGUAGES CXX)

# Put the finished program in build/out on every system.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")

add_executable(hello main.cpp)
target_compile_features(hello PRIVATE cxx_std_20)
set_target_properties(hello PROPERTIES CXX_EXTENSIONS OFF)

if(MSVC)
  target_compile_options(hello PRIVATE /W4 /permissive-)
else()
  target_compile_options(hello PRIVATE -Wall -Wextra -Wpedantic)
endif()
```

**File: `main.cpp (starter)`**
```cpp
#include <iostream>

int main() {
    std::cout << "=== My card ===\n";
    // TODO: print the line  Name: Ada Lovelace
    // TODO: print the line  Goal: write C++
    std::cout << "===============\n";
    return 0;
}
```
Replace each TODO comment with a statement, save, then in `try01` run the two build commands and the program. Expected output after your change:

**File: terminal output (not a saved file)**
```text
=== My card ===
Name: Ada Lovelace
Goal: write C++
===============
```

**Rung 2, change.** Replace Ada Lovelace by your own name and add a third line of your choice. Rebuild with only `cmake --build build` and run again.

**Rung 3, stretch (optional).** Print a small picture or a four-line poem. Then predict, and test, what happens if you remove one `\n`.

<details><summary>Solution</summary>

Only `main.cpp` changes; `CMakeLists.txt` stays as in the starter.

**File: `main.cpp (solution)`**
```cpp
#include <iostream>

int main() {
    std::cout << "=== My card ===\n";
    std::cout << "Name: Ada Lovelace\n";
    std::cout << "Goal: write C++\n";
    std::cout << "===============\n";
    return 0;
}
```

</details>

## Check yourself
1. What does the compiler do?
   <details><summary>Answer</summary>It translates your source text into a program the processor can run.</details>
2. What is the job of `CMakeLists.txt`?
   <details><summary>Answer</summary>It is the build recipe: it names the project, the program and its source files and the language level, and CMake uses it to drive the compiler.</details>
3. Predict: what is printed by `std::cout << "A" << "B\n";`?
   <details><summary>Answer</summary>`AB` followed by a new line, because both pieces go to the same stream one after the other.</details>
4. After you edit `main.cpp`, which command must you run before running the program again?
   <details><summary>Answer</summary>`cmake --build build` (configure is needed only once).</details>

## Common mistakes
The messages below are typical; exact wording and numbers depend on your compiler and system.

| Symptom or error text | Cause | Fix |
|---|---|---|
| PowerShell: `The term 'cmake' is not recognized as the name of a cmdlet, function, script file, or operable program.` or macOS/Linux: `cmake: command not found` | CMake is not installed, or the terminal was opened before the install | Install CMake (Step 2), close the terminal and open a new one |
| `CMake Error: The source directory "..." does not appear to contain CMakeLists.txt.` | The terminal is in the wrong folder, or the file name is wrong | Use the recovery command in Step 5; check the file is named `CMakeLists.txt` |
| `CMake Error at CMakeLists.txt:... (add_executable): Cannot find source file: main.cpp` | The file is missing, in another folder, or saved as `main.cpp.txt` | Show file extensions, rename to `main.cpp`, keep it beside `CMakeLists.txt` |
| GCC/Clang: `error: expected ';' before ...`; MSVC: `error C2143: syntax error: missing ';' before ...` | A statement is missing its semicolon (the error often points at the next line) | Add the `;` at the end of the previous statement |
| GCC: `error: 'cout' was not declared in this scope`; MSVC: `error C2065: 'cout': undeclared identifier` | `std::` was left off | Write `std::cout` |
| `fatal error: iostrem: No such file or directory` (misspelt header) | Typo in `#include` | Fix the spelling to `<iostream>` |
| PowerShell: `The term '.\build\out\hello.exe' is not recognized ...` or bash: `No such file or directory` | The build failed, or you are in the wrong folder | Scroll up for the first line containing `error`, fix it, rebuild |

## Best practice
Compile with warnings on and read them: let the compiler find mistakes before the program runs. Source: C++ Core Guidelines, P.5 "Prefer compile-time checking to run-time checking" https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines

## Going further
- CMake's own beginner tutorial: https://cmake.org/cmake/help/latest/guide/tutorial/index.html
- Every library name used here is listed on https://en.cppreference.com/w/cpp/io/cout

## Summary
- You installed a compiler and CMake and checked their versions.
- You created `main.cpp` and `CMakeLists.txt` and built them with two commands.
- You ran the program and explained each line, including `#include`, `main`, `std::cout`, `\n` and `return 0;`.
- You changed the printed text, rebuilt and saw the new result.

## Next lesson
**[02. Types and output](02-types-and-output.md):** store numbers and text in variables and format what you print.
