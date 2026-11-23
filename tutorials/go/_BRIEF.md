# Go track brief - 101 Zero to Hero

## Learners and outcome
Complete beginners from any field. Start with an everyday analogy, define new words,
show every folder, full file, command and real output. Finish with a small console
expense tracker that saves a CSV file. No prior programming, external libraries,
accounts, web servers or concurrency needed.

## Plan (12 lessons, three packs)
| Phase | Lesson | Build / exercise |
|---|---|---|
| 1 Foundations | 01 Hello, Go | OS setup, terminal, editor, module, greeting / recipe card |
| 1 | 02 Variables and types | inventory, var, :=, constants, zero values / stock update |
| 1 | 03 Input and math | Scanner, Scan, Atoi, ParseFloat, operators, tips / service charge |
| 1 | 04 Making decisions | if/else, switch, comparisons, &&, \|\|, ! / grade checker |
| 2 Building blocks | 05 Loops | all forms of for, break, continue / countdown |
| 2 | 06 Functions | parameters, multiple results, explicit named results / bill split |
| 2 | 07 Slices and maps | append, range, lookup, delete / shopping total |
| 2 | 08 Files | ReadFile, WriteFile, Scanner, restricted hand-written CSV / third row |
| 3 Real programs | 09 Errors | error values, New, wrapping, re-ask / minimum amount |
| 3 | 10 Structs and methods | record, value and pointer receivers / discount method |
| 3 | 11 Interfaces and packages | small interface, own package, exported names / second implementation |
| 3 | 12 Project: expense tracker | load/add/list/total/save CSV, integer cents, plain self-check / count command |

## Versions and verification
Minimum Go **1.22.0**, stated in supplied go.mod files and lesson front matter. Leave generated go.mod versions alone; there is no hand-edit step. Author toolchain:
Go 1.27.4 on Windows. Each code folder is a separate module; each exercise is runnable
in its own copied folder too. Use only the standard library. Smoke checks only:
one go run . with small input in code and one in exercise/solution. No go test or go vet.
Capture output before copying code into lessons; trigger compiler errors separately.
Verify with python scripts/verify_labs.py source/go/ (path substring, not go-101).
Build with python scripts/build_packs.py go-101. No art; assets: [].

## Sources (Tier 1: official; no Tier 2 required)
- Install: https://go.dev/doc/install and https://go.dev/dl/
- Editor: https://code.visualstudio.com/docs/getstarted/overview and https://code.visualstudio.com/docs/languages/go
- Modules: https://go.dev/doc/tutorial/create-module and https://go.dev/ref/mod
- Core style: https://go.dev/doc/effective_go
- Language: https://go.dev/ref/spec and https://go.dev/tour/
- Errors: https://go.dev/doc/tutorial/handle-errors and https://go.dev/blog/go1.13-errors
- Library: https://pkg.go.dev/fmt, https://pkg.go.dev/bufio, https://pkg.go.dev/strconv,
  https://pkg.go.dev/os, https://pkg.go.dev/strings, https://pkg.go.dev/encoding/csv

## Scope choices
Introduce a small explained error guard in 03, then develop it fully in 09.
Teach Scanner as the main path; the separate Scan run is optional, not needed by exercises.
Hand-written CSV is intentionally restricted: no commas, quotes or newlines in labels;
use encoding/csv for general CSV. Integer cents in the project avoid floating-point
money totals. Installation allows 60 minutes. Lessons 03/07/10 allow 60/40/50 minutes, with unneeded internals trimmed or optional. The project allows 90 minutes in two sittings, with a marked break after Step 4. Other lessons allow 35-45 minutes for first-time reading, typing and exercises. Shared logistics live in README.md; solution sections show only changed regions.
