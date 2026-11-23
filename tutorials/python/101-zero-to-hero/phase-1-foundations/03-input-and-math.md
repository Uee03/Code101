---
track: python
level: 101
phase: 1
phase_name: foundations
lesson: 03
title: Input and math
time: "35 min"
prerequisites: [101.1.02]
versions: { python: "3.12 or newer" }
verified: 2026-11-23 on Windows 11, Python 3.15.2
source: source/python/101-zero-to-hero/phase-1-foundations/03-input-and-math/
assets: []
---

# 03. Input and math

## Why it matters
A cash register does two jobs: it **asks** (what is the price?) and it **calculates** (what is the total?).
Programs do the same. In this lesson your program asks the user to type something, turns the typed text
into numbers, calculates, and shows a tidy answer.

## What you will build
A **tip calculator**. You type a bill and a tip percentage; it prints the tip and the total.

## Before you start
- Time: 35 minutes, including typing and the exercise.
- Lessons 01 and 02 done.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-1-foundations/03-input-and-math/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

If using a ZIP, extract it first: Windows, right-click the ZIP, **Extract All**, then **Extract**; macOS, double-click it;
Linux, open it in your archive manager and choose **Extract**. In the repository ZIP, open `Code101-main`, then the
`source` path listed above. You can also type every file below without downloading anything.

## Steps

### Step 1. Make a folder
```bash
cd ~/code101
mkdir lesson03
cd lesson03
code .
```
Expected result: VS Code opens an empty folder named `lesson03`. In that window choose **Terminal > New Terminal**.
The terminal folder must end in `lesson03`; recover with `cd ~/code101/lesson03`. Save each file before running it.
If asked about folder trust, choose **Yes, I trust the authors** for your own folder.

### Step 2. Meet the arithmetic operators
An **operator** is a symbol that does a calculation. Create a file `operators.py` and type:

**File: `operators.py`**
```python
# Python can do arithmetic. Each line prints each calculation and its answer.
print("7 + 2 =", 7 + 2)
print("7 - 2 =", 7 - 2)
print("7 * 2 =", 7 * 2)
print("7 / 2 =", 7 / 2)
print("7 // 2 =", 7 // 2)
print("7 % 2 =", 7 % 2)
print("7 ** 2 =", 7 ** 2)
```

Run it:
```bash
python operators.py
```

Expected output:
```text
7 + 2 = 9
7 - 2 = 5
7 * 2 = 14
7 / 2 = 3.5
7 // 2 = 3
7 % 2 = 1
7 ** 2 = 49
```

| Operator | Meaning | Example result |
|---|---|---|
| `+` | add | `7 + 2` is `9` |
| `-` | subtract | `7 - 2` is `5` |
| `*` | multiply | `7 * 2` is `14` |
| `/` | divide (always gives a decimal) | `7 / 2` is `3.5` |
| `//` | divide and round down to a whole number | `7 // 2` is `3` |
| `%` | remainder after dividing | `7 % 2` is `1` |
| `**` | power (7 multiplied by itself for exponent 2) | `7 ** 2` is `49` |

Python does multiplication before addition. More fully, the order is: `**` first, then `*` `/` `//` `%`, then `+` `-`. Use brackets to be clear: `(2 + 3) * 4` is `20`.

### Step 3. Ask the user for input
Create a new file `tip_calculator.py`. First type just the two questions:

**File: `tip_calculator.py`**
```python
# Tip calculator: asks for a bill, works out the tip and the total.
bill_text = input("Bill amount: ")
tip_text = input("Tip percent: ")
```

`input("...")` shows the message, waits for the user to type and press Enter, and gives back what they typed
as **text**, even if it looks like a number. We store it in `bill_text` and `tip_text`.
If you run this partial file from `lesson03`, it asks two questions and then ends without showing an answer;
that is expected. Finish Steps 4 and 5 before the full run.

### Step 4. Turn text into numbers
Add these lines below.

**File: `tip_calculator.py`**
```python
# Tip calculator: asks for a bill, works out the tip and the total.
bill_text = input("Bill amount: ")
tip_text = input("Tip percent: ")

# input() always gives text, so we turn the text into numbers.
bill = float(bill_text)
tip_percent = float(tip_text)
```

`float(...)` converts text such as `"80"` into the number `80.0`. (`int(...)` does the same for whole numbers.)
This is called **type conversion**.

### Step 5. Calculate and show the answer
Add the last lines. The finished file:

**File: `tip_calculator.py`**
```python
# Tip calculator: asks for a bill, works out the tip and the total.
bill_text = input("Bill amount: ")
tip_text = input("Tip percent: ")

# input() always gives text, so we turn the text into numbers.
bill = float(bill_text)
tip_percent = float(tip_text)

tip = bill * tip_percent / 100
total = bill + tip

print(f"Tip: {tip:.2f}")
print(f"Total: {total:.2f}")
```

