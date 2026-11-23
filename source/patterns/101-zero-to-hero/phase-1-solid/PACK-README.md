# Design Patterns + SOLID 101, Phase 1: SOLID

Source pack for lessons 01 to 06 of **Design Patterns + SOLID 101 (Zero to Hero)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/101-zero-to-hero/phase-1-solid/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything. No third-party packages or art assets.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

| Folder | Lesson | You build |
|---|---|---|
| `01-why-design-matters` | Why design matters | One long invoice function and the same program split into small functions; coupling, cohesion and three code smells. |
| `02-single-responsibility` | Single Responsibility | An `Invoice` class with four jobs split into `Invoice`, a formatter, a store and an email sender. |
| `03-open-closed` | Open/Closed | A discount `if` chain replaced by rule classes; a new employee discount added in a new file. |
| `04-liskov-substitution` | Liskov Substitution | A gift card that cannot refund, fixed by splitting `Payable` and `Refundable`. |
| `05-interface-segregation` | Interface Segregation | A fat notifier interface with empty stubs split into email, SMS and push roles. |
| `06-dependency-inversion` | Dependency Inversion and injection by hand | An `OrderService` that builds its own sender, rebuilt with constructor injection and a fake; ends with a SOLID mixed review. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program: `before.py` (the problem), `after.py` (the fix) and `main.py` (runs both). |
| `code/csharp/` | The same program in C#: `Before.cs`, `After.cs`, `Program.cs` and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output a later automated check will use. |

## How to run any program
1. Install Python 3.10 or newer (Python 101 lesson 01) and/or the .NET SDK 11 (C# 101 lesson 01). You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. The extracted root has the zip's name without `.zip`. In the all-phases zip, open the `patterns-101-phase-1-solid` folder first.
3. Open a terminal in the folder shown below. On Windows use PowerShell; on macOS or Linux use Terminal. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns/try02`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
6. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
Choose **one** example. Commands work in PowerShell and Bash.

**Folder: extracted phase-pack root (contains `01-why-design-matters` and PACK-README.md)**
```text
cd 01-why-design-matters/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/101-zero-to-hero/phase-1-solid/01-why-design-matters/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output. All `Lesson.csproj` files are identical; only the `.cs` files change.

## First-timer time
Lesson 01: 35 minutes for one language; 02: 35; 03: 40; 04: 40; 05: 40; 06: 45 (plus the same again if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, test frameworks, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

Next: Phase 2, Everyday principles (lessons 07 to 09).
