---
track: python
level: 101
phase: 3
phase_name: real-programs
lesson: 09
title: Handling errors
time: "40 min"
prerequisites: [101.2.08]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-3-real-programs/09-handling-errors/
assets: []
---

# 09. Handling errors

## Why it matters
A shop assistant does not close the shop because a customer gives an unclear answer. They explain what is needed and ask again. Your program can do the same when typed text is not a usable number.

## What you will build
Two reusable input functions: one re-asks for a valid age, the other for a valid bill amount. This supplies the error-handling pattern promised in lesson 03 (tip calculator); it also improves lesson 04's ticket input.

## Before you start
- Time: 40 minutes, including typing and the exercise.
- Finish lesson 08; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-3-real-programs/09-handling-errors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- In this lesson Windows commands use PowerShell 5.1-compatible syntax. macOS/Linux commands use `python3`.

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Open your lesson folder
Open a terminal (VS Code: **Terminal > New Terminal**). From any folder, run the commands for your system.
`$HOME` and `~` mean your home folder. The folder before the terminal's `>` or `$` is your current folder.

**PowerShell, starting folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/lesson09" -Force | Out-Null
Set-Location "$HOME/code101/lesson09"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson09
cd ~/code101/lesson09
code .
```
Expected result: VS Code opens `lesson09`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson09` unless a subfolder is explicitly named.

### Step 2. Separate a crash from an unsuitable value
An **exception** is an error detected while a program runs. A **traceback** is the trail of file locations printed for
an unhandled exception. `int("ten")` and `float("$80")` raise `ValueError`: the conversion understands the requested type,
but cannot use that text.

**Validation** checks whether input is acceptable. There are two separate questions:
1. Can Python convert it? Catch the specific `ValueError` if not.
2. Does the converted value fit our rule? A negative age converts successfully but still needs rejecting.

`try` marks code that might raise an exception. An `except ValueError:` block is an exception **handler**: it runs when
that specific exception happens in the `try` block. It is skipped when conversion succeeds.

### Step 3. Create both re-ask loops
Create `safe_input.py`. Focus first on the age function; the bill function repeats the same error-handling pattern.

<details><summary>Going further: the bill's extra number check</summary>

`math.isfinite` is a standard-library helper that rejects special floats: infinity (`inf`) and "not a number" (`nan`).
A **finite number** is an ordinary number rather than either of those special values. The `from ... import ...` form
imports just the named helper, as with `Path` in lesson 08. Keep the check as shown; you can return to this detail later.
</details>

**File: `~/code101/lesson09/safe_input.py`**
```python
from math import isfinite


def read_age():
    while True:
        try:
            age = int(input("Age: "))
        except ValueError:
            print("Use whole digits, for example 30.")
            continue
        if age < 0:
            print("Age cannot be negative.")
            continue
        return age


def read_bill():
    while True:
        try:
            bill = float(input("Bill amount: "))
        except ValueError:
            print("Use a number like 80.50, without a currency sign.")
            continue
        if not isfinite(bill) or bill < 0:
            print("Bill must be a finite number of zero or more.")
            continue
        return bill


age = read_age()
bill = read_bill()
print(f"Age accepted: {age}")
print(f"Bill accepted: {bill:.2f}")
```

### Step 4. Follow a failed attempt
Both functions use `while True` to ask again. The only line inside each `try` is the input conversion.
If conversion fails, the handler prints guidance and `continue` restarts the loop **before** the code can use a missing value.
If conversion succeeds but breaks a rule, an `if` prints different guidance and continues.
Only a good value reaches `return`, which ends the function and therefore its loop.

Use a dot in decimal amounts and omit currency or percentage signs. Catching conversion errors alone is not validation;
our rules also reject converted values that do not make sense for an age or bill.

## Run it
The typed answers are not shown below, so a prompt and the next output share a line.
In your terminal, each answer you type appears after its prompt, followed by a new line.

Enter these answers in order, pressing Enter after each: `ten`, `-1`, `30`, `$80`, `-5`, `80.50`.
The first two ages and first two bills are rejected without ending the program.

