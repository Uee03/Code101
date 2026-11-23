---
track: python
level: 101
phase: 3
phase_name: real-programs
lesson: 10
title: Modules and packages
time: "60 min (two sittings)"
prerequisites: [101.3.09]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-3-real-programs/10-modules-and-packages/
assets: []
---

# 10. Modules and packages

## Why it matters
A toolbox groups related tools so you can find one without rebuilding it. Modules and packages organise Python helpers in the same way. A separate toolbox for each project also stops one project's installed tools from upsetting another.

## What you will build
A delivery report built from your own module, your own package and standard-library helpers. Then you will create a virtual environment and use pip to install and import one pinned third-party package.

## Before you start
- Time: 60 minutes in two sittings; break before Step 5, including typing and the exercise.
- Finish lesson 09; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-3-real-programs/10-modules-and-packages/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- In this lesson Windows commands use PowerShell 5.1-compatible syntax. macOS/Linux commands use `python3`.
- The small report uses only Python itself. The separate pip practice needs an internet connection and installs only inside `.venv`.

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Open your lesson folder
Open a terminal (VS Code: **Terminal > New Terminal**). From any folder, run the commands for your system.
`$HOME` and `~` mean your home folder. The folder before the terminal's `>` or `$` is your current folder.

**PowerShell, starting folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/lesson10" -Force | Out-Null
Set-Location "$HOME/code101/lesson10"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson10
cd ~/code101/lesson10
code .
```
Expected result: VS Code opens `lesson10`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson10` unless a subfolder is explicitly named.

### Step 2. Create your own module
Lesson 08 introduced modules through `csv` and `pathlib`. Now create `totals.py` beside the report's future `main.py`.
The filename, without `.py`, is the module name used in an import.

**File: `~/code101/lesson10/totals.py`**
```python
def line_total(price, quantity):
    return price * quantity
```

### Step 3. Create a package with a nested module
A **package** groups modules under one name. In VS Code's Explorer, choose **New Folder** and name it `helpers` inside
`lesson10`. Create these **two files inside helpers**, not beside it. `__init__.py` has two underscores before and after
`init`; this file marks a regular package. Other package forms exist, but this course uses this explicit one.

**File: `~/code101/lesson10/helpers/__init__.py`**
```python
# This file marks helpers as a regular Python package.
```

**File: `~/code101/lesson10/helpers/formatting.py`**
```python
def format_money(cents):
    return f"{cents // 100}.{cents % 100:02d}"
```

`format_money` takes whole cents. `// 100` gives whole currency units and `% 100` gives leftover cents.
The format `:02d` means a whole number (`d`) padded with zeros (`0`) to at least two digits (`2`), so 5 cents shows as `05`.
This keeps stored amounts as integers instead of approximate decimal floats.

### Step 4. Assemble the report
Back in `lesson10` (outside `helpers`), create `main.py`. A **dotted import** such as `helpers.formatting` means the
`formatting` module inside the `helpers` package. Python finds your neighbouring modules when it runs this script.

**File: `~/code101/lesson10/main.py`**
```python
from datetime import date
from math import ceil

from helpers.formatting import format_money
from totals import line_total


def main():
    delivery = date(2026, 12, 1)
    total_cents = line_total(125, 3)
    boxes = ceil(7 / 3)
    print(f"Delivery: {delivery.isoformat()}")
    print(f"Total: {format_money(total_cents)}")
    print(f"Boxes for 7 jars, 3 per box: {boxes}")


if __name__ == "__main__":
    main()
```

`datetime.date` represents a calendar date; `date(2026, 12, 1)` is a fixed example date, not today's date.
`isoformat()` produces year-month-day text. `math.ceil` rounds upward: 7 jars at 3 per box need 3 boxes.
Other familiar standard-library tools are `pathlib` for paths and `csv` for tables; none needs pip installation.

The **main guard**, `if __name__ == "__main__":`, runs `main()` when this file is executed directly. Python supplies the
special name `__name__`: for an imported file it is the module's name instead. The guard stops the report from printing
just because another module imports its definitions.

**Break point:** Your module and package are ready. Before stopping, run `python main.py` from `lesson10`
(macOS/Linux: `python3 main.py`); compare it with the report output in **Run it** below.
For the second sitting, reopen this folder and choose **Terminal > New Terminal**.

