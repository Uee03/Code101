---
track: go
level: 101
phase: 3
phase_name: real-programs
lesson: 10
title: "Structs and methods"
time: 50 min
prerequisites: [101.3.09]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-3-real-programs/10-structs-and-methods/
assets: []
---

# 10. Structs and methods

## Why it matters
A library card groups a name and membership details on one record. A **struct** groups related values, while a **method** is a function attached to that type of record. Together they describe larger programs clearly.

## What you will build
An Expense with label and cents, a display method, an update method and a copied record.

## Before you start
- Finish lesson 09. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 50 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-3-real-programs/10-structs-and-methods/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson10`, full path `$HOME/code101/go/lesson10`. Do not put it inside another lesson. Open **only** `lesson10` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson10"`; macOS/Linux `cd "$HOME/code101/go/lesson10"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson10`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson10
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson10
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson10`.

### Step 3. Write the complete program
A **struct** is a type containing named **fields** (member values). type Expense struct defines a named type. An **instance** is a concrete value of it, created here with a **struct literal**: a written value naming its fields. A **receiver** is the value a method works on, written between `func` and its name. `(e Expense)` is a **value receiver**, which receives a copy. A **pointer** refers to an original value, and `(e *Expense)` is a **pointer receiver**, allowing the method to change that original.

In the Explorer select the root `lesson10` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

type Expense struct {
	Label string
	Cents int
}

func (e Expense) String() string {
	return fmt.Sprintf("%s: %d cents", e.Label, e.Cents)
}

func (e *Expense) AddCents(extra int) {
	e.Cents += extra
}

func main() {
	expense := Expense{Label: "Tea", Cents: 250}
	fmt.Println(expense.String())
	expense.AddCents(50)
	fmt.Println(expense.String())
	copyExpense := expense
	copyExpense.Label = "Copy"
	fmt.Println("Original label:", expense.Label)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson10 folder (or the pack's 10-structs-and-methods/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Tea: 250 cents
Tea: 300 cents
Original label: Tea
```

## How it works
1. `Expense{Label: "Tea", Cents: 250}` names both fields. `expense.Label` accesses one field.
2. `String` reads its copied receiver and returns text. `Sprintf` formats like Printf but returns a string instead of printing it; `expense.String()` calls it explicitly.
3. `AddCents` uses a pointer receiver to update the original Cents. Its `+=` adds to the stored value. A value receiver would update only a copy: the Common mistakes section shows the silent effect.
4. `copyExpense := expense` makes a separate copy of this simple record, so changing the copy's Label leaves the original Tea label alone.
5. Returning a description keeps formatting separate from printing. Lesson 11 uses a method as a contract.

**Optional receiver detail (not needed for Try it):** an **address** is a value's location in working memory. `&expense` refers to that location. Go does this automatically for `expense.AddCents(50)` because expense is a variable; you do not need to write `&` here. We use only pointers to existing records in this lesson.

## Try it
Discount: provide an operation named `Discount` that reduces the original expense by a supplied number of cents, then demonstrate a 50-cent discount. Starting from Tea at 250 cents, it must become 200 cents. Assume the discount is valid and does not exceed the expense.

If using the optional source, find `10-structs-and-methods/exercise/starter`, then copy the `starter` folder and rename it `try10` alongside `lesson10` in `$HOME/code101/go`. `try10` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try10` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try10` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try10"`; macOS/Linux `cd "$HOME/code101/go/try10"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson10

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

type Expense struct {
	Label string
	Cents int
}

func (e Expense) String() string {
	return fmt.Sprintf("%s: %d cents", e.Label, e.Cents)
}

func (e *Expense) AddCents(extra int) {
	// TODO: provide a discount operation that reduces the original expense.
	e.Cents += extra
}

func main() {
	expense := Expense{Label: "Tea", Cents: 250}
	fmt.Println(expense.String())
	expense.AddCents(50)
	fmt.Println(expense.String())
	copyExpense := expense
	copyExpense.Label = "Copy"
	fmt.Println("Original label:", expense.Label)
}
```

In `try10` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Tea: 250 cents
Tea: 200 cents
Original label: Tea
```

<details><summary>Solution</summary>

In `try10`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 11-24)**
```go
	return fmt.Sprintf("%s: %d cents", e.Label, e.Cents)
}

func (e *Expense) Discount(extra int) {
	e.Cents -= extra
}

func main() {
	expense := Expense{Label: "Tea", Cents: 250}
	fmt.Println(expense.String())
	expense.Discount(50)
	fmt.Println(expense.String())
	copyExpense := expense
	copyExpense.Label = "Copy"
```

</details>

## Check yourself
1. Which fields are in Expense?
   <details><summary>Answer</summary>Label string and Cents int.</details>
2. Why use *Expense for updates?
   <details><summary>Answer</summary>To change the original, not a copy.</details>
3. Does changing the copied Label change the original?
   <details><summary>Answer</summary>No, not in this simple struct.</details>
4. Does Sprintf print?
   <details><summary>Answer</summary>No. It returns text.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson10` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try10` folder. |
| `Tea: 250 cents (printed twice, with no compiler error)` | Used `(e Expense)` for AddCents, so it only changes a copy | Restore `(e *Expense)` so the original changes. Compare the full captured effect below. |
| `.\main.go:15:2: undefined: Cents` | Used a field without its receiver | Access the field through `e.Cents`. |
| `.\main.go:19:42: cannot use "250" (untyped string constant) as int value in struct literal` | Put text in the Cents field | Use the integer `250`, without quotes. |

With **only** the AddCents receiver changed to `(e Expense)`, `go run .` in `lesson10` succeeds but prints:

```text
Tea: 250 cents
Tea: 250 cents
Original label: Tea
```

The second amount is still 250, not 300. This is a behavior mistake, not a compiler error.

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Use a pointer receiver to modify an original value; a value receiver suits this small read-only display method. Source: Effective Go: Pointers vs. Values https://go.dev/doc/effective_go#pointers_vs_values

## Next lesson
**[11. Interfaces and packages](11-interfaces-and-packages.md):** use method contracts and your own package.
