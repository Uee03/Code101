# Go 201, Phase 1: Core Skills

Source pack for lessons 01 to 04 of **Go 201 (Hero to Super Hero)**. Every file is also shown in the lessons, so the pack is optional. It is also in the repository https://github.com/Uee03/Code101 under `source/go/201-hero-to-super-hero/phase-1-core-skills/` (**Code > Download ZIP**, or `git clone`).

| Folder | Lesson | You build / exercise |
|---|---|---|
| `01-interfaces-and-embedding` | Interfaces, embedding and small interfaces | a `Sender` interface, a counting wrapper, a fake / an `io.Writer` decorator |
| `02-goroutines-and-channels` | Goroutines and channels | a worker pool and pipeline / order-preserving squares and a timeout |
| `03-sync-context-cancellation` | sync, context and cancellation | a safe counter, timeouts, a stoppable ticker / an `RWMutex` cache and a context-aware wait |
| `04-generics` | Generics | `Map`, `Filter`, `Stack[T]`, `Set[T]` / `SortedKeys` and `GroupBy` |

## Inside each lesson folder

| Folder or file | What it is |
|---|---|
| `code/` | The finished program of the lesson, its own module with `go.mod`, with tests |
| `exercise/starter/` | The exercise starting point with TODO comments; its own module (`try0N`) |
| `exercise/solution/` | The complete answer; try the exercise first |
| `verify.json` | Maintainer file for automated checks; learners can ignore it |

## How to run

1. Install Go 1.22.0 or newer.
2. Unzip the pack (Windows: right-click > **Extract All**; macOS: double-click; Linux: `unzip go-201-phase-1-core-skills.zip`).
3. Open a terminal **in one lesson's `code` folder** (for example `01-interfaces-and-embedding/code`), check with `pwd` (or `Get-Location` in PowerShell), and run:
   ```text
   go run .
   go test ./...
   ```
   Do not run `go mod init`: `go.mod` is included. No external dependencies, so nothing is downloaded.
4. For an exercise, copy `exercise/starter` to a new folder named `try01` (use the lesson's number), open that folder and run `go run .`. Compare with `exercise/solution`.

## Needs

Go 1.22.0 or newer, nothing else. The race detector (`go test -race ./...`) mentioned in lessons 02 and 03 may need a C compiler on your platform.

## Status

Written by reading the code and the official documentation; **not yet run**. The lessons say so at the top. Level 201 continues with `phase-2-http-and-json`.
