# C# 101, Phase 1: Foundations

Source pack for lessons 01 to 04 of **C# 101 (Zero to Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-1-foundations/` (Code > Download ZIP, or git clone). Lessons can be followed without downloading anything. No third-party packages or art assets.

| Folder | Lesson | You build |
|---|---|---|
| `01-hello-csharp` | Hello, C# | A console program that prints two lines, then a recipe card of your own. A console program uses text in a terminal rather than buttons in a window. |
| `02-variables-and-types` | Variables and types | A stock label for notebooks. It remembers text, counts, a weight, a price and a yes/no answer, then calculates the stock value. |
| `03-input-and-math` | Input and math | A tip calculator with a bill split and an experiment showing that parsing can fail. This beginner calculator uses double for arithmetic practice; lesson 12 uses decimal for stored money. |
| `04-making-decisions` | Making decisions | A ticket machine that compares ages, combines yes/no answers, chooses one price and uses a switch expression for gate instructions. |

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

**Folder: extracted phase-pack root (contains `01-hello-csharp` and PACK-README.md)**
```text
cd 01-hello-csharp/code
dotnet run --project . --nologo
```

**Folder: all-in-one archive root `csharp-101` (contains `csharp-101-phase-1-foundations`)**
```text
cd csharp-101-phase-1-foundations/01-hello-csharp/code
dotnet run --project . --nologo
```

**Folder: extracted or cloned repository root `Code101` (contains source and tutorials)**
```text
cd source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp/code
dotnet run --project . --nologo
```
See that lesson's Run it section for input and exact output. The project files are identical across lessons; only C# files change. Source files still ship in full even where the text references an identical earlier file.

## First-timer time
Lesson 01: 100-120 minutes; lessons 02-04: 35-40 minutes each. No sign-in or HTTPS certificate is needed. The first-run banner is captured in lesson 01.

## Needs
.NET SDK 11.0.100 / net11.0; no package references, test frameworks, databases or servers. Main and solution outputs were captured on Windows 11 with SDK 11.0.100. macOS/Linux installation routes are documentation-based, not claimed locally tested. Source files use UTF-8 without BOM. bin/ and obj/ are build output excluded from packs; programs create their own practice CSV files where applicable.

Verification scope: smoke only, no dotnet test or xUnit. Lesson 12's tiny plain assertion method runs during normal startup, not in a test runner.

Next: Phase 2, Building blocks (loops, methods, collections and files).

Verified 2026-11-23 on Windows 11, SDK 11.0.100: **4/4 lessons PASS** in this phase; both main and solution smoke steps. Full track: **12 passed, 0 failed, 0 unverified**.
