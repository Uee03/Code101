---
track: python
level: 101
phase: 2
phase_name: building-blocks
lesson: 05
title: Loops
time: "40 min"
prerequisites: [101.1.04]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-2-building-blocks/05-loops/
assets: []
---

# 05. Loops

## Why it matters
A washing machine repeats wash-and-rinse steps without a person writing each instruction again. A loop lets a program repeat a block in the same way. You decide what repeats and when it stops.

## What you will build
A three-line times table and a small guessing game. The game keeps asking until you guess the fixed secret or choose to quit.

## Before you start
- Time: 40 minutes, including typing and the exercise.
- Finish lesson 04; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-2-building-blocks/05-loops/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson05" -Force | Out-Null
Set-Location "$HOME/code101/lesson05"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson05
cd ~/code101/lesson05
code .
```
Expected result: VS Code opens `lesson05`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson05` unless a subfolder is explicitly named.

### Step 2. Repeat a fixed number of times
If a program stops with an unhandled error, a **traceback** is the trail of file locations printed above the last error line.
A **loop** repeats a block; one trip through that block is an **iteration**. A **sequence** is a group of things in order, such as the numbers from `range`. A `for` loop visits each item in a sequence.
`range(1, 4)` supplies the whole numbers 1, 2 and 3: its start is included and its stop is excluded.
Create `times_table.py`. The loop's colon and four-space indent work just like the blocks in lesson 04.

**File: `~/code101/lesson05/times_table.py`**
```python
number = int(input("Times table number: "))

for multiplier in range(1, 4):
    product = number * multiplier
    print(f"{number} x {multiplier} = {product}")
```

The loop stores the current number in `multiplier`. Multiplication happens again for each new multiplier.
`range(3)` would instead supply 0, 1, 2. Use an integer in `range`, not the text returned directly by `input`.
For this first program, enter digits such as `3`; lesson 09 will handle bad numeric input.

### Step 3. Repeat until something happens
A `while` loop repeats while its condition is true. `while True` deliberately keeps going until a `break` instruction
ends the nearest loop. `continue` skips the rest of the current iteration and starts the next one.
Create `guessing_game.py`:

**File: `~/code101/lesson05/guessing_game.py`**
```python
secret = "7"

while True:
    guess = input("Guess 1-10 (q to quit): ")
    if guess == "q":
        print("Goodbye!")
        break
    if guess == "":
        print("Type a guess first.")
        continue
    if guess == secret:
        print("Correct!")
        break
    print("Not yet. Try again.")
```

Keep the three `if` statements' indentation exactly as shown. Here guesses stay as strings: `"7"` matches `"7"`.
The secret is fixed, not random, so you can follow every path. An empty answer is the empty string `""`.

## Run it
The typed answers are not shown below, so a prompt and the next output share a line.
In your terminal, each answer you type appears after its prompt, followed by a new line.

First run the times table. At its prompt, type `3` and press Enter.

**PowerShell, folder: `~/code101/lesson05` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson05"
python times_table.py
```

**macOS/Linux terminal, folder: `~/code101/lesson05`**
```bash
cd ~/code101/lesson05
python3 times_table.py
```

Expected output:
```text
Times table number: 3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
```

Now run the game. Press Enter without typing anything; then type `2` and Enter; then `7` and Enter.

**PowerShell, folder: `~/code101/lesson05` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson05"
python guessing_game.py
```

**macOS/Linux terminal, folder: `~/code101/lesson05`**
```bash
cd ~/code101/lesson05
python3 guessing_game.py
```

Expected output:
```text
Guess 1-10 (q to quit): Type a guess first.
Guess 1-10 (q to quit): Not yet. Try again.
Guess 1-10 (q to quit): Correct!
```

To stop a loop you accidentally made endless, press **Ctrl+C** in the terminal (also on macOS).
An **infinite loop** has no reachable stopping point. This game does have two: a correct guess or `q`.

## How it works
1. The times table converts its input to an integer, then visits the three values from `range`.
2. Each visit calculates and prints one product. After the last value, the `for` loop finishes.
3. The game asks for a guess at the start of **every** `while` iteration, so a wrong answer can change.
4. A `q` answer ends the loop with `break`. A blank answer reaches `continue`, skipping the later checks.
5. A correct answer also breaks; any other nonblank answer prints a retry message and loops back.

Both `break` and `continue` act on the nearest surrounding loop, not on the whole program.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **loop**, **iteration**, **sequence**, **for loop**, **while loop**, **range**, **break**, **continue**, **infinite loop**, **traceback**.

## Try it
**Countdown.** Print 3, 2, 1 on separate lines, then `Go!` once. Finish the starter using a loop that stops when
the count reaches zero.

Without the pack, in VS Code's Explorer for `~/code101/lesson05`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `05-loops/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson05` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson05/exercise`, not
`lesson05/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson05/exercise/countdown.py`**
```python
remaining = 3

# TODO: replace this print with a while loop that prints 3, 2, 1.
# Subtract 1 from remaining inside the loop.
print("TODO")
print("Go!")
```

Save your answer, then run it from the exercise folder:

**PowerShell, folder: `~/code101/lesson05/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson05/exercise"
python countdown.py
```

**macOS/Linux terminal, folder: `~/code101/lesson05/exercise`**
```bash
cd ~/code101/lesson05/exercise
python3 countdown.py
```

Expected output:
```text
3
2
1
Go!
```

<details><summary>Solution</summary>

**File: `~/code101/lesson05/exercise/countdown.py`**
```python
remaining = 3

while remaining > 0:
    print(remaining)
    remaining = remaining - 1

print("Go!")
```

Subtracting 1 moves the condition toward false. Indenting `Go!` would print it on every iteration.
</details>

## Check yourself

1. Which values does `range(1, 4)` provide?
   <details><summary>Answer</summary>1, 2 and 3. The stop value 4 is not included.</details>

2. What is the difference between `break` and `continue`?
   <details><summary>Answer</summary><code>break</code> ends the nearest loop; <code>continue</code> starts its next iteration.</details>

3. Why must the countdown change `remaining` inside its loop?
   <details><summary>Answer</summary>Otherwise it stays 3, the condition stays true and the loop never finishes.</details>

4. Why does the guessing game not call `int()`?
   <details><summary>Answer</summary>It only compares typed text with a fixed text secret; it does no arithmetic with guesses.</details>

## Common mistakes
Start with the last error line; the lines above it locate the file and problem.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\times_table.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson05` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `3 x 3 = 9` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `SyntaxError: expected ':'` | Forgot the `for` colon | Restore `:` at the end of the loop line. |
| `IndentationError: expected an indented block after 'for' statement on line 3` | Did not indent the loop block | Indent both body lines by four spaces. |
| `ValueError: invalid literal for int() with base 10: '$3'` | Typed `$3` instead of digits for the table number | Type `3`, without `$`. Words such as `abc` fail too; lesson 09 teaches how to ask again. |
| `TypeError: 'str' object cannot be interpreted as an integer` | Passed a string to `range` | Keep range values as integers; convert numeric input with `int` first. |

## Best practice
Make the stopping condition easy to find. Use `for` with `range` when you know the repeat count, and use an explicit condition or reachable `break` for an open-ended conversation.
Source: Python tutorial, Control flow https://docs.python.org/3/tutorial/controlflow.html#for-statements

## Next lesson
**06. Functions:** give a repeated calculation a name and reuse it with different inputs.
