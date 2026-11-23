---
track: csharp
level: 101
phase: 2
phase_name: building-blocks
lesson: 08
title: "Files"
time: 30-40 min
prerequisites: [101.2.07]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-2-building-blocks/08-files/
assets: []
---

# 08. Files

## Why it matters
A notebook preserves your shopping list after you leave the shop. Files let a program preserve text after it stops, instead of keeping everything only in memory.

## What you will build
A tiny pantry file, read back and totalled. CSV means comma-separated values: one row per line and one cell per comma-separated field.

## Before you start
- Complete lessons 01 through 07; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 30-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-2-building-blocks/08-files/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson08` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson08`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson08`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson08` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson08`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
A **path** describes a location. A **relative path** starts from the current folder; an **absolute path** identifies the full location. We combine the current folder, data and pantry.csv with Path.Combine rather than hand-writing platform-specific slashes.

**CSV** means comma-separated values. A **header** is the first row naming columns; a **delimiter** separates fields or rows. Our deliberately small CSV dialect uses header item,quantity, then two simple rows. Fields cannot contain commas, quotes or line breaks. Real CSV allows quoted fields; Split is not a general CSV parser. Write only the shown data here. Lesson 12 validates a similarly restricted format before saving.

Before typing, `\n` inside a string is an **escape sequence**, notation for a newline character; `\r` means a carriage return, used with newline in Windows line endings.

WriteAllText creates a file or replaces its entire contents. Work only in the new practice folder, never on a file you need to keep.

`StringSplitOptions.RemoveEmptyEntries` is an option on an **enum**, a set of named choices: it removes empty entries when splitting text.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string folder = Path.Combine(Directory.GetCurrentDirectory(), "data");
Directory.CreateDirectory(folder);
string path = Path.Combine(folder, "pantry.csv");
string csv = "item,quantity\nRice,3\nSoap,1\n";
File.WriteAllText(path, csv);
Console.WriteLine("Saved data/pantry.csv");
string contents = File.ReadAllText(path);
Console.WriteLine("Read back:");
Console.Write(contents);
string[] lines = contents.Split('\n', StringSplitOptions.RemoveEmptyEntries);
int total = 0;
for (int index = 1; index < lines.Length; index++)
{
    string[] cells = lines[index].Split(',');
    total = total + int.Parse(cells[1]);
}
Console.WriteLine($"Total units: {total}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson08` (or `source/csharp/101-zero-to-hero/phase-2-building-blocks/08-files/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson08"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson08"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson08` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Saved data/pantry.csv
Read back:
item,quantity
Rice,3
Soap,1
Total units: 4
```

After it runs, open data/pantry.csv in VS Code. The generated file is:

**File: `data/pantry.csv` (generated; also printed above)**
```csv
item,quantity
Rice,3
Soap,1
```


## How it works
1. Directory.GetCurrentDirectory gets the terminal's working folder, not necessarily the executable's folder. Directory.CreateDirectory creates data and is safe if it already exists.
2. Path.Combine uses the right separator on the current operating system. We print data/pantry.csv as a readable label, not as the exact Windows absolute path.
3. Backslash-n inside a string is an **escape sequence** representing a new line. File.WriteAllText writes the string and closes the file; File.ReadAllText reads all its text and closes the file. Console.Write does not add another newline, avoiding a blank line after the CSV.
4. Split divides text into an array. Single quotes hold a char delimiter. StringSplitOptions.RemoveEmptyEntries removes empty rows, including the one after the final newline. This is a named option on a built-in **enum**, a set of named choices. You only need the supplied option here.
5. The loop starts at 1 to skip the header. Each row is split at commas. cells[0] is the name and cells[1] the quantity text. Parse converts the quantity, and total accumulates the count.
6. Other applications may write carriage return plus newline instead of just newline. Lesson 12 removes a trailing carriage return when loading. A changed header or malformed row needs validation, not blind indexing.

## Try it
Write shopping.csv in the exercise folder with header item,quantity and rows Bread,2 and Milk,1. Read and print that file. Keep the final newline. This exercise asks for writing and reading, not parsing or totals.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-2-building-blocks/08-files/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise08`**. Do not copy starter *into* an existing exercise08 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise08` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise08; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise08`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise08/Program.cs` (starter)**
```csharp
string path = Path.Combine(Directory.GetCurrentDirectory(), "shopping.csv");
// TODO: write item,quantity header, Bread,2 and Milk,1 rows; then read and print.
Console.WriteLine("TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise08"`; macOS/Linux `cd "$HOME/code101/csharp/exercise08"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise08` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise08/Program.cs` (solution)**
```csharp
string path = Path.Combine(Directory.GetCurrentDirectory(), "shopping.csv");
File.WriteAllText(path, "item,quantity\nBread,2\nMilk,1\n");
Console.Write(File.ReadAllText(path));
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
item,quantity
Bread,2
Milk,1
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. After reading Rice,3 and Soap,1, predict Total units. Does the header add a unit?
   <details><summary>Answer</summary>Total units: 4. The loop starts at 1, skipping the header.</details>
2. Why use Path.Combine?
   <details><summary>Answer</summary>It builds a path with the current platform's separators.</details>
3. Why start parsing at index 1?
   <details><summary>Answer</summary>Index zero contains the header.</details>
4. Can Split handle every legal CSV file?
   <details><summary>Answer</summary>No. Quoted commas and embedded newlines need a real CSV parser.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unhandled exception. System.IO.FileNotFoundException: Could not find file '<project>\missing.csv'.` | ReadAllText(path) was changed to ReadAllText("missing.csv"). | Read the same path that WriteAllText created; check the terminal working folder. |
| `Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.` | The parser was changed from cells[1] to cells[2] on a two-field CSV row. | The quantity is cells[1]; cells[2] is beyond the row. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Use the high-level File text helpers for small files; remember WriteAllText replaces the target, so choose a disposable path and preserve valuable data first.
Source: Microsoft Learn, How to write text to a file https://learn.microsoft.com/dotnet/standard/io/how-to-write-text-to-a-file

## Next lesson
**[09. Handling errors](../phase-3-real-programs/09-handling-errors.md)**: start Phase 3 and recover from input mistakes.
