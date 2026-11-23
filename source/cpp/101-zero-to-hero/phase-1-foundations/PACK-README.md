# C++ 101, Phase 1: Foundations

Source pack for lessons 01 to 04 of **C++ 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-1-foundations/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-hello-cpp` | Hello, C++ | first program with CMake / business card |
| `02-types-and-output` | Types and output | variables and formatted output / pizza order |
| `03-input-and-decisions` | Input and decisions | ticket price with `std::cin` and `if` / grade checker |
| `04-loops` | Loops | `for`, `while`, range-based `for` / countdown by twos |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished project: `CMakeLists.txt` and `main.cpp`. |
| `exercise/starter/` | Runnable starting point with TODO markers; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently buildable. Try first. |
| `verify.json` | Maintainer steps for a later check run. Learners can ignore this file. |

## How to build and run any project

1. Install a C++20 compiler and CMake 3.28 or newer (lesson 01).
2. Extract the downloaded repository ZIP: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux **Extract Here** or `unzip`.
3. Open one `code` folder in VS Code (**File > Open Folder**) and select **Terminal > New Terminal**. Confirm the folder with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run the two commands in that folder (MSYS2 users add `-G Ninja` to the first):

```text
cmake -S . -B build
cmake --build build
```

5. Run the program. Windows PowerShell: `.\build\out\NAME.exe`; macOS/Linux: `./build/out/NAME`. `NAME` is `hello`, `types`, `ticket` or `loops` for lessons 01 to 04.

To do an exercise, copy the `starter` folder and rename it `try01` for lesson 01 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson folder. The try folder must directly contain `CMakeLists.txt`. Open the try folder alone in VS Code, edit, save, build and run there. Do not merge starter and solution files.

## Needs

A C++20 compiler (GCC 11+, Clang 14+, MSVC from Visual Studio 2022) and CMake 3.28+. Standard library only; no downloads at run time, no art, no accounts.
Lesson text: tutorials/cpp/101-zero-to-hero/phase-1-foundations/ in the repository.
Status: written, not yet run (no build or run has been performed on these files).

Next: Phase 2, Building Blocks.
