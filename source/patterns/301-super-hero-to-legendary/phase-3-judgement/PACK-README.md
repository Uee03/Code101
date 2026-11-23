# Design Patterns 301, Phase 3: Judgement

Source pack for lessons 09 and 10 of **Design Patterns 301 (Super Hero to Legendary)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/301-super-hero-to-legendary/phase-3-judgement/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

| Folder | Lesson | You build |
|---|---|---|
| `09-choosing-patterns-in-one-service` | Choosing patterns: a decision framework and one realistic service | The "complete task" use case of Tasks and Teams with exactly the patterns it needs, and a count of the types the design uses. |
| `10-architecture-level-patterns-and-design-review` | Architecture-level patterns and a design review | A small hexagonal application, a fitness function that checks the dependency rule, and a design review exercise with an answer key. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program (lesson 10 has `domain`, `application` and `adapters` folders inside). |
| `code/csharp/` | The same program in C#: `Program.cs`, more `.cs` files (lesson 10 has `Domain`, `Application` and `Adapters` folders) and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output a later automated check will use. |

## How to run any program
1. Install Python 3.10 or newer and/or the .NET SDK 11. You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. In the all-phases zip, open the `patterns-301-phase-3-judgement` folder first.
3. Open a terminal in the folder shown below. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. Lesson 10's checker reads the layer folders next to the program: run it from the `python` folder or the `csharp` folder that contains them.
6. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns301/try09`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
7. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
**Folder: extracted phase-pack root (contains `09-choosing-patterns-in-one-service` and PACK-README.md)**
```text
cd 09-choosing-patterns-in-one-service/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/301-super-hero-to-legendary/phase-3-judgement/09-choosing-patterns-in-one-service/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output.

## First-timer time
Lesson 09: 75 minutes for one language; 10: 90 (plus about 30 more minutes if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

This is the last phase of Patterns 301. Continue with the capstones (`capstones/platform` and a backend of your choice).
