# C# 301, Phase 1: Architecture

Source pack for lessons 01 to 03 of **C# 301 (Super Hero to Legendary)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-1-architecture/` (Code > Download ZIP, or git clone). Every file is also shown in full in the lesson, so you can follow without downloading anything.

**Status: written (not run).** The code and expected outputs were prepared by reading the code and the official documentation; they have not been executed yet. If your tool prints something different, trust it and report it.

| Folder | Lesson | You build |
|---|---|---|
| `01-clean-architecture-and-vertical-slices` | Clean architecture and vertical slices | `Orders.Domain` (no references) and `Orders.Api` (FastEndpoints, one folder per slice); exercise: a third slice, `ListOrders`. |
| `02-cqrs-without-ceremony` | CQRS without ceremony | A stock ledger with command and query handler interfaces and a logging decorator; exercise: a `ListOutOfStock` query. |
| `03-domain-driven-design-essentials` | Domain-driven design essentials | A `Money` value object, an `Order` aggregate with invariants and domain events; exercise: a `Sku` value object. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project that the lesson's Steps build. Type it yourself first; use this to compare. |
| `exercise/starter/` | Files to start the exercise from, with TODO markers: a few files that you add to (or use to replace files in) a copy of your finished lesson folder; the lesson says which. |
| `exercise/solution/` | The answer. Try the exercise before you look. |
| `verify.json` | Maintainer check data (commands and expected output). Not needed to follow the lesson. |

## How to run
1. Install the .NET SDK **11.0.100** (any later 11.0.1xx patch works with the `rollForward` setting). Lesson 01 of C# 101 explains installation. Each project targets `net11.0`; `code/global.json` (lesson 01) pins the SDK.
2. Unzip the pack (Windows: right-click, Extract All; macOS: double-click; Linux: `unzip`).
3. Open a terminal in the lesson's `code` folder and follow the lesson's **Run it** section. Lesson 01 uses `dotnet build src/Orders.Api`, then `dotnet run --project src/Orders.Api --no-build`, and `curl` against `http://127.0.0.1:5301`. Lessons 02 and 03 use `dotnet run --project . --nologo`.
4. For an exercise, copy your finished lesson folder, add or replace the starter files in the copy, and run the same command there. Never copy `bin` or `obj`.

## Needs
.NET SDK 11.0.100 / net11.0; lesson 01 needs the NuGet package FastEndpoints 9.0.0 (internet access for the first restore) and `curl`. Lessons 02 and 03 have no packages. No Docker, no databases. No lockfile is included: the first `dotnet restore` can create one if you enable it (lesson 10).

## First-timer time
Lesson 01: 70-90 minutes; 02: 60-80; 03: 70-90, each including the exercise.

Next: Phase 2, Performance.