`{tip:.2f}` means "show the number `tip` with exactly 2 digits after the decimal point", which is how money looks.

## Run it
```bash
python tip_calculator.py
```
The program stops and waits. Type `80`, press Enter, type `15`, press Enter. Your screen looks like this
(the numbers after the colons are what you typed):

```text
Bill amount: 80
Tip percent: 15
Tip: 12.00
Total: 92.00
```

## How it works
1. `input` pauses the program until the user presses Enter.
2. `float` converts the typed text into a number we can calculate with.
3. `bill * tip_percent / 100` is `80 * 15 / 100`, which is `12.0`.
4. The f-string inserts the numbers into the sentences, rounded to two decimal places.

New terms (also in the [course glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md)): **operator**, **input**, **type conversion**.

## Try it
**Split the bill.** Ask for the bill and the number of people, then print what each person pays.
Create `split_bill.py` in your `lesson03` folder (or copy `exercise/starter/split_bill.py` from the unzipped pack into it) with this text:

**File: `split_bill.py` (starter)**
```python
# Split the bill: ask for a bill and a number of people, then print each share.
# Replace each TODO. Run it and type 90 and 4: the answer should be 22.50.

bill_text = input("Bill amount: ")
bill = float(bill_text)

# TODO 1: ask "Number of people: " with input() and keep the text in people_text
people_text = ""

# TODO 2: turn people_text into a whole number with int() and keep it in people
people = 1

# TODO 3: work out the share (bill divided by people)
share = 0

print(f"Each person pays {share:.2f}")
```

Save, then from `lesson03` run `python split_bill.py` (macOS/Linux: `python3 split_bill.py`).
Typing `90` and `4` should end with `Each person pays 22.50`.

<details><summary>Solution</summary>

**File: `split_bill.py`**
```python
bill_text = input("Bill amount: ")
people_text = input("Number of people: ")

bill = float(bill_text)
people = int(people_text)

share = bill / people

print(f"Each person pays {share:.2f}")
```
`int(...)` works like `float(...)` but gives a whole number.
</details>

## Check yourself
1. What type does `input()` always return?
   <details><summary>Answer</summary>Text (<code>str</code>), even when the user types digits.</details>
2. What are `10 // 3` and `10 % 3`?
   <details><summary>Answer</summary><code>3</code> and <code>1</code>.</details>
3. What does `{total:.2f}` do inside an f-string?
   <details><summary>Answer</summary>Shows <code>total</code> with exactly two digits after the decimal point.</details>
4. What is `2 + 3 * 4`?
   <details><summary>Answer</summary>14, because multiplication happens first.</details>

## Common mistakes
Start with the last error line, then find your file and line number above it.
`<project>` stands for your folder; paths, line numbers and extra hints may differ by Python version.

| What you see | Cause | Fix |
|---|---|---|
| `can't open file '<project>\\tip_calculator.py': [Errno 2] No such file or directory` | The terminal is not in the folder holding this file | Run `cd ~/code101/lesson03` (PowerShell accepts this too), then rerun the command. |
| Old output, such as `Total: 92.00` | The editor change has not been saved; Python ran the old file | Save with Ctrl+S (macOS: Cmd+S), check that the tab's dot disappears, then rerun. |
| `ValueError: could not convert string to float: 'abc'` | Typed letters for the bill | Type numbers such as `80`, `15` or `12.5`, with no `$` or `%`. Lesson 09 (Phase 3) teaches recovery from bad input. |
| `ValueError: could not convert string to float: '$80'` | Included a currency sign | Type numbers such as `80`, `15` or `12.5`, with no `$` or `%`. Lesson 09 (Phase 3) teaches recovery from bad input. |
| `ValueError: could not convert string to float: '15%'` | Included a percent sign | Type numbers such as `80`, `15` or `12.5`, with no `$` or `%`. Lesson 09 (Phase 3) teaches recovery from bad input. |
| `ValueError: could not convert string to float: '12,5'` | Used a decimal comma | Type numbers such as `80`, `15` or `12.5`, with no `$` or `%`. Lesson 09 (Phase 3) teaches recovery from bad input. |
| `TypeError: can't multiply sequence by non-int of type 'float'` | Calculated with the unconverted text `bill_text` | Use the number `bill` after `float(bill_text)`. |
| `ZeroDivisionError: division by zero` | Entered zero people in the bill-splitting exercise | Use at least one person; lesson 09 adds a check before division. |

## Best practice
Keep the raw text and the converted number in separate, clearly named variables (`bill_text`, then `bill`). Naming the
conversion step makes it obvious where a bad value could slip in. "Explicit is better than implicit."
Source: PEP 20, The Zen of Python https://peps.python.org/pep-0020/

## Next lesson
**04. Making decisions:** let your program choose different actions with `if`.
