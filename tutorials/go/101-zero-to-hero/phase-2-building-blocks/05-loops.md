---
track: go
level: 101
phase: 2
phase_name: building-blocks
lesson: 05
title: "Loops"
time: 35 min
prerequisites: [101.1.04]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-2-building-blocks/05-loops/
assets: []
---

# 05. Loops

## Why it matters
A musician practices a phrase several times instead of rewriting it. A loop repeats instructions while a rule allows it. Go has just one loop keyword: for.

## What you will build
A three-day total, a shrinking countdown and a turn counter that skips one turn then stops.

## Before you start
- Finish lesson 04. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 35 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-2-building-blocks/05-loops/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson05`, full path `$HOME/code101/go/lesson05`. Do not put it inside another lesson. Open **only** `lesson05` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson05"`; macOS/Linux `cd "$HOME/code101/go/lesson05"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson05`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson05
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson05
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson05`.

### Step 3. Write the complete program
A **loop** repeats a block; that block is the loop's **body**. If it keeps printing without stopping, press **Ctrl+C** in the terminal before editing.

| Form | Meaning |
|---|---|
| `for start; condition; update { ... }` | prepare once, check each turn, update after each turn |
| `for condition { ... }` | repeat while condition is true |
| `for { ... }` | repeat until the body exits |

Lesson 07 adds for ... range. Go has no separate while or do loop.

In the Explorer select the root `lesson05` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func main() {
	total := 0
	for day := 1; day <= 3; day++ {
		total += day
		fmt.Println("Day:", day)
	}
	fmt.Println("Total:", total)
	remaining := 2
	for remaining > 0 {
		fmt.Println("Remaining:", remaining)
		remaining--
	}
	turn := 0
	for {
		turn++
		if turn == 2 {
			continue
		}
		if turn > 3 {
			break
		}
		fmt.Println("Turn:", turn)
	}
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson05 folder (or the pack's 05-loops/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Day: 1
Day: 2
Day: 3
Total: 6
Remaining: 2
Remaining: 1
Turn: 1
Turn: 3
```

## How it works
1. total is an **accumulator**, a running total. Start day at 1, check day <= 3, run the body, then day++ increases it by one. total += day means total = total + day.
2. The sum is 6. day exists only in that loop. **Scope** is the region where a name is available.
3. remaining-- decreases by one. At zero the next check is false. ++ and -- are statements, not values you can put inside Println.
4. continue skips the rest of an **iteration** (one pass); break leaves the nearest loop. Turn 2 is skipped, 3 prints, 4 breaks.
5. An **infinite loop** never ends unless its body exits. Ctrl+C stops a stuck terminal program on every OS. Decide what changes the condition or causes a break before running.

## Try it
Countdown: start at 3, use a counted for loop to print 3, 2, 1, decreasing the counter and stopping at zero. Print Go! after the loop.

If using the optional source, find `05-loops/exercise/starter`, then copy the `starter` folder and rename it `try05` alongside `lesson05` in `$HOME/code101/go`. `try05` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try05` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try05` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try05"`; macOS/Linux `cd "$HOME/code101/go/try05"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson05

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func main() {
	start := 3
	// TODO: print 3, 2, 1 with a for loop, then Go!
	fmt.Println("Start:", start)
}
```

In `try05` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
3
2
1
Go!
```

<details><summary>Solution</summary>

In `try05`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 4-11)**
```go

func main() {
	start := 3
	for count := start; count > 0; count-- {
		fmt.Println(count)
	}
	fmt.Println("Go!")
}
```

</details>

## Check yourself
1. Which keyword repeats work?
   <details><summary>Answer</summary>for.</details>
2. What does day++ do?
   <details><summary>Answer</summary>Increases day by one.</details>
3. How do break and continue differ?
   <details><summary>Answer</summary>break exits; continue skips the rest of one iteration.</details>
4. Why decrease remaining?
   <details><summary>Answer</summary>Otherwise its condition stays true forever.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson05` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try05` folder. |
| `Remaining: 2 (keeps repeating)` | Deleted remaining--, so the condition never changes | Press **Ctrl+C** in the terminal, restore `remaining--` inside the loop, save and rerun. |
| `.\main.go:11:31: undefined: day` | Used day after its loop | Keep day inside its loop; its name is not available after the loop. |
| `.\main.go:28:1: syntax error: unexpected EOF, expected }` | Deleted the final closing brace | Restore main's final `}`. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Use the simplest for form that expresses the stopping rule. Source: Effective Go: For https://go.dev/doc/effective_go#for

## Next lesson
**[06. Functions](06-functions.md):** name reusable calculations and return results.
