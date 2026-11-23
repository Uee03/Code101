---
track: python
level: 101
phase: 2
phase_name: building-blocks
lesson: 07
title: Lists and dictionaries
time: "35 min"
prerequisites: [101.2.06]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-2-building-blocks/07-lists-and-dictionaries/
assets: []
---

# 07. Lists and dictionaries

## Why it matters
A shopping list keeps items in order; a stock ledger lets you look up a quantity by an item name. Python has a different container for each job. Both save you from inventing a separate variable for every item.

## What you will build
A tiny inventory: an ordered shopping list, stock counts looked up by name, and a report printed with loops.

## Before you start
- Time: 35 minutes, including typing and the exercise.
- Finish lesson 06; use Python 3.12 or newer and VS Code from lesson 01.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-2-building-blocks/07-lists-and-dictionaries/` (on that page choose **Code, Download ZIP**, or run
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
New-Item -ItemType Directory -Path "$HOME/code101/lesson07" -Force | Out-Null
Set-Location "$HOME/code101/lesson07"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/lesson07
cd ~/code101/lesson07
code .
```
Expected result: VS Code opens `lesson07`. The folder-creation command prints nothing. If `code` is unavailable,
use VS Code's **File > Open Folder** and choose that folder instead.
In the new VS Code window choose **Terminal > New Terminal**; use that terminal for the remaining commands.
If asked about folder trust, choose **Yes, I trust the authors** for your own lesson folder.

For each file below, use **Explorer > New File**, type the exact filename, paste or type the complete content, and save
with **Ctrl+S** (macOS: **Cmd+S**). A dot on the editor tab means the file is not saved. All program files go in
`~/code101/lesson07` unless a subfolder is explicitly named.

### Step 2. Create the inventory file
A **collection** stores several values together. A **list** is an ordered, changeable collection written with square
brackets. An **index** is a position in a list; the first position is **0**, not 1.
A **dictionary** stores **key-value pairs**: a key is the lookup label, and its value is the associated data.
Dictionary keys are unique; list entries can repeat. Inside an f-string, using the other kind of quote for text
such as `'rice'` makes the inner and outer strings easy to distinguish. Create `inventory.py`:

**File: `~/code101/lesson07/inventory.py`**
```python
shopping = ["bread", "apples"]
shopping.append("milk")
print(f"First item: {shopping[0]}")
print(f"Items to buy: {len(shopping)}")

stock = {"bread": 4, "apples": 6, "milk": 2}
stock["bread"] = stock["bread"] - 1

for name in shopping:
    print(f"Buy: {name}")

for name, quantity in stock.items():
    print(f"{name}: {quantity} left")

if "rice" not in stock:
    print("Rice is not stocked.")
print(f"Rice count: {stock.get('rice', 0)}")
```

### Step 3. Read the lookups
- `shopping[0]` uses an integer position and gives `"bread"`. After appending milk, valid positions are 0, 1 and 2.
- `stock["bread"]` uses a dictionary key, not a numbered position. Assignment updates that key's value.
- A **method** is a function attached to a value, called using a dot. `shopping.append("milk")` adds one item at the end;
  it changes the list. `len(shopping)` is a function returning the item count, not the last index.
- `stock.items()` provides each key and value as a pair. `for name, quantity in ...` gives the two parts separate names.
- **Membership** asks whether an item is present: `in` tests for presence, and `not in` tests for absence. For a dictionary,
  these check keys. `stock.get("rice", 0)` returns 0 if rice has no entry, without creating an entry.

Save the file. Do not remove entries from a collection while the report loop is visiting that same collection.

## Run it

