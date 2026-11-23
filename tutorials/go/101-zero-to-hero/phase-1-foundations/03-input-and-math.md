---
track: go
level: 101
phase: 1
phase_name: foundations
lesson: 03
title: "Input and math"
time: 60 min
prerequisites: [101.1.02]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-1-foundations/03-input-and-math/
assets: []
---

# 03. Input and math

## Why it matters
A restaurant receipt starts with numbers someone supplies, then follows a calculation. A program must turn typed text into numbers before calculating a tip. Reading text and converting it are separate jobs.

## What you will build
A tip calculator. Step 4 is an optional comparison with another input reader; it is not needed for the exercise.

## Before you start
- Finish lesson 02. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-1-foundations/03-input-and-math/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson03`, full path `$HOME/code101/go/lesson03`. Do not put it inside another lesson. Open **only** `lesson03` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson03"`; macOS/Linux `cd "$HOME/code101/go/lesson03"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson03`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson03
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson03
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson03`.

### Step 3. Write the complete program
A **Scanner** is a reader that collects one line at a time; `os.Stdin` means **standard input**, normally text from your terminal. Use one Scanner for all three questions. Type 80, not $80, and 15, not 15%, with no spaces before or after either number.

A small **guard** stops safely if an operation fails. if runs its brace block when its condition is true; return here ends main. ! means not, || means or, != means not equal. Read `if !scanner.Scan()` as "if there was no line to read, stop". `err` holds an **error value**, a description of a failure; `nil` means no error here. Read `if err != nil` as "if converting the text failed, stop". Read the last guard as "if the bill or percent is negative, or people is zero or negative, stop". These checks keep bad input from silently becoming zero; lesson 04 explains decisions and lesson 09 develops errors.

In the Explorer select the root `lesson03` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("Bill amount (e.g. 80):")
	if !scanner.Scan() {
		fmt.Println("No bill input.")
		return
	}
	bill, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the bill.")
		return
	}
	fmt.Println("Tip percent (e.g. 15):")
	if !scanner.Scan() {
		fmt.Println("No tip input.")
		return
	}
	percent, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the percent.")
		return
	}
	fmt.Println("Number of people:")
	if !scanner.Scan() {
		fmt.Println("No people input.")
		return
	}
	people, err := strconv.Atoi(scanner.Text())
	if err != nil {
		fmt.Println("Use a whole number of people.")
		return
	}
	if bill < 0 || percent < 0 || people <= 0 {
		fmt.Println("Amounts must be nonnegative; people must be positive.")
		return
	}
	tip := bill * percent / 100
	total := bill + tip
	each := total / float64(people)
	fmt.Printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each)
	fmt.Println("Whole division:", 7/2, "Remainder:", 7%2)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

### Step 4. Optional: compare a separate token-input demo
You may skip to **Run it** and still complete the lesson. A **token** is one piece of input; this demo treats spaces and line endings as separators. A variable's **address** is its location in the computer's working memory; `&people` lets Scan fill that original variable. `_` is the **blank identifier**: it discards Scan's count while keeping its error.

Create a folder named scan-demo in the Explorer inside lesson03. Create main.go inside scan-demo. This is a second runnable package in the same module, so its main function cannot conflict with the parent's.

**File: `scan-demo/main.go`**
```go
package main

import "fmt"

