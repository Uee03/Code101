# C# 101 verification evidence

2026-11-23, Windows 11, .NET SDK 11.0.100, net11.0. Smoke only: no test suites, linters or benchmarks.

## Final verifier capture

From the repository root, after the revised lesson text and generated project manifests existed:

```powershell
python scripts\verify_labs.py source/csharp/
```

```text
[PASS      ] source/csharp/101-zero-to-hero/phase-1-foundations/01-hello-csharp
[PASS      ] source/csharp/101-zero-to-hero/phase-1-foundations/02-variables-and-types
[PASS      ] source/csharp/101-zero-to-hero/phase-1-foundations/03-input-and-math
[PASS      ] source/csharp/101-zero-to-hero/phase-1-foundations/04-making-decisions
[PASS      ] source/csharp/101-zero-to-hero/phase-2-building-blocks/05-loops
[PASS      ] source/csharp/101-zero-to-hero/phase-2-building-blocks/06-methods
[PASS      ] source/csharp/101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries
[PASS      ] source/csharp/101-zero-to-hero/phase-2-building-blocks/08-files
[PASS      ] source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors
[PASS      ] source/csharp/101-zero-to-hero/phase-3-real-programs/10-classes-and-objects
[PASS      ] source/csharp/101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records
[PASS      ] source/csharp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker

12 passed, 0 failed, 0 unverified (missing tools)
```

Each verify.json requires dotnet and runs the finished project and solution once with small input. Lessons 02-12 skip only code/global.json and code/Lesson.csproj text matching because those files are byte-identical to lesson 01 and are referenced explicitly; no C# code is exempted. All 36 main/starter/solution projects were also run in clean temporary copies before their source/output was copied into the lessons.

## Literal Windows walkthroughs

Created a temporary learner home; ran the PowerShell folder commands from lesson 01 verbatim, then reused them with the named lesson12/exercise12 folder substitutions. Tool installation was not repeated (SDK already present). Created files from lesson Markdown, not source/code. Lesson 01 generated its project, ran the unmodified greeting, then the finished program. Lesson 12 copied only the identical project settings from that learner's lesson01 folder, typed its two C# files from Markdown, and ran the menu/save sample. The exercise reconstructed the referenced identical helpers and replaced only the shown top-level region; both starter and solution ran. All temporary folders removed.

### lesson01-folder

```text
(no output)
```

### lesson01-new

```text
The template "Console App" was created successfully.
```

### lesson01-generated-run

```text
Hello, World!
```

### lesson01-finished-run

```text
Hello, C#!
I can run a program.
```

### lesson12-folder

```text
(no output)
```

### lesson12-finished-run

```text
Self-check passed.
Loaded: 0
1 Add | 2 List | 3 Save | 0 Exit
Description (no commas):
Amount (positive, dot for decimals):
Added.
1 Add | 2 List | 3 Save | 0 Exit
Tea: 2.50
Total: 2.50
1 Add | 2 List | 3 Save | 0 Exit
Saved expenses.csv
1 Add | 2 List | 3 Save | 0 Exit
Bye (only saved changes are kept).
```

### exercise12-folder

```text
(no output)
```

### exercise12-starter

```text
Self-check passed.
Loaded: 0
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Choose 1, 2, 3, 4 or 0.
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Bye (only saved changes are kept).
```

### exercise12-solution

```text
Self-check passed.
Loaded: 0
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Description (no commas):
Amount (positive, dot for decimals):
Added.
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Total: 2.50
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Saved expenses.csv
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Bye (only saved changes are kept).
```

## Fresh-home first-run banner

Ran dotnet new console in a disposable folder with DOTNET_CLI_HOME set to that temporary home and DOTNET_NOLOGO unset. DOTNET_GENERATE_ASPNET_CERTIFICATE=false and DOTNET_ADD_GLOBAL_TOOLS_TO_PATH=false were set for the child process only. Telemetry opt-out was unset for this capture so its real paragraph appears. No HTTPS certificate was created, trusted or cleaned; no user-level setting changed. The certificate-installation notice is absent by design; the lesson explains why no certificate or trust action is needed.

