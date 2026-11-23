# C# 201, Phase 1: Core Skills

Source pack for lessons 01 to 04 of **C# 201 (Hero to Super Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/201-hero-to-super-hero/phase-1-core-skills/` (Code > Download ZIP, or `git clone`). Every lesson shows all its code, so downloading is optional. No third-party packages.

> **Draft status.** These lessons and their code were written by reading the code and the official documentation; they have not been executed yet. If something behaves differently from the text, trust your tool's real output and report it.

| Folder | Lesson | You build |
|---|---|---|
| `01-interfaces-inheritance-polymorphism` | Interfaces, inheritance and polymorphism | A discount engine: one interface, an abstract base class that enforces a rule, three types, one wrapper (composition). |
| `02-generics-and-collections` | Generics and collections in depth | A generic in-memory repository, a generic `LargestBy` helper, and short tours of `SortedDictionary`, `HashSet` and `Queue`. |
| `03-linq` | LINQ | A dozen queries over six orders and three customers, plus two experiments: deferred execution and double enumeration. |
| `04-async-await-and-task` | async/await and Task | Sequential vs concurrent waits, cancellation, failures from one and two tasks, and CPU work on the thread pool. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project from the lesson's Steps. Type it yourself first; use this to compare. |
| `exercise/starter/` | The starting files of the Try it exercise, with `TODO` comments. |
| `exercise/solution/` | The finished exercise; try before you look. |
| `verify.json` | Machine-readable list of the steps and expected output of the lesson. |

## How to run any program
1. You need the **.NET SDK 11.0.100** (or a later 11.0.1xx patch) and an editor, as set up in C# 101 lesson 01. `global.json` pins the SDK; every project targets `net11.0`.
2. Extract the zip (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip`). Open a terminal in a lesson's `code` folder, the one that contains `Lesson.csproj`.
3. Run `dotnet run --project . --nologo`.
4. For an exercise, copy the `starter` folder to your own folder (for example `~/code101/csharp201/exercise01`), open that copy, edit it and run the same command there. Do not mix exercise and lesson files: every `.cs` file below a project folder is compiled.

**Folder: the extracted repository root `Code101` (contains `source` and `tutorials`)**
```text
cd source/csharp/201-hero-to-super-hero/phase-1-core-skills/01-interfaces-inheritance-polymorphism/code
dotnet run --project . --nologo
```

## First-timer time
Lesson 01: 50-60 minutes; 02: 50-60; 03: 55-65; 04: 55-65. The lessons end with a mixed review of the phase.

## Needs
.NET SDK 11.0.100 / net11.0. No Docker, database or network after the SDK is installed. Source files use UTF-8 without BOM; `bin/` and `obj/` are build output and are not part of the pack.

Next: Phase 2, Web APIs (lessons 05 to 07), which needs `curl` and the NuGet package FastEndpoints / FluentValidation.
