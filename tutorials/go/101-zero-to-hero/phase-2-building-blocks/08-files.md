---
track: go
level: 101
phase: 2
phase_name: building-blocks
lesson: 08
title: "Files"
time: 45 min
prerequisites: [101.2.07]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-2-building-blocks/08-files/
assets: []
---

# 08. Files

## Why it matters
A paper ledger keeps entries after you close it. A file lets a program preserve data after it finishes. A simple table format makes stored data readable by people and programs.

## What you will build
Write shopping.csv, read it back, scan rows and total costs. This is restricted CSV, not a general CSV parser.

## Before you start
- Finish lesson 07. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 45 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-2-building-blocks/08-files/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson08`, full path `$HOME/code101/go/lesson08`. Do not put it inside another lesson. Open **only** `lesson08` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson08"`; macOS/Linux `cd "$HOME/code101/go/lesson08"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson08`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson08
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson08
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson08`.

### Step 3. Write the complete program
A **file path** locates a file; shopping.csv is a **relative path**, meaning that file in the working folder. **CSV** means comma-separated values: a **row** is one line and a **field** is one column value. Our rules are two fields, no commas, quotes or newlines inside a label, and a whole-number cost. The first line is a **header** naming columns. A **byte** is a small unit of encoded data; a **sequence** is an ordered series, and a **byte slice** is a sequence of bytes. `[]byte(text)` converts a string to that form for file writing. Type `0600` exactly: it is a permission code controlling access to a newly created file. The leading zero marks **octal**, a way of writing numbers using digits 0 to 7; you do not need to calculate it here.

In the Explorer select the root `lesson08` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	// Restricted CSV: one label and one whole number, no quoting.
	text := "item,cost\ntea,3\nbread,2\n"
	err := os.WriteFile("shopping.csv", []byte(text), 0600)
	if err != nil {
		fmt.Println("Write failed:", err)
		return
	}
	data, err := os.ReadFile("shopping.csv")
	if err != nil {
		fmt.Println("Read failed:", err)
		return
	}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	if !scanner.Scan() || scanner.Text() != "item,cost" {
		fmt.Println("Missing or wrong header")
		return
	}
	total := 0
	for scanner.Scan() {
		fields := strings.Split(scanner.Text(), ",")
		if len(fields) != 2 {
			fmt.Println("Expected two fields")
			return
		}
		cost, err := strconv.Atoi(fields[1])
		if err != nil {
			fmt.Println("Invalid cost:", err)
			return
		}
		fmt.Println(fields[0], cost)
		total += cost
	}
	if scanner.Err() != nil {
		fmt.Println("Read lines failed:", scanner.Err())
		return
	}
	fmt.Println("Total:", total)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson08 folder (or the pack's 08-files/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
tea 3
bread 2
Total: 5
```

In the `lesson08` terminal, `Get-ChildItem` (PowerShell) or `ls` (macOS/Linux) lists the current folder: `shopping.csv` should be next to `main.go`. If it is missing, confirm the folder with `Get-Location` or `pwd`, return to `lesson08` and rerun. Click shopping.csv in the Explorer to view it. It was created by the program, not typed in advance:

**File: `shopping.csv`**
```csv
item,cost
tea,3
bread,2
```

Every run recreates this demo file. To clean up delete only shopping.csv in the Explorer, keeping your source and module files.

## How it works
1. `text` contains the whole table; `\n` marks line endings. `WriteFile` creates or replaces the file, removing old trailing contents (**truncation**). Do not put valuable data in this demo's shopping.csv.
2. `[]byte(text)` supplies file data in bytes; `0600` is the permission code explained in Step 3. `ReadFile` returns the file data and an error; `string(data)` converts the bytes back to text. This example is for small files.
3. `strings.NewReader` lets Scanner read text rather than keyboard input. Read and check the header first. The `||` check avoids inspecting a line if Scan failed.
4. `strings.Split` divides a row into a slice at each comma. Check the length before `fields[1]`, then parse cost with Atoi and add it to total.
5. `scanner.Err()` after the loop distinguishes a normal end of file from a read failure. Hand splitting cannot read general CSV with quoted or multiline values; use the standard library's `encoding/csv` package for that.

## Try it
Third item: include milk costing 4 in the saved table, keeping the header, tea and bread. The program must read back all three items and print Total: 9. Use the existing table format.

If using the optional source, find `08-files/exercise/starter`, then copy the `starter` folder and rename it `try08` alongside `lesson08` in `$HOME/code101/go`. `try08` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try08` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try08` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try08"`; macOS/Linux `cd "$HOME/code101/go/try08"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson08

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
	"strings"
)

func main() {
	// Restricted CSV: one label and one whole number, no quoting.
	// TODO: include milk costing 4 in the saved table.
	text := "item,cost\ntea,3\nbread,2\n"
	err := os.WriteFile("shopping.csv", []byte(text), 0600)
	if err != nil {
		fmt.Println("Write failed:", err)
		return
	}
	data, err := os.ReadFile("shopping.csv")
	if err != nil {
		fmt.Println("Read failed:", err)
		return
	}
	scanner := bufio.NewScanner(strings.NewReader(string(data)))
	if !scanner.Scan() || scanner.Text() != "item,cost" {
		fmt.Println("Missing or wrong header")
		return
	}
	total := 0
	for scanner.Scan() {
		fields := strings.Split(scanner.Text(), ",")
		if len(fields) != 2 {
			fmt.Println("Expected two fields")
			return
		}
		cost, err := strconv.Atoi(fields[1])
		if err != nil {
			fmt.Println("Invalid cost:", err)
			return
		}
		fmt.Println(fields[0], cost)
		total += cost
	}
	if scanner.Err() != nil {
		fmt.Println("Read lines failed:", scanner.Err())
		return
	}
	fmt.Println("Total:", total)
}
```

In `try08` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
tea 3
bread 2
milk 4
Total: 9
```

<details><summary>Solution</summary>

In `try08`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 10-16)**
```go

func main() {
	// Restricted CSV: one label and one whole number, no quoting.
	text := "item,cost\ntea,3\nbread,2\nmilk,4\n"
	err := os.WriteFile("shopping.csv", []byte(text), 0600)
	if err != nil {
		fmt.Println("Write failed:", err)
```

</details>

## Check yourself
1. Where does shopping.csv go?
   <details><summary>Answer</summary>In the folder where go run . was launched.</details>
2. What does WriteFile do to old contents?
   <details><summary>Answer</summary>Replaces and truncates them.</details>
3. Why check field count?
   <details><summary>Answer</summary>To avoid indexing a nonexistent second field.</details>
4. Can labels contain commas?
   <details><summary>Answer</summary>Not here. Use encoding/csv for general CSV.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson08` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try08` folder. |
| `.\main.go:13:9: undefined: os` | Removed the os import | Restore `"os"` in the import block. |
| `.\main.go:14:38: cannot use text (variable of type string) as []byte value in argument to os.WriteFile` | Passed the text variable directly to WriteFile | Restore `[]byte(text)`. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Check Scanner.Err after a scanning loop; end of input and a read failure are different. Source: Go standard library: Scanner.Err https://pkg.go.dev/bufio#Scanner.Err

## Next lesson
**[09. Errors](../phase-3-real-programs/09-errors.md):** handle failures and ask again; Phase 2 is complete.
