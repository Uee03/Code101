---
track: python
level: 101
phase: 1
phase_name: foundations
lesson: 04
title: Making decisions
time: "40 min"
prerequisites: [101.1.03]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-1-foundations/04-making-decisions/
assets: []
---

# 04. Making decisions

## Why it matters
A road sign says: "If the light is red, stop. Otherwise, if it is amber, slow down. Otherwise, go." Every useful
program makes choices like this: show a discount only if the customer qualifies, block a login if the password is wrong.
Python makes choices with `if`, `elif` (short for "else if") and `else` ("otherwise").

## What you will build
A **ticket machine**: you type your age and it tells you which ticket price applies.

## Before you start
- Time: 40 minutes, including typing and the exercise.
- Lessons 01 to 03 done.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-1-foundations/04-making-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Make a folder
```bash
cd ~/code101
mkdir lesson04
cd lesson04
code .
```
Expected result: VS Code opens an empty folder named `lesson04`. In that window choose **Terminal > New Terminal**.
The terminal folder must end in `lesson04`; recover with `cd ~/code101/lesson04`. Save each file before running it.
If asked about folder trust, choose **Yes, I trust the authors** for your own folder.

### Step 2. Learn to ask yes/no questions
A **comparison** asks a question and the answer is `True` or `False` (the **boolean** type from lesson 02).
Create `comparisons.py`. Single quotes can surround text too: the last line uses them so its text can contain double quotes.

**File: `comparisons.py`**
```python
# Comparisons ask a yes/no question. The answer is True or False.
print("5 > 3 :", 5 > 3)
print("5 < 3 :", 5 < 3)
print("5 == 5 :", 5 == 5)
print("5 != 5 :", 5 != 5)
print("5 >= 5 :", 5 >= 5)
print('"a" == "A" :', "a" == "A")
```

| Symbol | Question |
|---|---|
| `>` | is the left bigger? |
| `<` | is the left smaller? |
| `==` | are they equal? (two equals signs; one `=` stores a value) |
| `!=` | are they different? |
| `>=` / `<=` | bigger or equal / smaller or equal |

### Step 3. Combine questions with and, or, not
Add this at the bottom of `comparisons.py` (leave a blank line first). The finished file:

**File: `comparisons.py`**
```python
# Comparisons ask a yes/no question. The answer is True or False.
print("5 > 3 :", 5 > 3)
print("5 < 3 :", 5 < 3)
print("5 == 5 :", 5 == 5)
print("5 != 5 :", 5 != 5)
print("5 >= 5 :", 5 >= 5)
print('"a" == "A" :', "a" == "A")

# and, or, not combine yes/no answers.
age = 20
has_ticket = True
print("adult with ticket:", age >= 18 and has_ticket)
print("child or has ticket:", age < 18 or has_ticket)
print("no ticket:", not has_ticket)
```

Run it:
```bash
python comparisons.py
```

Expected output:
```text
5 > 3 : True
5 < 3 : False
5 == 5 : True
5 != 5 : False
5 >= 5 : True
"a" == "A" : False
adult with ticket: True
child or has ticket: True
no ticket: False
```

- `and`: true only if **both** sides are true.
- `or`: true if **at least one** side is true.
- `not`: flips true to false and false to true.
- Upper and lower case letters are different, so `"a" == "A"` is `False`.

### Step 4. Make your first decision
Create `ticket_machine.py`. Start with the question and the first rule only:

**File: `ticket_machine.py`**
```python
# Ticket machine: the price depends on the visitor's age.
age = int(input("How old are you? "))

if age < 5:
    print("Ticket: free")
```

Two things to notice:
- The line with `if` ends with a **colon** `:`.
- The next line is **indented** (pushed in by 4 spaces). Indented lines belong to the `if` and run only when the question is
  true. In VS Code, pressing the **Tab** key makes the indent.

### Step 5. Add more rules with elif and else
Replace the file's contents with the complete program. Python checks the questions from the top and uses the **first** one
that is true; `else` catches everything left over.

**File: `ticket_machine.py`**
```python
# Ticket machine: the price depends on the visitor's age.
age = int(input("How old are you? "))

if age < 0:
    print("Age cannot be negative.")
elif age < 5:
    print("Ticket: free")
elif age < 18:
    print("Ticket: child price, 5.00")
elif age < 65:
    print("Ticket: adult price, 10.00")
else:
    print("Ticket: senior price, 7.00")
```

Because the negative check is first, an age of `-1` is caught before the others.

## Run it
```bash
python ticket_machine.py
```
Try the ages below, running the program once for each. Press the **Up arrow** in the terminal to recall the last
command, then Enter to run it again. What you see:

