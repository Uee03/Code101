---
track: c
level: 101
phase: 1
phase_name: foundations
lesson: 01
title: "Hello, C: install and first program"
time: 75 min
prerequisites: [none]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)", cmake: "3.21 or newer" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-1-foundations/01-hello-c/
assets: []
---

# 01. Hello, C: install and first program

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- install a C compiler and CMake on your computer and check that they work;
- open a terminal and tell which folder it is in;
- write, compile and run a C program that prints two lines;
- read the first line of a compiler error and fix a missing semicolon.

## Recap
None, this is the start.

## Why it matters
A recipe written in English is useless until a cook reads it. A C program is a recipe written in a strict language; the **compiler** is the translator who turns the recipe into steps the computer itself can follow. Before you can cook anything you need the translator installed, and you need to know the one routine you will repeat in every lesson: write, translate, run.

## What you will build
A two-line program. When you run it the terminal shows:

```text
Hello, C!
My first program runs.
```

## Before you start
- A computer with Windows 10 or newer, macOS, or Linux, and permission to install software.
- Time: 75 minutes for a first-timer, mostly downloading and installing. Take a break after Step 3.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-1-foundations/01-hello-c/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains the working folder, building, running and exercise folders. This lesson repeats the essentials.
- No art, libraries or accounts.

## Steps

### Step 1. Open a terminal
A **terminal** is a window where you type commands and press Enter; the computer answers with text. The text shown before your typing area is the **prompt**; it often ends in `>` (Windows) or `$` or `%` (macOS/Linux) and is not part of the command.

- **Windows:** press the Windows key, type `PowerShell`, and open **Windows PowerShell** (or **Terminal**).
- **macOS:** press Cmd+Space, type `Terminal`, press Enter.
- **Linux:** press Ctrl+Alt+T, or open **Terminal** from your applications menu.

Expected result: a window with a blinking cursor after a prompt. Keep it open.

### Step 2. Install a C compiler and CMake
Choose **one** route for your computer. Check the official page if a button name has changed.

**Windows, route A (recommended): MSYS2 with gcc.** MSYS2 is a free collection of developer tools; its `gcc` is the GNU C compiler.
1. Download the installer from https://www.msys2.org/ and run it. Accept the default folder `C:\msys64`. Leave **Run MSYS2 now** ticked and choose **Finish**.
2. In the MSYS2 window that opens, type this command and press Enter. Press Enter again to accept all packages and type `Y` when asked to proceed:

**File: terminal (not a saved file)**
```bash
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-make
```
3. Add the tools to your **PATH**, the list of folders where Windows looks for commands: press the Windows key, type `Edit environment variables for your account` and open it. Under **User variables** select `Path`, choose **Edit**, **New**, type `C:\msys64\ucrt64\bin`, and select **OK** three times.
4. **Close every PowerShell window and open a new one.** Old windows do not see the new PATH.

**Windows, route B (alternative): Microsoft C compiler.** Download **Build Tools for Visual Studio** from https://visualstudio.microsoft.com/downloads/ (section *Tools for Visual Studio*), run it, tick the workload **Desktop development with C++** and install. Then start **Developer PowerShell for VS** from the Start menu (a normal PowerShell does not know the `cl` compiler). Install CMake from https://cmake.org/download/ with its Windows installer and choose to add CMake to the PATH.

**macOS:** in the terminal run:

**File: terminal (not a saved file)**
```bash
xcode-select --install
```
A dialog offers the **Command Line Tools**; choose **Install** and wait. They provide `clang` (and `gcc`, which is a name for clang on macOS) and `make`. For CMake, download the installer from https://cmake.org/download/ , or if you use Homebrew run `brew install cmake`.

**Linux (Debian or Ubuntu):**

**File: terminal (not a saved file)**
```bash
sudo apt update
sudo apt install build-essential cmake
```
`sudo` asks for your password (nothing appears while you type it). On Fedora use `sudo dnf install gcc make cmake`; on Arch use `sudo pacman -S base-devel cmake`.

Expected result: the installers finish without an error message.

### Step 3. Check the tools
In a **new** terminal (PowerShell on Windows; for route B use Developer PowerShell for VS) run the check for your tool.