### Step 5. Create the environment before installing anything
A **virtual environment** is a folder containing a project-specific Python environment and installed packages.
`venv` is Python's standard-library tool for creating one. In a terminal whose current folder is `lesson10`, run:

**PowerShell, folder: `~/code101/lesson10` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson10"
python -m venv .venv
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
cd ~/code101/lesson10
python3 -m venv .venv
```

Expected result: no printed output on success; a `.venv` folder is created. `-m` runs a module as a command.
If your Linux installation says `ensurepip is not available`, the distribution needs its Python venv component;
follow the [official venv installation notes](https://docs.python.org/3/library/venv.html). Do not use global pip as a workaround.

**Activation** changes a terminal so a short `python` command chooses the environment's Python. We instead call it
by its full path; you do not need activation. A PowerShell **execution policy** controls whether scripts may run;
you do not need to change it for these commands.

VS Code may offer to use `.venv`; click **Yes**. If it automatically activates a terminal, `(.venv)` at the start of
the prompt means that environment is selected. Type `deactivate` to leave it, or close that terminal. If a new terminal
shows `running scripts is disabled on this system`, its activation script was blocked: the full-path commands below
still work. Do not change the machine's policy. Confirm that you are using the isolated interpreter:

`-c` runs the short Python instructions in quotes; the **semicolon** `;` separates two statements.
`sys` supplies information about the running Python. `sys.prefix` is the current Python environment's folder;
`sys.base_prefix` is the base installation's folder. `!=` checks that they differ.

**PowerShell, folder: `~/code101/lesson10`**
```powershell
.\.venv\Scripts\python.exe -c "import sys; print(sys.prefix != sys.base_prefix)"
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
./.venv/bin/python -c "import sys; print(sys.prefix != sys.base_prefix)"
```
Expected output:

```text
True
```

### Step 6. Record a pinned dependency
**pip** is Python's package installer. A **dependency** is another library a project needs; here we install Colorama
only to practise installation and importing a third-party package. The report itself does not need it.
A **version pin** selects one exact release, rather than whichever release is newest when someone follows the lesson.
A **requirements file** lists dependencies for pip to install. Create `requirements.txt` in `lesson10`, not in `helpers`:

**File: `~/code101/lesson10/requirements.txt`**
```text
colorama==0.4.6
```

The one line asks for exactly Colorama 0.4.6. `==` in this file pins a version; it is not Python comparison code.
Save the file, then install it with the environment's interpreter:

**PowerShell, folder: `~/code101/lesson10`**
```powershell
.\.venv\Scripts\python.exe -m pip install --quiet --disable-pip-version-check -r requirements.txt
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
./.venv/bin/python -m pip install --quiet --disable-pip-version-check -r requirements.txt
```
Expected output: none on success (captured). `--quiet` suppresses routine progress; `--disable-pip-version-check` suppresses
pip upgrade notices; `-r` reads the named requirements file. Errors are still shown. This command downloads a public
package from the Python Package Index; it does not upload your project. Do not copy someone else's `.venv` folder.

### Step 7. Check the installed version and import it
Package **metadata** is information about a package, such as its installed version. `importlib.metadata.version` reads it.
Run **both** commands, still in `lesson10`:

**PowerShell, folder: `~/code101/lesson10`**
```powershell
.\.venv\Scripts\python.exe -c "from importlib.metadata import version; print(version('colorama'))"
.\.venv\Scripts\python.exe -c "import colorama; print('Colorama imported.')"
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
./.venv/bin/python -c "from importlib.metadata import version; print(version('colorama'))"
./.venv/bin/python -c "import colorama; print('Colorama imported.')"
```
`import colorama` proves that this interpreter can find the installed package.
The semicolon separates two short Python statements inside the command. Captured output, in command order:

```text
0.4.6
Colorama imported.
```

## Run it
Run the standard-library delivery report from `lesson10` (the package practice does not change its output).

**PowerShell, folder: `~/code101/lesson10` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson10"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
cd ~/code101/lesson10
python3 main.py
```

Expected output:
```text
Delivery: 2026-12-01
Total: 3.75
Boxes for 7 jars, 3 per box: 3
```

You can also run the same report with the virtual environment's interpreter:

**PowerShell, folder: `~/code101/lesson10`**
```powershell
.\.venv\Scripts\python.exe main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson10`**
```bash
./.venv/bin/python main.py
```
The report and its output are identical; no third-party imports occur in `main.py`.

