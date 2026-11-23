---
track: c
level: 101
phase: 2
phase_name: building-blocks
lesson: 09
title: "Headers and multiple files"
time: 50 min
prerequisites: [101.2.05, 101.2.08]
versions: { c_standard: "C17", gcc: "any recent version (11 or newer)", make: "GNU Make 3.81 or newer" }
verified: not yet run
source: source/c/101-zero-to-hero/phase-2-building-blocks/09-headers-and-multiple-files/
assets: []
---

# 09. Headers and multiple files

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- split a program into a header (`.h`) and source (`.c`) files;
- explain what an include guard is and why it is needed;
- build several files into one program with one command;
- write a small Makefile that rebuilds only what changed.

## Recap
1. What is a prototype? <details><summary>Answer</summary>A function's first line followed by `;`, which tells the compiler it exists.</details>
2. How do you reach a field of a struct through a pointer? <details><summary>Answer</summary>With `->`, for example `item->quantity`.</details>

## Why it matters
A cookbook is not one giant page: chapters live in separate sections and the contents page lists what each offers. In C, a **header file** (`.h`) is the contents page: it lists what a chapter offers. The **source file** (`.c`) holds the real steps. Splitting a program keeps each file small, lets files be reused, and lets a build tool recompile only what changed.

## What you will build
A tiny rectangle "library": `rectangle.h` declares a type and three functions, `rectangle.c` defines them, `main.c` uses them. You will build it by hand and then with a `Makefile`.

