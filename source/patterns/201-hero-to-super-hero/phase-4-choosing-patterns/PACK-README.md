# Design Patterns 201, Phase 4: Choosing patterns

Source pack for lesson 12 of **Design Patterns 201 (Hero to Super Hero)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/201-hero-to-super-hero/phase-4-choosing-patterns/` (Code > Download ZIP, or git clone). The lesson can be followed without downloading anything. No third-party packages or art assets.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

**Prerequisite:** Phases 1 to 3 of this level (lessons 01 to 11) and Design Patterns + SOLID 101.

| Folder | Lesson | You build |
|---|---|---|
| `12-choosing-combining-refactoring` | Choosing, combining and refactoring toward patterns | A messy `checkout` function refactored into Strategy, Chain of Responsibility, Observer and a Facade, with a program that runs old and new side by side and prints `same as before`; plus a decision table, a flowchart and an anti-pattern list. |

## Inside the lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | `before.py` (the messy function), `after.py` (the refactored design) and `main.py` (runs both on five orders). |
| `code/csharp/` | The same in C#: `Item.cs`, `Before.cs`, `After.cs`, `Program.cs` and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise (refactor a ticket-price function), with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output that an automated check will use later. |

## How to run any program
1. Install Python 3.10 or newer (Python 101 lesson 01) and/or the .NET SDK 11 (C# 101 lesson 01). You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. The extracted root has the zip's name without `.zip`. In the all-phases zip, open the `patterns-201-phase-4-choosing-patterns` folder first.
3. Open a terminal in the folder shown below. On Windows use PowerShell; on macOS or Linux use Terminal. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. For the exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns201/try12`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
6. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
Choose **one** example. Commands work in PowerShell and Bash.

**Folder: extracted phase-pack root (contains `12-choosing-combining-refactoring` and PACK-README.md)**
```text
cd 12-choosing-combining-refactoring/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/201-hero-to-super-hero/phase-4-choosing-patterns/12-choosing-combining-refactoring/code/csharp
dotnet run --project . --nologo
```
See the lesson's Run it section for the exact output.

## First-timer time
Lesson 12: 80 minutes for one language, in two sittings (plus about half as much again if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, test frameworks, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

This is the last phase of Design Patterns 201.