gcc or clang (all routes except B):

**File: terminal (not a saved file)**
```text
gcc --version
cmake --version
```

Microsoft route B:

**File: terminal (not a saved file)**
```text
cl
cmake --version
```

Expected result: a version line for each command. Your numbers will differ. For `gcc` the first line looks like `gcc (...) 14.2.0` (any recent version is fine; on macOS the text mentions `Apple clang`). `cmake --version` starts with `cmake version`. For route B, `cl` prints a banner starting with `Microsoft (R) C/C++ Optimizing Compiler Version` and a usage hint; that is normal.

If a command says it is not found, jump to **Common mistakes**. **Break point: you can stop here and continue later.**

### Step 4. Create your working folder and an editor
Make a folder for this lesson and move into it. Windows PowerShell:

**File: terminal (not a saved file)**
```powershell
New-Item -ItemType Directory -Force -Path "$HOME/code101/c/lesson01" | Out-Null
Set-Location "$HOME/code101/c/lesson01"
```

macOS/Linux:

**File: terminal (not a saved file)**
```bash
mkdir -p "$HOME/code101/c/lesson01"
cd "$HOME/code101/c/lesson01"
```

Nothing is printed when it works. Confirm with `Get-Location` (PowerShell) or `pwd` (macOS/Linux): the path must end in `lesson01`. To return here later use the same `Set-Location` or `cd` line.

