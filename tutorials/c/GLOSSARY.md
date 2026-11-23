# C glossary

Definitions follow the first introduction in the 101 lessons.

## 01. Hello, C: install and first program

- **compiler:** A tool that translates your C source file into a program the computer can run.
- **terminal:** A window where you type commands and press Enter.
- **prompt:** The text before the typing area; not part of a command.
- **editor:** An application for writing and saving text files.
- **PATH:** The list of folders where the operating system looks for commands.
- **function:** A named block of steps; every C program starts in `main`.
- **string:** Text in double quotes, such as `"Hello"`.
- **escape sequence:** A backslash code inside text, such as `\n` for a new line.
- **standard input/output library:** The ready-made tools in `<stdio.h>`, such as `printf`.
- **building / compiling / running:** Translating the source into a program file / the translation step / starting the program.

## 02. Types, printf and scanf

- **variable:** A named place in memory that holds a value.
- **type:** The kind of value a variable holds (`int`, `double`, `char`).
- **declaration:** The line that creates a variable: type, name, first value.
- **const:** Marks a value that may not change after it is set.
- **format string / format code:** The first text of `printf`, with `%` holes filled by the following values.
- **address (first mention):** Where a variable lives in memory; `&x` is the address of `x`.
- **integer division:** Dividing two `int` values drops the fraction (`7 / 2` is 3).
- **remainder:** What is left after integer division; the `%` operator (`7 % 2` is 1).

## 03. Making decisions

- **condition:** A question whose answer is true or false.
- **comparison operators:** `==`, `!=`, `<`, `<=`, `>`, `>=`.
- **logical operators:** `&&` (and), `||` (or), `!` (not).
- **switch / case / break / default:** Choose between fixed whole-number values; `break` leaves the switch.

## 04. Loops

- **loop:** A block of statements repeated while a condition stays true.
- **for / while / do ... while:** The three loop forms; `do ... while` always runs at least once.
- **`i++`, `i--`, `+=`:** Add 1, subtract 1, add to a variable.
- **break / continue:** Leave the loop / skip to the next round.
- **endless loop:** A loop whose condition never becomes false; stop it with Ctrl+C.

## 05. Functions

- **return type / parameter / argument:** The kind of value handed back / an input name in the definition / the value given in a call.
- **caller:** The code that calls a function.
- **prototype:** A function's first line followed by `;`, announcing it before it is defined.
- **pass by value:** The function receives a copy of each argument.
- **local variable:** A variable that exists only inside one function call.

## 06. Arrays and strings

- **array / index:** A row of same-type boxes under one name / the box number, counting from 0.
- **undefined behaviour:** A mistake for which C promises nothing (crash, garbage or apparent success).
- **`#define`:** Gives a name to a value before compiling.
- **terminator (`'\0'`):** The character with code 0 that ends a string.
- **cast:** Converts a value to another type on purpose, e.g. `(double)n`.
- **`fgets`:** Reads one line, never more than the size given.

## 07. Pointers

- **pointer:** A variable that holds an address.
- **dereference:** Following a pointer to the value it points to (`*p`).
- **`NULL`:** The pointer value that points nowhere.
- **`const` pointer parameter:** A promise that the function will only read through the pointer.

## 08. Structs

- **struct / field:** A record that bundles related values / one value inside it.
- **`typedef`:** Gives a type a new name.
- **`.` and `->`:** Field access on a variable / through a pointer.

## 09. Headers and multiple files

- **header file (`.h`) / source file (`.c`):** Declarations that other files include / the file with the function bodies.
- **include guard:** `#ifndef` / `#define` / `#endif` around a header so it is processed once.
- **object file (`.o`) / linker:** A compiled but unlinked piece / the tool that joins pieces into a program.
- **Makefile / rule / target:** A file of build rules / `target: dependencies` plus a command / the file a rule makes.

## 10. Memory and common bugs

- **dynamic memory / heap / stack:** Memory rented while the program runs / where `malloc` memory lives / memory C manages automatically for local variables.
- **`malloc`, `realloc`, `free`:** Ask for memory, resize it, give it back.
- **`sizeof`:** The size in bytes of a type or value.
- **dangling pointer:** A pointer that still holds the address of freed memory.
- **memory leak / use after free / double free / buffer overflow:** Forgetting to free / using freed memory / freeing twice / writing past the end of a block.
- **AddressSanitizer:** A compiler option (`-fsanitize=address`) that inserts memory checks.

## 11. Files

- **file handle (`FILE *`):** The connection between a program and a file.
- **modes `"r"`, `"w"`, `"a"`:** Read / write (empties the file) / append.
- **`sscanf` / `fscanf`:** `scanf` that reads from a string / from a file.

## 12. Project: expense tracker

- **conditional operator (`?:`):** `condition ? a : b` gives `a` when true, otherwise `b`.
- **`static` function:** A function only its own file can use.
- **`size_t`:** The unsigned whole-number type C uses for sizes and counts.
- **CMake:** A tool that reads `CMakeLists.txt` and writes the build files for your compiler.
