# Design Patterns + SOLID 101, Phase 2: Everyday principles

Source pack for lessons 07 to 09 of **Design Patterns + SOLID 101 (Zero to Hero)**. Every example is written twice, in **Python** and in **C#**; follow the language you know and use the other one to compare. The optional originals are at https://github.com/Uee03/Code101 under `source/patterns/101-zero-to-hero/phase-2-everyday-principles/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything. No third-party packages or art assets.

**Status: draft, written but not yet run.** The code and the expected output were prepared by reading the code and the official documentation. If something behaves differently on your machine, trust your tool's real output.

| Folder | Lesson | You build |
|---|---|---|
| `07-dry-kiss-yagni` | DRY, KISS and YAGNI | A totals module with a duplicated rule, a needless one-liner and unused extras, cleaned up; plus a case where lookalike code must stay separate. |
| `08-composition-over-inheritance` | Composition over inheritance | A notifier class tree replaced by interchangeable channel and tone parts; Slack added with one class. |
| `09-class-diagrams-and-review` | Reading and drawing class diagrams, and a mixed review | A messy `OrderProcessor` refactored with SRP, OCP, DIP and composition, plus Mermaid class diagrams you read and draw. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/python/` | The finished Python program: `before.py`, `after.py` and `main.py` (lesson 07 also has `lookalikes.py`). |
| `code/csharp/` | The same program in C#: `Before.cs`, `After.cs`, `Program.cs` and `Lesson.csproj` (lesson 07 also has `Lookalikes.cs`). |
| `exercise/starter/python/`, `exercise/starter/csharp/` | The starting point of the Try it exercise, with TODO markers. |
| `exercise/solution/python/`, `exercise/solution/csharp/` | The complete answers; try before you look. |
| `verify.json` | The commands and expected output a later automated check will use. |

## How to run any program
1. Install Python 3.10 or newer (Python 101 lesson 01) and/or the .NET SDK 11 (C# 101 lesson 01). You only need the language you are following.
2. Unzip: Windows, right-click the zip, **Extract All**, **Extract**. macOS: double-click the zip. Linux: **Extract Here** in the file manager, or run `unzip` in the download folder. The extracted root has the zip's name without `.zip`. In the all-phases zip, open the `patterns-101-phase-2-everyday-principles` folder first.
3. Open a terminal in the folder shown below. On Windows use PowerShell; on macOS or Linux use Terminal. Put paths with spaces in quotes.
4. Python: run `python main.py` (macOS and Linux: `python3 main.py`). C#: run `dotnet run --project . --nologo` in the folder that contains `Lesson.csproj`.
5. For an exercise, copy the `starter/python` or `starter/csharp` folder into your own folder (for example `~/code101/patterns/try08`) and rename the copy; do not put the starter inside a folder you already made. Edit `main.py` or `Program.cs` and run the same command there. Save before running.
6. Never copy `bin` or `obj` folders; they are build output.
7. Lesson 09 also uses Markdown files with Mermaid diagrams. To see them as pictures in VS Code, install the extension **Markdown Preview Mermaid Support** (`bierner.markdown-mermaid`) and open the preview with **Ctrl+Shift+V** (macOS: **Cmd+Shift+V**).

## Exact starting folders
Choose **one** example. Commands work in PowerShell and Bash.

**Folder: extracted phase-pack root (contains `07-dry-kiss-yagni` and PACK-README.md)**
```text
cd 07-dry-kiss-yagni/code/python
python main.py
```

**Folder: extracted or cloned repository root `Code101` (contains `source` and `tutorials`), C# example**
```text
cd source/patterns/101-zero-to-hero/phase-2-everyday-principles/07-dry-kiss-yagni/code/csharp
dotnet run --project . --nologo
```
See each lesson's Run it section for the exact output. All `Lesson.csproj` files are identical; only the `.cs` files change.

## First-timer time
Lesson 07: 40 minutes for one language; 08: 40; 09: 60 in **two sittings**, with the break after Run it (plus the same again if you follow both languages).

## Needs
Python 3.10 or newer and/or .NET SDK 11 (`net11.0`); no package references, test frameworks, databases or servers. Source files use UTF-8 without BOM. `bin/` and `obj/` are build output and are excluded from packs.

Next: End of Design Patterns + SOLID 101. Level 201 of the track covers the catalogue of named design patterns.
