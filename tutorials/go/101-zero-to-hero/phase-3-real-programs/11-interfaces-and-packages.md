---
track: go
level: 101
phase: 3
phase_name: real-programs
lesson: 11
title: "Interfaces and packages"
time: 45 min
prerequisites: [101.3.10]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-3-real-programs/11-interfaces-and-packages/
assets: []
---

# 11. Interfaces and packages

## Why it matters
Different appliances fit the same socket when they provide the expected connection. An interface is a contract of methods a value must provide. Packages put related tools in labelled drawers.

## What you will build
Your own receipt package and a Reporter interface accepting it. The exercise adds another reporter without changing printReport.

## Before you start
- Finish lesson 10. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 45 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-3-real-programs/11-interfaces-and-packages/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson11`, full path `$HOME/code101/go/lesson11`. Do not put it inside another lesson. Open **only** `lesson11` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson11"`; macOS/Linux `cd "$HOME/code101/go/lesson11"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson11`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson11
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson11
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson11`.

### Step 3. Write the complete program
An **interface** lists required methods. A package groups files in a folder; a module groups packages under its go.mod path. receipt is a child package of this module, not a downloaded module.

In the Explorer click **New Folder**, name it `receipt`, select it and click **New File** to create `receipt.go`.

**File: `receipt/receipt.go`**
```go
package receipt

import "fmt"

type Receipt struct {
	Label string
	Cents int
}

func (r Receipt) Summary() string {
	return fmt.Sprintf("%s: %d cents", r.Label, r.Cents)
}
```

In the Explorer select the root `lesson11` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import (
	"example.com/code101/lesson11/receipt"
	"fmt"
)

type Reporter interface {
	Summary() string
}

func printReport(report Reporter) {
	fmt.Println(report.Summary())
}

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson11 folder (or the pack's 11-interfaces-and-packages/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Tea: 300 cents
```

## How it works
1. receipt/receipt.go uses package receipt, not main. Ordinary Go files in a folder declare the same package. This library package has no main function.
2. Receipt, Label, Cents and Summary are **exported names**: capital initials make them accessible to other packages. Lowercase names are **unexported**, available only inside their package. Spelling and case matter.
3. The receipt import is the module path plus /receipt. Go finds this package locally, with no publishing or website required. Standard fmt keeps its short import path.
4. Reporter promises Summary() string: no inputs, one string result. printReport accepts any value satisfying that method contract.
5. Receipt **implements** Reporter automatically by having the exact method. There is no implements keyword or registration. Go checks names, input types and result types, not intended meaning.
6. The interface lets the calling code use a promised behavior rather than one particular record type.

## Try it
Second reporter: make the starter's `Note` usable by the existing `printReport` function. Demonstrate a note containing Paid after the receipt, producing the two output lines below. Do not change `Reporter` or `printReport`; work out what behavior Note must provide.

If using the optional source, find `11-interfaces-and-packages/exercise/starter`, then copy the `starter` folder and rename it `try11` alongside `lesson11` in `$HOME/code101/go`. `try11` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try11` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try11` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try11"`; macOS/Linux `cd "$HOME/code101/go/try11"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson11

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import (
	"example.com/code101/lesson11/receipt"
	"fmt"
)

type Reporter interface {
	Summary() string
}

func printReport(report Reporter) {
	fmt.Println(report.Summary())
}

// TODO: make Note usable by printReport; demonstrate a note reading Paid.
type Note struct {
	Text string
}

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
}
```

**File: `receipt/receipt.go (starter)`**
```go
package receipt

import "fmt"

type Receipt struct {
	Label string
	Cents int
}

func (r Receipt) Summary() string {
	return fmt.Sprintf("%s: %d cents", r.Label, r.Cents)
}
```

In `try11` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Tea: 300 cents
Paid
```

<details><summary>Solution</summary>

In `try11`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 13-28)**
```go
	fmt.Println(report.Summary())
}

type Note struct {
	Text string
}

func (n Note) Summary() string {
	return n.Text
}

func main() {
	report := receipt.Receipt{Label: "Tea", Cents: 300}
	printReport(report)
	printReport(Note{Text: "Paid"})
}
```

</details>

## Check yourself
1. What exports Receipt?
   <details><summary>Answer</summary>Its capital R.</details>
2. Where does the import path come from?
   <details><summary>Answer</summary>The module path plus /receipt.</details>
3. Must Note declare implements Reporter?
   <details><summary>Answer</summary>No. The matching method is enough.</details>
4. Is receipt a second module?
   <details><summary>Answer</summary>No, a package in this module.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson11` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try11` folder. |
| `main.go:4:2: no required module provides package example.com/code101/lesson11/recipt; to add it:`<br>`	go get example.com/code101/lesson11/recipt` | Misspelled the local receipt import as recipt | Compare the import with the `receipt` folder and module line in `go.mod`. **Do not run `go get`**: this package is local; correct the typo. |
| `.\main.go:18:14: cannot use report (variable of struct type receipt.Receipt) as Reporter value in argument to printReport: receipt.Receipt does not implement Reporter (missing method Summary)` | Renamed Receipt's required Summary method | Restore `Summary() string` in receipt/receipt.go. |
| `.\main.go:13:21: report.summary undefined (type Reporter has no field or method summary, but does have method Summary)` | Called a differently capitalized method | Use `Summary`, matching the interface and declaration. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Keep package names short, lowercase and descriptive; export only what callers need. Source: Effective Go: Package names https://go.dev/doc/effective_go#package-names

## Next lesson
**[12. Project: expense tracker](12-expense-tracker.md):** build a persistent expense tracker.
