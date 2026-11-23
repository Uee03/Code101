# C++ track brief - 101 Zero to Hero

## Learners and outcome
Complete beginners from any field; knowing C is not required. Start with an everyday analogy,
define new words, show every folder, full file, command and (derived) output. Finish with a
small console expense tracker that saves a text file. No external libraries, accounts or GUI.
Desktop windows (Qt or Dear ImGui) come at level 201.

## Plan (12 lessons, three packs)
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 Foundations | 01 Hello, C++ | install compiler + CMake (Windows MSVC Build Tools or MSYS2, macOS xcode-select, Linux build-essential), CMake project, hello / business card |
| 1 | 02 Types and output | int, double, bool, char, std::string, const, brace init, cout formatting / pizza order |
| 1 | 03 Input and decisions | cin, getline, failed input, if/else if/else, && \|\| ! / grade checker |
| 1 | 04 Loops | for, while, range-for, break, continue, sentinel input / countdown by twos |
| 2 Building blocks | 05 Functions and references | parameters, returns, struct result, &, const & / discount |
| 2 | 06 Strings and vectors | std::string ops, find/substr, vector push_back/back/pop_back / name list |
| 2 | 07 Maps and algorithms | std::map, structured bindings, sort/accumulate/find / stock map |
| 2 | 08 Pointers and references | &, *, nullptr, non-owning pointers, phase 1-2 review / cheapest price |
| 3 Real programs | 09 Classes and RAII | class, ctor, private, const members, destructor, scope / wallet |
| 3 | 10 Smart pointers | unique_ptr, make_unique, std::move, no new/delete / ticket factory |
| 3 | 11 Files and errors | ofstream, ifstream, getline loop, throw, try/catch / archive lookup |
| 3 | 12 Project: expense tracker | header + source + main, command loop, cents, save/load, phase review / count command |

## Versions and verification policy
C++20 (CXX_STANDARD via `cxx_std_20`, extensions off), CMake 3.28 or newer. Compilers: GCC 11+,
Clang 14+, MSVC from Visual Studio 2022 Build Tools. Standard library only (`<filesystem>`, `<map>`,
`<memory>`, `<fstream>`, `<sstream>`, `<algorithm>`, `<numeric>`, `<iomanip>`).
**Status: written, not yet run.** Under the repository's no-smoke-test policy nothing was built or
executed; expected output was derived by reading the code. Every lesson carries the draft notice and
`verified: not yet run`. Each `verify.json` configures, builds and runs `code` and `exercise/solution`
with `cmake -S . -B build`, `cmake --build build` and `cmake -E env build/out/NAME`, so a later run can
confirm everything and remove the notices.

## Layout and build decisions
- One CMake project per lesson/exercise; the program lands in `build/out/` on every generator through
  `set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<1:out>")` (a generator expression stops Visual Studio
  from adding `Debug/`). If a later run shows a different location, fix this one line in every CMakeLists.txt.
- Warnings on (`/W4 /permissive-` for MSVC, `-Wall -Wextra -Wpedantic` otherwise). Some starters warn about an unused
  parameter on purpose until the TODO is done.
- Program names per lesson: hello, types, ticket, loops, functions, strings, maps, pointers, account, smartptr, files, tracker.
- Money is stored as whole cents in lessons 09 and 12; amounts typed as double are rounded once with std::llround.
- Brace initialisation, `std::` always spelled out, no `using namespace`, `'\n'` instead of `std::endl`.

## Sources (Tier 1: official)
- C++ Core Guidelines: https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines (rule ids cited in every Best practice)
- Language and library reference: https://en.cppreference.com/
- CMake: https://cmake.org/cmake/help/latest/guide/tutorial/index.html and https://cmake.org/download/
- MSVC Build Tools: https://learn.microsoft.com/en-us/cpp/overview/acquire-msvc
- MSYS2: https://www.msys2.org/
- Editor: https://code.visualstudio.com/docs/languages/cpp

## Scope choices
No templates, move semantics beyond `std::move` for `unique_ptr`, `shared_ptr`, inheritance, operator overloading, lambdas,
exceptions beyond `runtime_error` / `invalid_argument`, or manual `new`/`delete` (shown once, labelled "do not write this").
Lesson 03 avoids mixing `>>` and `getline` (the pitfall is named, the fix is not taught). Hand-written text file format in lessons 11
and 12 is deliberately simple (no empty labels). Times: 01 90; 02 40; 03 50; 04 45; 05 50; 06 50; 07 60; 08 40; 09 60; 10 50; 11 60; 12 90 (two sittings, break after Step 4).
