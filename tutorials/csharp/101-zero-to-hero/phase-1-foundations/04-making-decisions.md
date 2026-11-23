---
track: csharp
level: 101
phase: 1
phase_name: foundations
lesson: 04
title: "Making decisions"
time: 35-40 min
prerequisites: [101.1.03]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-1-foundations/04-making-decisions/
assets: []
---

# 04. Making decisions

## Why it matters
A ticket clerk follows a price card: small children go free, older children pay less and adults pay the standard fare. Conditions let a program follow ordered rules like these.

## What you will build
A ticket machine that compares ages, combines yes/no answers, chooses one price and uses a switch expression for gate instructions.

## Before you start
- Complete lessons 01 through 03; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-1-foundations/04-making-decisions/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson04` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson04`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson04`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson04` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson04`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
A **comparison** asks a yes/no question. `==` means equal, `!=` not equal, `<` less, `>` greater, `<=` at most and `>=` at least. A **boolean expression** produces true or false. A **condition** is a boolean expression used to choose work.

&& means both sides must be true. || means at least one must be true. ! flips true to false or false to true. C# uses **short-circuit evaluation**: with && a false left side skips the right; with || a true left side skips the right. Parentheses group conditions.

A **switch expression** selects a value. Each **arm** is one pattern/result pair; a **pattern** describes what to match (`true` or `false` here). `=>` separates the match from its result.

The full file includes both comparisons and the price card. Do not copy just an else fragment into an empty file. We fix hasTicket to true so you can focus on the price rules.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
Console.WriteLine("Age (whole number):");
int age = int.Parse(Console.ReadLine() ?? "");
bool hasTicket = true;
Console.WriteLine($"Adult with ticket: {age >= 18 && hasTicket}");
Console.WriteLine($"Child or has ticket: {age < 18 || hasTicket}");
Console.WriteLine($"No ticket: {!hasTicket}");
Console.WriteLine($"Exactly 18: {age == 18}; not 18: {age != 18}");
Console.WriteLine($"At most 65: {age <= 65}; over 65: {age > 65}");
if (age < 0)
{
    Console.WriteLine("Age cannot be negative.");
}
else if (age < 5)
{
    Console.WriteLine("Ticket: free");
}
else if (age < 18)
{
    Console.WriteLine("Ticket: child price, 5.00");
}
else if (age < 65)
{
    Console.WriteLine("Ticket: adult price, 10.00");
}
else
{
    Console.WriteLine("Ticket: senior price, 7.00");
}
string lane = hasTicket switch
{
    true => "Go to the gate",
    false => "Buy a ticket"
};
Console.WriteLine(lane);
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson04` (or `source/csharp/101-zero-to-hero/phase-1-foundations/04-making-decisions/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson04"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson04"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson04` (terminal)**
```powershell
dotnet run --project . --nologo
```
Type these lines **as answers to the prompts**, pressing Enter after each, not as shell commands:

**Keyboard input**
```text
30
```
Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Age (whole number):
Adult with ticket: True
Child or has ticket: True
No ticket: False
Exactly 18: False; not 18: True
At most 65: True; over 65: False
Ticket: adult price, 10.00
Go to the gate
```


## How it works
1. Read and parse age using lesson 03's pattern. The printed comparisons are independent experiments; their results do not change hasTicket.
2. if checks negative ages before the free-ticket age. An **if/else chain** chooses the first true **branch**, one possible path through the instructions.
3. Braces enclose a **block**, a group of statements. **Indentation**, spaces at the start of a line, makes a block easier to read; braces, not indentation, determine membership in C#.
4. else if tries another condition only if earlier ones were false. else catches the remaining case. For age 30, negative, under 5 and under 18 all fail, then under 65 succeeds; the senior branch is skipped. Order matters: a child of 3 also satisfies under 18, but the free branch wins first.
5. A **switch expression** selects a value from alternatives. Here true maps to Go to the gate and false maps to Buy a ticket. `=>` separates each pattern (value to match here) from its result. Commas separate arms; the assignment ends in a semicolon. This is a value-producing expression, unlike the statement blocks above.

## Try it
Read a score from 0 to 100. Check invalid scores first (below 0 OR above 100), then Fail below 50, Pass below 75, otherwise Merit. Use if/else if/else blocks. The captured exercise run uses 90.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-1-foundations/04-making-decisions/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise04`**. Do not copy starter *into* an existing exercise04 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise04` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise04; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise04`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise04/Program.cs` (starter)**
```csharp
Console.WriteLine("Score (0-100):");
int score = int.Parse(Console.ReadLine() ?? "");
// TODO: invalid first, then Fail below 50, Pass below 75, otherwise Merit.
Console.WriteLine("TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise04"`; macOS/Linux `cd "$HOME/code101/csharp/exercise04"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise04` (terminal)**
```powershell
dotnet run --project . --nologo
```
For the shown solution run, enter these lines when prompted:

**Exercise keyboard input**
```text
90
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Score (0-100):
TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise04/Program.cs` (solution)**
```csharp
Console.WriteLine("Score (0-100):");
int score = int.Parse(Console.ReadLine() ?? "");
if (score < 0 || score > 100)
{
    Console.WriteLine("Invalid score");
}
else if (score < 50)
{
    Console.WriteLine("Fail");
}
else if (score < 75)
{
    Console.WriteLine("Pass");
}
else
{
    Console.WriteLine("Merit");
}
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Score (0-100):
Merit
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. For the sample age 30, which Ticket line prints, and why does the senior line not print?
   <details><summary>Answer</summary>Ticket: adult price, 10.00. The age-under-65 branch wins and the rest of the chain is skipped.</details>
2. What is !true?
   <details><summary>Answer</summary>false.</details>
3. Why check negative ages first?
   <details><summary>Answer</summary>Otherwise they also match under 5 and get a free ticket.</details>
4. What does a switch expression produce?
   <details><summary>Answer</summary>A value selected from its matching arm.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0029: Cannot implicitly convert type 'int' to 'bool'` | The condition became else if (age = 5), assigning an int. | Use == to compare; the condition must produce bool. |
| `error CS1513: } expected` | The closing brace before string lane was removed. | Match every opening brace with its closing brace; the compiler may point at the end of the file. |
| `Unhandled exception. System.FormatException: The input string 'ten' was not in a correct format.` | The age input was ten. | Enter digits; lesson 09 shows a retry loop for invalid text. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Keep alternatives in one if/else chain when only one branch should run; use a switch expression when selecting a value makes alternatives clearer.
Source: Microsoft Learn, Selection statements https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements

## Next lesson
**[05. Loops](../phase-2-building-blocks/05-loops.md)**: start Phase 2 and repeat work with loops.
