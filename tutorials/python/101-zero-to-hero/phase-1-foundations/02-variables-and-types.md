---
track: python
level: 101
phase: 1
phase_name: foundations
lesson: 02
title: Variables and types
time: "35 min"
prerequisites: [101.1.01]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-1-foundations/02-variables-and-types/
assets: []
---

# 02. Variables and types

## Why it matters
Imagine a kitchen shelf with **labelled jars**: "sugar", "flour", "salt". You do not need to remember what is
inside each jar; you read the label. A **variable** is a labelled jar inside the computer's memory. It lets a
program remember a value and use it later by name. Each jar holds a particular **type** of thing (liquid, powder,
whole spices), and Python needs to know the type so it knows what you can do with it.

## What you will build
A program that stores facts about a person, prints them, shows the type of each fact, and updates one of them.

## Before you start
- Time: 35 minutes, including typing and the exercise.
- Lesson 01 done (Python installed, terminal and editor working).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-1-foundations/02-variables-and-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Make a folder for this lesson
In your terminal:

```bash
cd ~/code101
mkdir lesson02
cd lesson02
code .
```

Expected result: VS Code opens an empty folder named `lesson02`. In that window choose **Terminal > New Terminal**.
The terminal folder must end in `lesson02`; recover with `cd ~/code101/lesson02`. Save each file before running it.
If asked about folder trust, choose **Yes, I trust the authors** for your own folder.

### Step 2. Create the file
In VS Code create a new file named `variables.py`.

### Step 3. Create variables
Type these lines. The `=` sign here does not mean "equals"; it means "**put the value on the right into the jar
named on the left**".

**File: `variables.py`**
```python
# A variable is a labelled jar that holds a value.
name = "Ada"
age = 36
height_m = 1.65
is_student = False
```

Four jars, four types:

| Variable | Value | Type name in Python | In plain words |
|---|---|---|---|
| `name` | `"Ada"` | `str` | text (a **string**) |
| `age` | `36` | `int` | a whole number (an **integer**) |
| `height_m` | `1.65` | `float` | a number with a decimal point |
| `is_student` | `False` | `bool` | a yes/no value, written `True` or `False` (a **boolean**) |

Rules for variable names: use lower-case letters, digits and underscores; no spaces; do not start with a digit.
`height_m` is good; `my height` and `2fast` are not.

### Step 4. Print the values
Add these lines **under** the ones you already have. The file now looks like this:

**File: `variables.py`**
```python
# A variable is a labelled jar that holds a value.
name = "Ada"
age = 36
height_m = 1.65
is_student = False

print("Name:", name)
print("Age:", age)
print("Height in metres:", height_m)
print("Is a student:", is_student)
```

Run it:
```bash
python variables.py
```

Expected output:
```text
Name: Ada
Age: 36
Height in metres: 1.65
Is a student: False
```

`print` can take several things separated by commas and shows them with a space between.
Notice `"Name:"` is text you wrote, and `name` (no quotes) is the jar. Quotes mean "this exact text"; no quotes means
"look inside the jar".

### Step 5. Ask Python for the type
Add this block at the bottom of the file (after a blank line).

**File: `variables.py`**
```python
# type() tells us what kind of value is inside the jar.
print(type(name))
print(type(age))
print(type(height_m))
print(type(is_student))
```

Run `python variables.py` again. After the four lines from Step 4 you now also see:
```text
<class 'str'>
<class 'int'>
<class 'float'>
<class 'bool'>
```
`class` is Python's word for "kind of thing"; you will meet it properly in lesson 11.

### Step 6. Put variables inside text with an f-string
Add this block at the bottom.

**File: `variables.py`**
```python
# An f-string puts variables inside text.
print(f"{name} is {age} years old and {height_m} m tall.")
```

An **f-string** is text with the letter `f` before the opening quote. Anything inside `{ }` is replaced by what is
in that jar. The symbols `{ }` are **curly brackets** (also called braces); use your keyboard layout's brace keys
(often Shift with the square-bracket keys, or AltGr on some layouts).
Save, then run `python variables.py` from `lesson02` (macOS/Linux: `python3 variables.py`); the new last line is:
```text
Ada is 36 years old and 1.65 m tall.
```

### Step 7. Change a variable
Add the last block at the bottom:

**File: `variables.py`**
```python
# A variable can be changed after it is created.
age = age + 1
print(f"Next year {name} will be {age}.")
```

