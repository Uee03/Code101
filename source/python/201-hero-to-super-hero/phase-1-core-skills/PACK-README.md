# Python 201 - Phase 1: Core skills

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

Four independent lessons, 230 minutes including typing/exercises. Prerequisite: Python 101 completed and Python 3.12 installed. No art assets are used. Full walkthroughs: https://github.com/Uee03/Code101/tree/main/tutorials/python/201-hero-to-super-hero/phase-1-core-skills . Glossary: https://github.com/Uee03/Code101/blob/main/tutorials/python/GLOSSARY.md .

## Extract and choose a lesson
Windows: right-click ZIP, **Extract All > Extract**. macOS: double-click. Linux: your archive manager's **Extract**. Open the extracted `python-201-phase-1-core-skills` folder in an editor and **Terminal > New Terminal** there. If using the all-level ZIP, open this same phase folder inside `python-201` first. Do not execute files inside an archive viewer.

Each lesson contains `code` (finished files), `exercise/starter`, `exercise/solution` and a future verification specification. Work on a copy. Source packs are optional; every new file is shown in the lesson.

| Lesson | Run from its code directory | Outcome | Time |
|---|---|---|---|
| 01 Classes in depth | `models.py` | dataclasses, properties, dunders and independent composed state | 60 min |
| 02 Type hints and mypy | `main.py` | protocols, narrowing and strict development-time contracts | 60 min |
| 03 Iterators and generators | `main.py` | lazy/single-pass consumption and exhaustion | 50 min |
| 04 Decorators and context managers | `main.py` | preserved metadata, single-yield lifetime and reliable cleanup | 60 min |

## First example
From the phase root:

**PowerShell**
```powershell
Set-Location ./01-classes-in-depth/code
py -3.12 models.py
py -3.12 -m unittest -v
```

**macOS/Linux**
```bash
cd 01-classes-in-depth/code
python3.12 models.py
python3.12 -m unittest -v
```
Expected application output, not yet run: the first note has three words, notebook lengths are 1 and 0, and equal note values compare True. Test outcomes remain unrun.

For 03 and 04, open a fresh terminal in the phase root and repeat exactly these navigation/run steps, changing the directory to the table's lesson slug and the script to `main.py`. Their unittest command is identical. Lesson 02 also runs with plain Python, but its checker needs its local environment:

**PowerShell - starting folder: phase root**
```powershell
Set-Location ./02-type-hints-and-mypy/code
py -3.12 -m venv .venv
& ./.venv/Scripts/python.exe -m pip install -r requirements.txt
& ./.venv/Scripts/python.exe main.py
& ./.venv/Scripts/python.exe -m mypy
& ./.venv/Scripts/python.exe -m unittest -v
```

**macOS/Linux - starting folder: phase root**
```bash
cd 02-type-hints-and-mypy/code
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python main.py
.venv/bin/python -m mypy
.venv/bin/python -m unittest -v
```
The checker and tests above are learner commands; none was executed during authoring. Dependency pins are teaching snapshots, not a transitive lock or current security certification. No activation/global installation is needed.

## Exercises and review
Copy the chosen lesson's `exercise/starter` folder itself into your own lesson workspace and rename it `tryNN`, where NN is 01-04. Do not copy it *into* an existing try folder. Follow that lesson's exact execution command. The source solution answers the guided rung; change/stretch rungs are deliberate practice. Lessons 01/03/04 exercises use plain Python; 02 can also be checked by its installed mypy.

Phase mixed review is at the end of lesson 04. Continue with phase 2 for owned asynchronous tasks, installable packages and validated configuration.
