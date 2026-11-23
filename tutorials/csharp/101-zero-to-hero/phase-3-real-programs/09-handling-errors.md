---
track: csharp
level: 101
phase: 3
phase_name: real-programs
lesson: 09
title: "Handling errors"
time: 35-45 min
prerequisites: [101.2.08]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors/
assets: []
---

# 09. Handling errors

## Why it matters
A receptionist asks again when a form has an unreadable age instead of closing the office. Error handling lets a program recover from predictable mistakes and finish necessary cleanup.

## What you will build
A quantity prompt that re-asks with TryParse, plus an optional number read demonstrating try, catch and finally.

## Before you start
- Complete lessons 01 through 08; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-45 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson09` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson09`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson09`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson09` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson09`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
A **try block** surrounds work that can fail. A **catch block** handles a matching exception. A **finally block** runs when control leaves the try/catch, whether the operation succeeded or a matching exception was caught; it is not guaranteed after forced process termination.

Use TryParse for expected user mistakes. Then deliberately use Parse in the optional-number step to see a caught exception. FormatException means unexpected text shape; OverflowException means an integer outside its supported range. int supports -2147483648 through 2147483647.

`string?` permits a missing string value; `input is null` checks for end of input, not a blank line. `return` at the top level ends the program. These reuse lesson 03's null idea; lesson 11 develops safe access. Focus here on the retry rule and the matching exception handler.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
Console.WriteLine("Quantity (positive whole number):");
int quantity;
while (true)
{
    string? input = Console.ReadLine();
    if (input is null)
    {
        Console.WriteLine("Input ended.");
        return;
    }
    if (int.TryParse(input, out quantity) && quantity > 0)
    {
        break;
    }
    Console.WriteLine("Please enter a positive whole number:");
}
try
{
    Console.WriteLine("Optional number (try a word):");
    int optional = int.Parse(Console.ReadLine() ?? "");
    Console.WriteLine($"Optional: {optional}");
}
catch (FormatException)
{
    Console.WriteLine("That was not a whole number.");
}
catch (OverflowException)
{
    Console.WriteLine("That whole number is too large or too small.");
}
finally
{
    Console.WriteLine("Finished the optional-number step.");
}
Console.WriteLine($"Accepted: {quantity}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson09` (or `source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson09"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson09"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson09` (terminal)**
```powershell
dotnet run --project . --nologo
```
Type these lines **as answers to the prompts**, pressing Enter after each, not as shell commands:

**Keyboard input**
```text
oops
3
word
```
Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Quantity (positive whole number):
Please enter a positive whole number:
Optional number (try a word):
That was not a whole number.
Finished the optional-number step.
Accepted: 3
```


## How it works
1. The loop starts with an uninitialized int quantity. while (true) has no natural false condition, so explicit exits are essential.
2. string? permits a missing string value. input is null detects end of input; return at the top level ends the program. This prevents a redirected empty input stream from printing retry prompts forever. Pressing Enter without text is different: that is an empty string and should re-ask.
3. TryParse writes quantity through out. && checks `quantity > 0` only after parsing succeeds. A positive value breaks out; otherwise the prompt repeats. No exception is needed for routine retries.
4. The optional Parse call is inside try. Typing word throws FormatException and skips the remaining statements in try. The matching catch prints a friendly explanation; the OverflowException catch handles another failure. Only the matching catch runs.
5. finally prints its completion message on either path. This is a teaching signal, not resource cleanup the program actually needs. File.ReadAllText and WriteAllText already close their files; other resource patterns are outside this lesson.
6. After handling a matching exception and executing finally, normal flow resumes and prints quantity. An unrelated exception would still escape after finally; catching everything silently would hide real defects.

## Try it
Re-ask for an age from 0 through 130 with TryParse. Accept valid input, print it once, and break. If input is null, print Input ended. and return. With old followed by 25, there should be one retry.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-3-real-programs/09-handling-errors/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise09`**. Do not copy starter *into* an existing exercise09 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise09` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise09; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise09`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise09/Program.cs` (starter)**
```csharp
Console.WriteLine("Age (0-130):");
// TODO: re-ask with TryParse until 0-130; stop cleanly when ReadLine returns null.
Console.WriteLine("TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise09"`; macOS/Linux `cd "$HOME/code101/csharp/exercise09"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise09` (terminal)**
```powershell
dotnet run --project . --nologo
```
For the shown solution run, enter these lines when prompted:

**Exercise keyboard input**
```text
old
25
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Age (0-130):
TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise09/Program.cs` (solution)**
```csharp
Console.WriteLine("Age (0-130):");
while (true)
{
    string? input = Console.ReadLine();
    if (input is null)
    {
        Console.WriteLine("Input ended.");
        return;
    }
    if (int.TryParse(input, out int age) && age >= 0 && age <= 130)
    {
        Console.WriteLine($"Age: {age}");
        break;
    }
    Console.WriteLine("Try an age from 0 to 130:");
}
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Age (0-130):
Try an age from 0 to 130:
Age: 25
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. The sample input is oops, then 3, then word. Predict what prints after the catch and finally.
   <details><summary>Answer</summary>Accepted: 3. The failed optional conversion is handled and does not erase the accepted quantity.</details>
2. Is a blank line end of input?
   <details><summary>Answer</summary>No. It is an empty string; end of input returns null.</details>
3. Which catch handles an enormous integer?
   <details><summary>Answer</summary>OverflowException.</details>
4. Does finally mean success?
   <details><summary>Answer</summary>No. It also runs when the operation failed.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0165: Use of unassigned local variable 'quantity'` | out quantity was changed to out int parsed while the condition still reads quantity. | Keep out quantity so TryParse assigns the variable being checked and printed. |
| `error CS1513: } expected` | The closing brace of finally was removed. | Close finally before the Accepted print. |
| `Please enter a positive whole number:` | The quantity input was word (the same retry occurs for nonpositive quantities). | This is a handled input mistake, not a crash. Enter a positive whole number. |
| `That whole number is too large or too small.` | The optional-number input was 999999999999999999999. | The matching catch handled it; use an int-range number on the next run. No unhandled exception is expected. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Catch only exceptions you can meaningfully handle. Use TryParse for expected invalid input instead of making exceptions your normal retry mechanism.
Source: Microsoft Learn, Best practices for exceptions https://learn.microsoft.com/dotnet/standard/exceptions/best-practices-for-exceptions

## Next lesson
**[10. Classes and objects](10-classes-and-objects.md)**: bundle state with the operations that change it.
