---
track: python
level: 101
phase: 2
phase_name: building-blocks
lesson: 06
title: Functions
time: "30 min"
prerequisites: [101.2.05]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-2-building-blocks/06-functions/
assets: []
---

# 06. Functions

## Why it matters
A recipe card gives a name to a set of cooking steps. Instead of rewriting the recipe for every meal, you follow the same card with different quantities. A function packages a job in the same way.

## What you will build
An order calculator with one reusable function for multiplying a price by a quantity.

## Before you start
- Time: 30 minutes, including typing and the exercise.
- Finish lesson 05; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-2-building-blocks/06-functions/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson06" -Force | Out-Null
Set-Location "$HOME/code101/lesson06"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson06
cd ~/code101/lesson06
code .
```
Expected result: VS Code opens `lesson06`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson06` unless a subfolder is explicitly named.

### Step 2. Define a named calculation
`def` defines a function. A **parameter** is a named input in the definition, such as `price` or `quantity`.
An **argument** is the actual value supplied when you use it, such as `2.5`. A **call** runs a function by writing its
name followed by parentheses. A function's **body** is the indented lines under `def`.
A **positional argument** is matched to a parameter by its place in the call. Create `main.py` with the whole program:

**File: `~/code101/lesson06/main.py`**
```python
def line_total(price, quantity):
    subtotal = price * quantity
    return subtotal


bread_total = line_total(2.5, 2)
fruit_total = line_total(1.2, 3)
order_total = bread_total + fruit_total

print(f"Bread: {bread_total:.2f}")
print(f"Fruit: {fruit_total:.2f}")
print(f"Order: {order_total:.2f}")
```

### Step 3. Follow one call before running
Read `line_total(2.5, 2)` as "run this recipe using a price of 2.5 and a quantity of 2".
The first argument becomes `price`; the second becomes `quantity`. `subtotal` becomes 5.0.
The **caller** is the line of code that used the function. `return subtotal` sends the value back to that line,
which stores it in `bread_total`.

A **return value** is the result sent back by a function. `return` also ends that call immediately.
`print` displays something; it is not a substitute for returning a result you want to calculate with.
Save `main.py` before running it.

## Run it

**PowerShell, folder: `~/code101/lesson06` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson06"
python main.py
```

**macOS/Linux terminal, folder: `~/code101/lesson06`**
```bash
cd ~/code101/lesson06
python3 main.py
```

Expected output:
```text
Bread: 5.00
Fruit: 3.60
Order: 8.60
```

## How it works
1. Python reads the `def` block and remembers the function; it does not calculate the order yet.
2. The bread call runs the block using 2.5 and 2, returning 5.0.
3. The fruit call uses 1.2 and 3, returning a float displayed as 3.60.
4. The caller adds the two results, then formats each number with two decimal places.

**Scope** means where a name can be used. `price`, `quantity` and `subtotal` are **local variables**: their names belong
to this function call, not to the code below it. Each call gets its own local names. The returned number can outlive those
names because the caller keeps it in a different variable. Pass inputs in and return results instead of reaching into a
function's locals. These floats are practice calculations; lesson 12 stores money as whole cents.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **parameter**, **argument**, **call**, **caller**, **body**, **positional argument**, **return value**, **scope**, **local variable**.

## Try it
**Sale price.** Write `discounted_price(price, percent)` so it returns the price after a percentage discount.
With a price of 80 and a discount of 25 percent, the result is 60. Keep the final print outside the function.

Without the pack, in VS Code's Explorer for `~/code101/lesson06`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `06-functions/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson06` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson06/exercise`, not
`lesson06/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson06/exercise/discount.py`**
```python
def discounted_price(price, percent):
    # TODO: calculate price minus price * percent / 100 and return it.
    return price


sale_price = discounted_price(80, 25)
print(f"Sale price: {sale_price:.2f}")
```

**PowerShell, folder: `~/code101/lesson06/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson06/exercise"
python discount.py
```

**macOS/Linux terminal, folder: `~/code101/lesson06/exercise`**
```bash
cd ~/code101/lesson06/exercise
python3 discount.py
```

Expected output:
```text
Sale price: 60.00
```

<details><summary>Solution</summary>

**File: `~/code101/lesson06/exercise/discount.py`**
```python
def discounted_price(price, percent):
    saving = price * percent / 100
    return price - saving


sale_price = discounted_price(80, 25)
print(f"Sale price: {sale_price:.2f}")
```

The caller gets the result, so it can print it, store it, or use it in another calculation.
</details>

## Check yourself

1. In `line_total(2.5, 2)`, are `2.5` and `2` parameters or arguments?
   <details><summary>Answer</summary>Arguments: actual values passed into the call. <code>price</code> and <code>quantity</code> are parameters.</details>

2. Does writing a `def` block run its body immediately?
   <details><summary>Answer</summary>No. The body runs when the function is called.</details>

3. Why can the caller not print `subtotal` directly?
   <details><summary>Answer</summary>That name is local to <code>line_total</code>. Use the returned value instead.</details>

4. What does `return` do besides supply a value?
   <details><summary>Answer</summary>It ends the current function call.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\main.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson06` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Order: 8.60` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `SyntaxError: expected ':'` | Forgot the colon after `def` | Restore `:` and keep the function body indented. |
| `TypeError: line_total() missing 1 required positional argument: 'quantity'` | Supplied only one positional argument | Supply price and quantity, in that order. |
| `NameError: name 'subtotal' is not defined` | Used the local name `subtotal` outside its function | Store and use its return value, such as `bread_total`. |

## Best practice
Give functions and variables lowercase names with underscores, such as `line_total` and `bread_total`, so their spelling follows a consistent convention.
Source: PEP 8, Function and variable names https://peps.python.org/pep-0008/#function-and-variable-names

## Next lesson
**07. Lists and dictionaries:** store many related values and process them with loops.
