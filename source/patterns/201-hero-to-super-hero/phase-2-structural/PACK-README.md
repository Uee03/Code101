# Design Patterns 201, Phase 2: Structural patterns

Source pack for lessons 04 to 07 of **Design Patterns 201 (Hero to Super Hero)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The lessons also show a short TypeScript sketch in the text only. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/201-hero-to-super-hero/phase-2-structural/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything. No third-party packages or art assets.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

**Prerequisite:** Phase 1 of this level (lessons 01 to 03) and Design Patterns + SOLID 101.

| Folder | Lesson | You build |
|---|---|---|
| `04-adapter-and-facade` | Adapter and Facade | A Fahrenheit sensor adapted to a Celsius interface, and a home-theater facade over three classes. |
| `05-decorator-and-proxy` | Decorator and Proxy | Stackable text sinks whose order changes the output, and a caching and a protection proxy in front of a slow forecast service. |
| `06-composite-and-flyweight` | Composite and Flyweight | A folder and document tree with recursive sizes, and a forest whose trees share two immutable tree types. |
| `07-bridge` | Bridge | Message kinds and delivery channels as two hierarchies joined by one reference; ends with a table for choosing among the seven structural patterns. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program: one module per pattern and `main.py` that runs them. |
| `code/csharp/` | The same program in C#: one `.cs` file per pattern, `Program.cs` and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output that an automated check will use later. |

## How to run any program
1. Install Python 3.10 or newer (Python 101 lesson 01) and/or the .NET SDK 11 (C# 101 lesson 01). You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. The extracted root has the zip's name without `.zip`. In the all-phases zip, open the `patterns-201-phase-2-structural` folder first.
3. Open a terminal in the folder shown below. On Windows use PowerShell; on macOS or Linux use Terminal. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns201/try04`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
6. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
Choose **one** example. Commands work in PowerShell and Bash.

**Folder: extracted phase-pack root (contains `04-adapter-and-facade` and PACK-README.md)**
```text
cd 04-adapter-and-facade/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/201-hero-to-super-hero/phase-2-structural/04-adapter-and-facade/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output. All `Lesson.csproj` files are identical; only the `.cs` files change.

## First-timer time
Lesson 04: 55 minutes for one language; 05: 55; 06: 55; 07: 45 (plus about half as much again if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, test frameworks, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

Next: Phase 3, Behavioral patterns (lessons 08 to 11).
