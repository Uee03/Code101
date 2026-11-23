---
track: python
level: 101
phase: 1
phase_name: foundations
lesson: 01
title: Hello, Python
time: "60 min (two sittings)"
prerequisites: [none]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-1-foundations/01-hello-python/
assets: []
---

# 01. Hello, Python

## Why it matters
Think of a **recipe**. A recipe is a list of instructions, written so that anyone who follows them
exactly gets the same dish. A **program** is a recipe for a computer. The computer is a very literal
cook: it does exactly what you wrote, in the order you wrote it, and never guesses what you meant.
In this lesson you install the tools, write your first recipe, and watch the computer follow it.

## What you will build
A two-line program that makes the computer write two sentences on the screen.

## Before you start
- A Windows, macOS or Linux computer where you may install software.
- Time: 60 minutes in two sittings; break before Step 7. Setting things up (Steps 1 to 6) is the hard part and you only do it once; writing your first
  program (Steps 7 and 8) is the easy part. No experience needed.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-1-foundations/01-hello-python/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Open a terminal
A **terminal** is a window where you give the computer written instructions (**commands**) instead of
clicking. You type a command and press **Enter**.

- **Windows:** press the Windows key, type `PowerShell`, press Enter.
- **macOS:** press Cmd + Space, type `Terminal`, press Enter.
- **Linux:** press Ctrl + Alt + T.

Expected result: a window with a blinking cursor after a line that ends in `>` (Windows) or `$` (macOS, Linux).
The text before that symbol tells you which folder the terminal is in. You can close and reopen terminals as needed during the course.

### Step 2. Install Python
Python is the language we will use. Install it **once**.

**Windows**
Python for Windows is installed with the **Python install manager** (this is how python.org now ships it).
1. Open https://www.python.org/downloads/ and click the download button for Windows.
2. Double-click the downloaded file and click **Install**.
3. Close your terminal and open a **new** one (Step 1), so it knows about the new install.

**macOS**
1. Open https://www.python.org/downloads/ and download the macOS installer.
2. Open the downloaded file and click **Continue** until it finishes.

**Linux (Debian or Ubuntu)**
In the terminal from Step 1, `sudo` asks to run with administrator permission; `apt` is the system software installer.
`update` refreshes its software list; `python3-venv` adds support for isolated project environments (lesson 10).
```bash
sudo apt update
sudo apt install python3 python3-venv
```
Older Linux releases install an older Python. Step 3 shows how to check; if your version is below 3.12, follow
https://docs.python.org/3/using/unix.html to get a newer one.

Expected result: Python is installed. Nothing opens on your screen; that is normal.

