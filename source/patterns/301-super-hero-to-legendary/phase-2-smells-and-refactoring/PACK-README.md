# Design Patterns 301, Phase 2: Smells and refactoring

Source pack for lessons 06 to 08 of **Design Patterns 301 (Super Hero to Legendary)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

| Folder | Lesson | You build |
|---|---|---|
| `06-code-smells-catalog` | Code smells catalog | A smelly module, a scanner that measures long methods, long parameter lists, nesting and large classes, and a catalogue table. |
| `07-refactoring-moves-with-tests` | Refactoring moves with tests as a safety net | A 216-case golden master and four refactoring moves, plus one deliberately broken move it catches. |
| `08-anti-patterns-before-and-after` | Anti-patterns with before and after | God object, anemic model, golden hammer, service locator and singleton abuse, each with an observable symptom and a fix. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program (`main.py` and helper files). |
| `code/csharp/` | The same program in C#: `Program.cs` (and sometimes more `.cs` files) and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output a later automated check will use. |

## How to run any program
1. Install Python 3.10 or newer and/or the .NET SDK 11. You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. In the all-phases zip, open the `patterns-301-phase-2-smells-and-refactoring` folder first.
3. Open a terminal in the folder shown below. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. Lesson 06 reads its own source file (`smelly.py` or `Smelly.cs`) from disk: run it from the folder that contains it.
6. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns301/try07`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
7. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
**Folder: extracted phase-pack root (contains `06-code-smells-catalog` and PACK-README.md)**
```text
cd 06-code-smells-catalog/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output.

## First-timer time
Lesson 06: 70 minutes for one language; 07: 75; 08: 60 (plus about 30 more minutes if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, test frameworks, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

Next: Phase 3, Judgement (lessons 09 and 10).
