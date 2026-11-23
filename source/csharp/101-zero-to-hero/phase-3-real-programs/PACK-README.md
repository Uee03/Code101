# C# 101, Phase 3: Real Programs

Source pack for lessons 09 to 12 of **C# 101 (Zero to Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-3-real-programs/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything. No third-party packages or art assets.

| Folder | Lesson | You build |
|---|---|---|
| `09-handling-errors` | Handling errors | A quantity prompt that re-asks with TryParse, plus an optional number read demonstrating try, catch and finally. |
| `10-classes-and-objects` | Classes and objects | Two independent counters, one for tickets and one for drinks. Only the ticket counter increases. |
| `11-null-safety-and-records` | Null safety and records | An optional note, two equal receipt records and a revised copy (text and amount only). |
| `12-expense-tracker` | Project: expense tracker | An expense tracker with a menu, a List of Expense records, restricted CSV persistence and a tiny in-memory self-check using a plain Assert method. This is a learning project, not accounting software. Use invented expenses and a disposable folder; it has no backups, atomic saves, currency conversion or audit history. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| code/ | The finished project from Steps. Type it yourself first; use this to compare. |
| exercise/starter/ | Starting project with TODO markers. |
| exercise/solution/ | Complete answer project; try before you look. |
| verify.json | Maintainer smoke check; runs the example once and the solution once in clean folders. |

## How to run any program
1. Install .NET SDK 11.0.100 (or a later 11.0.1xx servicing patch) and an editor using lesson 01. The SDK includes the runtime. These projects target net11.0; global.json pins the SDK feature band with latestPatch roll-forward. Official support decision checked 2026-11-23: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core . Keep servicing updates installed.
2. Windows: right-click the zip, Extract All, Extract. macOS: double-click the zip. Linux: use Extract Here in the file manager, or unzip the zip in its download folder. The extracted root has the zip's name without .zip. In the all-phases zip, first open the matching phase folder under csharp-101.
3. Open a terminal in a lesson's code folder (the folder containing Lesson.csproj). On Windows use PowerShell; on macOS/Linux use Terminal. Paths with spaces need quotes. The same dotnet command works on each OS. Per-user Linux installs may require the two export lines from lesson 01 in each new terminal.
4. Run dotnet run --project . --nologo. For interactive examples type answers and press Enter after each. Follow the lesson's Run it section for exact small input and captured output.
5. For an exercise, copy the `starter` folder into your own `~/code101/csharp`, then rename the copy `exerciseNN` (use the lesson number). Do not put starter inside a pre-created exerciseNN folder. Open the renamed folder. Edit Program.cs and run the same command there. Do not mix exercise and main files: all .cs files beneath one project are compiled together. Save before running. Never copy bin or obj.

## Exact starting folders
Choose **one** example, not all three. Commands work in PowerShell and Bash.

**Folder: extracted phase-pack root (contains `09-handling-errors` and PACK-README.md)**
```text
cd 09-handling-errors/code
dotnet run --project . --nologo
```

**Folder: all-in-one archive root `csharp-101` (contains `csharp-101-phase-3-real-programs`)**
```text
cd csharp-101-phase-3-real-programs/09-handling-errors/code
dotnet run --project . --nologo
```

**Folder: extracted or cloned repository root `Code101` (contains source and tutorials)**
```text
cd source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors/code
dotnet run --project . --nologo
```
See that lesson's Run it section for input and exact output. The project files are identical across lessons; only C# files change. Source files still ship in full even where the text references an identical earlier file.

## First-timer time
Lesson 09: 35-45 minutes; 10: 45-55; 11: 40-50; 12: 90-120 in **two sittings**, break after Run it. The project skips blank CRLF CSV rows; use only disposable practice data.

## Needs
.NET SDK 11.0.100 / net11.0; no package references, test frameworks, databases or servers. Main and solution outputs were captured on Windows 11 with SDK 11.0.100. macOS/Linux installation routes are documentation-based, not claimed locally tested. Source files use UTF-8 without BOM. bin/ and obj/ are build output excluded from packs; programs create their own practice CSV files where applicable.

Verification scope: smoke only, no dotnet test or xUnit. Lesson 12's tiny plain assertion method runs during normal startup, not in a test runner.

Next: End of C# 101. Keep practice data separate from real financial records.

Verified 2026-11-23 on Windows 11, SDK 11.0.100: **4/4 lessons PASS** in this phase; both main and solution smoke steps. Full track: **12 passed, 0 failed, 0 unverified**.