## How it works
1. Python imports its standard-library helpers, then your package and module. Imports make names available for use.
2. The guard calls `main()` only for a direct run.
3. The report uses a fixed date, an integer-cent line total, and an upward-rounded box count.
4. Your package formats cents for display; your module multiplies a price and quantity.
5. The separate venv steps installed a pinned dependency into `.venv`, not into the shared Python installation.

Keep `totals.py`, `helpers` and `main.py` in the same parent folder. Do not name your files `csv.py`, `math.py`,
`datetime.py` or `colorama.py`: a neighbouring file can hide the intended library module. Recreate an environment with
`python -m venv .venv` and the requirements installation command when moving to another machine; do not share `.venv`.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **package**, **dotted import**, **main guard**, **virtual environment**, **venv**, **pip**, **dependency**, **version pin**, **requirements file**, **activation**, **execution policy**, **metadata**, **semicolon**, **sys.prefix**.

## Try it
**Your own conversion module.** Finish the two-file program so 3 minutes displays as 180 seconds.
Keep the conversion function in `conversions.py` and use it from `main.py`. This exercise needs no pip dependency and no
package subfolder: two neighbouring modules are enough. Keep these files together.

Without the pack, in VS Code's Explorer for `~/code101/lesson10`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `10-modules-and-packages/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson10` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson10/exercise`, not
`lesson10/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson10/exercise/conversions.py`**
```python
def minutes_to_seconds(minutes):
    # TODO: return minutes multiplied by 60.
    return minutes
```

**File: `~/code101/lesson10/exercise/main.py`**
```python
# TODO: import minutes_to_seconds from conversions.
# Then replace 0 with minutes_to_seconds(3).
seconds = 0
print(f"Seconds: {seconds}")
```

**PowerShell, folder: `~/code101/lesson10/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson10/exercise"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson10/exercise`**
```bash
cd ~/code101/lesson10/exercise
python3 main.py
```

Expected output:
```text
Seconds: 180
```

<details><summary>Solution</summary>

**File: `~/code101/lesson10/exercise/conversions.py`**
```python
def minutes_to_seconds(minutes):
    return minutes * 60
```

**File: `~/code101/lesson10/exercise/main.py`**
```python
from conversions import minutes_to_seconds


seconds = minutes_to_seconds(3)
print(f"Seconds: {seconds}")
```

The function is defined in one module and called from the other. Import names omit the `.py` filename ending.
</details>

## Check yourself

1. How does a module differ from the regular package shown here?
   <details><summary>Answer</summary>A module is a named unit of code, here one .py file; the package groups modules in a folder marked with __init__.py.</details>

2. Do `csv` and `math` need pip installation?
   <details><summary>Answer</summary>No. They are part of the standard library shipped with Python.</details>

3. Why use the environment's `python -m pip`, not a bare `pip` command?
   <details><summary>Answer</summary>It selects pip belonging to that interpreter and avoids installing into a different Python by accident.</details>

4. What does the main guard prevent?
   <details><summary>Answer</summary>Running the report automatically when another file imports the module.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\main.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson10` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Boxes for 7 jars, 3 per box: 3` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `ModuleNotFoundError: No module named 'total'. Did you mean: 'totals'?` | Imported `total` but the file is `totals.py` | Use `from totals import line_total` beside that file. |
| `ModuleNotFoundError: No module named 'helpers'` | Put the helper files beside main.py instead of in `helpers` | Create `helpers` inside lesson10 and place `__init__.py` and `formatting.py` inside it. |
| `ImportError: cannot import name 'ceill' from 'math' (unknown location). Did you mean: 'ceil'?` | Misspelled the imported name | Use `ceil`, with one final l. |
| `ERROR: Could not find a version that satisfies the requirement colorama==0.4.6 (from versions: none)`<br>`ERROR: No matching distribution found for colorama==0.4.6` | pip could not find the pinned package; no connection or no accessible package index can cause this | Check your internet connection and package-index access, then rerun the Step 6 install command. Do not remove the version pin. |

## Best practice
Use a separate virtual environment for each project, and record dependencies so someone else can recreate it. Use the same interpreter for installing and running.
Source: Python tutorial, Virtual environments and packages https://docs.python.org/3/tutorial/venv.html

## Next lesson
**11. Classes basics:** keep related data and behaviour together in your own kind of object.
