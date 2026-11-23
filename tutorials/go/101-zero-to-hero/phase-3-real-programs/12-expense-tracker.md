---
track: go
level: 101
phase: 3
phase_name: real-programs
lesson: 12
title: "Project: expense tracker"
time: 90 min
prerequisites: [101.3.11]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

## Why it matters
A household ledger combines entering purchases, reading old entries and calculating totals. This project brings your separate lessons into a useful console application. Small clear functions give each job its own place.

## What you will build
An expense tracker with add, list, total and quit, persistent expenses.csv, integer cents, and a tiny self-check with plain if checks. No accounts, libraries or test framework. The exercise adds count.

## Before you start
- Finish lesson 11. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 90 minutes. Two sittings; break after Step 4.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson12`, full path `$HOME/code101/go/lesson12`. Do not put it inside another lesson. Open **only** `lesson12` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson12"`; macOS/Linux `cd "$HOME/code101/go/lesson12"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson12`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson12
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson12
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson12`.

### Step 3. Write the data helpers
All three source files use package main, so go run . compiles them together. Create the data helpers, the self-check, then main.

**Data contract** means the rules every saved record must follow: labels are nonempty after removing surrounding spaces and contain no commas, quotes or newlines. Amounts are whole cents from 1 to 1000000 (350 means 3.50); at most 1000 entries keeps totals small enough for our int values. The restricted CSV has header label,cents and exactly two fields per row.

**Persistence** means keeping data between runs. A missing first-run file means an empty ledger (the list of saved expenses); a corrupt existing file stops loading instead of overwriting it. Only quit saves. End of input or Ctrl+C does not save edits.

`TrimSpace` removes surrounding spaces. `ContainsAny` checks whether text contains any forbidden character. `os.IsNotExist` recognizes a missing file; `Itoa` turns an int into text. For strings, `+=` adds text at the end; `%02d` prints a whole number using at least two digits, adding a zero when needed. In load, a returned `nil` slice means no list result because an error occurred; successful empty data uses `[]Expense{}` instead. The short form `if err := scanner.Err(); err != nil` first creates err, then checks it; that err exists only inside this if.

In the Explorer select the root `lesson12` folder, click **New File**, type `expense.go` and press Enter. Paste the complete file:

**File: `expense.go`**
```go
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Expense struct {
	Label string
	Cents int
}

func money(cents int) string {
	return fmt.Sprintf("%d.%02d", cents/100, cents%100)
}

func (e Expense) String() string {
	return e.Label + ": " + money(e.Cents)
}

func parseRow(row string) (Expense, error) {
	fields := strings.Split(row, ",")
	if len(fields) != 2 {
		return Expense{}, errors.New("expected label,cents")
	}
	label := strings.TrimSpace(fields[0])
	if label == "" || strings.ContainsAny(label, "\"\r\n") {
		return Expense{}, errors.New("label must be nonempty, with no quotes or newlines")
	}
	cents, err := strconv.Atoi(fields[1])
	if err != nil {
		return Expense{}, fmt.Errorf("cents: %w", err)
	}
	if cents <= 0 || cents > 1000000 {
		return Expense{}, errors.New("cents must be from 1 to 1000000")
	}
	return Expense{Label: label, Cents: cents}, nil
}

func load(path string) ([]Expense, error) {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return []Expense{}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("load: %w", err)
	}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	if !scanner.Scan() || scanner.Text() != "label,cents" {
		return nil, errors.New("expected label,cents header")
	}
	expenses := []Expense{}
	for scanner.Scan() {
		expense, err := parseRow(scanner.Text())
		if err != nil {
			return nil, fmt.Errorf("row %d: %w", len(expenses)+2, err)
		}
		if len(expenses) >= 1000 {
			return nil, errors.New("maximum 1000 expenses")
		}
		expenses = append(expenses, expense)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return expenses, nil
}

func save(path string, expenses []Expense) error {
	text := "label,cents\n"
	for _, expense := range expenses {
		text += expense.Label + "," + strconv.Itoa(expense.Cents) + "\n"
	}
	return os.WriteFile(path, []byte(text), 0600)
}
```

This file defines the record, validation, display, loading and saving. The main function will call these helpers.

### Step 4. Add the startup self-check
A **self-check** is a few plain checks of the program's assumptions. This one reads no files and changes no saved data.

In the Explorer select the root `lesson12` folder, click **New File**, type `check.go` and press Enter. Paste the complete file:

**File: `check.go`**
```go
package main

import "errors"

