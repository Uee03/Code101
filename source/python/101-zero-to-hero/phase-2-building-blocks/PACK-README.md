# Python 101, Phase 2: Building blocks

Source pack for lessons 05 to 08 of **Python 101 (Zero to Hero)**. The pack is optional: each lesson shows the code and exercise.
Find these files in https://github.com/Uee03/Code101 under `source/python/101-zero-to-hero/phase-2-building-blocks/`.
Choose **Code > Download ZIP** at the repository, or use `git clone https://github.com/Uee03/Code101.git`.
The [glossary](https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md) defines the course terms.

| Folder | Lesson | You build | First-timer time |
|--------|--------|-----------|------------------|
| `05-loops` | Loops | a times table, guessing game and countdown | 40 min |
| `06-functions` | Functions | an order calculator and discount helper | 30 min |
| `07-lists-and-dictionaries` | Lists and dictionaries | an inventory and shopping cart | 35 min |
| `08-files` | Files | text/CSV saving and an append-only journal | 60 min (two sittings) |

## Inside each lesson folder

| Folder or file | What it is |
|----------------|------------|
| `code/` | The finished program from the lesson. Type it yourself first; open this to compare. |
| `exercise/starter/` | Where the "Try it" exercise starts (has `TODO` markers). |
| `exercise/solution/` | The exercise answer. Try before you look. |

## How to run any program

1. Install Python 3.12 or newer (lesson 01), and finish Phase 1 (lessons 01 to 04).
2. Unzip this pack: Windows, right-click `python-101-phase-2-building-blocks.zip`, choose **Extract All**, then **Extract**;
   macOS, double-click it; Linux, open a terminal in the zip's folder and run `unzip python-101-phase-2-building-blocks.zip`.
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
Set-Location 05-loops/code
python times_table.py
```

**macOS/Linux terminal**
```bash
cd 05-loops/code
python3 times_table.py
```

## Programs

| Folder | Run inside `code` | Exercise file to run after finishing the TODOs |
|--------|-------------------|-----------------------------------------------|
| `05-loops` | `python times_table.py`, then `python guessing_game.py` | `python countdown.py` |
| `06-functions` | `python main.py` | `python discount.py` |
| `07-lists-and-dictionaries` | `python inventory.py` | `python cart.py` |
| `08-files` | `python files_demo.py` | `python journal.py` |

## Needs

Python 3.12 or newer. Nothing else to install in this phase. On macOS/Linux replace `python` with `python3`
in the program table. Interactive programs wait for your input; the lessons list sample answers.

Lesson 08 writes `note.txt` and `shopping.csv` beside its script, replacing the demo data each time. The exercise
appends to `journal.txt` beside its copied script. Use practice data only.

Lesson 08 takes two sittings: stop after the text-note run in Step 3, before adding CSV in Step 4.
Optional Going further notes explain the unchanged path and encoding recipe.

Next: Phase 3, Real programs (errors, modules and packages, classes, and a CSV expense tracker).

Updated 2026-11-23: beginner walk-through clarifications, honest timings, exact starter-copy instructions and glossary link.
