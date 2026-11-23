# C 101: Zero to Hero

For complete beginners from any field. Start at 01 and work in order (each lesson links its recommended earlier lessons, but you may pick any order).
Language standard: **C17**. Console programs only, portable across Windows, macOS and Linux. Standard library only.

> **Draft: written but not yet run.** Every lesson in this track was prepared by reading the code and the official documentation. Nothing has been compiled or executed yet. If your tool prints something different, trust your tool and report it.

| Lesson | Read | Phase |
|---|---|---|
| 01 | [Hello, C: install and first program](101-zero-to-hero/phase-1-foundations/01-hello-c.md) | foundations |
| 02 | [Types, printf and scanf](101-zero-to-hero/phase-1-foundations/02-types-printf-scanf.md) | foundations |
| 03 | [Making decisions](101-zero-to-hero/phase-1-foundations/03-making-decisions.md) | foundations |
| 04 | [Loops](101-zero-to-hero/phase-1-foundations/04-loops.md) | foundations |
| 05 | [Functions](101-zero-to-hero/phase-2-building-blocks/05-functions.md) | building-blocks |
| 06 | [Arrays and strings](101-zero-to-hero/phase-2-building-blocks/06-arrays-and-strings.md) | building-blocks |
| 07 | [Pointers](101-zero-to-hero/phase-2-building-blocks/07-pointers.md) | building-blocks |
| 08 | [Structs](101-zero-to-hero/phase-2-building-blocks/08-structs.md) | building-blocks |
| 09 | [Headers and multiple files](101-zero-to-hero/phase-2-building-blocks/09-headers-and-multiple-files.md) | building-blocks |
| 10 | [Memory and common bugs](101-zero-to-hero/phase-3-real-programs/10-memory-and-bugs.md) | real-programs |
| 11 | [Files](101-zero-to-hero/phase-3-real-programs/11-files.md) | real-programs |
| 12 | [Project: expense tracker](101-zero-to-hero/phase-3-real-programs/12-expense-tracker.md) | real-programs |

## How every lesson works

The source is optional: each lesson shows every file in full, plus the exercise starter and the changed regions of the solution. Start with lesson 01 to install a C compiler and CMake.

### Get the optional source

Open https://github.com/Uee03/Code101 and choose **Code > Download ZIP**. Or, if you already use Git, run `git clone https://github.com/Uee03/Code101.git` in a folder where you keep projects. Git is not needed for this course.

Extract the downloaded ZIP: **Windows**, right-click > **Extract All** > **Extract**; **macOS**, double-click; **Linux**, right-click > **Extract Here**, or run `unzip Code101-main.zip` in Downloads (use the real downloaded filename if it differs). The lessons' source is in `source/c/101-zero-to-hero/phase-1-foundations`, `phase-2-building-blocks` and `phase-3-real-programs`. Each lesson's **Before you start** gives its full source path.

### Working folder

Type your own examples in a fresh folder outside the source download. These are exactly lesson 01's folder steps. Later lessons repeat them with `lesson01` replaced by the folder name that lesson lists.

From any folder, **Windows PowerShell**:

**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/c/lesson01" | Out-Null
Set-Location "$HOME/code101/c/lesson01"
```

**macOS/Linux**:

**File: terminal (not a saved file)**
```bash
mkdir -p "$HOME/code101/c/lesson01"
cd "$HOME/code101/c/lesson01"
```

These commands create and select the folder and print nothing when they work. `$HOME` means your personal folder. `Set-Location` is PowerShell's `cd`; `New-Item` creates the folder, `-Force` accepts an existing one, `-Path` gives its location and `| Out-Null` hides the creation summary. `mkdir -p` creates a folder and any missing parent folders on macOS/Linux.

Open that single folder in your editor (in VS Code: **File > Open Folder**, then **Terminal > New Terminal**). The Explorer is the file list on the left; hover over the folder name for **New File** (page with a plus) and **New Folder** (folder with a plus). Create each file with its shown name and save with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS); a dot on the editor tab means "not saved". On Windows turn on **File Explorer > View > Show > File name extensions** so a file named `main.c` is not really `main.c.txt`.

Check where you are with `Get-Location` (PowerShell) or `pwd` (macOS/Linux). The prompt usually shows the current folder before `>` or `$` (sometimes `%` on macOS). If you are elsewhere, use the lesson's recovery command, for example `cd "$HOME/code101/c/lesson02"`.

### Build and run

A **compiler** turns your `.c` text files into a program the computer can run. Pick the row that matches the tool you installed in lesson 01. Every lesson says `FILES` or names the files; `app` is the name of the finished program.

| Your tool | Build (run in the folder that holds the `.c` files) | Run |
|---|---|---|
| gcc or clang: Linux, macOS, Windows with MSYS2 | `gcc -std=c17 -Wall -Wextra -o app main.c` | macOS/Linux `./app`; Windows PowerShell `.\app` |
| Microsoft C compiler `cl` (Windows, "Developer PowerShell for VS") | `cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c` | `.\app` |

What the flags mean:

- `-std=c17` / `/std:c17`: use the 2017 version of the C language.
- `-Wall -Wextra` / `/W4`: show helpful **warnings**, messages about code that compiles but is probably a mistake. Read them: they find many beginner bugs.
- `-o app` / `/Fe:app.exe`: name the finished program `app` (on Windows it becomes `app.exe`; typing `.\app` runs it).
- `/D_CRT_SECURE_NO_WARNINGS` (Microsoft only): hide Microsoft's extra notices about `scanf`, `fopen` and `strcpy`, which are standard C. It is not a security setting; later lessons explain how to use those functions safely.

When a lesson has several files, list them all: `gcc -std=c17 -Wall -Wextra -o app main.c extra.c`. `cl` also leaves `.obj` files in the folder; they are harmless intermediate files.

If the compiler prints **nothing** and returns to the prompt, the build worked. A message containing `error` means no program was made; read the first error first and fix it, then build again.

### Exercise folders

The lesson shows the full starter files, so no download is necessary. To type them yourself, create the folder named in the lesson (for example `try02`) next to `lesson02`, open it alone in your editor, and create the files shown.

If you have the source, **copy the `starter` folder and rename it `try02`** (use the name the lesson gives). In your file manager select `exercise/starter`, copy it, go to `$HOME/code101/c`, paste it, then rename the pasted folder. Do not create `try02` and paste `starter` inside it: the `.c` files must sit directly in `try02`.

Open only the try folder, edit, save, build and run with the commands in the lesson. Try before opening the solution. Never put the starter and solution in the same folder: two `main` functions conflict.

### Safety habits used in every lesson

- Every `scanf` result is checked; every size is limited (`%19s`, `fgets` with a size); every `malloc` result is checked.
- Programs only create files in their own folder and never ask for passwords, accounts or the network.