// selfCheck is a few plain checks, not a test framework.
func selfCheck() error {
	expense, err := parseRow("Tea,250")
	if err != nil {
		return err
	}
	if expense.Label != "Tea" || expense.Cents != 250 {
		return errors.New("row values differ")
	}
	if money(305) != "3.05" {
		return errors.New("money formatting differs")
	}
	_, err = parseRow("Tea,0")
	if err == nil {
		return errors.New("zero amount was accepted")
	}
	return nil
}
```

This function checks assumptions without reading or writing your ledger; a non-nil error will stop startup.

**Break here (end of sitting 1, about 40 minutes).** Save `expense.go` and `check.go`. They are helper files, so do not run the program yet: it still needs `main.go`. On returning, open `lesson12` and use the Step 1 recovery command.

### Step 5. Add the command loop (sitting 2)

In the Explorer select the root `lesson12` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	if err := selfCheck(); err != nil {
		fmt.Println("Self-check failed:", err)
		return
	}
	fmt.Println("Self-check: OK")
	path := "expenses.csv"
	expenses, err := load(path)
	if err != nil {
		fmt.Println("Load failed:", err)
		return
	}
	fmt.Println("Loaded:", len(expenses))
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Command: add, list, total, quit")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended. Use quit to save next time.")
			}
			return
		}
		switch scanner.Text() {
		case "add":
			fmt.Println("Label (no commas or quotes):")
			if !scanner.Scan() {
				fmt.Println("Input ended before label.")
				return
			}
			label := scanner.Text()
			fmt.Println("Amount in cents (350 means 3.50):")
			if !scanner.Scan() {
				fmt.Println("Input ended before amount.")
				return
			}
			expense, err := parseRow(label + "," + scanner.Text())
			if err != nil {
				fmt.Println("Not added:", err)
				continue
			}
			if len(expenses) >= 1000 {
				fmt.Println("Maximum 1000 expenses")
				continue
			}
			expenses = append(expenses, expense)
			fmt.Println("Added:", expense.String())
		case "list":
			for index, expense := range expenses {
				fmt.Println(index+1, expense.String())
			}
		case "total":
			total := 0
			for _, expense := range expenses {
				total += expense.Cents
			}
			fmt.Println("Total:", money(total))
		case "quit":
			if err := save(path, expenses); err != nil {
				fmt.Println("Save failed:", err)
				continue
			}
			fmt.Println("Saved:", len(expenses), "expenses")
			return
		default:
			fmt.Println("Unknown command")
		}
	}
}
```