func main() {
	var people int
	fmt.Println("People (one whole number):")
	_, err := fmt.Scan(&people)
	if err != nil {
		fmt.Println("Use a whole number.")
		return
	}
	fmt.Println("People:", people)
}
```

Save it. `./scan-demo` means the folder called `scan-demo` inside the current folder. In the **lesson03 root** terminal, on every OS run:

**File: terminal (not a saved file)**
```text
go run ./scan-demo
```
When asked for people type 2 and press Enter. Actual program output, excluding keyboard echo:

**File: `terminal output (not a saved file)`**
```text
People (one whole number):
People: 2
```

This demo ends after one value. It does not share a Scanner with the calculator. The parent's go run . still runs only the calculator.

## Run it
Inside your own lesson03 folder (or the pack's 03-input-and-math/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Type the following lines in order, pressing Enter after each. Wait for each matching prompt:

**File: `keyboard input (not a saved file)`**
```text
80
15
2
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Bill amount (e.g. 80):
Tip percent (e.g. 15):
Number of people:
Tip: 12.00
Total: 92.00
Each: 46.00
Whole division: 3 Remainder: 1
```

## How it works
1. `Scan()` waits for one line and reports whether it read one; `Text()` retrieves that line as a string.
2. **Parsing** means interpreting text as a number. `ParseFloat(text, 64)` produces a float64; `Atoi` produces an int. Each also returns an error, which the guards check before calculating.
3. `percent, err :=` creates percent while reusing err; at least one name must be new for `:=` in the same block.
4. **Operators** `+`, `-`, `*`, `/`, `%` mean addition, subtraction, multiplication, division and integer **remainder** (the leftover). Multiplication and division happen before addition and subtraction; parentheses change that order. Dividing a percent by 100 gives its fraction of the bill.
5. `float64(people)` is a **conversion** from int to float64, so both sides of the division have the same type. **Integer division** drops the fractional part: `7/2` gives 3 and `7%2` gives 1. `%.2f` displays two decimal places without changing the value.

**Optional Step 4 only:** `fmt.Scan` reads a whitespace-separated token rather than a full line. Keep it in its own program: input readers can collect extra text in advance, so sharing them can lose input.

## Try it
Service charge: keep all three questions and their validation, but charge a fixed 10 percent regardless of the entered tip percent. With 80, 15, 2, the charge is 8.00, total 88.00, and each person pays 44.00. Work out the calculation yourself.

If using the optional source, find `03-input-and-math/exercise/starter`, then copy the `starter` folder and rename it `try03` alongside `lesson03` in `$HOME/code101/go`. `try03` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try03` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try03` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try03"`; macOS/Linux `cd "$HOME/code101/go/try03"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson03

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("Bill amount (e.g. 80):")
	if !scanner.Scan() {
		fmt.Println("No bill input.")
		return
	}
	bill, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the bill.")
		return
	}
	fmt.Println("Tip percent (e.g. 15):")
	if !scanner.Scan() {
		fmt.Println("No tip input.")
		return
	}
	percent, err := strconv.ParseFloat(scanner.Text(), 64)
	if err != nil {
		fmt.Println("Use digits for the percent.")
		return
	}
	fmt.Println("Number of people:")
	if !scanner.Scan() {
		fmt.Println("No people input.")
		return
	}
	people, err := strconv.Atoi(scanner.Text())
	if err != nil {
		fmt.Println("Use a whole number of people.")
		return
	}
	if bill < 0 || percent < 0 || people <= 0 {
		fmt.Println("Amounts must be nonnegative; people must be positive.")
		return
	}
	// TODO: charge a fixed 10 percent; keep the questions and validation.
	tip := 0.0 * percent
	total := bill + tip
	each := total / float64(people)
	fmt.Printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each)
	fmt.Println("Whole division:", 7/2, "Remainder:", 7%2)
}
```

In `try03` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

After editing, type these lines in order, pressing Enter after each and waiting for the matching prompts:

**File: `keyboard input (not a saved file)`**
```text
80
15
2
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Bill amount (e.g. 80):
Tip percent (e.g. 15):
Number of people:
Tip: 8.00
Total: 88.00
Each: 44.00
Whole division: 3 Remainder: 1
```

<details><summary>Solution</summary>

In `try03`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 43-49)**
```go
		fmt.Println("Amounts must be nonnegative; people must be positive.")
		return
	}
	tip := bill * 10 / 100
	total := bill + tip
	each := total / float64(people)
	fmt.Printf("Tip: %.2f\nTotal: %.2f\nEach: %.2f\n", tip, total, each)
```

</details>

## Check yourself
1. Why parse Text()?
   <details><summary>Answer</summary>It returns a string; calculations need numbers.</details>
2. What is integer 7/2?
   <details><summary>Answer</summary>3.</details>
3. Why convert people?
   <details><summary>Answer</summary>To match the float64 total before dividing.</details>
4. What happens when converting the bill fails?
   <details><summary>Answer</summary>The program prints a helpful message and returns before doing math.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson03` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try03` folder. |
| `Use digits for the bill.` | Entered `$80` at the bill prompt | Enter `80`, with no currency sign or surrounding spaces. |
| `Use digits for the bill.` | Entered `80 ` with a trailing space | Remove leading/trailing spaces; this reader does not trim numeric input. |
| `Use digits for the percent.` | Entered `15%` at the percent prompt | Enter `15`, with no percent sign or surrounding spaces. |
| `.\main.go:48:10: invalid operation: total / people (mismatched types float64 and int)` | Removed the conversion before division | Restore `float64(people)` so the two numeric types match. |
| `.\main.go:37:17: undefined: strConv` | Misspelled strconv at the whole-number conversion | Use the exact package name `strconv`. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Choose one input-reading strategy for terminal input; check Scan before using Text. Source: Go standard library: Scanner https://pkg.go.dev/bufio#Scanner

## Next lesson
**[04. Making decisions](04-making-decisions.md):** choose which instructions run.
