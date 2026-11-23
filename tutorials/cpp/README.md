# C++ 101: Zero to Hero

For complete beginners from any field. You do not need to know C first. Start at 01 and work in order (you may pick another order; each lesson lists the lessons it builds on).
Language level C++20, build tool CMake 3.28 or newer, standard library only. Console programs only; desktop windows come at level 201.

Status: **written, not yet run.** Every lesson carries a draft notice until the code has been built and run once on a real machine.

| Lesson | Read | Phase |
|---|---|---|
| 01 | [Hello, C++](101-zero-to-hero/phase-1-foundations/01-hello-cpp.md) | foundations |
| 02 | [Types and output](101-zero-to-hero/phase-1-foundations/02-types-and-output.md) | foundations |
| 03 | [Input and decisions](101-zero-to-hero/phase-1-foundations/03-input-and-decisions.md) | foundations |
| 04 | [Loops](101-zero-to-hero/phase-1-foundations/04-loops.md) | foundations |
| 05 | [Functions and references](101-zero-to-hero/phase-2-building-blocks/05-functions-and-references.md) | building-blocks |
| 06 | [Strings and vectors](101-zero-to-hero/phase-2-building-blocks/06-strings-and-vectors.md) | building-blocks |
| 07 | [Maps and algorithms](101-zero-to-hero/phase-2-building-blocks/07-maps-and-algorithms.md) | building-blocks |
| 08 | [Pointers and references](101-zero-to-hero/phase-2-building-blocks/08-pointers-and-references.md) | building-blocks |
| 09 | [Classes and RAII](101-zero-to-hero/phase-3-real-programs/09-classes-and-raii.md) | real-programs |
| 10 | [Smart pointers](101-zero-to-hero/phase-3-real-programs/10-smart-pointers.md) | real-programs |
| 11 | [Files and errors](101-zero-to-hero/phase-3-real-programs/11-files-and-errors.md) | real-programs |
| 12 | [Project: expense tracker](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) | real-programs |

## How every lesson works

The source is optional: each lesson shows every file in full. Lesson 01 installs the tools; do it first.

### Get the optional source

Open https://github.com/Uee03/Code101 and choose **Code > Download ZIP**. Or, if you already use Git, run `git clone https://github.com/Uee03/Code101.git` in a folder where you keep projects. Git is not needed for this course.

Extract the downloaded repository ZIP: **Windows**, right-click > **Extract All** > **Extract**; **macOS**, double-click; **Linux**, right-click > **Extract Here**, or run `unzip Code101-main.zip` in Downloads (use the actual downloaded filename if different). Open the extracted `Code101-main/source/cpp/101-zero-to-hero` folder to find `phase-1-foundations`, `phase-2-building-blocks` and `phase-3-real-programs`. Each lesson's Before you start gives its full source path. Each lesson folder has `code/` (the finished project), `exercise/starter/` and `exercise/solution/`.

### Working folder

Type your own copy of each example in a fresh folder outside the source download. Lesson 01 shows these steps; later lessons repeat them with `lesson01` replaced by the folder name listed in that lesson.

From any folder, **Windows PowerShell**:

**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/cpp/lesson01" | Out-Null
Set-Location "$HOME/code101/cpp/lesson01"
```

**macOS/Linux**:

**File: terminal (not a saved file)**
```bash
mkdir -p "$HOME/code101/cpp/lesson01"
cd "$HOME/code101/cpp/lesson01"
```

These commands create and select the folder without printing a result. `$HOME` means your personal folder. `Set-Location` is PowerShell's `cd`; `New-Item` creates the directory, `-Force` accepts an existing one, `-Path` supplies its location and `| Out-Null` hides the creation summary. `mkdir -p` creates a folder and any missing parents on macOS/Linux. Stop if a command reports an error.

In VS Code choose **File > Open Folder**, select that single lesson folder, then **Terminal > New Terminal**. The Explorer is the file list on the left. Hover over the folder name for **New File** or **New Folder**. Create each file with its shown name. Save with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS); a dot on a tab means unsaved. On Windows enable **File Explorer > View > Show > File name extensions** so you never end up with `main.cpp.txt`.

Check the folder with `Get-Location` (PowerShell) or `pwd` (macOS/Linux); the displayed path must end in your lesson folder. If you are elsewhere, use that lesson's recovery command.

### Build and run

Every lesson is its own small CMake project: a `CMakeLists.txt` file (the build recipe) plus one or more `.cpp` files. In the project folder run these two commands on every OS:

**File: terminal (not a saved file)**
```text
cmake -S . -B build
cmake --build build
```

The first command, **configure**, reads `CMakeLists.txt` and creates a `build` folder with the files your compiler needs. The second command, **build**, runs the compiler and creates the program. Our `CMakeLists.txt` files put the finished program in `build/out`, so you run it like this:

- **Windows PowerShell:** `.\build\out\NAME.exe` (the leading `.\` means "in this folder")
- **macOS and Linux:** `./build/out/NAME`

`NAME` is the program name that the lesson tells you. After you change a `.cpp` file, run only `cmake --build build` again, then run the program. Configure once per project folder.

If you chose the MSYS2 route in lesson 01, add `-G Ninja` to the first command (`cmake -S . -B build -G Ninja`) and run `./build/out/NAME.exe` inside the MSYS2 window.

### Exercise folders

The lesson shows the full starter files, so no download is necessary. To type them yourself, create the named `tryNN` folder next to `lessonNN`, open it alone in VS Code and create the files shown, including `CMakeLists.txt`.

If you have the source, **copy the `starter` folder and rename it `try01`** for lesson 01 (use each later lesson's try name). In your file manager, select `exercise/starter`, copy it, go to `$HOME/code101/cpp`, paste it, then rename the pasted folder. Do not create `try01` and paste `starter` inside it: the try folder must directly contain `CMakeLists.txt`.

Open only the try folder in VS Code, make your changes, save, then run the build and run commands above in that folder. Try before opening the solution. Solution blocks show the changed region; replace that region and leave other lines alone. Never mix starter and solution files in one folder: two `main` functions cannot live in one program.

### About warnings

Our `CMakeLists.txt` files ask the compiler to warn about suspicious code. A **warning** is a message that does not stop the build but points at something probably wrong. Read warnings; fix them. Some starters produce a warning on purpose until you finish the TODO.
