---
track: go
level: 101
phase: 1
phase_name: foundations
lesson: 02
title: "Variables and types"
time: 35 min
prerequisites: [101.1.01]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-1-foundations/02-variables-and-types/
assets: []
---

# 02. Variables and types

## Why it matters
Labelled jars help a cook remember what is inside. A variable is a labelled place for a value; its type tells Go what kind belongs there. Go catches many mix-ups before the program runs.

## What you will build
An inventory card with an item, quantity, price, stock flag and the default values of empty variables.

## Before you start
- Finish lesson 01. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 35 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-1-foundations/02-variables-and-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson02`, full path `$HOME/code101/go/lesson02`. Do not put it inside another lesson. Open **only** `lesson02` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson02"`; macOS/Linux `cd "$HOME/code101/go/lesson02"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson02`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson02
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson02
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson02`.

### Step 3. Write the complete program
A declaration gives a name to a value; later assignment can change it.

| Type | Meaning | Example | Zero value |
|---|---|---|---|
| `int` | whole number | `3` | `0` |
| `float64` | number allowing decimal fractions | `2.5` | `0` |
| `string` | text in double quotes | `"tea"` | `""` (empty text) |
| `bool` | yes/no value | `true` or `false` | `false` |

In the Explorer select the root `lesson02` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func main() {
	var item string = "notebook"
	quantity := 3
	var price float64 = 2.5
	var inStock bool = true
	const shop = "Corner Shop"
	quantity = quantity + 2
	var emptyCount int
	var emptyPrice float64
	var emptyName string
	var emptyFlag bool
	fmt.Println(shop, item)
	fmt.Println("Quantity:", quantity)
	fmt.Printf("Price: %.2f; in stock: %t\n", price, inStock)
	fmt.Printf("Zero values: %d %.1f %q %t\n", emptyCount, emptyPrice, emptyName, emptyFlag)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson02 folder (or the pack's 02-variables-and-types/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Corner Shop notebook
Quantity: 5
Price: 2.50; in stock: true
Zero values: 0 0.0 "" false
```

## How it works
- A **variable** is a named value that may change. Its **type** says which values and operations are allowed. var item string states the type explicitly.
- quantity := 3 is a **short declaration**: it creates a variable and infers (works out) its int type. Use := inside functions.
- quantity = quantity + 2 is **assignment**: calculate the right side, then replace the old value. Use = to update; := in the same block must introduce at least one new name.
- A **constant** cannot be reassigned. const shop gives a fixed label.
- A **zero value** is the default when no initial value is supplied. %q shows the empty string as "".
- Println separates arguments (supplied values) with spaces. Printf uses a **format string** with placeholders: %d for int, %.2f for two decimal places, %.1f for one, %q for quoted text, %t for bool. `\n` means a newline; Printf does not add one automatically.
- Floating-point values are approximations, not exact money storage. Lesson 12 uses integer cents for money totals.

## Try it
Stock update: start with 8, sell 3, update quantity using subtraction (-), then print Remaining: 5. Delete the `fmt.Println("Before:", quantity, "Sold:", sold)` line and print `Remaining:` with the updated quantity instead. Subtraction removes the right amount from the left amount.

If using the optional source, find `02-variables-and-types/exercise/starter`, then copy the `starter` folder and rename it `try02` alongside `lesson02` in `$HOME/code101/go`. `try02` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try02` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try02` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try02"`; macOS/Linux `cd "$HOME/code101/go/try02"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson02

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func main() {
	quantity := 8
	sold := 3
	// TODO: subtract sold from quantity, then print quantity.
	fmt.Println("Before:", quantity, "Sold:", sold)
}
```

In `try02` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Remaining: 5
```

<details><summary>Solution</summary>

In `try02`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 5-10)**
```go
func main() {
	quantity := 8
	sold := 3
	quantity = quantity - sold
	fmt.Println("Remaining:", quantity)
}
```

</details>

## Check yourself
1. What type is quantity := 3?
   <details><summary>Answer</summary>int.</details>
2. How do you update quantity?
   <details><summary>Answer</summary>Use =, not a second := in the same block.</details>
3. What is the zero value of bool?
   <details><summary>Answer</summary>false.</details>
4. Can shop be reassigned?
   <details><summary>Answer</summary>No. It is a constant.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson02` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try02` folder. |
| `.\main.go:11:13: cannot use "five" (untyped string constant) as int value in assignment` | Assigned text to quantity | Keep quantity numeric, for example `quantity = 5`. |
| `.\main.go:12:6: declared and not used: unusedCount` | Added a variable without using it | Use the variable or remove its declaration. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Use mixedCaps for multiword names, as in inStock; keep names understandable. Source: Effective Go: MixedCaps https://go.dev/doc/effective_go#mixed-caps

## Next lesson
**[03. Input and math](03-input-and-math.md):** read typed values and calculate tips.
