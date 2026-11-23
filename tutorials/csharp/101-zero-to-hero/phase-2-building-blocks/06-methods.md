---
track: csharp
level: 101
phase: 2
phase_name: building-blocks
lesson: 06
title: "Methods"
time: 35-40 min
prerequisites: [101.2.05]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-2-building-blocks/06-methods/
assets: []
---

# 06. Methods

## Why it matters
A recipe can refer to a smaller recipe for sauce. Methods do the same for programs: name one useful operation, give it ingredients and optionally get a result back.

## What you will build
A paint estimate: one method calculates a rectangular area and another prints the litres needed for a named room.

## Before you start
- Complete lessons 01 through 05; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-2-building-blocks/06-methods/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson06` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson06`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson06`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson06` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson06`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
The room is **3 metres wide and 4 metres long**. One litre covers **6 square metres**, so `roomArea / 6` gives the litres needed. Area receives width and height and returns their product. PrintEstimate receives a room name and litres, then prints a line; it has no value to return.

A **call** starts a method; the **caller** is the code making that call. A method's **body** is its block of instructions. A **parameter** names an input in the definition; an **argument** is the actual value at a call. A **return value** is the result passed back to the caller. **Scope** is where a name can be used: a **local variable** belongs to its own block or method. **void** means the method returns no value.

Write `static` before these helper methods for now. It keeps their inputs explicit: they cannot read variables declared in the surrounding top-level instructions. Lesson 10 contrasts these helpers with methods attached to an object.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
double roomArea = Area(3, 4);
double paintLitres = roomArea / 6;
PrintEstimate("Kitchen", paintLitres);

static double Area(double width, double height)
{
    double result = width * height;
    return result;
}

static void PrintEstimate(string room, double litres)
{
    Console.WriteLine($"{room}: {litres:F2} litres");
}
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson06` (or `source/csharp/101-zero-to-hero/phase-2-building-blocks/06-methods/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson06"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson06"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson06` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Kitchen: 2.00 litres
```


## How it works
1. Top-level instructions call Area with arguments 3 and 4. A **call** starts a method with particular arguments. C# converts these int literals to double parameters width and height.
2. `static double Area` defines the helper and says it returns a double. As noted before typing, pass in everything it needs rather than reading surrounding variables.
3. Area computes a local variable result, then return ends the call and hands the value back. The caller stores it as roomArea. The definition may be written below its call; writing a definition does not run its body immediately.
4. Dividing 12 square metres by coverage of 6 square metres per litre gives 2 litres. PrintEstimate receives Kitchen and 2, and formats the result.
5. **void** means no return value. A void method can print or do other work; you cannot store its result as a number.
6. **Scope** is the region where a name can be used. **Local variables** belong to their block or method. width, height and result exist inside Area; room and litres exist inside PrintEstimate. The caller cannot use result directly. Giving two separate methods a local variable with the same name does not share the value.

## Try it
Complete DeliveryPrice: return a base fee of 2.00m plus 1.50m per box. The supplied call passes three boxes. Keep arithmetic in the method and the formatted print at the call site.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-2-building-blocks/06-methods/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise06`**. Do not copy starter *into* an existing exercise06 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise06` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise06; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise06`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise06/Program.cs` (starter)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine($"Delivery: {DeliveryPrice(3):F2}");

static decimal DeliveryPrice(int boxes)
{
    // TODO: return a base fee of 2.00m plus 1.50m per box.
    return 0m;
}
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise06"`; macOS/Linux `cd "$HOME/code101/csharp/exercise06"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise06` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Delivery: 0.00
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise06/Program.cs` (solution)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine($"Delivery: {DeliveryPrice(3):F2}");

static decimal DeliveryPrice(int boxes)
{
    return 2.00m + boxes * 1.50m;
}
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Delivery: 6.50
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. Area receives 3 and 4, then roomArea is divided by 6. Predict the Kitchen line.
   <details><summary>Answer</summary>Kitchen: 2.00 litres. Area returns 12 square metres, and 12 / 6 is 2.</details>
2. What does return do?
   <details><summary>Answer</summary>It ends this call and passes the result to the caller.</details>
3. Can a void call be assigned to double?
   <details><summary>Answer</summary>No. void supplies no value.</details>
4. Why can the caller not use result?
   <details><summary>Answer</summary>That local variable is in Area's scope, not the caller's.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0103: The name 'result' does not exist in the current context` | Console.WriteLine(result) was added in the caller, outside Area. | Read roomArea, which receives the returned result; a local name stays in its scope. |
| `warning CS8321: The local function 'Area' is declared but never used` | Area(3, 4) was replaced with the literal 12, leaving Area defined but never called. | Call Area to compute the value. This warning alone does not stop the program. |
| `error CS1002: ; expected` | The WriteLine inside PrintEstimate lost its semicolon. | Restore the semicolon and save. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Give each method one clear job, and supply needed information through parameters rather than hidden surrounding variables.
Source: Microsoft Learn, Methods https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/methods

## Next lesson
**[07. Arrays, lists and dictionaries](07-arrays-lists-and-dictionaries.md)**: organise several values together.
