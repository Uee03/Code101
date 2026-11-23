---
track: python
level: 101
phase: 3
phase_name: real-programs
lesson: 12
title: "Project: expense tracker"
time: "90 min (two sittings)"
prerequisites: [101.3.11]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

## Why it matters
A paper expense notebook has three useful actions: add a purchase, read past entries and add up the cost. A console program can offer the same actions from a menu and keep the notebook in a file. This project joins the building blocks you have practised.

## What you will build
A menu-driven console app that adds, lists and totals expenses, saving a CSV beside the script. It uses whole cents, rejects bad amounts, reloads saved entries at startup, and includes a tiny plain-assert self-check run with Python.

## Before you start
- Time: 90 minutes in two sittings; break before Step 3, including typing and the exercise.
- Finish lesson 11; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson12" -Force | Out-Null
Set-Location "$HOME/code101/lesson12"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson12
cd ~/code101/lesson12
code .
```
Expected result: VS Code opens `lesson12`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson12` unless a subfolder is explicitly named.

### Step 2. Build the storage and calculation module
Create `tracker.py`. Keep this example's practice data separate from real financial records.
A **constant** is a name intended not to change; Python convention writes it in capitals, such as `FIELDS`.
`None` represents an absent value, not zero or an empty string. The CSV reader uses it for missing cells or extra columns. `is None` checks for that special missing value.
`raise ValueError(...)` deliberately signals an exception when a file breaks our rules.
`reader.fieldnames` holds the CSV header's column names. A **schema** is the expected names and order: here,
`description,cents`. `.strip()` returns text with leading and trailing spaces removed.

**File: `~/code101/lesson12/tracker.py`**
```python
import csv


FIELDS = ["description", "cents"]


def format_money(cents):
    return f"{cents // 100}.{cents % 100:02d}"


def total_expenses(expenses):
    total = 0
    for expense in expenses:
        total = total + expense["cents"]
    return total


def load_expenses(path):
    expenses = []
    try:
        with path.open("r", newline="", encoding="utf-8") as file:
            reader = csv.DictReader(file)
            if reader.fieldnames is None:
                return []
            if reader.fieldnames != FIELDS:
                raise ValueError("CSV header must be description,cents")
            for row in reader:
                if None in row or row["description"] is None or row["cents"] is None:
                    raise ValueError("CSV row needs exactly two fields")
                description = row["description"].strip()
                cents = int(row["cents"])
                if not description or cents <= 0:
                    raise ValueError("CSV rows need a description and positive cents")
                expenses.append({"description": description, "cents": cents})
    except FileNotFoundError:
        return []
    return expenses


def save_expenses(path, expenses):
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(expenses)
```

The loader accepts a missing or empty
file as an empty notebook. Otherwise it checks the header and each row before accepting it. CSV stores text, so cents
must be converted back to integers on reading. A comma in a description is allowed: the CSV tools quote it correctly.

<details><summary>Going further: why the loader checks row shape</summary>

`FIELDS` records our expected column names once. `reader.fieldnames != FIELDS` rejects any different header.
For an overlong row, `DictReader` stores extra cells under the key `None`; for a short row, a missing cell gets the
value `None`. The `None in row` and `is None` checks reject both shapes before we use the cells. Keep them as shown;
they protect existing data rather than treating a damaged row as a new empty notebook.
</details>

`format_money` uses the exact integer-cent formatting from lesson 10. We copy it here rather than importing
`helpers.formatting` so this project stays in one folder and does not depend on your lesson10 folder. `total_expenses` takes a list of expense dictionaries
and adds their cents. `save_expenses` writes the **entire** list, including its header, using the file tools from lesson 08.

**Break point:** The storage module is ready; it defines helpers but does not print anything by itself.
For the second sitting, reopen `lesson12`, choose **Terminal > New Terminal**, and continue with the menu.

### Step 3. Build the menu and input layer
Create `main.py` beside `tracker.py`. It imports the helpers but keeps user questions and screen output in this file.
A **tuple** is an ordered group of values that cannot be changed in place. The parenthesised tuple
`(OSError, ValueError, csv.Error)` lists the three exception types this loader can handle.
The **operating system** (Windows, macOS or Linux) is the software managing files and devices.
`OSError` reports a failure from that system, such as denied file access. `csv.Error` reports a problem detected
by the CSV reader. `except ... as error` gives the caught exception the local name `error` so we can display its message.
Inside the f-string, `'description'` uses the other quote style to distinguish it from the surrounding text.

