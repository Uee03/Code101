---
track: csharp
level: 101
phase: 2
phase_name: building-blocks
lesson: 05
title: "Loops"
time: 35-40 min
prerequisites: [101.1.04]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-2-building-blocks/05-loops/
assets: []
---

# 05. Loops

## Why it matters
A packing checklist can say "label the next box" once and repeat it for every box. A loop gives a computer the same ability without copying the instruction over and over.

## What you will build
A packing checklist that counts boxes, visits letters in a label, counts down checks and demonstrates skipping and stopping.

## Before you start
- Complete lessons 01 through 04; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-2-building-blocks/05-loops/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson05` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson05`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson05`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson05` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson05`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
A **sequence** is an ordered series of values. A loop **body** is the block of work it repeats. A **loop** repeats a block. An **iteration** is one pass through that block. Use for when a start, condition and update describe the count; foreach to visit each member of a sequence; while to repeat as long as a condition stays true.

A **char** holds one character (normally written in single quotes), unlike a string in double quotes. A string is a sequence of chars, so foreach can visit the letters in BAG before we learn collections in lesson 07.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
for (int box = 1; box <= 3; box++)
{
    Console.WriteLine($"Pack box {box}");
}
foreach (char letter in "BAG")
{
    Console.WriteLine($"Label letter: {letter}");
}
int remaining = 2;
while (remaining > 0)
{
    Console.WriteLine($"Checks left: {remaining}");
    remaining--;
}
for (int number = 1; number <= 6; number++)
{
    if (number == 2)
    {
        continue;
    }
    if (number == 5)
    {
        break;
    }
    Console.WriteLine($"Keep {number}");
}
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson05` (or `source/csharp/101-zero-to-hero/phase-2-building-blocks/05-loops/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson05"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson05"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson05` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Pack box 1
Pack box 2
Pack box 3
Label letter: B
Label letter: A
Label letter: G
Checks left: 2
Checks left: 1
Keep 1
Keep 3
Keep 4
```


## How it works
1. The for header creates box once, checks `box <= 3` before each pass and updates after each pass. `++` increases by one. The semicolons inside the parentheses separate those three jobs; they do not finish the loop body.
2. foreach takes one character from BAG at a time in order. letter is the current item, not an index. The body prints B, then A, then G.
3. while checks remaining before every iteration. `--` subtracts one. Without that update the positive condition would never become false: an **infinite loop**, work that does not reach its stopping condition. If you accidentally create one, click the terminal and press Ctrl+C to interrupt it.
4. The last for loop explores the numbers. **continue** skips the remainder of this iteration, then the loop updates and checks again. It skips 2. **break** exits the nearest loop immediately, so 5 and 6 are not printed. These words belong inside the loop's braces.
5. A variable declared in the for header is available only in the loop. This is an example of scope; lesson 06 gives it a full treatment.

## Try it
Count the even integers in 1 through 6, inclusive. Print only the final count. The `%` remainder operator from lesson 03 can help you recognize even numbers.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-2-building-blocks/05-loops/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise05`**. Do not copy starter *into* an existing exercise05 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise05` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise05; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise05`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise05/Program.cs` (starter)**
```csharp
int count = 0;
// TODO: loop from 1 through 6; count values where number % 2 == 0.
Console.WriteLine($"Even numbers: {count}");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise05"`; macOS/Linux `cd "$HOME/code101/csharp/exercise05"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise05` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Even numbers: 0
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise05/Program.cs` (solution)**
```csharp
int count = 0;
for (int number = 1; number <= 6; number++)
{
    if (number % 2 == 0)
    {
        count++;
    }
}
Console.WriteLine($"Even numbers: {count}");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Even numbers: 3
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. Predict the Keep lines: which of 1 through 6 reach the final WriteLine?
   <details><summary>Answer</summary>Keep 1, Keep 3 and Keep 4. continue skips 2; break exits at 5.</details>
2. What does continue skip?
   <details><summary>Answer</summary>The rest of this iteration, not the entire loop.</details>
3. How does break differ?
   <details><summary>Answer</summary>It exits the nearest loop immediately.</details>
4. Why must remaining decrease?
   <details><summary>Answer</summary>Otherwise the while condition stays true forever.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Checks left: 2` | remaining-- was removed, so this line repeats indefinitely. | Click the terminal and press Ctrl+C; restore remaining-- so the condition eventually becomes false. |
| `Pack box 1` then `Pack box 2` | Only those two box lines print after changing box <= 3 to box < 3. This is an off-by-one mistake (one too few iterations). | Use <= 3 to include box 3. Those are two separate output lines; there is no Pack box 3. |
| `error CS1513: } expected` | The final closing brace of the last for loop was removed. | Match each loop and if brace; indentation alone does not close a block. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Choose a loop with an obvious stopping rule. Use foreach when visiting every item and for when the index or count matters.
Source: Microsoft Learn, Iteration statements https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements

## Next lesson
**[06. Methods](06-methods.md)**: name reusable operations with parameters and results.
