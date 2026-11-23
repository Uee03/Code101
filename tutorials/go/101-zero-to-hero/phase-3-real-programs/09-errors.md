---
track: go
level: 101
phase: 3
phase_name: real-programs
lesson: 09
title: "Errors"
time: 40 min
prerequisites: [101.2.08]
versions: { go: "1.22.0 or newer" }
verified: 2026-11-23 on Windows, Go 1.27.4
source: source/go/101-zero-to-hero/phase-3-real-programs/09-errors/
assets: []
---

# 09. Errors

## Why it matters
A form can be filled incorrectly; a helpful clerk explains why and asks again. A Go operation returns an error value instead of making you guess whether it worked. The caller decides whether to stop or retry.

## What you will build
A whole-unit amount reader that explains bad input, rejects zero and asks again until a positive number or end of input.

## Before you start
- Finish lesson 08. Install Go 1.22.0 or newer and VS Code with its Go extension using lesson 01.
- Time: 40 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/go/101-zero-to-hero/phase-3-real-programs/09-errors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- [How every lesson works](../../README.md#how-every-lesson-works) explains extraction, folders, saving and running supplied examples.
- No art or external packages. Each lesson and copied exercise is independent.

## Steps

### Step 1. Create a separate working folder
Repeat the [working-folder steps](../../README.md#working-folder) with these exact differences: folder `lesson09`, full path `$HOME/code101/go/lesson09`. Do not put it inside another lesson. Open **only** `lesson09` in VS Code, then **Terminal > New Terminal**.

To recover: PowerShell `Set-Location "$HOME/code101/go/lesson09"`; macOS/Linux `cd "$HOME/code101/go/lesson09"`. Confirm with `Get-Location` or `pwd`. All commands below run here unless stated otherwise.

### Step 2. Create the module
In `lesson09`, on every OS run this once (skip it for supplied code, which already has `go.mod`):

**File: terminal (not a saved file)**
```text
go mod init example.com/code101/lesson09
```
Expected output:
```text
go: creating new go.mod: module example.com/code101/lesson09
```
Leave the generated `go` version alone; it may differ from the pack's `go 1.22.0`. The [module explanation](../../README.md#module-file) is identical; only the module name ends in `lesson09`.

### Step 3. Write the complete program
An **error value** is an ordinary value that describes a failure. Normally it is a second result. nil means success here. A **guard clause** handles an exceptional condition early, keeping the normal path simple.

In the Explorer select the root `lesson09` folder, click **New File**, type `main.go` and press Enter. Paste the complete file:

**File: `main.go`**
```go
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
)

func parseAmount(text string) (int, error) {
	amount, err := strconv.Atoi(text)
	if err != nil {
		return 0, fmt.Errorf("amount %q: %w", text, err)
	}
	if amount <= 0 {
		return 0, errors.New("amount must be positive")
	}
	return amount, nil
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Amount in whole units:")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended.")
			}
			return
		}
		amount, err := parseAmount(scanner.Text())
		if err != nil {
			fmt.Println("Try again:", err)
			continue
		}
		fmt.Println("Accepted:", amount)
		break
	}
}
```

Save each file with **Ctrl+S** (Windows/Linux) or **Cmd+S** (macOS). A dot on a tab means not saved. Keep these .go files beside go.mod; do not name them .go.txt.

## Run it
Inside your own lesson09 folder (or the pack's 09-errors/code), on every OS run:

**File: `terminal (not a saved file)`**
```text
go run .
```

Type the following lines in order, pressing Enter after each. Wait for each matching prompt:

**File: `keyboard input (not a saved file)`**
```text
tea
0
12
```

Expected output (captured on Go 1.27.4, Windows; program output only, not typed-input echo):

**File: `terminal output (not a saved file)`**
```text
Amount in whole units:
Try again: amount "tea": strconv.Atoi: parsing "tea": invalid syntax
Amount in whole units:
Try again: amount must be positive
Amount in whole units:
Accepted: 12
```

## How it works
1. parseAmount returns (int, error). On failure the calling code must use the error and ignore the numeric result.
2. fmt.Errorf adds context. %q quotes the input; %w performs **error wrapping**, preserving the underlying error rather than just its text. %v would only format its text.
3. errors.New creates our own error for a rule parsing cannot check: zero is valid numeric text but not a positive amount. This extra rule check is **validation**.
4. return amount, nil marks success. main prints failures then continues to re-ask. Success prints Accepted and breaks out.
5. When Scan has no next line, check scanner.Err, then return. Do not repeatedly ask after input ends.

## Try it
Minimum amount: accept only whole-number amounts of at least 10. For smaller numbers print `amount must be at least 10` and ask again. Keep the existing helpful message for non-numbers. Enter 5 then 12; 5 must be rejected and 12 accepted.

If using the optional source, find `09-errors/exercise/starter`, then copy the `starter` folder and rename it `try09` alongside `lesson09` in `$HOME/code101/go`. `try09` must directly contain `go.mod` and `main.go`, not another `starter` folder. Without the source, create `try09` and type the starter files below; create any named subfolders first with Explorer's **New Folder** icon.

Follow [exercise setup](../../README.md#exercise-folders): open **only** `try09` in VS Code, open **Terminal > New Terminal**, edit and save. No `go mod init`: the starter includes `go.mod`. Recovery: PowerShell `Set-Location "$HOME/code101/go/try09"`; macOS/Linux `cd "$HOME/code101/go/try09"`.

**File: `go.mod (starter)`**
```text
module example.com/code101/lesson09

go 1.22.0
```

**File: `main.go (starter)`**
```go
package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strconv"
)

func parseAmount(text string) (int, error) {
	amount, err := strconv.Atoi(text)
	if err != nil {
		return 0, fmt.Errorf("amount %q: %w", text, err)
	}
	// TODO: accept only amounts of at least 10.
	if amount <= 0 {
		return 0, errors.New("amount must be positive")
	}
	return amount, nil
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("Amount in whole units:")
		if !scanner.Scan() {
			if scanner.Err() != nil {
				fmt.Println("Input failed:", scanner.Err())
			} else {
				fmt.Println("Input ended.")
			}
			return
		}
		amount, err := parseAmount(scanner.Text())
		if err != nil {
			fmt.Println("Try again:", err)
			continue
		}
		fmt.Println("Accepted:", amount)
		break
	}
}
```

In `try09` run, on every OS:

**File: `terminal (not a saved file)`**
```text
go run .
```

After editing, type these lines in order, pressing Enter after each and waiting for the matching prompts:

**File: `keyboard input (not a saved file)`**
```text
5
12
```

Expected output after your change (captured from the solution, excluding keyboard echo):

**File: `terminal output (not a saved file)`**
```text
Amount in whole units:
Try again: amount must be at least 10
Amount in whole units:
Accepted: 12
```

<details><summary>Solution</summary>

In `try09`, delete the TODO comment(s) and replace the corresponding region(s) below. All other lines and files, including `go.mod`, are unchanged from the starter. Save and run the same command and inputs.

**File: `main.go` (replacement region, solution lines 13-20)**
```go
	if err != nil {
		return 0, fmt.Errorf("amount %q: %w", text, err)
	}
	if amount < 10 {
		return 0, errors.New("amount must be at least 10")
	}
	return amount, nil
}
```

</details>

## Check yourself
1. What does err == nil mean?
   <details><summary>Answer</summary>Success.</details>
2. Why does parsing not reject zero?
   <details><summary>Answer</summary>It is valid numeric text; validation is separate.</details>
3. What does %w preserve?
   <details><summary>Answer</summary>The underlying error.</details>
4. Why return at end of input?
   <details><summary>Answer</summary>There is no possible next answer.</details>

## Common mistakes
One diagnostic below mentions a **method**: a function attached to a type. You will write your own methods in lesson 10.

These messages were captured by making the specific changes described below in this lesson's files, or by using the wrong folder, command or input. Compiler output may start with `# example.com/code101/lesson09` (your module name); that heading is normal. `main.go:line:column` locates the problem. Your numbers and path separators may differ; fix the described change, save and rerun. A table row shows the relevant diagnostic line, not necessarily every line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `go: go.mod file not found in current directory or any parent directory; see 'go help modules'` | Ran outside the module folder | Confirm `Get-Location` (PowerShell) or `pwd`; use the recovery command in Step 1 to return to the folder holding `go.mod`. For an exercise, return to its `try09` folder. |
| `.\main.go:34:13: assignment mismatch: 1 variable but parseAmount returns 2 values` | Captured one variable from a two-result call | Capture both: `amount, err := parseAmount(scanner.Text())`. |
| `.\main.go:17:13: cannot use "amount must be positive" (constant of type string) as error value in return statement: string does not implement error (missing method Error)` | Returned text where an error is required | Restore `errors.New("amount must be positive")`; the method named Error is how Go recognizes an error description (methods are explained in lesson 10). |

If output has not changed, save the editor tab (a dot means unsaved) and confirm your current folder before changing code.

## Best practice
Use %w to add context when callers should still be able to inspect the original cause. Source: Go blog: Working with Errors in Go 1.13 https://go.dev/blog/go1.13-errors

## Next lesson
**[10. Structs and methods](10-structs-and-methods.md):** group values and attach methods.
