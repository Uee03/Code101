---
track: csharp
level: 101
phase: 3
phase_name: real-programs
lesson: 11
title: "Null safety and records"
time: 40-50 min
prerequisites: [101.3.10]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records/
assets: []
---

# 11. Null safety and records

## Why it matters
A receipt may have an empty notes box without the receipt itself being missing. Null safety makes missing information explicit; records describe bundles of values such as receipts.

## What you will build
An optional note, two equal receipt records and a revised copy. The example uses only text and a number.

## Before you start
- Complete lessons 01 through 10; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 40-50 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson11` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson11`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson11`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson11` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson11`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
Focus on five connected ideas: a possibly absent value, safe access, a record, a changed copy, and comparing record values.

A **reference type** holds a reference (a way to reach a stored value); classes and record classes are examples. A **nullable reference type** permits null: `string?` says text may be absent, while `string` says it should be present. Nullable checking produces compiler warnings, not automatic runtime protection. The `??` fallback was introduced in lesson 03. The **null-conditional operator** `?.` reads a property only when the value is present; otherwise it gives null.

A **record** describes related data. `Receipt(string Description, decimal Amount)` supplies a constructor and readable properties named Description and Amount: the type comes first, then its name. `with` makes a **non-destructive copy**, keeping the original unchanged. `==` compares the data values (**value equality**), so separately created receipts can compare equal. Our record contains only text and a number; mutable nested data and record implementation details are outside this lesson.

### Step 5. Create Receipt.cs
In VS Code Explorer choose **New File**. Put `Receipt.cs` directly beside Lesson.csproj, not inside bin or obj. Paste or type all the following, then save. This defines a type used by the main program.

**File: `Receipt.cs`**
```csharp
public record Receipt(string Description, decimal Amount);
```

### Step 6. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string? note = null;
Console.WriteLine($"Note: {note ?? "(none)"}");
Console.WriteLine($"Note length: {note?.Length ?? 0}");
Receipt original = new Receipt("Lunch", 12.50m);
Receipt same = new Receipt("Lunch", 12.50m);
Receipt revised = original with { Amount = 13.00m };
Console.WriteLine($"Same values: {original == same}");
Console.WriteLine($"Original: {original.Amount:F2}; revised: {revised.Amount:F2}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson11` (or `source/csharp/101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson11"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson11"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson11` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Note: (none)
Note length: 0
Same values: True
Original: 12.50; revised: 13.00
```


## How it works
1. `string? note = null` states that the note is absent, not an empty string. `??` gives the display fallback `(none)`.
2. `note?.Length` does not read Length on a missing note. Its null result becomes 0 through `?? 0`.
3. Receipt.cs supplies the data shape. The two constructor arguments fill Description and Amount in that order.
4. original and same hold matching values, so `==` returns true. `original with { Amount = 13.00m }` creates a revised receipt, copying Description and replacing Amount; original still holds 12.50.
5. A compiler warning is advice, not a runtime fix. Keep safe access or a fallback instead of ignoring a warning about null.

## Try it
Print an optional contact email using (no email) as fallback. Then create an updated record with ada@example.test and print the updated contact. Leave the original contact unchanged.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-3-real-programs/11-null-safety-and-records/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise11`**. Do not copy starter *into* an existing exercise11 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise11` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise11; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise11`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise11/Contact.cs` (starter)**
```csharp
public record Contact(string Name, string? Email);
```

**File: `~/code101/csharp/exercise11/Program.cs` (starter)**
```csharp
string? email = null;
Contact person = new Contact("Ada", email);
// TODO: print Ada: (no email), then copy person with Email = "ada@example.test".
Console.WriteLine("TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise11"`; macOS/Linux `cd "$HOME/code101/csharp/exercise11"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise11` (terminal)**
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

Keep `Contact.cs` identical to the starter above; only Program.cs changes.

**File: `~/code101/csharp/exercise11/Program.cs` (solution)**
```csharp
string? email = null;
Contact person = new Contact("Ada", email);
Console.WriteLine($"{person.Name}: {person.Email ?? "(no email)"}");
Contact updated = person with { Email = "ada@example.test" };
Console.WriteLine($"{updated.Name}: {updated.Email}");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Ada: (no email)
Ada: ada@example.test
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. After the with copy changes Amount to 13.00, predict the Original and revised amounts.
   <details><summary>Answer</summary>Original: 12.50; revised: 13.00. The copy leaves original unchanged.</details>
2. What does ?. do for null?
   <details><summary>Answer</summary>It skips member access and yields null.</details>
3. Why do separately constructed receipts compare equal?
   <details><summary>Answer</summary>Record equality compares data values.</details>
4. Does with modify original?
   <details><summary>Answer</summary>No. It creates a copy with the requested changes; here its values are text and a number.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `warning CS8602: Dereference of a possibly null reference.` | note?.Length ?? 0 was replaced with note.Length while note is null. | Keep ?. with a fallback. The warning allows the build, but the unsafe program will crash. |
| `Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.` | The same unsafe note.Length read executed after Note: (none). | Use safe access; a warning does not supply a missing value. |
| `error CS1002: ; expected` | The final WriteLine lost its semicolon. | Restore the semicolon and save. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

The CS8602 row is a **warning**: the build succeeds, prints `Note: (none)`, then the unsafe read crashes with NullReferenceException. Fix the warning before running again.

## Best practice
Enable nullable analysis and fix warnings by modelling missing values honestly and checking before access. Suppressing a warning does not prevent a null-reference exception.
Source: Microsoft Learn, Nullable reference types https://learn.microsoft.com/dotnet/csharp/nullable-references

## Next lesson
**[12. Project: expense tracker](12-expense-tracker.md)**: combine the building blocks into a saved expense tracker.
