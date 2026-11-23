---
track: python
level: 101
phase: 2
phase_name: building-blocks
lesson: 08
title: Files
time: "60 min (two sittings)"
prerequisites: [101.2.07]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-2-building-blocks/08-files/
assets: []
---

# 08. Files

## Why it matters
A whiteboard loses its notes when you wipe it; a notebook keeps them for tomorrow. Variables are the whiteboard of a running program. Files let you keep information after Python stops.

## What you will build
A text note and a shopping table saved beside your script, then read back. The exercise makes a journal that adds entries instead of replacing them.

## Before you start
- Time: 60 minutes in two sittings; break before Step 4, including typing and the exercise.
- Finish lesson 07; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-2-building-blocks/08-files/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson08" -Force | Out-Null
Set-Location "$HOME/code101/lesson08"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson08
cd ~/code101/lesson08
code .
```
Expected result: VS Code opens `lesson08`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson08` unless a subfolder is explicitly named.

### Step 2. Choose a file and its mode
A **file path** describes a file's location. `Path` is a ready-made helper for paths. Use the folder-setting line
below as a recipe for keeping the note beside your script; its parts are explained in the optional note.

`path.open(...)` opens a file. Its first argument is the **file mode**: `"w"` writes, creating a file or
**erasing its previous content**; `"r"` reads an existing file; `"a"` appends at the end, creating a file if needed.
Only use disposable practice files here.

`with ... as file:` starts a **context manager** block: Python closes the file automatically when the block ends,
even if something goes wrong. Keep reads and writes inside that block. `write` saves text; `read` retrieves all its text.
`\n` in a Python string means a newline. `end=""` prevents `print` from adding another newline after one already stored.

<details><summary>Going further: imports, paths and text settings (reference, not memorisation)</summary>

A **module** is a named unit of Python code. The **standard library** is the ready-made modules shipped with Python.
An **import** makes a module or selected names available: `import csv` selects the CSV module;
`from pathlib import Path` selects its path helper. `pathlib` is the standard-library module for file paths.
You will write your own modules in lesson 10.

`__file__` is this script's path. `Path(__file__)` makes a path value; `resolve()` makes it absolute (the full location),
and `.parent` selects its containing folder. `/` joins that folder and a filename here; it does not divide numbers.
This keeps files beside the script even if the terminal starts elsewhere.

A **text encoding** is a rule for storing characters as bytes (small units of stored data). **UTF-8** supports many
languages; `encoding="utf-8"` selects it. A **keyword argument** supplies a setting by parameter name, such as `encoding=`
instead of only by position. Keep these settings as shown. For CSV, `newline=""` lets its tools handle row endings,
including on Windows.
</details>

### Step 3. Write and read a text note
Create `files_demo.py` in `lesson08`. Type this first part; Python creates `note.txt` for you.

**File: `~/code101/lesson08/files_demo.py` (first part)**
```python
import csv
from pathlib import Path


folder = Path(__file__).resolve().parent
note_path = folder / "note.txt"

with note_path.open("w", encoding="utf-8") as file:
    file.write("Remember the milk.\n")

with note_path.open("r", encoding="utf-8") as file:
    note = file.read()
print(note, end="")
```

Save. From `lesson08`, run `python files_demo.py` (macOS/Linux: `python3 files_demo.py`). Expected output:
```text
Remember the milk.
```

**Break point:** your note has survived in `note.txt`. For the second sitting, reopen `lesson08`, choose
**Terminal > New Terminal**, and use `cd ~/code101/lesson08` if needed. Keep all the lines above.

### Step 4. Add a table to the same file
**CSV** means comma-separated values, a text format for rows and columns. A **header** is its first row, naming columns.
Use the CSV module rather than splitting on commas yourself: real cell text may also contain commas.
Append the following directly below the existing `print(note, end="")` line, leaving a blank line between them.

**File: `~/code101/lesson08/files_demo.py` (append below the first part)**
```python
rows = [
    {"item": "bread", "quantity": 2},
    {"item": "apples", "quantity": 3},
]
csv_path = folder / "shopping.csv"

with csv_path.open("w", newline="", encoding="utf-8") as file:
    writer = csv.DictWriter(file, fieldnames=["item", "quantity"])
    writer.writeheader()
    writer.writerows(rows)

with csv_path.open("r", newline="", encoding="utf-8") as file:
    reader = csv.DictReader(file)
    for row in reader:
        quantity = int(row["quantity"])
        print(f"{row['item']}: {quantity}")
```

The `"w"` blocks replace `note.txt` and `shopping.csv` each time. The `"r"` blocks read them back.
Do not create those files manually. Save before running the complete program.