**File: `~/code101/lesson12/main.py`**
```python
import csv
from pathlib import Path

from tracker import format_money, load_expenses, save_expenses, total_expenses


def read_cents():
    while True:
        try:
            cents = int(input("Amount in cents (250 = 2.50): "))
        except ValueError:
            print("Use whole cents, for example 250.")
            continue
        if cents <= 0:
            print("Amount must be positive.")
            continue
        return cents


def main():
    path = Path(__file__).resolve().parent / "expenses.csv"
    try:
        expenses = load_expenses(path)
    except (OSError, ValueError, csv.Error) as error:
        print(f"Cannot load expenses: {error}")
        return

    while True:
        print("1 Add | 2 List | 3 Total | 4 Quit")
        choice = input("Choice: ")
        if choice == "1":
            description = input("Description: ").strip()
            if not description:
                print("Description cannot be empty.")
                continue
            cents = read_cents()
            updated = expenses + [{"description": description, "cents": cents}]
            try:
                save_expenses(path, updated)
            except OSError as error:
                print(f"Cannot save expenses: {error}")
                continue
            expenses = updated
            print("Saved.")
        elif choice == "2":
            if not expenses:
                print("No expenses yet.")
            for expense in expenses:
                amount = format_money(expense["cents"])
                print(f"{expense['description']}: {amount}")
        elif choice == "3":
            total = total_expenses(expenses)
            print(f"Total: {format_money(total)}")
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Choose 1, 2, 3 or 4.")


if __name__ == "__main__":
    main()
```

The menu repeats until option 4. `.strip()` removes leading and trailing spaces from a description; blank descriptions
are rejected. Enter money as **whole cents**: 250 means 2.50, not 250.00. `read_cents` catches bad integer text and re-asks,
then rejects zero and negative amounts. Keeping cents as integers avoids float rounding in stored amounts and totals.

`expenses + [new_expense]` makes a new list with one more dictionary. The app saves that list before replacing its
in-memory list. A failed save prints the error instead of claiming success. At startup, the tuple of exception types catches
only known loading failures. A bad header or cell must not be silently treated as an empty notebook and then overwritten.

This learning app rewrites a small CSV on each add. It is not crash-safe or designed for simultaneous users: interruption
while writing can damage the file. Use only disposable practice data and keep backups; do not treat it as financial software.
A class is not required here: independent functions already separate storage, calculations and conversation.

### Step 4. Add a tiny self-check, without a test framework
**Going further (optional):** the menu app is already complete. This separate file demonstrates developer checks;
you can return to it after using the app. It does not change the app's code.
A **self-check** is a small program that exercises a few known examples. `assert condition` stops with `AssertionError`
if its condition is false; a true assertion prints nothing. Use assertions for developer checks, **not** for validating
user input: Python's `-O` option can remove them.

Create `self_check.py` beside the other two files. `TemporaryDirectory` makes a disposable folder; its `with` block
removes it afterward. The self-check therefore does not read or overwrite your own `expenses.csv`.

**File: `~/code101/lesson12/self_check.py`**
```python
from pathlib import Path
from tempfile import TemporaryDirectory

from tracker import format_money, load_expenses, save_expenses, total_expenses


with TemporaryDirectory() as folder:
    path = Path(folder) / "expenses.csv"
    assert load_expenses(path) == []
    expenses = [{"description": "Tea, large", "cents": 250}]
    save_expenses(path, expenses)
    assert load_expenses(path) == expenses
    assert total_expenses(expenses) == 250
    assert format_money(205) == "2.05"

print("Self-check passed.")
```

`save_expenses` followed by `load_expenses` checks that the saved data can be read back unchanged, including a comma
in a description. Other assertions check a missing file, a total and a leading zero in the cents display.
No extra tools are needed.

## Run it
The typed answers are not shown below, so a prompt and the next output share a line.
In your terminal, each answer you type appears after its prompt, followed by a new line.

Start with no `expenses.csv` in `lesson12` for the first-run capture. If one already exists, preserve it by renaming it
in your file manager before this practice run; do not delete data you want to keep. Run the menu app:

**PowerShell, folder: `~/code101/lesson12` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson12"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson12`**
```bash
cd ~/code101/lesson12
python3 main.py
```

Enter these answers in order, each followed by Enter: `1`, `Tea`, `250`, `2`, `3`, `4`. You add one expense, list it, total it, then quit.

Expected output:
```text
1 Add | 2 List | 3 Total | 4 Quit
Choice: Description: Amount in cents (250 = 2.50): Saved.
1 Add | 2 List | 3 Total | 4 Quit
Choice: Tea: 2.50
1 Add | 2 List | 3 Total | 4 Quit
Choice: Total: 2.50
1 Add | 2 List | 3 Total | 4 Quit
Choice: Goodbye!
```