| You type | Output |
|---|---|
| `3` | `Ticket: free` |
| `10` | `Ticket: child price, 5.00` |
| `30` | `Ticket: adult price, 10.00` |
| `70` | `Ticket: senior price, 7.00` |
| `-1` | `Age cannot be negative.` |

Example of one run:
```text
How old are you? 30
Ticket: adult price, 10.00
```

## How it works
Python runs the questions top to bottom. For age `10`: `10 < 0` is false, `10 < 5` is false, `10 < 18` is true, so it prints
the child price and **skips the rest**. That is why the order matters: for `3`, both `age < 5` and `age < 18` are true, but the
first true question wins.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **comparison**, **condition**, **boolean expression**, **indentation**, **block**, **elif**.

- A **comparison** asks a yes/no question about two values, like `age < 5`.
- A **boolean expression** is anything that works out to `True` or `False`: a comparison, or comparisons joined by `and`, `or`, `not`.
- A **condition** is the boolean expression after `if` or `elif`; it decides whether the lines under it run.
- **Indentation** is the spaces at the start of a line.
- A **block** is the group of indented lines that belong to one `if`, `elif` or `else`.

## Try it
**Grade checker.** Read a score from 0 to 100 and print `Fail` (below 50), `Pass` (50 to 74), `Merit` (75 or more), or
`Invalid score` (below 0 or above 100). Create `grade_checker.py` in your `lesson04` folder
(or copy `exercise/starter/grade_checker.py` from the unzipped pack into it) with this text:

**File: `grade_checker.py` (starter)**
```python
# Grade checker: turn a score from 0 to 100 into a result.
# Rules: below 50 is "Fail", 50 to 74 is "Pass", 75 or more is "Merit",
# and anything below 0 or above 100 is "Invalid score".
# Replace the TODO with if / elif / else blocks.

score = int(input("Score (0-100): "))

# TODO: write the if / elif / else here. Check "Invalid score" first.
print("TODO")
```

Save, then from `lesson04` run `python grade_checker.py` (macOS/Linux: `python3 grade_checker.py`).
Test with `30` (Fail), `60` (Pass), `90` (Merit) and `101` (Invalid score).

<details><summary>Solution</summary>

**File: `grade_checker.py`**
```python
score = int(input("Score (0-100): "))

if score < 0 or score > 100:
    print("Invalid score")
elif score < 50:
    print("Fail")
elif score < 75:
    print("Pass")
else:
    print("Merit")
```
</details>

## Check yourself
1. What is the difference between `=` and `==`?
   <details><summary>Answer</summary><code>=</code> stores a value in a variable; <code>==</code> asks whether two values are equal.</details>
2. What does `not (5 > 3)` give?
   <details><summary>Answer</summary><code>False</code>.</details>
3. In the ticket machine, why does age `3` not print the child price too?
   <details><summary>Answer</summary>Python uses only the first true branch of an <code>if / elif</code> chain.</details>
4. Why must the lines after `if age < 5:` be indented?
   <details><summary>Answer</summary>Indentation tells Python which lines belong to the <code>if</code>.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\ticket_machine.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson04` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `How old are you? Ticket: adult price, 10.00` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `IndentationError: expected an indented block after 'if' statement on line 4` | Removed indentation below the first `if` | Indent the print by four spaces. The line number in your own file may differ. |
| `ValueError: invalid literal for int() with base 10: 'ten'` | Typed a word | Type a whole number such as `10`. The grade checker also needs a whole score, not `74.5`. |
| `ValueError: invalid literal for int() with base 10: '10.5'` | Typed a decimal where a whole age is needed | Type a whole number such as `10`. The grade checker also needs a whole score, not `74.5`. |
| `ValueError: invalid literal for int() with base 10: ''` | Pressed Enter without an age | Type a whole number such as `10`. The grade checker also needs a whole score, not `74.5`. |
| `SyntaxError: expected ':'` | Omitted the colon | End the `if` line with `:`. |
| `SyntaxError: invalid syntax. Maybe you meant '==' or ':=' instead of '='?` | Used assignment `=` in the condition | Use comparison `==` instead. |
| `SyntaxError: invalid syntax` | Indented `else:` inside the preceding block | Align `else:` with `if` and `elif`. |
| `IndentationError: unindent does not match any outer indentation level` | Dedented `else:` to a column that matches no outer block | Align it with `if`; use four spaces for each block level. |

## Best practice
Use 4 spaces per indentation level (the Tab key in VS Code does this) and never mix tabs and spaces in one file.
Source: PEP 8, "Indentation" https://peps.python.org/pep-0008/#indentation

## Next lesson
**05. Loops (Phase 2):** repeat work without copying and pasting. You have finished Phase 1.