If the installer screen differs, use the [official installation guide](https://docs.python.org/3/using/windows.html)
before continuing; do not guess at unfamiliar options.

### Step 3. Check that Python works
Type the command below and press Enter. (Windows: `python`. macOS and Linux: `python3`. From now on
this course writes `python`; macOS and Linux learners should type `python3` instead.)

```bash
python --version
```
The `--version` option asks Python to print its version and stop. If Windows opens the Microsoft Store instead,
install the manager from Step 2. In Windows Settings choose **Apps > Advanced app settings > App execution aliases**
and turn off the `python.exe` entries labelled **App Installer**, then open a new terminal.

On Windows, the first time you use `python` it may ask whether to install the latest Python. That question means "download
the language now". Type `Y` (yes, install) and press Enter, wait for it to finish, then run the command again.

Expected output (your numbers may be higher; they must be 3.12 or newer):
```text
Python 3.15.2
```

If `python` is not recognised, install the manager from Step 2 and open a **new** terminal before trying again.
The manager also supplies the `py` command, which selects an installed Python; `py --version` is an alternative check.
If neither works, use the [official troubleshooting guide](https://docs.python.org/3/using/windows.html#troubleshooting).

### Step 4. Install a code editor
A **code editor** is a notepad made for code. We use Visual Studio Code (free).

1. Open https://code.visualstudio.com/ and download it for your computer.
2. Install it with the default options.
3. Open VS Code. On the left, click the square **Extensions** icon, search for `Python`, and click **Install**
   on the one published by **Microsoft**.
4. Close your terminal and open a **new** one (Step 1). A terminal opened before VS Code was installed does not know the
   `code` command used in Step 6.

Expected result: VS Code is open and the Python extension is listed as installed.

### Step 5. Make a folder for the course
A **folder** (also called a directory) holds files. In your terminal run these commands, one at a time,
pressing Enter after each:

```bash
cd ~
mkdir code101
cd code101
mkdir lesson01
cd lesson01
```

What the commands mean: `cd` = go into a folder, `mkdir` = make a new folder, `~` = your personal home folder
(on Windows PowerShell `~` works too).

Expected result: on macOS and Linux, no output. On Windows, each `mkdir` prints a small table starting with
`Directory:`; that is normal. Your terminal now sits inside `code101/lesson01`: the text before the `>` or `$`
ends with `lesson01`. If you ever lose track, type `cd ~/code101/lesson01` to come back.

### Step 6. Open the folder in VS Code
Still in the terminal, run:

```bash
code .
```

The dot means "this folder". VS Code opens showing an empty folder called `lesson01`. The first time, it asks
"Do you trust the authors of the files in this folder?". Click **Yes, I trust the authors**; the folder is yours.
If you see `'code' is not recognized` (or `command not found: code`), open the folder from VS Code instead:
choose **File, Open Folder**, and pick `code101/lesson01` inside your user folder.
In the new VS Code window choose **Terminal > New Terminal**; run the remaining commands there.
Its current folder should end in `lesson01`; recover with `cd ~/code101/lesson01` if needed.

**Break point:** setup is complete. For your second sitting, reopen VS Code and this folder, then choose
**Terminal > New Terminal**. If needed, run `cd ~/code101/lesson01`.

### Step 7. Create your first file
On Windows, if you create files outside VS Code, enable **File Explorer > View > Show > File name extensions**
so you can spot an accidental `hello.py.txt` name.
1. In VS Code, hover over the file list on the left and click the **New File** icon.
2. Name the file `hello.py` and press Enter. The `.py` ending tells the computer this is a Python file.

### Step 8. Type the program
Click in the empty file and type **exactly** the two lines below. Capital letters, round brackets
(**parentheses**) `( )` and straight quote marks `"` all matter. VS Code may add the closing quote and
parenthesis automatically; move past those characters with the Right arrow rather than typing them twice.

**File: `hello.py`**
```python
print("Hello, world!")
print("My name is Python, and I am your first program.")
```

Save the file: press **Ctrl + S** (Windows, Linux) or **Cmd + S** (macOS). A dot on the file's tab at the top means
"not saved yet"; the dot disappears when the file is saved. Python only sees what is saved.

## Run it
In the terminal (still inside `lesson01`), run:

```bash
python hello.py
```

Expected output:
```text
Hello, world!
My name is Python, and I am your first program.
```

Congratulations: you just wrote and ran a program.

## How it works
Python reads the file from the top, one line at a time (this reader is called the **interpreter**).

- `print` is a **function**: a named helper that does one job. Here the job is "show this on the screen".
- The brackets `( )` hold what you give the helper.
- `"Hello, world!"` is a **string**: text between quote marks. The quote marks are not shown on screen; they only tell
  Python "this is text, not an instruction".
- Each line is one **statement**: one instruction. Python does line 1, then line 2.
- `.py` files with instructions are called **scripts**. Running a script means asking Python to follow it.

## Try it
Make a **recipe card**. Create a file called `recipe_card.py` in the same `lesson01` folder (the starter text is below; you can
also copy `exercise/starter/recipe_card.py` from the unzipped pack into `lesson01`). Python must run it from the folder it is in.
Lines starting with `#` are **comments**: notes for humans that Python ignores.
`TODO` means "a reminder to yourself: replace this". Finish the card so it has the output shown below.

**File: `recipe_card.py` (starter)**
```python
# Recipe card: print a title, a blank line, then the ingredients.
# Replace each TODO with a print(...) line.

# TODO 1: print the recipe name, for example: Recipe: Tea

# TODO 2: print an empty line (hint: print() with nothing inside)

# TODO 3: print "Ingredients:"

# TODO 4: print two ingredients, one per line, starting with a dash
```

Run it with `python recipe_card.py`. When you are done it should print:
```text
Recipe: Tea

Ingredients:
- 1 tea bag
- 1 cup of hot water
```

<details><summary>Solution</summary>

**File: `recipe_card.py`**
```python
print("Recipe: Tea")
print()
print("Ingredients:")
print("- 1 tea bag")
print("- 1 cup of hot water")
```

`print()` with nothing inside prints an empty line. Your own recipe can be different; only the shape must match.
</details>

## Check yourself
1. What is a program, in one sentence?
   <details><summary>Answer</summary>A list of instructions a computer follows exactly, in order.</details>
2. What does `print("Hi")` show on the screen: `print("Hi")`, `"Hi"` or `Hi`?
   <details><summary>Answer</summary><code>Hi</code>. The quote marks only mark the text.</details>
3. What is the difference between a terminal and a code editor?
   <details><summary>Answer</summary>You type commands in a terminal; you write and save files in a code editor.</details>
4. What does a `#` at the start of a line do?
   <details><summary>Answer</summary>Makes a comment; Python ignores the line.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\hello.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson01` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `My name is Python, and I am your first program.` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `SyntaxError: invalid syntax` | Typed `python hello.py` while the line began with `>>>` (Python's interactive prompt) | Type `exit()` and press Enter to leave Python, then run the command in the terminal. |
| `SyntaxError: unterminated string literal (detected at line 1)` | Missing closing quote in the first `print` | Restore the straight closing quote before `)`. |
| `NameError: name 'Print' is not defined. Did you mean: 'print'?` | Used capital `P` | Use lower-case `print`; Python distinguishes capital letters. |

## Best practice
Keep comments true. A comment that disagrees with the code is worse than no comment, so change the comment whenever
you change the line it describes.
Source: PEP 8, "Comments" https://peps.python.org/pep-0008/#comments

## Next lesson
**02. Variables and types:** give values names so your programs can remember things.
