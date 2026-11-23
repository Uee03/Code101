---
track: csharp
level: 101
phase: 2
phase_name: building-blocks
lesson: 07
title: "Arrays, lists and dictionaries"
time: 40-50 min
prerequisites: [101.2.06]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries/
assets: []
---

# 07. Arrays, lists and dictionaries

## Why it matters
A row of numbered lockers, an expandable shopping list and an address book organise things differently. Arrays, lists and dictionaries are the corresponding tools for organising values.

## What you will build
A pantry inventory with two fixed shelves, an editable shopping list and a lookup from item names to stock counts.

## Before you start
- Complete lessons 01 through 06; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 40-50 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson07` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson07`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson07`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson07` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson07`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
A **collection** groups values. An **array** has a fixed length; an **index** is an item's numbered position, starting at zero. A **list** can grow and shrink. A **dictionary** maps a unique key to a value, like a name to a count.

Use shelves for the fixed array, items for the growable list, and stock for keyed lookup. A **key** is the label used to find an entry. For now read `List<string>` as "list of text" and `Dictionary<string, int>` as "text keys to whole-number values"; the angle brackets specify what each holds. The word **generic** means a type design that accepts these chosen types. A **constructor**, called with `new`, creates a ready-to-use value; lesson 10 teaches our own. Focus only on choosing and using the three containers.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
string[] shelves = { "Top", "Bottom" };
Console.WriteLine($"First shelf: {shelves[0]}; shelf count: {shelves.Length}");
shelves[1] = "Middle";
Console.WriteLine($"Second shelf: {shelves[1]}");
List<string> items = new List<string> { "Rice", "Tea" };
items.Add("Soap");
items.Remove("Tea");
Console.WriteLine($"Items: {items.Count}");
foreach (string item in items)
{
    Console.WriteLine(item);
}
Dictionary<string, int> stock = new Dictionary<string, int>();
stock["Rice"] = 2;
stock["Rice"] = stock["Rice"] + 1;
stock["Soap"] = 1;
if (stock.TryGetValue("Rice", out int rice))
{
    Console.WriteLine($"Rice in stock: {rice}");
}
if (!stock.TryGetValue("Tea", out int tea))
{
    Console.WriteLine("Tea has no entry.");
}
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson07` (or `source/csharp/101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson07"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson07"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson07` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
First shelf: Top; shelf count: 2
Second shelf: Middle
Items: 2
Rice
Soap
Rice in stock: 3
Tea has no entry.
```


## How it works
1. `string[]` declares an array of strings. Braces provide its initial elements. With two elements, valid indexes are 0 and 1, never 2. Length is two; changing shelves[1] replaces a value without changing the array's length. The next print confirms `Second shelf: Middle`.
2. `new List<string>` creates the list; the braces supply its starting items.
3. Add appends Soap; Remove removes Tea if found. Count reports the current number of list elements (arrays use Length). foreach visits Rice then Soap in list order.
4. new Dictionary starts an empty dictionary. Assigning with a new key adds an entry; assigning with an existing key replaces its value. Reading stock["Rice"] is safe here because we just added that key.
5. TryGetValue returns true and supplies a value when the key exists. It returns false for a missing key, avoiding an exception. The `!` from lesson 04 reverses that bool: the Tea branch runs because lookup failed.
6. The exercise only needs a dictionary; you do not have to force all three collection types into every program.

## Try it
The supplied score board gives Ada three points. Increase her score by two, then display it after a safe lookup. Use a string key and an int value.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-2-building-blocks/07-arrays-lists-and-dictionaries/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise07`**. Do not copy starter *into* an existing exercise07 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise07` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise07; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise07`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise07/Program.cs` (starter)**
```csharp
Dictionary<string, int> scores = new Dictionary<string, int>();
scores["Ada"] = 3;
// TODO: add 2 to Ada's score and print it using TryGetValue.
Console.WriteLine("Ada: TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise07"`; macOS/Linux `cd "$HOME/code101/csharp/exercise07"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise07` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Ada: TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise07/Program.cs` (solution)**
```csharp
Dictionary<string, int> scores = new Dictionary<string, int>();
scores["Ada"] = 3;
scores["Ada"] = scores["Ada"] + 2;
if (scores.TryGetValue("Ada", out int score))
{
    Console.WriteLine($"Ada: {score}");
}
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Ada: 5
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. After shelves[1] is changed, what do the second-shelf line and the earlier shelf-count line say?
   <details><summary>Answer</summary>Second shelf: Middle; the earlier shelf count is 2. Replacing an element does not grow the array.</details>
2. Can an array grow by assignment?
   <details><summary>Answer</summary>No. Use List for a growable sequence.</details>
3. How do Length and Count differ here?
   <details><summary>Answer</summary>Arrays expose Length; List and Dictionary expose Count.</details>
4. What if TryGetValue cannot find a key?
   <details><summary>Answer</summary>It returns false; in this string-to-int dictionary the out value is 0.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.` | shelves[0] was changed to shelves[2] in this two-element array. | Use index 0 or 1; the length is 2. |
| `Unhandled exception. System.Collections.Generic.KeyNotFoundException: The given key 'Tea' was not present in the dictionary.` | The Tea branch tried Console.WriteLine(stock["Tea"]) when no such entry exists. | Use TryGetValue for a key that may be absent; do not read stock["Tea"] after lookup failed. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Choose a collection based on its job: fixed-size ordered values, a growable sequence or keyed lookup. Use TryGetValue when a dictionary key may be absent.
Source: Microsoft Learn, Collections https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/collections

## Next lesson
**[08. Files](08-files.md)**: keep small amounts of data after a program exits.
