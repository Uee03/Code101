---
track: python
level: 101
phase: 3
phase_name: real-programs
lesson: 11
title: Classes basics
time: "35 min"
prerequisites: [101.3.10]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-3-real-programs/11-classes-basics/
assets: []
---

# 11. Classes basics

## Why it matters
A label on a savings jar belongs to that particular jar, as does the money inside it. A design for making jars is not the same thing as one real jar. Classes and objects make this distinction useful in a program.

## What you will build
Two savings-jar objects, each with its own label and balance. Depositing into one will not change the other.

## Before you start
- Time: 35 minutes, including typing and the exercise.
- Finish lesson 10; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-3-real-programs/11-classes-basics/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson11" -Force | Out-Null
Set-Location "$HOME/code101/lesson11"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson11
cd ~/code101/lesson11
code .
```
Expected result: VS Code opens `lesson11`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson11` unless a subfolder is explicitly named.

### Step 2. Define a class and make two objects
A **class** is a definition for a kind of object. An **object** is a value with its own data and behaviour;
an **instance** is an individual object made from a class. An **attribute** is a named value belonging to an object,
accessed with a dot. A method, introduced in lesson 07, is a function attached to an object.

Create `main.py`. Class names conventionally use capitals to start each word, such as `SavingsJar`.

**File: `~/code101/lesson11/main.py`**
```python
class SavingsJar:
    def __init__(self, label, cents):
        self.label = label
        self.cents = cents

    def deposit(self, cents):
        if cents <= 0:
            print("Deposit must be positive.")
            return
        self.cents = self.cents + cents

    def describe(self):
        return f"{self.label}: {self.cents} cents"


holiday = SavingsJar("Holiday", 500)
books = SavingsJar("Books", 200)
holiday.deposit(150)
print(holiday.describe())
print(books.describe())
```

### Step 3. Follow the first jar being created
`SavingsJar("Holiday", 500)` creates an instance. Python calls `__init__` to initialise it.
The **initializer** is the `__init__` method that sets up a new instance's starting data; keep both pairs of underscores.
`self` is the conventional parameter name for the instance receiving a method call. Python supplies it automatically.

In `__init__(self, label, cents)`, `self.label = label` stores that argument on this jar. `self.cents = cents` stores its
own balance. The second call makes a separate jar with different attributes. The temporary parameter name `cents` and
the stored attribute `self.cents` are separate: the parameter is available during the call, while the attribute
stays on the jar after that call ends.

`holiday.deposit(150)` passes `holiday` as `self` and 150 as `cents`. Write only the amount in the call; do not pass
`holiday` again. The method changes this object's data. A nonpositive amount prints guidance and returns early without
changing the balance. A bare `return` (without a value) ends the call without supplying a calculation result.
This beginner class expects integer-cent arguments; it is not a complete banking model.

## Run it

**PowerShell, folder: `~/code101/lesson11` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson11"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson11`**
```bash
cd ~/code101/lesson11
python3 main.py
```

Expected output:
```text
Holiday: 650 cents
Books: 200 cents
```

## How it works
1. Python reads the class definition, including its three methods.
2. Two class calls create two instances; each initializer sets that instance's label and cents.
3. `holiday.deposit(150)` changes only the holiday jar from 500 to 650 cents.
4. `describe()` returns a string using the receiving object's attributes. The caller prints it.
5. The books jar remains at 200 cents because none of its methods changed its balance.

Use a class when several values and their operations naturally belong together. A simple standalone calculation can
stay a function; you do not need to wrap every piece of code in a class. Keep per-object data on `self`, inside the
initializer, rather than sharing a changing balance on the class itself.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **class**, **object**, **instance**, **attribute**, **initializer**, **self**, **bare return**.

## Try it
**Step counters.** Finish `walk(self, count)` so each call adds `count` to this counter's steps. The starter
creates Ada and Lin, then records 300 and 200 steps for Ada only. Use positive whole counts in this exercise;
input validation is not part of this tiny counter.

Without the pack, in VS Code's Explorer for `~/code101/lesson11`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `11-classes-basics/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson11` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson11/exercise`, not
`lesson11/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson11/exercise/step_counter.py`**
```python
class StepCounter:
    def __init__(self, name):
        self.name = name
        self.steps = 0

    def walk(self, count):
        # TODO: increase this object's steps by count.
        self.steps = self.steps


ada = StepCounter("Ada")
lin = StepCounter("Lin")
ada.walk(300)
ada.walk(200)
print(f"{ada.name}: {ada.steps}")
print(f"{lin.name}: {lin.steps}")
```

**PowerShell, folder: `~/code101/lesson11/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson11/exercise"
python step_counter.py
```

**macOS/Linux terminal, folder: `~/code101/lesson11/exercise`**
```bash
cd ~/code101/lesson11/exercise
python3 step_counter.py
```

Expected output:
```text
Ada: 500
Lin: 0
```

<details><summary>Solution</summary>

**File: `~/code101/lesson11/exercise/step_counter.py`**
```python
class StepCounter:
    def __init__(self, name):
        self.name = name
        self.steps = 0

    def walk(self, count):
        self.steps = self.steps + count


ada = StepCounter("Ada")
lin = StepCounter("Lin")
ada.walk(300)
ada.walk(200)
print(f"{ada.name}: {ada.steps}")
print(f"{lin.name}: {lin.steps}")
```

Both objects start at zero. Calling Ada's method twice changes Ada's attribute, leaving Lin at zero.
</details>

## Check yourself

1. Is `SavingsJar` a class or one particular jar?
   <details><summary>Answer</summary>It is the class. <code>holiday</code> and <code>books</code> refer to instances made from it.</details>

2. What does `self` identify inside `deposit`?
   <details><summary>Answer</summary>The specific object receiving that method call.</details>

3. Why does depositing into Holiday not change Books?
   <details><summary>Answer</summary>Each instance has its own <code>self.cents</code> attribute, set by its initializer.</details>

4. Should a call be `holiday.deposit(holiday, 150)`?
   <details><summary>Answer</summary>No. Python supplies self; call <code>holiday.deposit(150)</code>.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\main.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson11` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Books: 200 cents` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `TypeError: SavingsJar.deposit() takes 1 positional argument but 2 were given` | Left `self` out of the method definition | Restore `def deposit(self, cents):`; Python supplies self automatically. |
| `TypeError: SavingsJar.deposit() takes 2 positional arguments but 3 were given` | Passed the jar twice | Call `holiday.deposit(150)`, not `holiday.deposit(holiday, 150)`. |
| `TypeError: SavingsJar() takes no arguments` | Typed single underscores around init | Use exactly `__init__`, with two underscores on each side. |
| `TypeError: SavingsJar.deposit() missing 1 required positional argument: 'cents'` | Called the method on the class instead of an instance | Create a jar, then call `holiday.deposit(150)`. |
| `AttributeError: 'SavingsJar' object has no attribute 'balance'` | Used an attribute name this class does not define | Use `holiday.cents`, or call `holiday.describe()`. |

## Best practice
Put data that belongs to one instance in that instance, usually through `self` in `__init__`. Each jar needs its own balance; putting it on `self` keeps one jar's updates separate from the other's.
Source: Python tutorial, Class and instance variables https://docs.python.org/3/tutorial/classes.html#class-and-instance-variables

## Next lesson
**12. Project: expense tracker:** combine input, loops, functions, modules and CSV storage into one usable console app.
