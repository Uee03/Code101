# Design Patterns 301, Phase 1: Application patterns

Source pack for lessons 01 to 05 of **Design Patterns 301 (Super Hero to Legendary)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/301-super-hero-to-legendary/phase-1-application-patterns/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

| Folder | Lesson | You build |
|---|---|---|
| `01-di-containers-and-composition-roots` | Dependency injection containers and composition roots | A tiny container with lifetimes and start-up validation (Python) and the same checks with `Microsoft.Extensions.DependencyInjection` (C#). |
| `02-repository-and-unit-of-work` | Repository and Unit of Work | A repository that sees pending changes and a unit of work that rolls back a partly failed commit. |
| `03-specification-and-query-object` | Specification and Query Object | Composable specifications that run in memory and print parameterised SQL; a query object with allow-listed sort. |
| `04-cqrs-and-the-mediator` | CQRS and the mediator in practice | A mediator with logging and validation behaviours and a read model that can lag. |
| `05-domain-events-outbox-and-saga` | Domain events, outbox and saga | An outbox, a crashing relay, idempotent consumers, a choreographed reaction and an orchestrated saga with compensation. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program (`main.py`, sometimes more files). |
| `code/csharp/` | The same program in C#: `Program.cs` (and sometimes more `.cs` files) and `Lesson.csproj`. |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output a later automated check will use. |

## How to run any program
1. Install Python 3.10 or newer and/or the .NET SDK 11. You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. In the all-phases zip, open the `patterns-301-phase-1-application-patterns` folder first.
3. Open a terminal in the folder shown below. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns301/try02`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
6. Never copy `bin` or `obj` folders; they are build output.

## Exact starting folders
**Folder: extracted phase-pack root (contains `01-di-containers-and-composition-roots` and PACK-README.md)**
```text
cd 01-di-containers-and-composition-roots/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/301-super-hero-to-legendary/phase-1-application-patterns/01-di-containers-and-composition-roots/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output.

## First-timer time
Lesson 01: 60 minutes for one language; 02: 60; 03: 60; 04: 60; 05: 75 (plus about 30 more minutes if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`). Lesson 01 (C#) needs one NuGet package, `Microsoft.Extensions.DependencyInjection` 11.0.0, restored automatically by `dotnet run` (internet access the first time). No lock file is shipped. All other lessons need no packages, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

Next: Phase 2, Smells and refactoring (lessons 06 to 08).
