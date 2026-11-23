---
track: go
level: 101
phase: 2
phase_name: building-blocks
lesson: 07
title: "Slices and maps"
time: 40 min
prerequisites: [101.2.06]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-2-building-blocks/07-slices-and-maps/
assets: []
---

# 07. Slices and maps

## Why it matters
A shopping list remembers items in order, while a price list lets you find a cost by name. Go provides slices for ordered collections and maps for lookups. Choose the collection that fits the question.

## What you will build
An ordered shopping list, price map, total and missing-key lookup that distinguishes absence from a zero price.

## Before you start
- Finish lesson 06. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-2-building-blocks/07-slices-and-maps/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson07`, full path `$HOME/code101/go/lesson07`. Do not put it inside another lesson. Open **only** `lesson07` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson07"`; macOS/Linux `cd "$HOME/code101/go/lesson07"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson07`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson07
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson07
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson07`.

### Step 3. Write the complete program
A **slice** is an ordered collection that can grow. An **element** is one value in it; an **index** is its position, starting at zero. A **map** stores key/value pairs. A **key** is the value used for lookup, and its associated **value** is the answer. Here keys are strings and prices are ints.

In the Explorer select the root `lesson07` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import "fmt"

func main() {
	items := []string{"tea", "bread"}
	items = append(items, "milk")
	fmt.Println("Count:", len(items), "First:", items[0])
	for index, item := range items {
		fmt.Println(index, item)
	}
	prices := map[string]int{"tea": 3, "bread": 2, "milk": 4}
	total := 0
	for _, item := range items {
		total += prices[item]
	}
	fmt.Println("Total:", total)
	price, found := prices["coffee"]
	fmt.Println("Coffee:", price, "Found:", found)
	prices["coffee"] = 5
	delete(prices, "bread")
	fmt.Println("Coffee added:", prices["coffee"])
	_, found = prices["bread"]
	fmt.Println("Bread found:", found)
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson07 folder (or the pack's 07-slices-and-maps/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Count: 3 First: tea
0 tea
1 bread
2 milk
Total: 9
Coffee: 0 Found: false
Coffee added: 5
Bread found: false
```

## How it works
1. `[]string{"tea", "bread"}` is a **slice literal**, a written starting collection. `items[0]` is tea; `len` counts elements.
2. `append` adds an element and returns the updated slice. Assign that result back to `items` so its length includes milk.
3. `for index, item := range items` visits positions and values in order. **range** is Go's collection loop form. **Iteration order** means the order in which the loop visits items. Use `_` to discard an index you do not need.
4. `map[string]int` is a string-keyed map of integers. `price, found := prices["coffee"]` also returns a boolean saying whether the key exists. A missing key gives the zero value, here 0; a zero price alone does not prove absence.
5. Assignment inserts or updates a key/value pair. `delete` removes a pair, even if it is already absent. Maps have no promised visiting order, so this program totals by visiting the ordered slice instead.

## Try it
Shopping total: append another tea to the starter slice, then sum prices by visiting items with range. Keep total an int. The result is 3 + 4 + 3 = 10.

If using the optional source, find `07-slices-and-maps/exercise/starter`, then copy the `starter` folder and rename it `try07` alongside `lesson07` in `$HOME/code101/go`. `try07` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try07` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try07` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try07"`; macOS/Linux `cd "$HOME/code101/go/try07"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson07

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import "fmt"

func main() {
	items := []string{"tea", "milk"}
	prices := map[string]int{"tea": 3, "milk": 4}
	// TODO: append another tea and sum the prices using range.
	fmt.Println("Items:", items, "Prices available:", len(prices))
}
```

In `try07` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Total: 10
```

<details><summary>Solution</summary>

In `try07`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 5-14)**
```go
func main() {
	items := []string{"tea", "milk"}
	prices := map[string]int{"tea": 3, "milk": 4}
	items = append(items, "tea")
	total := 0
	for _, item := range items {
		total += prices[item]
	}
	fmt.Println("Total:", total)
}
```

</details>

## Check yourself
1. What is the first index?
   <details><summary>Answer</summary>0.</details>
2. Why assign append results?
   <details><summary>Answer</summary>The returned slice includes the new element and updated length.</details>
3. Does a zero map result prove absence?
   <details><summary>Answer</summary>No; use the second boolean result.</details>
4. Can you rely on map iteration order?
   <details><summary>Answer</summary>No. Use a slice for ordered display.</details>

## Common mistakes
These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson07` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try07` folder. |
| `.\main.go:7:24: cannot use 4 (untyped int constant) as string value in argument to append` | Appended a number to a string slice | Append a string such as `"milk"`. |
| `.\main.go:8:52: undefined: index` | Used index before the range loop declares it | Use `items[0]` here; index exists only inside its loop. |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Use two-result map lookups when absence must be distinguished from a stored zero value. Source: Effective Go: Maps https://go.dev/doc/effective_go#maps

## Next lesson
**[08. Files](08-files.md):** keep a small table in a file.
