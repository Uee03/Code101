# C++ 101, Phase 3: Real Programs

Source pack for lessons 09 to 12 of **C++ 101 (Zero to Hero)**.
The optional source is also available at https://github.com/Uee03/Code101 under `source/cpp/101-zero-to-hero/phase-3-real-programs/` (**Code > Download ZIP**, then extract the repository). Every file needed is shown in the lessons.

| Folder | Lesson | You build / exercise |
|---|---|---|
| `09-classes-and-raii` | Classes and RAII | bank account, scope logger / wallet |
| `10-smart-pointers` | Smart pointers | `std::unique_ptr` documents / ticket factory |
| `11-files-and-errors` | Files and errors | `std::ofstream`, `std::ifstream`, exceptions / archive lookup |
| `12-expense-tracker` | Project: expense tracker | console tracker saving `expenses.txt` / `count` command |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | Finished project: `CMakeLists.txt` and the `.cpp` / `.hpp` files (lesson 12 has three source files). |
| `exercise/starter/` | Runnable starting point with TODO markers; copy the whole folder. |
| `exercise/solution/` | Complete answer, also independently buildable. Try first. |
| `verify.json` | Maintainer steps for a later check run. Learners can ignore this file. |

## How to build and run any project

1. Install a C++20 compiler and CMake 3.28 or newer (lesson 01).
2. Extract the downloaded repository ZIP: Windows right-click > **Extract All** > **Extract**; macOS double-click; Linux **Extract Here** or `unzip`.
3. Open one `code` folder, for example `12-expense-tracker/code`, in VS Code (**File > Open Folder**) and select **Terminal > New Terminal**. Confirm the folder with `Get-Location` (PowerShell) or `pwd` (macOS/Linux).
4. Run the two commands in that folder (MSYS2 users add `-G Ninja` to the first):

```text
cmake -S . -B build
cmake --build build
```

5. Run the program from that folder. Windows PowerShell: `.\build\out\NAME.exe`; macOS/Linux: `./build/out/NAME`. `NAME` is `account`, `smartptr`, `files` or `tracker` for lessons 09 to 12.

Lessons 11 and 12 create text files (`notes.txt`, `todo.txt`, `expenses.txt`) in the folder you run them from. They overwrite their demo files on each run; never keep valued data in them.

To do an exercise, copy the `starter` folder and rename it `try09` for lesson 09 (use the corresponding try name for later lessons). Put it alongside, not inside, the lesson folder. The try folder must directly contain `CMakeLists.txt`. Open the try folder alone in VS Code, edit, save, build and run there.

## Needs

A C++20 compiler (GCC 11+, Clang 14+, MSVC from Visual Studio 2022) and CMake 3.28+. Standard library only (lesson 12 uses `<filesystem>`); no downloads at run time, no art, no accounts.
Complete Phases 1 and 2 first; terms continue in lesson order.
Lesson text: tutorials/cpp/101-zero-to-hero/phase-3-real-programs/ in the repository.
Status: written, not yet run.