An **editor** is an application for writing and saving text files. Any plain text editor works; this course assumes **Visual Studio Code** (free, https://code.visualstudio.com/). Open it, choose **File > Open Folder**, select `lesson01`, and accept the trust prompt only for your own folders. You may install the **C/C++** extension from Microsoft when VS Code offers it; it colours the code and is optional. Use **Terminal > New Terminal** inside VS Code for the commands below.

### Step 5. Write the program
In the Explorer (the file list on the left) hover over `lesson01` and choose **New File**. Type `main.c` and press Enter. On Windows make sure the name is not `main.c.txt` (turn on **File name extensions** in File Explorer's View menu). Type or paste the complete file:

**File: `main.c`**
```c
#include <stdio.h>

int main(void) {
    printf("Hello, C!\n");
    printf("My first program runs.\n");
    return 0;
}
```

Save with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on the tab means "not saved".

### Step 6. Predict, then build and run
**Predict first:** how many lines will the program print, and what does `\n` do? Write down your guess, then continue.

Build with the compiler (run in `lesson01`). gcc or clang (Windows route A, macOS, Linux):

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c
```

Microsoft route B:

**File: terminal (not a saved file)**
```text
cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c
```

Expected result: gcc prints nothing and returns to the prompt. `cl` prints `main.c` and then returns to the prompt. A new file `app` (Windows: `app.exe`) appears in the folder.

## Run it
macOS and Linux:

**File: terminal (not a saved file)**
```text
./app
```

Windows PowerShell (both routes):

**File: terminal (not a saved file)**
```text
.\app
```

Expected output:
```text
Hello, C!
My first program runs.
```

## How it works
The compiler reads `main.c` top to bottom.

1. `#include <stdio.h>` asks the compiler to bring in the description of the **standard input/output library**: ready-made tools such as `printf`. Lines starting with `#` are instructions for the compiler's first step, not part of the program's behaviour.
2. `int main(void) { ... }` defines the **function** called `main`. A function is a named block of steps. Every C program starts running at `main`. `int` says it hands back a whole number when it finishes; `(void)` says it needs nothing to start.
3. `printf("Hello, C!\n");` calls the `printf` function to print the **string** (text in double quotes) inside the brackets. `\n` is an **escape sequence** meaning "start a new line". Each statement ends with a semicolon `;`, like a full stop.
4. `return 0;` hands the number 0 back to the operating system; 0 means "everything went well". Any other number means a problem.
5. Braces `{ }` group the statements that belong to `main`.

**Compiling** is the translation step; **running** starts the translated program. Misconception: running `gcc` does not run your program. It only makes the file `app`; you run that file in a second command. If you change `main.c`, you must build again before the change shows up.

## Try it
Write a **recipe card**. In a new folder `try01` next to `lesson01` create `main.c` with the starter below (or copy `exercise/starter`, see [exercise folders](../../README.md#exercise-folders)). Open only `try01` in your editor.

**File: `main.c` (starter)**
```c
#include <stdio.h>

int main(void) {
    printf("Recipe: Tea\n");
    /* TODO: print the line "Ingredients:" and then three ingredient lines. */
    /* TODO: print a final line that lists the steps. */
    return 0;
}
```

Build and run with the commands above. Aim for this output (your own ingredients may differ if you prefer, but check the format):

```text
Recipe: Tea
Ingredients:
- 1 cup water
- 1 tea bag
- 1 spoon sugar
Steps: boil, steep, sip.
```

Then change it: add a line with a cooking time. Stretch (optional): print a blank line between the ingredients and the steps; decide for yourself how.

<details><summary>Solution</summary>

Replace the two TODO comment lines in `main.c`; every other line stays as in the starter. Build and run again.

**File: `main.c` (solution)**
```c
#include <stdio.h>

int main(void) {
    printf("Recipe: Tea\n");
    printf("Ingredients:\n");
    printf("- 1 cup water\n");
    printf("- 1 tea bag\n");
    printf("- 1 spoon sugar\n");
    printf("Steps: boil, steep, sip.\n");
    return 0;
}
```

</details>

## Check yourself
1. What does the compiler do, and what is the difference between building and running?
   <details><summary>Answer</summary>It translates your `.c` file into a program file; building makes the file, running starts it.</details>
2. What happens if you remove `\n` from the end of the first `printf`?
   <details><summary>Answer</summary>Both messages appear on the same line, because nothing starts a new line.</details>
3. Which function does every C program start in?
   <details><summary>Answer</summary>`main`.</details>
4. A line in your terminal starts with `error:` after a build. Has `app` been updated?
   <details><summary>Answer</summary>No. Fix the first error, save and build again.</details>

## Common mistakes
Messages below marked "typical message" are the usual wording; your compiler version may word them differently. The first error in the list is the one to fix.

| Symptom or error text | Cause | Fix |
|---|---|---|
| PowerShell: `The term 'gcc' is not recognized as the name of a cmdlet, function, script file, or operable program.` | The compiler is not on the PATH, or the terminal was opened before installing | Redo the PATH step, then close all terminals and open a new one. For route B use Developer PowerShell for VS. |
| `gcc: fatal error: no input files` (typical message) | Ran `gcc` without the file name | Add `main.c` at the end of the build command. |
| `error: expected ';' before 'return'` (typical message, line number varies) | A semicolon is missing at the end of the line above | Add `;` after the closing bracket of the previous `printf`. |
| `warning: implicit declaration of function 'printf'` or an error with similar words (typical message) | The line `#include <stdio.h>` is missing or misspelled | Add `#include <stdio.h>` as the first line. |
| `.\app` or `./app` says it cannot be found, or an old output appears | The build failed so no new program exists, or you are in the wrong folder | Scroll up for the first `error`, fix it, build again; check the folder with `Get-Location` or `pwd`. |
| Nothing changes after editing | The file is not saved (dot on the tab) or you did not build again | Save with Ctrl+S or Cmd+S, then build, then run. |
| `main.c.txt` exists instead of `main.c` | Windows hid the real extension | Show file name extensions and rename the file. |

## Best practice
Always compile with warnings on (`-Wall -Wextra`) and read them; many mistakes are caught before you ever run the program. Source: GCC manual, Warning Options https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html

## Going further
- The C language reference on cppreference: https://en.cppreference.com/w/c
- Microsoft's guide to the C standard options for `cl`: https://learn.microsoft.com/en-us/cpp/build/reference/std-specify-language-standard-version

## Summary
- You installed a C compiler and CMake and checked their versions.
- You opened a terminal and made a working folder.
- You wrote, built and ran a program that prints two lines.
- You fixed a missing semicolon by reading the first error.

## Next lesson
**[02. Types, printf and scanf](02-types-printf-scanf.md):** store numbers and text in variables, print them neatly and read what the user types.