## Before you start
- Finish lessons 05 and 08 (functions and structs).
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/c/101-zero-to-hero/phase-2-building-blocks/09-headers-and-multiple-files/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) and [build and run](../../README.md#build-and-run) have the commands.
- Working folder: `lesson09`. Recovery: PowerShell `Set-Location "$HOME/code101/c/lesson09"`; macOS/Linux `cd "$HOME/code101/c/lesson09"`.
- For the Makefile step you need `make`: it comes with `build-essential` (Linux) and the Command Line Tools (macOS). With MSYS2 on Windows the command is `mingw32-make`, installed in lesson 01. With the Microsoft route skip the Makefile part of **Run it**; lesson 12 uses CMake instead.

## Steps

### Step 1. Create the working folder
Repeat the [working-folder steps](../../README.md#working-folder) with the folder name `lesson09`. Open only `lesson09` in your editor and open a terminal there.

### Step 2. The header
A header contains **declarations**: the types and function prototypes other files may use. It contains no function bodies. Because several files may include the same header (and a header may include another), it starts with an **include guard**: `#ifndef RECTANGLE_H` ("if not defined") makes the compiler read the contents only the first time; `#define RECTANGLE_H` records that it has been read; `#endif` closes the condition. Without the guard the type would be defined twice and the compiler would complain.

Create `rectangle.h`:

**File: `rectangle.h`**
```c
#ifndef RECTANGLE_H
#define RECTANGLE_H

typedef struct {
    int width;
    int height;
} Rectangle;

int rectangle_area(const Rectangle *r);
int rectangle_perimeter(const Rectangle *r);
int rectangle_is_square(const Rectangle *r);

#endif
```

### Step 3. The source file with the function bodies
`#include "rectangle.h"` uses double quotes for your own headers (angle brackets `<stdio.h>` are for the standard library). Create `rectangle.c`:

**File: `rectangle.c`**
```c
#include "rectangle.h"

int rectangle_area(const Rectangle *r) {
    return r->width * r->height;
}

int rectangle_perimeter(const Rectangle *r) {
    return 2 * (r->width + r->height);
}

int rectangle_is_square(const Rectangle *r) {
    return r->width == r->height;
}
```

### Step 4. The main file
Create `main.c`:

**File: `main.c`**
```c
#include <stdio.h>

#include "rectangle.h"

int main(void) {
    Rectangle desk = {120, 60};
    Rectangle tile = {30, 30};
    printf("Desk area: %d\n", rectangle_area(&desk));
    printf("Desk perimeter: %d\n", rectangle_perimeter(&desk));
    printf("Desk is square: %d\n", rectangle_is_square(&desk));
    printf("Tile is square: %d\n", rectangle_is_square(&tile));
    return 0;
}
```

Save all three files. **Predict first:** what do the four lines print?

### Step 5. Build the files together
List every `.c` file in the command (never the `.h`). gcc or clang:

**File: terminal (not a saved file)**
```text
gcc -std=c17 -Wall -Wextra -o app main.c rectangle.c
```

Microsoft `cl`:

**File: terminal (not a saved file)**
```text
cl /nologo /std:c17 /W4 /D_CRT_SECURE_NO_WARNINGS /Fe:app.exe main.c rectangle.c
```

Run `./app` (macOS/Linux) or `.\app` (Windows). Expected output (not yet run):

```text
Desk area: 7200
Desk perimeter: 360
Desk is square: 0
Tile is square: 1
```

## Run it
Now build the same program with a Makefile (gcc or clang).

### Build with a Makefile
Behind the scenes `gcc` does two jobs for each `.c` file: it **compiles** it into an **object file** (`.o`, the translated but unlinked pieces) and then **links** the object files into the program. A **Makefile** lists these jobs as **rules**: `target: dependencies`, followed by the command to make the target. `make` compares file times and reruns only the rules whose dependencies are newer.

Create a file named exactly `Makefile` (no extension). **Each command line must start with a Tab character, not spaces.** Most editors insert a Tab when you press the Tab key; if yours inserts spaces, change it for this file.

**File: `Makefile`**
```make
CC = gcc
CFLAGS = -std=c17 -Wall -Wextra

app: main.o rectangle.o
	$(CC) $(CFLAGS) -o app main.o rectangle.o

main.o: main.c rectangle.h
	$(CC) $(CFLAGS) -c main.c

rectangle.o: rectangle.c rectangle.h
	$(CC) $(CFLAGS) -c rectangle.c

.PHONY: clean
clean:
	rm -f app app.exe main.o rectangle.o
```

Line by line: `CC` and `CFLAGS` are variables written as `$(CC)` when used. The first rule says: to make `app`, you need `main.o` and `rectangle.o`, then link them. `-c` means "compile only, do not link". The `.o` rules list the `.h` file as a dependency, so changing the header rebuilds both objects. `.PHONY: clean` says `clean` is a job name, not a file, and the `clean` rule deletes the generated files (on Windows PowerShell delete them by hand: `Remove-Item app.exe, main.o, rectangle.o`).

Run `make` on macOS/Linux, or `mingw32-make` on Windows with MSYS2:

**File: terminal (not a saved file)**
```text
make
```

Expected output (not yet run), the three commands in order:

```text
gcc -std=c17 -Wall -Wextra -c main.c
gcc -std=c17 -Wall -Wextra -c rectangle.c
gcc -std=c17 -Wall -Wextra -o app main.o rectangle.o
```

Run `make` again and it says the target is up to date (typical message: `make: 'app' is up to date.`). On Windows the program is really `app.exe`, so `mingw32-make` may rebuild the link step every time; that is harmless. Edit `rectangle.c` (add a space), save and run `make` again: only `rectangle.o` and the link step run.

## How it works
1. `main.c` sees only the **declarations** from `rectangle.h`. That is enough to compile: the compiler checks that `rectangle_area(&desk)` is called with the right types.
2. `rectangle.c` is compiled separately into its own piece. The **linker** joins the pieces and connects each call to the function body. If a body is missing the link step fails (see Common mistakes).
3. The include guard prevents "redefinition" errors when two headers both include `rectangle.h`.
4. The header defines the **interface** (what exists); the `.c` file holds the **implementation** (how it works). Other files depend only on the interface.
5. Misconception: the header is not "the library". It is just text pasted in by `#include`; the compiled code comes from the `.c` file you also build.

## Try it
**Guided.** A temperature library in `try09` (see [exercise folders](../../README.md#exercise-folders)). It already converts Fahrenheit to Celsius. Add the other direction in the header and the source file and call it from `main.c`. Build with `gcc -std=c17 -Wall -Wextra -o app main.c temperature.c`.

**File: `temperature.h` (starter)**
```c
#ifndef TEMPERATURE_H
#define TEMPERATURE_H

double fahrenheit_to_celsius(double f);
/* TODO: declare double celsius_to_fahrenheit(double c); here. */

#endif
```

**File: `temperature.c` (starter)**
```c
#include "temperature.h"

double fahrenheit_to_celsius(double f) {
    return (f - 32.0) * 5.0 / 9.0;
}

/* TODO: define celsius_to_fahrenheit here. */
```

**File: `main.c` (starter)**
```c
#include <stdio.h>

#include "temperature.h"

int main(void) {
    printf("212 F = %.1f C\n", fahrenheit_to_celsius(212.0));
    /* TODO: print the line 100 C = 212.0 F using celsius_to_fahrenheit. */
    return 0;
}
```

Expected output after you finish:

```text
212 F = 100.0 C
100 C = 212.0 F
```

**Change.** Add a `Makefile` for the exercise. **Stretch (optional):** add a function `kelvin_from_celsius` to the library.

<details><summary>Solution</summary>

Replace the three TODO comments. Every other line is unchanged.

**File: `temperature.h` (solution)**
```c
#ifndef TEMPERATURE_H
#define TEMPERATURE_H

double fahrenheit_to_celsius(double f);
double celsius_to_fahrenheit(double c);

#endif
```

**File: `temperature.c` (solution)**
```c
#include "temperature.h"

double fahrenheit_to_celsius(double f) {
    return (f - 32.0) * 5.0 / 9.0;
}

double celsius_to_fahrenheit(double c) {
    return c * 9.0 / 5.0 + 32.0;
}
```

**File: `main.c` (solution)**
```c
#include <stdio.h>

#include "temperature.h"

int main(void) {
    printf("212 F = %.1f C\n", fahrenheit_to_celsius(212.0));
    printf("100 C = %.1f F\n", celsius_to_fahrenheit(100.0));
    return 0;
}
```

</details>

## Check yourself
1. What goes in a header, and what goes in a `.c` file?
   <details><summary>Answer</summary>Declarations (types, prototypes) in the header; function bodies in the `.c` file.</details>
2. What does the include guard prevent?
   <details><summary>Answer</summary>The same header's contents being processed twice, which causes redefinition errors.</details>
3. You change only `rectangle.c` and run `make`. Which commands run?
   <details><summary>Answer</summary>Compiling `rectangle.c` and the final link; `main.c` is not recompiled.</details>
4. Why must a Makefile command line start with a Tab?
   <details><summary>Answer</summary>`make` uses the Tab to recognise a recipe line; spaces give a "missing separator" error.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `undefined reference to 'rectangle_area'` (typical message from the linker, often with `in function 'main'`) | The build command did not list `rectangle.c` | Add every `.c` file to the command. |
| `error: conflicting types for 'Rectangle'` or `redefinition` (typical message) | The header has no include guard and is included twice | Add `#ifndef`, `#define`, `#endif`. |
| `fatal error: rectangle.h: No such file or directory` (typical message) | Header misspelled, or the header is in another folder | Check the spelling and keep it beside `main.c`. |
| `Makefile:4: *** missing separator.  Stop.` (typical message) | A recipe line starts with spaces | Replace the leading spaces with one Tab. |
| `make: command not found` or `mingw32-make: command not found` | Make is not installed or not on the PATH | Redo the install in lesson 01 and open a new terminal. |
| The new function is "unknown" in `main.c` | The prototype was not added to the header | Declare it in the header. |

## Best practice
Put only declarations in headers and give every header an include guard. Source: GNU Make manual, Introduction https://www.gnu.org/software/make/manual/html_node/Introduction.html

## Going further
- How `make` decides what to rebuild: https://www.gnu.org/software/make/manual/make.html
- CMake, a tool that writes Makefiles for you, is used in lesson 12.

## Summary
- You split a program into a header, a source file and `main.c`.
- You explained the include guard.
- You built several files together and with a Makefile.

## Next lesson
**[10. Memory and common bugs](../phase-3-real-programs/10-memory-and-bugs.md):** ask for memory while the program runs, give it back and avoid the classic C mistakes.
