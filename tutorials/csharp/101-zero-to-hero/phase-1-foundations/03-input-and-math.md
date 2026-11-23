---
track: csharp
level: 101
phase: 1
phase_name: foundations
lesson: 03
title: "Input and math"
time: 35-40 min
prerequisites: [101.1.02]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-1-foundations/03-input-and-math/
assets: []
---

# 03. Input and math

## Why it matters
A waiter asks for the bill and how many people are sharing before reaching for a calculator. A program also asks for information before it can calculate something useful.

## What you will build
A tip calculator with a bill split and an experiment showing that parsing can fail. This beginner calculator uses double for arithmetic practice; lesson 12 uses decimal for stored money.

## Before you start
- Complete lessons 01 through 02; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-1-foundations/03-input-and-math/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson03` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson03`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson03`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson03` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson03`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
We read people, bill and tip percent on separate lines. Enter 2, 80 and 15 with Enter after each. Later enter no at the optional coupon prompt.

An **operator** performs an operation. + adds, - subtracts, * multiplies, / divides and % gives the remainder of division. Multiplication and division happen before addition and subtraction; parentheses can make another order explicit. Integer division discards the fraction: 7 / 2 is 3 with int operands. With a double operand, division can retain a fraction.

For this first version, type a positive people count and ordinary finite, nonnegative bill and percent values, without currency or percent signs. It does not yet validate these rules. Lesson 04 adds decisions; lesson 09 adds a re-ask loop.

Before typing: **parsing** converts text into a number. `Console.ReadLine()` reads a line of text; it returns **null** (no value) at end of input. `?? ""` supplies empty text for that case. These are **nested calls**: the inner ReadLine finishes before Parse uses its result. An **exception** signals a failure while a program runs; Parse can raise one for invalid text. TryParse instead returns a success/failure bool and supplies a value through `out`. Lesson 09 shows how to retry.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine("People (whole number):");
int people = int.Parse(Console.ReadLine() ?? "");
Console.WriteLine("Bill (use a dot):");
double bill = double.Parse(Console.ReadLine() ?? "");
Console.WriteLine("Tip percent (number only):");
double percent = double.Parse(Console.ReadLine() ?? "");
double tip = bill * percent / 100;
double total = bill + tip;
Console.WriteLine($"Tip: {tip:F2}");
Console.WriteLine($"Total: {total:F2}");
Console.WriteLine($"Per person: {total / people:F2}");
Console.WriteLine($"Change from 100: {100 - total:F2}");
Console.WriteLine($"7 / 2 with integers: {7 / 2}");
Console.WriteLine($"7 % 2 remainder: {7 % 2}");
Console.WriteLine("Optional whole-number coupon (try a word):");
bool parsed = int.TryParse(Console.ReadLine(), out int coupon);
Console.WriteLine($"Coupon parsed: {parsed}; value: {coupon}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson03` (or `source/csharp/101-zero-to-hero/phase-1-foundations/03-input-and-math/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson03"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson03"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson03` (terminal)**
```powershell
dotnet run --project . --nologo
```
Type these lines **as answers to the prompts**, pressing Enter after each, not as shell commands:

**Keyboard input**
```text
2
80
15
no
```
Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
People (whole number):
Bill (use a dot):
Tip percent (number only):
Tip: 12.00
Total: 92.00
Per person: 46.00
Change from 100: 8.00
7 / 2 with integers: 3
7 % 2 remainder: 1
Optional whole-number coupon (try a word):
Coupon parsed: False; value: 0
```


## How it works
1. Each prompt appears before a read. Console.ReadLine waits for Enter and returns text, even when you type digits. An empty line is an empty string. End of input gives **null**, meaning no value at all.
2. `??` is the **null-coalescing operator**: choose the left value unless it is null; then use the right fallback. Here the fallback is an empty string. Lesson 11 develops null safety fully. An empty string still cannot be parsed as a number.
3. **Parsing** converts text into a value. int.Parse expects a whole number; double.Parse accepts a fractional number. These calls are **nested**: the inner read finishes before the outer Parse call uses its result. Culture setup from lesson 02 makes a dot the decimal separator.
4. Tip equals bill times percent divided by 100. Total adds the tip; the next expressions divide the total and subtract it from 100. F2 makes the displayed result easy to read.
5. int.TryParse attempts conversion without raising an exception for bad text. Its return value is a bool indicating success. `out int coupon` declares a variable receiving the parsed value (zero on failure here). The sample word produces False and zero. We only display the result now; deciding what to do next starts in lesson 04.
6. An **exception** reports a problem during execution. Parse throws FormatException for words instead of digits. That differs from a compiler error, which stops a program from building.

## Try it
Build a simpler bill splitter: read a bill, read a positive whole-number people count, then print Share with F2. Use 90 and 3. Leave the two reads in place. A zero people count is outside this exercise: it prints `Share: Infinity`, not a useful share or an exception. Lesson 04 gives you the decisions needed to reject it.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-1-foundations/03-input-and-math/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise03`**. Do not copy starter *into* an existing exercise03 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise03` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise03; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise03`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise03/Program.cs` (starter)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine("Bill (use a dot):");
double bill = double.Parse(Console.ReadLine() ?? "");
Console.WriteLine("People (positive whole number):");
int people = int.Parse(Console.ReadLine() ?? "");
// TODO: calculate and print each person's share with F2.
Console.WriteLine("Share: TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise03"`; macOS/Linux `cd "$HOME/code101/csharp/exercise03"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise03` (terminal)**
```powershell
dotnet run --project . --nologo
```
For the shown solution run, enter these lines when prompted:

**Exercise keyboard input**
```text
90
3
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Bill (use a dot):
People (positive whole number):
Share: TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise03/Program.cs` (solution)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine("Bill (use a dot):");
double bill = double.Parse(Console.ReadLine() ?? "");
Console.WriteLine("People (positive whole number):");
int people = int.Parse(Console.ReadLine() ?? "");
Console.WriteLine($"Share: {bill / people:F2}");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Bill (use a dot):
People (positive whole number):
Share: 30.00
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. Predict 7 / 2 and 7 % 2 as printed by this program.
   <details><summary>Answer</summary>3 and 1. Integer division discards the fraction; remainder keeps what is left.</details>
2. What does TryParse return for a word?
   <details><summary>Answer</summary>False; the out int is zero.</details>
3. Why does 7 / 2 print 3 here?
   <details><summary>Answer</summary>Both operands are integers, so integer division discards the fraction.</details>
4. Does ?? make Parse accept empty text?
   <details><summary>Answer</summary>No. It only supplies a fallback for null.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unhandled exception. System.FormatException: The input string '$80' was not in a correct format.` | The bill input was $80, including the currency sign. | Enter 80, without a currency sign. |
| `Unhandled exception. System.FormatException: The input string '15%' was not in a correct format.` | The percent input was 15%, including the percent sign. | Enter 15, without %. Percent is calculated by the program. |
| `Unhandled exception. System.FormatException: The input string 'ten' was not in a correct format.` | The people input was ten. | Enter a positive whole number in digits; lesson 09 shows retries. |
| `Unhandled exception. System.OverflowException: Value was either too large or too small for an Int32.` | The people input was 999999999999999999999. | Use a positive int no larger than 2147483647; lesson 09 rejects values outside the range. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Use TryParse for routine user-entry failures instead of using exceptions for normal control flow.
Source: Microsoft Learn, Best practices for exceptions https://learn.microsoft.com/dotnet/standard/exceptions/best-practices-for-exceptions

## Next lesson
**[04. Making decisions](04-making-decisions.md)**: choose what to do using yes/no conditions.
