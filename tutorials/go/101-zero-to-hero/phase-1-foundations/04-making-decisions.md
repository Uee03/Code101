---
track: go
level: 101
phase: 1
phase_name: foundations
lesson: 04
title: "Making decisions"
time: 40 min
prerequisites: [101.1.03]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-1-foundations/04-making-decisions/
assets: []
---

# 04. Making decisions

## Why it matters
A ticket clerk applies rules: a young child enters free; another visitor pays. A condition is the program version of a yes/no question. Combining questions expresses realistic rules.

## What you will build
A ticket-rule demonstration with comparisons, combined conditions and a weekend switch. Edit a stored age so you can focus on decisions.

## Before you start
- Finish lesson 03. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-1-foundations/04-making-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson04`, full path `$HOME/code101/go/lesson04`. Do not put it inside another lesson. Open **only** `lesson04` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson04"`; macOS/Linux `cd "$HOME/code101/go/lesson04"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson04`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson04
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson04
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson04`.

### Step 3. Write the complete program
A **comparison** relates two values and produces a bool.

| Symbol | Question |
|---|---|
| `==` / `!=` | equal / not equal? |
| `<` / `>` | less / greater? |
| `<=` / `>=` | less or equal / greater or equal? |
| `&&` | both sides true? |
| `\|\|` | at least one side true? |
| `!` | reverse true and false |

= stores a value; == compares. Keep opening braces on the if/switch line; write } else { together.

In the Explorer select the root `lesson04` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func main() {
	age := 30
	hasTicket := true
	fmt.Println("5 > 3:", 5 > 3)
	fmt.Println("5 < 3:", 5 < 3)
	fmt.Println("5 == 5:", 5 == 5)
	fmt.Println("5 != 5:", 5 != 5)
	fmt.Println("5 >= 5:", 5 >= 5)
	fmt.Println("5 <= 5:", 5 <= 5)
	fmt.Println("Adult with ticket:", age >= 18 && hasTicket)
	fmt.Println("Child or ticket:", age < 18 || hasTicket)
	fmt.Println("No ticket:", !hasTicket)
	if age < 0 {
		fmt.Println("Invalid age")
	} else if age < 5 {
		fmt.Println("Ticket: free")
	} else if age < 18 {
		fmt.Println("Ticket: 5.00")
	} else {
		fmt.Println("Ticket: 10.00")
	}
	day := "Saturday"
	switch day {
	case "Saturday", "Sunday":
		fmt.Println("Weekend hours")
	default:
		fmt.Println("Weekday hours")
	}
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson04 folder (or the pack's 04-making-decisions/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
5 > 3: true
5 < 3: false
5 == 5: true
5 != 5: false
5 >= 5: true
5 <= 5: true
Adult with ticket: true
Child or ticket: true
No ticket: false
Ticket: 10.00
Weekend hours
```

### Step 4. Change the age and rerun
Keep the terminal in `lesson04`. First change `age := 30` to `age := 3` in `main.go`, save, and run `go run .`. Then repeat the identical save-and-run step with age 12, then -1; only that number changes. Captured full outputs follow.

**Age 3: terminal output**
```text
5 > 3: true
5 < 3: false
5 == 5: true
5 != 5: false
5 >= 5: true
5 <= 5: true
Adult with ticket: false
Child or ticket: true
No ticket: false
Ticket: free
Weekend hours
```

**Age 12: terminal output**
```text
5 > 3: true
5 < 3: false
5 == 5: true
5 != 5: false
5 >= 5: true
5 <= 5: true
Adult with ticket: false
Child or ticket: true
No ticket: false
Ticket: 5.00
Weekend hours
```

**Age -1: terminal output**
```text
5 > 3: true
5 < 3: false
5 == 5: true
5 != 5: false
5 >= 5: true
5 <= 5: true
Adult with ticket: false
Child or ticket: true
No ticket: false
Invalid age
Weekend hours
```

Finally restore `age := 30` and save, so your source matches Step 3.

## How it works
- A **boolean expression** produces true or false. A **condition** uses it to choose whether a block runs. age >= 18 && hasTicket is true for age 30 with a ticket.
- && evaluates its right side only when the left is true; || only when the left is false. This is **short-circuit evaluation**. !hasTicket flips the answer.
- An **if/else chain** checks top to bottom, running the first matching **branch** (choice of block). else catches what remains. Check negative ages first so invalid input does not get a free ticket.
- Braces, not indentation, group Go instructions. No colon follows if and no parentheses are required around its condition.
- A **switch** chooses the matching case. Comma-separated weekend strings are alternatives; default is the fallback. Normal cases do not continue into the next case, so no break is needed.

## Try it
Grade checker: score := 60 should print Pass. Reject outside 0..100 first using ||. Print Fail below 50, Pass below 75, otherwise Merit. Replace the TODO output with an if/else chain.

If using the optional source, find `04-making-decisions/exercise/starter`, then copy the `starter` folder and rename it `try04` alongside `lesson04` in `$HOME/code101/go`. `try04` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try04` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try04` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try04"`; macOS/Linux `cd "$HOME/code101/go/try04"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson04

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func main() {
	score := 60
	// TODO: invalid outside 0..100; Fail below 50; Merit from 75; otherwise Pass.
	fmt.Println("Score:", score)
}
```

In `try04` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Pass
```

<details><summary>Solution</summary>

In `try04`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 4-16)**
```go

func main() {
	score := 60
	if score < 0 || score > 100 {
		fmt.Println("Invalid score")
	} else if score < 50 {
		fmt.Println("Fail")
	} else if score < 75 {
		fmt.Println("Pass")
	} else {
		fmt.Println("Merit")
	}
}
```

</details>

## Check yourself
1. How do = and == differ?
   <details><summary>Answer</summary>= assigns; == compares.</details>
2. What does !true give?
   <details><summary>Answer</summary>false.</details>
3. Can age 3 run both ticket branches?
   <details><summary>Answer</summary>No, only the first true branch runs.</details>
4. Do normal switch cases need break?
   <details><summary>Answer</summary>No.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson04` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try04` folder. |
| `.\main.go:17:9: syntax error: cannot use assignment age = 5 as value` | Used assignment where a condition was needed | Use `==` for equality, not `=`; restore `age < 0` for this guard. |
| `.\main.go:20:2: syntax error: unexpected keyword else, expected }` | Put else on a separate line | Write `} else if age < 5 {` on one line. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Keep opening braces on the condition line and else on the preceding closing-brace line. Source: Effective Go: Semicolons https://go.dev/doc/effective_go#semicolons

## Next lesson
**[05. Loops](../phase-2-building-blocks/05-loops.md):** repeat with for; Phase 1 is complete.