**PowerShell, folder: `~/code101/lesson09` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson09"
python safe_input.py
```

**macOS/Linux terminal, folder: `~/code101/lesson09`**
```bash
cd ~/code101/lesson09
python3 safe_input.py
```

Expected output:
```text
Age: Use whole digits, for example 30.
Age: Age cannot be negative.
Age: Bill amount: Use a number like 80.50, without a currency sign.
Bill amount: Bill must be a finite number of zero or more.
Bill amount: Age accepted: 30
Bill accepted: 80.50
```

## How it works
1. `read_age()` first catches bad whole-number text, then rejects negative integers. It returns 30 in this run.
2. `read_bill()` catches bad decimal text, then rejects negative or non-finite floats. It returns 80.5.
3. The caller stores only accepted values and prints them. `:.2f` displays the bill as 80.50.
4. An unrelated error, such as a misspelled variable, is **not** caught by `except ValueError`; it remains visible to fix.

**Connect this to lessons 03 and 04:** their conversions were `float(bill_text)` and `int(input(...))`.
The bodies above show the complete replacement pattern: conversion inside `try`, a specific handler, a rule check,
and `return` only on success. A ticket machine can call `read_age()` before its price decisions; a calculator can call
`read_bill()` before arithmetic. This file is self-contained; you do not need to edit the older lesson folders.
A tip percentage would use the same float re-ask pattern with its own prompt and allowed range.

Do not put a blanket `except:` around the whole program: that would also hide programming mistakes and can intercept
an intentional Ctrl+C. Keep the risky operation and its handler close together.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **exception**, **try/except**, **validation**, **handler**, **finite number**.

## Try it
**Safe bill splitting.** The bill is fixed at 90. Repeatedly ask `Number of people: ` until the answer converts
to a whole number and is at least 1. For text that cannot convert, display `Use a whole number.` and ask again.
For zero or a negative number, display `At least one person is needed.` and ask again. Divide only after a valid answer.
This prevents the zero-division problem seen in lesson 03.

Without the pack, in VS Code's Explorer for `~/code101/lesson09`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `09-handling-errors/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson09` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson09/exercise`, not
`lesson09/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson09/exercise/split_bill.py`**
```python
# TODO: replace the fixed people value with a re-ask loop.
# Catch ValueError from int(input(...)); also reject values below 1.
bill = 90
people = 1
print(f"Each person pays {bill / people:.2f}")
```

**PowerShell, folder: `~/code101/lesson09/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson09/exercise"
python split_bill.py
```

**macOS/Linux terminal, folder: `~/code101/lesson09/exercise`**
```bash
cd ~/code101/lesson09/exercise
python3 split_bill.py
```

Enter `four`, then `0`, then `4`, pressing Enter after each.

Expected output:
```text
Number of people: Use a whole number.
Number of people: At least one person is needed.
Number of people: Each person pays 22.50
```

<details><summary>Solution</summary>

**File: `~/code101/lesson09/exercise/split_bill.py`**
```python
bill = 90

while True:
    try:
        people = int(input("Number of people: "))
    except ValueError:
        print("Use a whole number.")
        continue
    if people < 1:
        print("At least one person is needed.")
        continue
    break

print(f"Each person pays {bill / people:.2f}")
```

Conversion failure and a converted-but-invalid number take different paths. Neither reaches the division.
</details>

## Check yourself

1. Does `int("-1")` raise `ValueError`?
   <details><summary>Answer</summary>No. It converts successfully to -1; an explicit rule must reject a negative age or people count.</details>

2. Why is `continue` inside the exception handler?
   <details><summary>Answer</summary>It starts a fresh attempt before later code tries to use a value that was not successfully assigned.</details>

3. Why not catch every exception?
   <details><summary>Answer</summary>You would hide unrelated programming errors. Catch the exception you can actually recover from.</details>

4. Why does the `try` block contain only the conversion?
   <details><summary>Answer</summary>It keeps the handler focused on a failed conversion rather than hiding unrelated errors elsewhere.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\safe_input.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson09` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Bill accepted: 80.50` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `Use whole digits, for example 30.` | Typed `ten` for the age; the handler caught the conversion error | Enter a whole number. This is guidance, not a crash. |
| `Use a number like 80.50, without a currency sign.` | Typed `$80` for the bill; the handler caught it | Use `80.50`, without a sign or decimal comma. |
| `SyntaxError: expected ':'` | Omitted the colon after `except ValueError` | Restore `:` so the handler can be parsed. |
| `UnboundLocalError: cannot access local variable 'age' where it is not associated with a value` | Removed `continue` from the first conversion handler | Keep it inside the handler so a failed assignment cannot reach `if age < 0`. |
| `NameError: name 'isfinite' is not defined` | Forgot to import `isfinite` | Restore the import at the top of this file. |

## Best practice
Catch specific exceptions and keep the `try` block limited to the operation you expect might fail. Validate the converted result separately.
Source: Python tutorial, Handling exceptions https://docs.python.org/3/tutorial/errors.html#handling-exceptions

## Next lesson
**10. Modules and packages:** split helpers into files and learn isolated package installation with `venv` and `pip`.
