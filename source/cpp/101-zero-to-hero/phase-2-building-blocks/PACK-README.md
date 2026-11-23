# C++ 101, Phase 2: Building Blocks

Source pack for lessons 05 to 08 of **C++ 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-2-building-blocks/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `05-functions-and-references` | Functions and references | rectangle, tip, greeting / discount |
| `06-strings-and-vectors` | Strings and vectors | text search, shopping list / name list |
| `07-maps-and-algorithms` | Maps and algorithms | word counts, sort and search / stock map |
| `08-pointers-and-references` | Pointers and references | `&`, `*`, `nullptr` / cheapest price |

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
3. Open one `code` folder, for example `05-functions-and-references/code`, in VS Code (**File > Open Folder**) and select **Terminal > New Terminal**. Confirm the folder with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run the two commands in that folder (MSYS2 users add `-G Ninja` to the first):

```text
cmake -S . -B build
cmake --build build
```

5. Run the program. Windows PowerShell: `.\build\out\NAME.exe`; macOS/Linux: `./build/out/NAME`. `NAME` is `functions`, `strings`, `maps` or `pointers` for lessons 05 to 08.

To do an exercise, copy the `starter` folder and rename it `try05` for lesson 05 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson folder. The try folder must directly contain `CMakeLists.txt`. Open the try folder alone in VS Code, edit, save, build and run there. Some starters produce a compiler warning about an unused parameter until you finish the TODO; that is expected.

## Needs

A C++20 compiler (GCC 11+, Clang 14+, MSVC from Visual Studio 2022) and CMake 3.28+. Standard library only; no downloads at run time, no art, no accounts.
Complete Phase 1 first; terms continue in lesson order.
Lesson text: tutorials/cpp/101-zero-to-hero/phase-2-building-blocks/ in the repository.
Status: written, not yet run.

Next: Phase 3, Real Programs.
