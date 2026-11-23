# Python 101, Phase 3: Real programs

Source pack for lessons 09 to 12 of **Python 101 (Zero to Hero)**. The pack is optional: each lesson shows the code and exercise.
Find these files in https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-3-real-programs/`.
Choose **Code > Download ZIP** at the repository, or use `git clone https://github.com/Uee03/Code101.git`.
The [glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md) defines the course terms.

| Folder | Lesson | You build | First-timer time |
|--------|--------|-----------|------------------|
| `09-handling-errors` | Handling errors | age/bill re-ask loops and a safe bill splitter | 40 min |
| `10-modules-and-packages` | Modules and packages | a modular report, a package and an isolated pip install | 60 min (two sittings) |
| `11-classes-basics` | Classes basics | independent savings jars and step counters | 35 min |
| `12-expense-tracker` | Project: expense tracker | a menu-driven CSV app and a plain-assert self-check | 90 min (two sittings) |

## Inside each lesson folder

| Folder or file | What it is |
|----------------|------------|
| `code/` | The finished program from the lesson. Type it yourself first; open this to compare. |
| `exercise/starter/` | Where the "Try it" exercise starts (has `TODO` markers). |
| `exercise/solution/` | The exercise answer. Try before you look. |

## How to run any program

1. Install Python 3.12 or newer (lesson 01), and finish Phase 2 (lessons 05 to 08).
2. Unzip this pack: Windows, right-click `python-101-phase-3-real-programs.zip`, choose **Extract All**, then **Extract**;
   macOS, double-click it; Linux, open a terminal in the zip's folder and run `unzip python-101-phase-3-real-programs.zip`.
3. In the extracted pack, open a terminal **inside** the lesson's `code` folder (type `cd` followed by the folder path).
4. Run `python <file>.py` (macOS and Linux: `python3 <file>.py`). Use the filenames below, without the angle brackets.

For an exercise, copy the lesson's `starter` folder itself into your own lesson folder and rename the copy
`exercise`. Do not copy it *into* an existing `exercise` folder: you need `lessonNN/exercise/main.py` (or the named
exercise script), not `lessonNN/exercise/starter/main.py`. Work on the copy. Without the pack, create the
`exercise` folder and type the starter shown in the lesson. Keep all related files together.
The answer is in `exercise/solution`; try before looking.

Example, starting in this extracted phase folder:

**PowerShell**
```powershell
Set-Location 09-handling-errors/code
python safe_input.py
```

**macOS/Linux terminal**
```bash
cd 09-handling-errors/code
python3 safe_input.py
```

## Programs

| Folder | Run inside `code` | Exercise file to run after finishing the TODOs |
|--------|-------------------|-----------------------------------------------|
| `09-handling-errors` | `python safe_input.py` | `python split_bill.py` |
| `10-modules-and-packages` | `python main.py` | `python main.py` (keep `conversions.py` beside it) |
| `11-classes-basics` | `python main.py` | `python step_counter.py` |
| `12-expense-tracker` | `python main.py`; separately, `python self_check.py` | `python main.py` (keep `tracker.py` and `self_check.py` beside it) |

## Needs

Python 3.12 or newer. All main programs and exercises use the standard library only. On macOS/Linux replace
`python` with `python3` in the program table. Lesson 10 separately practises `venv` and `pip` with the exact dependency
`colorama==0.4.6` from `code/requirements.txt`; that practice requires internet access. Its lesson gives every command,
including explicit environment-interpreter paths. If VS Code activates `.venv`, `(.venv)` appears in the prompt;
`deactivate` leaves it. A blocked activation script does not prevent the full-path Python commands from working.
You do not need to change PowerShell's script policy. Lesson 10 breaks before Step 5 (environments);
lesson 12 breaks before Step 3 (the menu).

Lesson 12 saves `expenses.csv` beside the script and reloads it at startup. Amounts are positive whole cents:
250 means 2.50. Use disposable practice data; this teaching app is not crash-safe or for simultaneous users.
`self_check.py` uses plain `assert` and a temporary CSV; run it with ordinary Python, not pytest. It does not touch
your notebook. The tiny self-check is an optional, separate learner command.

You have completed Python 101. More Python lessons are planned.

Updated 2026-11-23: beginner walk-through clarifications, honest timings, exact starter-copy instructions and glossary link.