```text

Welcome to .NET 11.0!
---------------------
SDK Version: 11.0.100

Telemetry
---------
The .NET tools collect usage data in order to help us improve your experience. It is collected by Microsoft and shared with the community. You can opt-out of telemetry by setting the DOTNET_CLI_TELEMETRY_OPTOUT environment variable to '1' or 'true' using your favorite shell.

Read more about .NET CLI Tools telemetry: https://aka.ms/dotnet-cli-telemetry

----------------
Write your first app: https://aka.ms/dotnet-hello-world
Find out what's new: https://aka.ms/dotnet-whats-new
Explore documentation: https://aka.ms/dotnet-docs
Report issues and find source on GitHub: https://github.com/dotnet/core
Use 'dotnet --help' to see available commands or visit: https://aka.ms/dotnet-cli
--------------------------------------------------------------------------------------
The template "Console App" was created successfully.
```

## Mistake reproductions against the actual lesson projects

Every case starts from the named lesson's own code or exercise solution in a disposable copy, not an unrelated scratch program. Triggers and fixes are in each Common mistakes table. Compiler paths/positions are removed; local paths become <project>. Exception stack frames are omitted in these excerpts. Setup uses an empty PATH in a child PowerShell and a temporary incompatible global.json; the original pin is never changed. The missing-decrement run captures two repeated lines, then stops only that executable's captured PID with Stop-Process -Id; the learner's interactive recovery is Ctrl+C.

### 01-semicolon

```text
error CS1002: ; expected

The build failed. Fix the build errors and run again.
```

### 01-capitalization

```text
error CS0103: The name 'console' does not exist in the current context

The build failed. Fix the build errors and run again.
```

### 02-type

```text
error CS0029: Cannot implicitly convert type 'string' to 'int'

The build failed. Fix the build errors and run again.
```

### 02-semicolon

```text
error CS1002: ; expected

The build failed. Fix the build errors and run again.
```

### 03-currency

```text
People (whole number):
Bill (use a dot):
Unhandled exception. System.FormatException: The input string '$80' was not in a correct format.
```

### 03-percent

```text
People (whole number):
Bill (use a dot):
Tip percent (number only):
Unhandled exception. System.FormatException: The input string '15%' was not in a correct format.
```

### 03-word

```text
People (whole number):
Unhandled exception. System.FormatException: The input string 'ten' was not in a correct format.
```

### 03-overflow

```text
People (whole number):
Unhandled exception. System.OverflowException: Value was either too large or too small for an Int32.
```

### 03-zero

```text
Bill (use a dot):
People (positive whole number):
Share: Infinity
```

### 04-condition

```text
error CS0029: Cannot implicitly convert type 'int' to 'bool'

The build failed. Fix the build errors and run again.
```

### 04-brace

```text
error CS1513: } expected

The build failed. Fix the build errors and run again.
```

### 04-word

```text
Age (whole number):
Unhandled exception. System.FormatException: The input string 'ten' was not in a correct format.
```

### 05-offbyone

```text
Pack box 1
Pack box 2
Label letter: B
Label letter: A
Label letter: G
Checks left: 2
Checks left: 1
Keep 1
Keep 3
Keep 4
```

### 05-brace

```text
error CS1513: } expected

The build failed. Fix the build errors and run again.
```

### 06-scope

```text
error CS0103: The name 'result' does not exist in the current context

The build failed. Fix the build errors and run again.
```

### 06-unused

```text
warning CS8321: The local function 'Area' is declared but never used
Kitchen: 2.00 litres
```

### 06-semicolon

```text
error CS1002: ; expected

The build failed. Fix the build errors and run again.
```

### 07-index

```text
Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.
```

### 07-key

```text
First shelf: Top; shelf count: 2
Second shelf: Middle
Items: 2
Rice
Soap
Rice in stock: 3
Unhandled exception. System.Collections.Generic.KeyNotFoundException: The given key 'Tea' was not present in the dictionary.
```

### 08-missingfile

