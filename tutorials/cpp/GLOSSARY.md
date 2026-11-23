# C++ glossary

Definitions follow the first introduction in the 101 lessons.

## 01. Hello, C++

- **terminal:** A window for typing commands and pressing Enter.
- **prompt:** The text before your cursor; not part of a command.
- **current folder:** The folder a command works in.
- **compiler:** A tool that translates source text into a program the processor can run.
- **CMake:** A build tool that reads `CMakeLists.txt` and drives the compiler on any operating system.
- **configure (CMake):** The first CMake command: reads the recipe and prepares the `build` folder.
- **build:** The second command: runs the compiler and linker to create the program.
- **linker:** The step that joins compiled pieces into one program.
- **editor:** An application for writing and saving text files.
- **source file:** A text file of program instructions; C++ source files end in `.cpp`.
- **header:** A file of declarations you include, such as `<iostream>`.
- **function:** A named block of instructions; every program starts at `main`.
- **namespace:** A family name for names; `std::` means the standard library.
- **string literal:** Text between double quotes in the source.
- **statement:** An instruction that ends with a semicolon.
- **warning:** A compiler message that does not stop the build but points at something probably wrong.

## 02. Types and output

- **variable:** A named place in memory with a type and a value.
- **type:** The kind of value a variable holds, such as `int` or `double`.
- **brace initialisation:** Giving a variable its starting value with `{ }`; it refuses narrowing conversions.
- **const:** Marks a value that never changes after it is set.
- **assignment:** Storing a new value in a variable with `=`.
- **sticky (stream manipulator):** A setting such as `std::fixed` that stays on for later output.
- **narrowing conversion:** A conversion that could lose information, for example `double` to `int`.

## 03. Input and decisions

- **standard input stream (`std::cin`):** What the user types in the terminal.
- **failed state:** The condition of a stream after a read did not work.
- **condition:** A true-or-false test.
- **comparison operators:** `<`, `>`, `<=`, `>=`, `==`, `!=`.
- **logical operators:** `&&` (and), `||` (or), `!` (not).
- **magic constant:** A bare number in code whose meaning is not named.

## 04. Loops

- **loop:** Code that repeats.
- **iteration:** One pass through a loop's block.
- **infinite loop:** A loop whose condition never becomes false; stop it with Ctrl+C.
- **range-based for:** A loop that visits each item of a container or string.
- **off-by-one error:** A loop that runs one time too few or too many.

## 05. Functions and references

- **return type, parameter, argument, body:** The output type, the named inputs, the actual values given in a call, and the code inside the braces.
- **pass by value:** The function gets its own copy.
- **struct:** A new type that bundles named values (its members).
- **void:** The return type of a function that returns nothing.
- **reference:** Another name for an existing variable; `double&`.
- **const reference:** A read-only reference, `const std::string&`, which avoids a copy.

## 06. Strings and vectors

- **std::string:** A type that owns and grows text.
- **position / index:** A place in a string or vector, counting from 0.
- **npos:** The special value `find` returns when nothing matches.
- **std::size_t:** The whole-number type used for sizes and positions.
- **std::vector:** A list of items of one type that grows on demand.
- **undefined behaviour:** A bug that the language does not promise to report; the program may crash or appear to work.

## 07. Maps and algorithms

- **std::map:** A container of unique keys, kept sorted, each with a value.
- **key / value:** The lookup name and what is stored under it.
- **structured binding:** `[word, count]`: names for the parts of a pair.
- **auto:** Lets the compiler work out a type.
- **iterator:** A marker pointing at an item; `begin()` is the first, `end()` is just past the last.
- **algorithm:** A ready-made operation on a range, such as `std::sort`.

## 08. Pointers and references

- **address:** Where an item lives in memory.
- **pointer:** A variable that holds an address; `int*`.
- **dereference:** Using `*pointer` to reach the value at the address.
- **nullptr:** The pointer value that points at nothing.
- **dangling pointer:** A pointer to something that no longer exists.
- **non-owning (borrowed) pointer:** A pointer that only looks; someone else owns the object.

## 09. Classes and RAII

- **class:** A type with private data and member functions that protect its rules.
- **member function:** A function that belongs to a class.
- **invariant:** A rule that must always hold for an object.
- **constructor:** The function that sets up an object; same name as the class.
- **member initialiser list:** `: owner_{owner}`, which sets members while the object is built.
- **explicit:** Stops a one-argument constructor being used for accidental conversions.
- **const member function:** A member function that promises not to change the object.
- **destructor:** The function `~Name()` that runs automatically when an object's scope ends.
- **scope:** The region of code between braces in which a name exists.
- **RAII:** Resource Acquisition Is Initialisation: take a resource in the constructor, give it back in the destructor.

## 10. Smart pointers

- **free store (heap):** Memory whose lifetime is chosen while the program runs.
- **std::unique_ptr:** A smart pointer that is the single owner of an object and deletes it when destroyed.
- **std::make_unique:** Creates an object and returns the `unique_ptr` that owns it.
- **ownership:** The responsibility to clean up an object.
- **std::move:** Hands ownership to someone else; the source becomes empty.

## 11. Files and errors

- **std::ofstream / std::ifstream:** Streams that write to or read from a file.
- **relative path:** A file name looked up from the current folder.
- **exception:** An error object that is thrown and travels outward to a matching `catch`.
- **throw / try / catch:** Raise an exception, guard code, handle an exception.
- **std::runtime_error:** The standard exception type for failures found while running.

## 12. Project: expense tracker

- **include guard (`#pragma once`):** Makes a header be read only once.
- **linker error:** A build error when a promised function has no body in any compiled file.
- **std::istringstream:** A stream that reads from a string.
- **std::ostringstream:** A stream that writes into a string.
- **anonymous namespace:** `namespace { ... }`: helpers private to one file.
- **command loop:** A loop that reads a command, runs it and repeats.