In VS Code, open the generated `expenses.csv` beside your script. Its captured contents are:

**File: `~/code101/lesson12/expenses.csv` (generated, not typed)**
```csv
description,cents
Tea,250
```

To use the program later, run the **same `python main.py` command above** from the **same lesson12 folder**.
The startup loader reads this CSV; choose 2 to list existing entries. This repeat is identical: do not recreate or clear
the CSV. Adding the same Tea entry a second time intentionally creates a second purchase, not a replacement.

Now run the separate self-check with ordinary Python (not `pytest`):

**PowerShell, folder: `~/code101/lesson12` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson12"
python self_check.py
```

**macOS/Linux terminal, folder: `~/code101/lesson12`**
```bash
cd ~/code101/lesson12
python3 self_check.py
```

Expected output:
```text
Self-check passed.
```

## How it works
1. The main guard starts the app only when `main.py` is run directly.
2. `Path(__file__).resolve().parent` anchors `expenses.csv` beside that script. The loader converts stored cents and
   refuses malformed headers or rows. A genuinely missing file starts an empty list.
3. Each menu iteration reads a choice as text. Unknown choices print guidance rather than crashing.
4. Add validates a description and cents, saves the new list, then reports success. List formats each expense. Total adds
   integer cents before formatting. Quit breaks out of the loop.
5. Both storage functions use `with`, UTF-8 and CSV-specific newline handling. The self-check imports the same helpers
   without launching the menu, and writes only to its temporary directory.

Keep `main.py`, `tracker.py` and `self_check.py` together. The app has no external dependencies. To reset a disposable
notebook, stop the app and rename its CSV in your file manager; the next launch begins a new notebook.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **constant**, **None**, **raise**, **schema**, **tuple**, **operating system**, **OSError**, **csv.Error**, **except ... as**, **self-check**, **assert**, **TemporaryDirectory**, **strip**.

## Try it
**Add a count option.** Add option 5 to display `Expense count: N`, where N is the number of saved purchases.
The starter already shows `5 Count` in the menu and has an `elif choice == "5":` block containing a TODO print.
Replace that print only. Keep option 4 as Quit. The two unchanged helper files are exact copies from Steps 2 and 4:
copy `tracker.py` and `self_check.py` into `exercise` too; their names and contents do not change. Only `main.py` differs.
Because this copy lives in `exercise`, it uses its own `exercise/expenses.csv`, not the original app's CSV.

Without the pack, in VS Code's Explorer for `~/code101/lesson12`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `12-expense-tracker/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson12` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson12/exercise`, not
`lesson12/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson12/exercise/main.py`**
```python
import csv
from pathlib import Path

from tracker import format_money, load_expenses, save_expenses, total_expenses


def read_cents():
    while True:
        try:
            cents = int(input("Amount in cents (250 = 2.50): "))
        except ValueError:
            print("Use whole cents, for example 250.")
            continue
        if cents <= 0:
            print("Amount must be positive.")
            continue
        return cents


def main():
    path = Path(__file__).resolve().parent / "expenses.csv"
    try:
        expenses = load_expenses(path)
    except (OSError, ValueError, csv.Error) as error:
        print(f"Cannot load expenses: {error}")
        return

    while True:
        print("1 Add | 2 List | 3 Total | 4 Quit | 5 Count")
        choice = input("Choice: ")
        if choice == "1":
            description = input("Description: ").strip()
            if not description:
                print("Description cannot be empty.")
                continue
            cents = read_cents()
            updated = expenses + [{"description": description, "cents": cents}]
            try:
                save_expenses(path, updated)
            except OSError as error:
                print(f"Cannot save expenses: {error}")
                continue
            expenses = updated
            print("Saved.")
        elif choice == "2":
            if not expenses:
                print("No expenses yet.")
            for expense in expenses:
                amount = format_money(expense["cents"])
                print(f"{expense['description']}: {amount}")
        elif choice == "3":
            total = total_expenses(expenses)
            print(f"Total: {format_money(total)}")
        elif choice == "4":
            print("Goodbye!")
            break
        elif choice == "5":
            # TODO: print the number of saved expenses using len(expenses).
            print("TODO")
        else:
            print("Choose 1, 2, 3, 4 or 5.")


if __name__ == "__main__":
    main()
```

The starter pack contains all three files. If typing instead, copy the exact complete `tracker.py` and `self_check.py` already shown above into `exercise`; no lines change. Save all three files before running.

**PowerShell, folder: `~/code101/lesson12/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson12/exercise"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson12/exercise`**
```bash
cd ~/code101/lesson12/exercise
python3 main.py
```