The entry point runs the self-check, loads entries and reads commands until quit.

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson12 folder (or the pack's 12-expense-tracker/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Type the following lines in order, pressing Enter after each. Wait for each matching prompt:

**File: `keyboard input (not a saved file)`**
```text
add
Coffee
350
list
total
quit
```

In a new folder there is no `expenses.csv`; the output below starts with `Loaded: 0`. If you run again, the saved entries load and the Loaded count will differ. Keep your saved file; use a new lesson folder if you want to repeat the empty-ledger example.

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Self-check: OK
Loaded: 0
Command: add, list, total, quit
Label (no commas or quotes):
Amount in cents (350 means 3.50):
Added: Coffee: 3.50
Command: add, list, total, quit
1 Coffee: 3.50
Command: add, list, total, quit
Total: 3.50
Command: add, list, total, quit
Saved: 1 expenses
```

Click expenses.csv in the Explorer to view it. It was created by the program, not typed in advance:

**File: `expenses.csv`**
```csv
label,cents
Coffee,350
```

Next run loads the saved purchase; do not add it again unless you intend another expense. Type quit and Enter to finish.

## How it works
1. `main` runs `selfCheck` before reading the ledger. It stops on a failed check, otherwise it loads saved entries. A missing file starts an empty slice; other file errors stop startup.
2. `parseRow` checks the format, label and cents before returning an Expense. Callers never add a failed result. `money` uses integer division and remainder for exact cents; the display tools were explained in Step 3.
3. Scanner reads commands. `add` reads two more lines and appends only a valid expense. `list` visits in order; `total` adds cents. The 1000-entry limit applies when loading and adding.
4. `quit` builds restricted CSV and writes it. Only a successful save ends with Saved. End of input or Ctrl+C does not save; if a save fails, the program keeps the entries and asks for another command.
5. All three files share `package main` and can use each other's functions without imports. `go run .` compiles them together; `go run main.go` would omit the helpers.

**Limitations:** this is a local demo for one person, not a safe place for important records. Keep copies of files you value: an interrupted save can leave an incomplete file.

## Try it
Count command: add case "count" to the switch and print Count: followed by len(expenses). Include count in the command prompt. Use only the existing len and switch skills. In a fresh exercise folder enter add, Coffee, 350, count, quit on separate lines.

If using the optional source, find `12-expense-tracker/exercise/starter`, then copy the `starter` folder and rename it `try12` alongside `lesson12` in `$HOME/code101/go`. `try12` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try12` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try12` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try12"`; macOS/Linux `cd "$HOME/code101/go/try12"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson12

go 1.22.0
```

**File: `check.go (starter)`**: identical, byte for byte, to Step 4; create the same file in `try12` with those complete contents. There are no changed lines in this file.

**File: `expense.go (starter)`**: identical, byte for byte, to Step 3; create the same file in `try12` with those complete contents. There are no changed lines in this file.

**File: `main.go (starter)`**
```go
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	if err := selfCheck(); err != nil {
		fmt.Println("Self-check failed:", err)
		return
	}
	fmt.Println("Self-check: OK")
	path := "expenses.csv"
	expenses, err := load(path)
	if err != nil {
		fmt.Println("Load failed:", err)
		return
	}
	fmt.Println("Loaded:", len(expenses))
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Command: add, list, total, quit")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended. Use quit to save next time.")
			}
			return
		}
		switch scanner.Text() {
		case "add":
			fmt.Println("Label (no commas or quotes):")
			if !scanner.Scan() {
				fmt.Println("Input ended before label.")
				return
			}
			label := scanner.Text()
			fmt.Println("Amount in cents (350 means 3.50):")
			if !scanner.Scan() {
				fmt.Println("Input ended before amount.")
				return
			}
			expense, err := parseRow(label + "," + scanner.Text())
			if err != nil {
				fmt.Println("Not added:", err)
				continue
			}
			if len(expenses) >= 1000 {
				fmt.Println("Maximum 1000 expenses")
				continue
			}
			expenses = append(expenses, expense)
			fmt.Println("Added:", expense.String())
		case "list":
			for index, expense := range expenses {
				fmt.Println(index+1, expense.String())
			}
		// TODO: add a count case that prints Count: followed by len(expenses).
		case "total":
			total := 0
			for _, expense := range expenses {
				total += expense.Cents
			}
			fmt.Println("Total:", money(total))
		case "quit":
			if err := save(path, expenses); err != nil {
				fmt.Println("Save failed:", err)
				continue
			}
			fmt.Println("Saved:", len(expenses), "expenses")
			return
		default:
			fmt.Println("Unknown command")
		}
	}
}
```

In `try12` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

After editing, type these lines in order, pressing Enter after each and waiting for the matching prompts:

**File: `keyboard input (not a saved file)`**
```text
add
Coffee
350
count
quit
```

Use a fresh try folder with no expenses.csv. Do not run the unedited starter with these inputs first: it would save an entry and change the next run.

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Self-check: OK
Loaded: 0
Command: add, list, total, count, quit
Label (no commas or quotes):
Amount in cents (350 means 3.50):
Added: Coffee: 3.50
Command: add, list, total, count, quit
Count: 1
Command: add, list, total, count, quit
Saved: 1 expenses
```

<details><summary>Solution</summary>

In `try12`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 21-27)**
```go
	fmt.Println("Loaded:", len(expenses))
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Command: add, list, total, count, quit")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
```

**File: `main.go` (replacement region, solution lines 58-65)**
```go
			for index, expense := range expenses {
				fmt.Println(index+1, expense.String())
			}
		case "count":
			fmt.Println("Count:", len(expenses))
		case "total":
			total := 0
			for _, expense := range expenses {
```

</details>

## Check yourself
1. Why integer cents?
   <details><summary>Answer</summary>Exact totals without decimal floating-point rounding.</details>
2. When are edits saved?
   <details><summary>Answer</summary>Only after successful quit.</details>
3. What happens to malformed existing CSV?
   <details><summary>Answer</summary>Loading returns an error and main stops without silently replacing it.</details>
4. Does selfCheck use a framework?
   <details><summary>Answer</summary>No. A few plain checks in an ordinary function.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson12` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try12` folder. |
| `.\main.go:10:12: undefined: selfCheck` | Ran go run main.go and omitted the other two files | Use `go run .` from `lesson12`, with all three .go files beside go.mod. |
| `Not added: cents: strconv.Atoi: parsing "3.50": invalid syntax` | Entered a decimal at the whole-cents prompt | Enter `350` for 3.50, without a currency sign or decimal point. |

The complete captured result of `go run main.go` in `lesson12` is:

```text
# command-line-arguments
.\main.go:10:12: undefined: selfCheck
.\main.go:16:19: undefined: load
.\main.go:46:20: undefined: parseRow
.\main.go:66:26: undefined: money
.\main.go:68:14: undefined: save
```

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Separate validation from the input loop; return errors so the caller chooses what to show and whether to retry. Source: Go: Return and handle an error https://go.dev/doc/tutorial/handle-errors

## Next lesson
**101 complete.** Keep this project as a reference. For independent practice use the same skills to track books or supplies: write down fields and file rules first. Next, work through the official [Tour of Go](https://go.dev/tour/) for guided practice with language features beyond this course.