**PowerShell, folder: `~/code101/lesson07` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson07"
python inventory.py
```

**macOS/Linux terminal, folder: `~/code101/lesson07`**
```bash
cd ~/code101/lesson07
python3 inventory.py
```

Expected output:
```text
First item: bread
Items to buy: 3
Buy: bread
Buy: apples
Buy: milk
bread: 3 left
apples: 6 left
milk: 2 left
Rice is not stocked.
Rice count: 0
```

## How it works
1. Python makes a two-item list, then appends milk. Its length is now 3.
2. The dictionary starts with four breads; the assignment stores one fewer, leaving 3.
3. The first loop follows the shopping list order. The second visits dictionary entries in **insertion order**: the order you added them. Updating a value does not move its key.
4. The membership check finds no rice key; `get` supplies the fallback value 0.

Lists answer "what is at this position?" Dictionaries answer "what belongs to this label?" Choose based on the question,
not on which punctuation is shorter. A later assignment to the same dictionary key replaces its value.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **collection**, **list**, **index**, **dictionary**, **key-value pair**, **method**, **membership**, **insertion order**.

## Try it
**Shopping cart.** Add each listed item's price to `total`. `cart` contains bread twice; charge for both entries.
The prices here are whole practice units. Finish the total so it includes every cart entry.

Without the pack, in VS Code's Explorer for `~/code101/lesson07`, choose **New Folder**, name it `exercise`,
and create the starter files below inside it.
With the pack, **instead** find `07-lists-and-dictionaries/exercise/starter` in the extracted source folder.
Copy the `starter` folder itself into `~/code101/lesson07` and rename the copy `exercise`.
Do not copy it into an existing `exercise` folder: the result must be `lesson07/exercise`, not
`lesson07/exercise/starter`. Work on the copy, not the original starter.

**File: `~/code101/lesson07/exercise/cart.py`**
```python
cart = ["bread", "milk", "bread"]
prices = {"bread": 2, "milk": 3}
total = 0

# TODO: loop over cart and add prices[name] to total for each item.
print(f"Cart total: {total}")
```

**PowerShell, folder: `~/code101/lesson07/exercise` (the first command gets you there)**
```powershell
Set-Location "$HOME/code101/lesson07/exercise"
python cart.py
```

**macOS/Linux terminal, folder: `~/code101/lesson07/exercise`**
```bash
cd ~/code101/lesson07/exercise
python3 cart.py
```

Expected output:
```text
Cart total: 7
```

<details><summary>Solution</summary>

**File: `~/code101/lesson07/exercise/cart.py`**
```python
cart = ["bread", "milk", "bread"]
prices = {"bread": 2, "milk": 3}
total = 0

for name in cart:
    total = total + prices[name]

print(f"Cart total: {total}")
```

The list controls how many items you buy. The dictionary supplies the price for each name, including repeated bread.
</details>

## Check yourself

1. What is the index of the first list item?
   <details><summary>Answer</summary>0. For a three-item list, the last index is 2.</details>

2. What does `stock.get("rice", 0)` do when rice is missing?
   <details><summary>Answer</summary>Returns 0 without adding rice to the dictionary.</details>

3. What does `"bread" in stock` check?
   <details><summary>Answer</summary>Whether the dictionary has a key named <code>bread</code>, not whether a value equals that text.</details>

4. Why does the cart charge for bread twice?
   <details><summary>Answer</summary>The loop visits each list entry; duplicate entries are allowed.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\inventory.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson07` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Rice count: 0` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `IndexError: list index out of range` | Index 3 is past the end of a three-item list | Use indices 0 to 2, or loop over items directly. |
| `KeyError: 'rice'` | Looked up a missing key directly | Check membership first, or use `stock.get("rice", 0)`. |
| `SyntaxError: '{' was never closed` | Forgot the dictionary's closing curly bracket | Add `}` at the end of the stock dictionary. |

## Best practice
When you need both dictionary keys and their values, loop over `dictionary.items()` rather than maintaining a separate counter or repeating lookups.
Source: Python tutorial, Looping techniques https://docs.python.org/3/tutorial/datastructures.html#looping-techniques

## Next lesson
**08. Files:** keep your program's text and table data after the program stops.