Start with no CSV in the exercise folder. Enter `1`, `Tea`, `250`, `5`, `4`, each followed by Enter.

Expected output:
```text
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
Choice: Description: Amount in cents (250 = 2.50): Saved.
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
Choice: Expense count: 1
1 Add | 2 List | 3 Total | 4 Quit | 5 Count
Choice: Goodbye!
```

<details><summary>Solution</summary>

**File: `~/code101/lesson12/exercise/main.py`**
```python
import csv
from pathlib import Path

from tracker import format_money, load_expenses, save_expenses, total_expenses


def read_cents():
    while True:
        try:
            cents = int(input("Amount in cents (250 = 2.50): "))
        except ValueError:
            print("Use whole cents, for example 250.")
            continue
        if cents <= 0:
            print("Amount must be positive.")
            continue
        return cents


def main():
    path = Path(__file__).resolve().parent / "expenses.csv"
    try:
        expenses = load_expenses(path)
    except (OSError, ValueError, csv.Error) as error:
        print(f"Cannot load expenses: {error}")
        return

    while True:
        print("1 Add | 2 List | 3 Total | 4 Quit | 5 Count")
        choice = input("Choice: ")
        if choice == "1":
            description = input("Description: ").strip()
            if not description:
                print("Description cannot be empty.")
                continue
            cents = read_cents()
            updated = expenses + [{"description": description, "cents": cents}]
            try:
                save_expenses(path, updated)
            except OSError as error:
                print(f"Cannot save expenses: {error}")
                continue
            expenses = updated
            print("Saved.")
        elif choice == "2":
            if not expenses:
                print("No expenses yet.")
            for expense in expenses:
                amount = format_money(expense["cents"])
                print(f"{expense['description']}: {amount}")
        elif choice == "3":
            total = total_expenses(expenses)
            print(f"Total: {format_money(total)}")
        elif choice == "4":
            print("Goodbye!")
            break
        elif choice == "5":
            print(f"Expense count: {len(expenses)}")
        else:
            print("Choose 1, 2, 3, 4 or 5.")


if __name__ == "__main__":
    main()
```

`tracker.py` and `self_check.py` stay exactly as shown in Steps 2 and 4. `len(expenses)` counts purchases, not cents or CSV header rows.
</details>

## Check yourself

1. Why store 250 instead of the float 2.50?
   <details><summary>Answer</summary>Whole cents use exact integer arithmetic for storage and totals. Formatting adds the decimal point for display.</details>

2. Why is `FileNotFoundError` handled differently from a malformed CSV?
   <details><summary>Answer</summary>No file is normal on first use; a malformed existing file needs attention and must not silently become an empty notebook.</details>

3. Why does the code replace `expenses` only after saving succeeds?
   <details><summary>Answer</summary>It avoids reporting an in-memory addition as saved when the write failed. The demo still needs backups because a partial disk write is possible.</details>

4. Can the self-check overwrite your real practice expenses?
   <details><summary>Answer</summary>No. It uses a TemporaryDirectory and removes that disposable folder when finished.</details>

5. Why not use `assert cents > 0` as user-input validation?
   <details><summary>Answer</summary>Assertions can be disabled. User validation must use ordinary conditions and explicit error handling.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\main.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson12` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Choice: Goodbye!` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `Use whole cents, for example 250.` | Typed `2.50` at the cents prompt; the app caught the conversion error | Enter `250` for 2.50; keep read_cents' retry handler. |
| `Cannot load expenses: CSV header must be description,cents` | Saved a semicolon-separated header instead of `description,cents` | Stop the app and back up the CSV. Correct the header and its rows, or rename the broken practice CSV to start fresh. |
| `AssertionError` | Changed the self-check expectation from `2.05` to `2.50` | 205 cents is 2.05. Restore that expectation; if an unchanged check fails, fix the helper, not the assertion. |

For example, changing only the final expected money string to `"2.50"` produces this traceback
(`<project>` is your folder; line numbers can differ). Restore `"2.05"` afterward:

```text
Traceback (most recent call last):
  File "<project>\self_check.py", line 14, in <module>
    assert format_money(205) == "2.50"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError
```

## Best practice
Keep assertions for developer self-checks, not for required user-input validation. Handle expected bad input with explicit checks and exceptions.
Source: Python language reference, The assert statement https://docs.python.org/3/reference/simple_stmts.html#the-assert-statement

## Next lesson
You have completed all 12 lessons of Python 101; keep this expense tracker as your starting project.
Continue with [Python 201 lesson 01, classes in depth](../../201-hero-to-super-hero/phase-1-core-skills/01-classes-in-depth.md).