## Run it
**PowerShell, folder: `~/code101/lesson08` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson08"
python files_demo.py
```

**macOS/Linux terminal, folder: `~/code101/lesson08`**
```bash
cd ~/code101/lesson08
python3 files_demo.py
```

Expected output:
```text
Remember the milk.
bread: 2
apples: 3
```

In VS Code's Explorer, click `note.txt` and `shopping.csv` to inspect the generated files. The CSV's first row names
`item` and `quantity`. Running the demo again replaces both files with the same example data.

## How it works
1. The script chooses its own folder, opens the note in write mode, and writes one line. Leaving `with` closes it.
2. It opens the note again in read mode and reads all its text. `end=""` stops `print` from adding a second newline.
3. `rows` is a list of dictionaries: each dictionary is one row with the same two column keys.
4. `csv.DictWriter` creates a writer; `fieldnames` gives the column order. `writeheader()` writes those names;
   `writerows(rows)` writes every row. The library handles commas and quotes.
5. `csv.DictReader` uses the header to make each row a dictionary. CSV values come back as **strings**, so the code uses
   `int(row["quantity"])` before treating a quantity as a number. The file stays open until the loop ends.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **file path**, **CSV**, **header**, **file mode**, **with**, **context manager**, **text encoding**, **keyword argument**, **module**, **import**, **standard library**, **pathlib**.

## Try it
**One-line journal.** Ask for a journal entry and save it without erasing earlier entries. Then display the
whole journal, with one entry per line and no extra blank line. On the first run, there is no journal file yet.

Without the pack, in VS Code's Explorer for `~/code101/lesson08`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `08-files/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson08` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson08/exercise`, not
`lesson08/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson08/exercise/journal.py`**
```python
from pathlib import Path


path = Path(__file__).resolve().parent / "journal.txt"
entry = input("Journal entry: ")

# TODO: open path in append mode with encoding="utf-8" using with.
# Write entry followed by "\n". Then read and print the whole file.
print("TODO")
```

**PowerShell, folder: `~/code101/lesson08/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson08/exercise"
python journal.py
```

**macOS/Linux terminal, folder: `~/code101/lesson08/exercise`**
```bash
cd ~/code101/lesson08/exercise
python3 journal.py
```

The typed answers are not shown below, so a prompt and the next output share a line.
In your terminal, each answer you type appears after its prompt, followed by a new line.

For the captured first run, type `Walked by the river.` and press Enter. Start without an existing `exercise/journal.txt`; later runs keep earlier entries too. Your second run prints both entries, not just the new one.

Expected output:
```text
Journal entry: Walked by the river.
```

<details><summary>Solution</summary>

**File: `~/code101/lesson08/exercise/journal.py`**
```python
from pathlib import Path


path = Path(__file__).resolve().parent / "journal.txt"
entry = input("Journal entry: ")

with path.open("a", encoding="utf-8") as file:
    file.write(entry + "\n")

with path.open("r", encoding="utf-8") as file:
    print(file.read(), end="")
```

Append mode preserves previous entries. Keeping reading in a separate block ensures the write has finished and closed.
</details>

## Check yourself

1. What is the dangerous difference between `"w"` and `"a"`?
   <details><summary>Answer</summary>Write mode erases existing contents; append mode preserves them and adds at the end.</details>

2. Why use `with` when opening a file?
   <details><summary>Answer</summary>It closes the file automatically on leaving the block, including when an error interrupts it.</details>

3. Is the quantity read from CSV already an integer?
   <details><summary>Answer</summary>No. CSV cells are strings; convert the quantity with <code>int</code> before arithmetic.</details>

4. Where do the generated files go, even if you launch the script from another folder?
   <details><summary>Answer</summary>Beside the script, because the path starts from <code>__file__</code> rather than the current terminal folder.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\files_demo.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson08` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `apples: 3` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `FileNotFoundError: [Errno 2] No such file or directory: '<project>\\missing.txt'` | Opened a nonexistent file in read mode | Check the filename, or create it in write/append mode first. `<project>` stands for your lesson folder; your full path will be longer. |
| `ValueError: I/O operation on closed file.` | Tried another write after leaving the first `with` block | Keep writes indented inside the open-file block, or open a new block. |

## Best practice
Open CSV files with `newline=""` and specify the text encoding. Let the CSV reader/writer manage delimiters and row endings rather than building rows by hand.
Source: Python library reference, csv https://docs.python.org/3/library/csv.html#csv.reader

## Next lesson
**09. Handling errors (Phase 3):** recover from bad input and re-ask instead of stopping. You have finished Phase 2.
