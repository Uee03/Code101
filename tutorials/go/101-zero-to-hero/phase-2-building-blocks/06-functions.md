---
track: go
level: 101
phase: 2
phase_name: building-blocks
lesson: 06
title: "Functions"
time: 40 min
prerequisites: [101.2.05]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-2-building-blocks/06-functions/
assets: []
---

# 06. Functions

## Why it matters
A reusable recipe takes ingredients and produces a result. A function takes inputs and returns results without copying instructions. Go can return several results together.

## What you will build
A rectangle calculator returning area and perimeter, and a bill splitter returning an amount and validity flag.

## Before you start
- Finish lesson 05. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-2-building-blocks/06-functions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson06`, full path `$HOME/code101/go/lesson06`. Do not put it inside another lesson. Open **only** `lesson06` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson06"`; macOS/Linux `cd "$HOME/code101/go/lesson06"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson06`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson06
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson06
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson06`.

### Step 3. Write the complete program
A **parameter** names an input in a function definition. An **argument** is the actual value supplied by a call: width is a parameter; 3 is an argument. rectangle declares two int inputs and two int results. Capture both results, or discard one deliberately with _.

In the Explorer select the root `lesson06` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func rectangle(width int, height int) (int, int) {
	area := width * height
	perimeter := 2 * (width + height)
	return area, perimeter
}

func split(total float64, people int) (each float64, valid bool) {
	if people <= 0 {
		return 0, false
	}
	each = total / float64(people)
	valid = true
	return each, valid
}

func main() {
	area, perimeter := rectangle(3, 4)
	fmt.Println("Area:", area, "Perimeter:", perimeter)
	each, valid := split(90, 3)
	fmt.Printf("Each: %.2f; valid: %t\n", each, valid)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson06 folder (or the pack's 06-functions/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Area: 12 Perimeter: 14
Each: 30.00; valid: true
```

## How it works
1. Go starts in main, not at the first function written. rectangle(3, 4) supplies width 3 and height 4. Local variables belong to that function's scope.
2. return area, perimeter sends values back and ends the function. **Multiple return values** return related results without combining them into one value.
3. split declares **named results**: (each float64, valid bool) creates variables initially at their zero values. It returns 0 and false before dividing if people is invalid.
4. The valid path assigns and explicitly returns both results, making the returned data visible.
5. A **caller** is the code that runs a function. Callers receive results in order. A function promising results must return them on every possible path. main promises none, so its early return has no values.

## Try it
Delivery split: share the total bill plus a fixed 6.00 delivery charge equally among the people. Invalid people counts must still be rejected. With a 90.00 bill and 3 people, print 32.00 each and keep both results.

If using the optional source, find `06-functions/exercise/starter`, then copy the `starter` folder and rename it `try06` alongside `lesson06` in `$HOME/code101/go`. `try06` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try06` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try06` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try06"`; macOS/Linux `cd "$HOME/code101/go/try06"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson06

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func rectangle(width int, height int) (int, int) {
	area := width * height
	perimeter := 2 * (width + height)
	return area, perimeter
}

func split(total float64, people int) (each float64, valid bool) {
	if people <= 0 {
		return 0, false
	}
	// TODO: include a 6.00 delivery charge before dividing.
	each = 0
	valid = true
	return each, valid
}

func main() {
	area, perimeter := rectangle(3, 4)
	fmt.Println("Area:", area, "Perimeter:", perimeter)
	each, valid := split(90, 3)
	fmt.Printf("Each: %.2f; valid: %t\n", each, valid)
}
```

In `try06` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Area: 12 Perimeter: 14
Each: 32.00; valid: true
```

<details><summary>Solution</summary>

In `try06`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 12-18)**
```go
	if people <= 0 {
		return 0, false
	}
	each = (total + 6) / float64(people)
	valid = true
	return each, valid
}
```

</details>

## Check yourself
1. How many results does rectangle return?
   <details><summary>Answer</summary>Two: area, then perimeter.</details>
2. Is width a parameter?
   <details><summary>Answer</summary>Yes; 3 in a call is an argument.</details>
3. What are the initial named-result values in split?
   <details><summary>Answer</summary>each is 0 and valid is false.</details>
4. Why check people first?
   <details><summary>Answer</summary>To avoid zero or negative divisors.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson06` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try06` folder. |
| `.\main.go:9:1: missing return` | Printed the results instead of returning them | Restore `return area, perimeter`. |
| `.\main.go:21:31: cannot use "3" (untyped string constant) as int value in argument to rectangle` | Passed text where rectangle needs an int | Pass `3`, not `"3"`. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Named results can document a function; keep explicit return values when they clarify the flow. Source: Effective Go: Named result parameters https://go.dev/doc/effective_go#named-results

## Next lesson
**[07. Slices and maps](07-slices-and-maps.md):** collect values in slices and maps.