Python first works out the right side (`age + 1` is `37`), then puts the result back into the `age` jar.
Save and run the same command from `lesson02` again. The new last line is:
```text
Next year Ada will be 37.
```

## Run it
The complete file is now:

**File: `variables.py`**
```python
# A variable is a labelled jar that holds a value.
name = "Ada"
age = 36
height_m = 1.65
is_student = False

print("Name:", name)
print("Age:", age)
print("Height in metres:", height_m)
print("Is a student:", is_student)

# type() tells us what kind of value is inside the jar.
print(type(name))
print(type(age))
print(type(height_m))
print(type(is_student))

# An f-string puts variables inside text.
print(f"{name} is {age} years old and {height_m} m tall.")

# A variable can be changed after it is created.
age = age + 1
print(f"Next year {name} will be {age}.")
```

Run it in the `lesson02` folder:
```bash
python variables.py
```

Expected output:
```text
Name: Ada
Age: 36
Height in metres: 1.65
Is a student: False
<class 'str'>
<class 'int'>
<class 'float'>
<class 'bool'>
Ada is 36 years old and 1.65 m tall.
Next year Ada will be 37.
```

## How it works
Python reads top to bottom. When it sees `name = "Ada"` it creates a jar called `name` and stores the text `Ada`.
Later lines **use** the jar by writing its name. A line can only use a jar that was created **above** it; that is why the
order of lines matters. `age = age + 1` is allowed because the right side is calculated first.

Terms from this lesson (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **variable**, **type**, **string**, **integer**, **float**,
**boolean**, **f-string**.

## Try it
Make a **business card**. Create `business_card.py` in your `lesson02` folder (or copy `exercise/starter/business_card.py`
from the unzipped pack into it) with this text:

**File: `business_card.py` (starter)**
```python
# Business card: store facts in variables, then print them.
# Replace each TODO. Do not change the lines that already work.

full_name = "TODO"        # TODO 1: put your name in the quotes
job_title = "TODO"        # TODO 2: put a job title in the quotes
years_experience = 0      # TODO 3: put a whole number

print(f"{full_name}, {job_title}")
print(f"Experience: {years_experience} years")

# TODO 4: make years_experience one bigger, then print the new value
#         using an f-string, for example: Next year: 6 years
```

Save, then from `lesson02` run `python business_card.py` (macOS/Linux: `python3 business_card.py`).
Expected shape of the output (your values will differ):
```text
Grace Hopper, Computer Scientist
Experience: 5 years
Next year: 6 years
```

<details><summary>Solution</summary>

**File: `business_card.py`**
```python
full_name = "Grace Hopper"
job_title = "Computer Scientist"
years_experience = 5

print(f"{full_name}, {job_title}")
print(f"Experience: {years_experience} years")

years_experience = years_experience + 1
print(f"Next year: {years_experience} years")
```
</details>

## Check yourself
1. What type is `"36"` (with quote marks): `int` or `str`?
   <details><summary>Answer</summary><code>str</code>. Quote marks make it text, even though it looks like a number.</details>
2. After `x = 5` and `x = x + 2`, what is in `x`?
   <details><summary>Answer</summary>7.</details>
3. Why does `print(nme)` fail when the jar is called `name`?
   <details><summary>Answer</summary>Python looks for a jar called <code>nme</code>, finds none, and reports a NameError.</details>
4. Which is a valid variable name: `first name`, `2nd_place`, `first_name`?
   <details><summary>Answer</summary><code>first_name</code>.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\variables.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson02` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Next year Ada will be 37.` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `NameError: name 'nme' is not defined. Did you mean: 'name'?` | Misspelled `name` as `nme` | Use the exact name you defined above the print. |
| `TypeError: can only concatenate str (not "int") to str` | Added text and a number; concatenate means joining text with `+` | Keep both values the same type; lesson 03 teaches `int()` for converting digit text. |
| `{name} is {age} years old and {height_m} m tall.` | Forgot `f` before the string | Restore the `f` so curly-bracket expressions are replaced with values. |

## Best practice
Choose descriptive names: `height_m` tells the reader the unit, `h` does not. Use lower_case_with_underscores for variables.
Source: PEP 8, "Naming Conventions" https://peps.python.org/pep-0008/#naming-conventions

## Next lesson
**03. Input and math:** let the user type values in, and calculate with them.