```text
Saved data/pantry.csv
Unhandled exception. System.IO.FileNotFoundException: Could not find file '<project>\missing.csv'.
File name: '<project>\missing.csv'
```

### 08-index

```text
Saved data/pantry.csv
Read back:
item,quantity
Rice,3
Soap,1
Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.
```

### 09-unassigned

```text
error CS0165: Use of unassigned local variable 'quantity'

The build failed. Fix the build errors and run again.
```

### 09-brace

```text
error CS1513: } expected

The build failed. Fix the build errors and run again.
```

### 09-friendly

```text
Quantity (positive whole number):
Please enter a positive whole number:
Optional number (try a word):
That whole number is too large or too small.
Finished the optional-number step.
Accepted: 3
```

### 10-private

```text
error CS0122: 'Counter.count' is inaccessible due to its protection level

The build failed. Fix the build errors and run again.
```

### 10-capitalization

```text
error CS0103: The name 'console' does not exist in the current context

The build failed. Fix the build errors and run again.
```

### 11-null

```text
warning CS8602: Dereference of a possibly null reference.
Note: (none)
Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.
```

### 11-semicolon

```text
error CS1002: ; expected

The build failed. Fix the build errors and run again.
```

### 12-input

```text
Self-check passed.
Loaded: 0
1 Add | 2 List | 3 Save | 0 Exit
Choose 1, 2, 3 or 0.
Description (no commas):
Use a nonempty description without commas or line breaks.
Amount (positive, dot for decimals):
Invalid amount; nothing added.
Bye (only saved changes are kept).
```

### 12-csv

```text
Self-check passed.
Skipped invalid CSV row 3.
Loaded: 1
1 Add | 2 List | 3 Save | 0 Exit
Bye (only saved changes are kept).
```

### 01-wrongfolder

```text
Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.
```

### 01-sdk

```text
The command could not be loaded, possibly because:
  * You intended to execute a .NET application:
      The application 'run' does not exist or is not a managed .dll or .exe.
  * You intended to execute a .NET SDK command:
      A compatible .NET SDK was not found.

Requested SDK version: 11.0.200
global.json file: <project>\global.json

Installed SDKs:

Install the [11.0.200] .NET SDK or update [<project>\global.json] to match an installed SDK.

Learn about SDK resolution:
https://aka.ms/dotnet/sdk-not-found
11.0.100 [C:\Program Files\dotnet\sdk]
```

### 01-path

```text
dotnet : The term 'dotnet' is not recognized as the name of a cmdlet, function, script file, or operable program. 
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ dotnet --version
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (dotnet:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

### 05-infinite

```text
Pack box 1
Pack box 2
Pack box 3
Label letter: B
Label letter: A
Label letter: G
Checks left: 2
Checks left: 2
```

## Scope, audit and review resolution

- Windows execution only. macOS/Linux install instructions remain documentation-based. The current .NET 11 download page was fetched; VS Code and CLI environment-variable docs refresh failed twice through the proxy and were not retried further.
- Small intentional mistake reproductions are diagnostic captures, not a test suite. Main and solution verifier runs remain one small input each. No servers, certificates, global tools, machine PATH changes or user settings were created/changed.
- Source snippets were compared with source files, including exact reconstruction of lesson 12's referenced helpers. Template order, consecutive steps, local links, standard optional-source wording, skip lists and UTF-8 without BOM checked.
- All 20 Should-fix findings addressed; 16 actionable Nits fixed. Two Nit-labelled positive observations (lesson 10's two-file/private-access behavior and lesson 12's already-working happy/invalid-input paths) retained and rechecked, not invented changes. See [_WALKTHROUGH-FIXES.md](_WALKTHROUGH-FIXES.md).
- Phase READMEs distinguish phase zip, all-in-one archive and repository roots, and explain exact starter-folder copying. Pack command/results are recorded in [_STATE.md](_STATE.md).

Final archive audit: all four ZIPs have correct lesson counts, no build output, and sizes below 25 MB. Verified every README cd path against its actual phase archive, all-in-one archive and repository layout; all passed.
