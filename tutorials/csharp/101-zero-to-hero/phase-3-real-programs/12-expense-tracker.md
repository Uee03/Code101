---
track: csharp
level: 101
phase: 3
phase_name: real-programs
lesson: 12
title: "Project: expense tracker"
time: 90-120 min (two sittings)
prerequisites: [101.3.11]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/
assets: []
---

# 12. Project: expense tracker

## Why it matters
A pocket expense notebook has entries and simple actions: add a purchase, read the page and put it somewhere safe. We can now combine those ideas into one console application.

## What you will build
An expense tracker with a menu, a List of Expense records, restricted CSV persistence and a tiny in-memory self-check using a plain Assert method. This is a learning project, not accounting software. Use invented expenses and a disposable folder; it has no backups, atomic saves, currency conversion or audit history.

## Before you start
- Complete lessons 01 through 11; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: **90-120 minutes in two sittings**. First: build and run (Steps through Run it). **Break after Run it**, before How it works; second: trace the helpers and do the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson12` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson12`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson12`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson12` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson12`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
We have met the pieces: input (03), choices (04), loops (05), methods (06), lists (07), files (08), errors (09), objects (10) and records/null safety (11). The new work is connecting them.

Plan the menu: 1 adds an entry, 2 lists entries plus their total, 3 saves the whole list, and 0 exits. Saving is explicit: exit does not save. With no CSV file, start empty. Later runs load the file in the terminal's current folder.

Our header is description,amount, with two fields per row. Reject empty descriptions and commas or line breaks in descriptions. Amounts must be positive decimals with a dot and no currency sign, exponent or thousands separator. This narrow format keeps hand-written CSV understandable; it is not a general CSV reader.

A **switch statement** (unlike lesson 04's switch expression) chooses statements to execute. A case matches a menu value, break exits the switch, and default handles other choices. The outer while repeats the menu. The separate break in choice == "0" exits that loop.

Before typing the helpers: `Trim()` removes outer whitespace; `TrimEnd('\r')` removes a final carriage return. `Contains` checks whether a character occurs in text. `string.IsNullOrWhiteSpace` recognizes empty or space-only text, so blank CSV rows can be skipped. An **overload** is another form of a method with different parameters. Here the longer TryParse form takes `NumberStyles.AllowDecimalPoint` (a named option permitting a decimal dot) and invariant culture so currency signs and separators are rejected. `throw new` raises an exception for a caller to handle.

A **self-check** is a small internal sanity check. An **assertion** states something expected to be true and fails visibly if false. We write an ordinary method, not install a test framework or call dotnet test.

### Step 5. Create Expense.cs
In VS Code Explorer choose **New File**. Put `Expense.cs` directly beside Lesson.csproj, not inside bin or obj. Paste or type all the following, then save. This defines a type used by the main program.

**File: `Expense.cs`**
```csharp
public record Expense(string Description, decimal Amount);
```

### Step 6. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
SelfCheck();
string path = Path.Combine(Directory.GetCurrentDirectory(), "expenses.csv");
List<Expense> expenses = LoadExpenses(path);
Console.WriteLine($"Loaded: {expenses.Count}");
while (true)
{
    Console.WriteLine("1 Add | 2 List | 3 Save | 0 Exit");
    string choice = Console.ReadLine() ?? "0";
    if (choice == "0")
    {
        Console.WriteLine("Bye (only saved changes are kept).");
        break;
    }
    switch (choice)
    {
        case "1":
            AddExpense(expenses);
            break;
        case "2":
            ShowExpenses(expenses);
            break;
        case "3":
            try
            {
                File.WriteAllText(path, ToCsv(expenses));
                Console.WriteLine("Saved expenses.csv");
            }
            catch (IOException)
            {
                Console.WriteLine("Could not save: file is busy or storage failed.");
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("Could not save: folder is not writable.");
            }
            break;
        default:
            Console.WriteLine("Choose 1, 2, 3 or 0.");
            break;
    }
}

static void AddExpense(List<Expense> expenses)
{
    Console.WriteLine("Description (no commas):");
    string description = (Console.ReadLine() ?? "").Trim();
    if (description == "" || description.Contains(',') || description.Contains('\r') || description.Contains('\n'))
    {
        Console.WriteLine("Use a nonempty description without commas or line breaks.");
        return;
    }
    Console.WriteLine("Amount (positive, dot for decimals):");
    if (!decimal.TryParse(Console.ReadLine(), NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out decimal amount) || amount <= 0)
    {
        Console.WriteLine("Invalid amount; nothing added.");
        return;
    }
    expenses.Add(new Expense(description, amount));
    Console.WriteLine("Added.");
}

static void ShowExpenses(List<Expense> expenses)
{
    decimal total = 0m;
    foreach (Expense expense in expenses)
    {
        Console.WriteLine($"{expense.Description}: {expense.Amount:F2}");
        total = total + expense.Amount;
    }
    Console.WriteLine($"Total: {total:F2}");
}

static string ToCsv(List<Expense> expenses)
{
    string csv = "description,amount\n";
    foreach (Expense expense in expenses)
    {
        csv = csv + $"{expense.Description},{expense.Amount.ToString(CultureInfo.InvariantCulture)}\n";
    }
    return csv;
}

static List<Expense> LoadExpenses(string path)
{
    List<Expense> expenses = new List<Expense>();
    if (!File.Exists(path))
    {
        return expenses;
    }
    try
    {
        string[] lines = File.ReadAllText(path).Split('\n');
        if (lines.Length == 0 || lines[0].TrimEnd('\r') != "description,amount")
        {
            Console.WriteLine("Unrecognized CSV header; keep a backup before saving.");
            return expenses;
        }
        for (int index = 1; index < lines.Length; index++)
        {
            string line = lines[index].TrimEnd('\r');
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }
            try
            {
                expenses.Add(ParseExpense(line));
            }
            catch (FormatException)
            {
                Console.WriteLine($"Skipped invalid CSV row {index + 1}.");
            }
        }
    }
    catch (IOException)
    {
        Console.WriteLine("Could not load expenses.csv; keep a backup before saving.");
    }
    catch (UnauthorizedAccessException)
    {
        Console.WriteLine("Cannot read expenses.csv; keep a backup before saving.");
    }
    return expenses;
}

static Expense ParseExpense(string line)
{
    string[] cells = line.Split(',');
    if (cells.Length != 2 || cells[0].Trim() == "" || !decimal.TryParse(cells[1], NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out decimal amount) || amount <= 0)
    {
        throw new FormatException("Invalid expense row.");
    }
    return new Expense(cells[0], amount);
}

static void SelfCheck()
{
    Expense sample = new Expense("Tea", 2.50m);
    string csv = ToCsv(new List<Expense> { sample });
    string row = csv.Split('\n')[1];
    Expense restored = ParseExpense(row);
    Assert(restored == sample, "CSV round trip keeps the expense.");
    Assert(csv.StartsWith("description,amount\n"), "CSV includes the header.");
    Console.WriteLine("Self-check passed.");
}

static void Assert(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}
```

This is the whole application, not fragments to paste into several programs. Keep the top-level instructions above the static helper definitions; Expense is in its own file. All helpers belong in this one Program.cs.

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson12` (or `source/csharp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson12"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson12"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson12` (terminal)**
```powershell
dotnet run --project . --nologo
```
Type these lines **as answers to the prompts**, pressing Enter after each, not as shell commands:

**Keyboard input**
```text
1
Tea
2.50
2
3
0
```
Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
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

Start with a fresh practice folder to reproduce Loaded: 0. If expenses.csv already exists, preserve it somewhere else in your file manager before this demonstration. Choice 3 creates the following file beside the project in this run:

**File: `expenses.csv` (generated)**
```csv
description,amount
Tea,2.50
```

To continue using the app, run the same dotnet command from the same folder. It loads your saved file; choose 2 to inspect entries, 3 after making changes, and 0 to exit. If a load warning appears, exit without saving and back up the file before repairing it. No server or background process is left running.


### Break point: end of sitting one
The program has run and saved a sample. Close it, keep both source files and expenses.csv, and take a break. Next sitting, reopen lesson12, read How it works, then make the separate exercise copy.

## How it works
1. At startup SelfCheck creates one Tea record, turns it into CSV text and parses it back in memory. Assert checks equality and the header. This is a **round trip**: convert to another form and back. If a check fails, throw new InvalidOperationException stops the run with an explanation. Otherwise print Self-check passed. It is intentionally tiny, not a test suite or proof of every path.
2. Build the path using the working folder, then LoadExpenses. File.Exists checks for a first-run missing file. An empty list is a valid starting state.
3. The menu reads a string. ?? "0" makes end of input a clean exit. Each switch case calls a method, saves the file, or explains valid choices. A switch statement does work rather than returning a selected value.
4. AddExpense trims outer spaces from the description and rejects forbidden characters. Contains asks whether a character occurs in a string. Parentheses around ReadLine's fallback let Trim run on a chosen non-null string. A bare return leaves the current void method without ending the menu loop.
5. decimal.TryParse uses an **overload**, a method with the same name but a different parameter list. NumberStyles.AllowDecimalPoint is an enum option allowing our restricted decimal form; InvariantCulture fixes the separator. out decimal amount receives the number. Failure or zero adds nothing. List.Add stores a new Expense only after validation.
6. ShowExpenses prints each record and accumulates the total in decimal. F2 rounds only the displayed value. This version accepts more than two fractional digits, so stored CSV can retain fractions smaller than a cent. A real money system needs an explicit currency and rounding policy.
7. ToCsv starts with a header and appends a line per record. ToString with invariant culture writes a portable number; we do not use F2 for persistence because display rounding should not change stored values. WriteAllText replaces the file. Separate catches report storage and permission failures without claiming a successful save.
8. LoadExpenses splits lines without removing positions, validates the header and trims a final carriage return for Windows-style line endings. It skips blank or whitespace-only lines before parsing, keeping original CSV row numbers. Each nonblank row goes through ParseExpense. Checking cells.Length before cells[1] uses short-circuit evaluation to avoid indexing malformed rows. A bad row throws FormatException and is skipped with its row number. I/O (**input/output**) and permission failures have separate messages. Loaded rows remain in the returned list.
9. A warning about an unreadable file, bad header or skipped rows means loading may be incomplete. **Do not press Save over the only copy**: exit with 0, back up expenses.csv in your file manager, and repair the source first. Saving an incomplete list replaces the original. This limitation is deliberate and important.
10. Assert throws only when its condition is false; the normal run exercises this tiny check. No extra tools are needed.

## Try it
Add menu choice 4 to print only the total, without listing expenses. The starter already advertises choice 4 and marks its missing case. Keep all other behavior unchanged. The shown run adds Tea, asks for the total, saves and exits.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-3-real-programs/12-expense-tracker/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise12`**. Do not copy starter *into* an existing exercise12 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise12` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise12; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise12`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

Start by copying **only** Program.cs and Expense.cs from your finished lesson12 into exercise12 (or type the identical main files above). Then replace the entire top-level region, from `using System.Globalization;` through the closing menu-loop brace immediately before `static void AddExpense`, with the following. All seven helper methods, from AddExpense through Assert, are **byte-identical** to the main program and stay unchanged. Differences: menu text, fallback-choice text, and the marked missing choice 4.

**File: `~/code101/csharp/exercise12/Program.cs` (starter)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
SelfCheck();
string path = Path.Combine(Directory.GetCurrentDirectory(), "expenses.csv");
List<Expense> expenses = LoadExpenses(path);
Console.WriteLine($"Loaded: {expenses.Count}");
while (true)
{
    Console.WriteLine("1 Add | 2 List | 3 Save | 4 Total | 0 Exit");
    string choice = Console.ReadLine() ?? "0";
    if (choice == "0")
    {
        Console.WriteLine("Bye (only saved changes are kept).");
        break;
    }
    switch (choice)
    {
        case "1":
            AddExpense(expenses);
            break;
        case "2":
            ShowExpenses(expenses);
            break;
        case "3":
            try
            {
                File.WriteAllText(path, ToCsv(expenses));
                Console.WriteLine("Saved expenses.csv");
            }
            catch (IOException)
            {
                Console.WriteLine("Could not save: file is busy or storage failed.");
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("Could not save: folder is not writable.");
            }
            break;
        // TODO: add case "4" to sum Amount values and print Total with F2.
        default:
            Console.WriteLine("Choose 1, 2, 3, 4 or 0.");
            break;
    }
}
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise12"`; macOS/Linux `cd "$HOME/code101/csharp/exercise12"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise12` (terminal)**
```powershell
dotnet run --project . --nologo
```
Before editing, choose **4**, then **0** at the menu. The starter has no total behavior yet and prints:

**Captured starter output**
```text
Self-check passed.
Loaded: 0
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Choose 1, 2, 3, 4 or 0.
1 Add | 2 List | 3 Save | 4 Total | 0 Exit
Bye (only saved changes are kept).
```

Complete your change, then run again. Every sample transcript below starts with no expenses.csv in exercise12; before repeating a sample, move any existing exercise CSV somewhere safe in your file manager first.

For the shown solution run, enter these lines when prompted:

**Exercise keyboard input**
```text
1
Tea
2.50
4
3
0
```
<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

Keep Expense.cs and all seven helper methods unchanged from the starter. Replace only the top-level region shown below; the sole behavior change is the added choice 4.

**File: `~/code101/csharp/exercise12/Program.cs` (solution)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
SelfCheck();
string path = Path.Combine(Directory.GetCurrentDirectory(), "expenses.csv");
List<Expense> expenses = LoadExpenses(path);
Console.WriteLine($"Loaded: {expenses.Count}");
while (true)
{
    Console.WriteLine("1 Add | 2 List | 3 Save | 4 Total | 0 Exit");
    string choice = Console.ReadLine() ?? "0";
    if (choice == "0")
    {
        Console.WriteLine("Bye (only saved changes are kept).");
        break;
    }
    switch (choice)
    {
        case "1":
            AddExpense(expenses);
            break;
        case "2":
            ShowExpenses(expenses);
            break;
        case "3":
            try
            {
                File.WriteAllText(path, ToCsv(expenses));
                Console.WriteLine("Saved expenses.csv");
            }
            catch (IOException)
            {
                Console.WriteLine("Could not save: file is busy or storage failed.");
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("Could not save: folder is not writable.");
            }
            break;
        case "4":
            decimal total = 0m;
            foreach (Expense expense in expenses)
            {
                total = total + expense.Amount;
            }
            Console.WriteLine($"Total: {total:F2}");
            break;
        default:
            Console.WriteLine("Choose 1, 2, 3, 4 or 0.");
            break;
    }
}
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
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

The solution follows the task directly: it uses the extra switch case to sum Amount values and then leaves the switch with break.

</details>

## Check yourself
1. With only Tea at 2.50 entered, predict the Total line after menu choice 2. Is it saved yet?
   <details><summary>Answer</summary>Total: 2.50. Listing does not save; choose 3 to save.</details>
2. Does 0 save pending changes?
   <details><summary>Answer</summary>No. Choose 3 before 0 to save.</details>
3. Why reject commas in descriptions?
   <details><summary>Answer</summary>This teaching format splits at commas and does not implement CSV quoting.</details>
4. What does the self-check establish?
   <details><summary>Answer</summary>The tiny sample survives a CSV round trip and the generated text has its header; it does not prove every path.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `Invalid amount; nothing added.` | After choosing 1 and entering Tea, the amount was $5. | Enter a positive number with a dot, such as 2.50, without a currency sign. |
| `Use a nonempty description without commas or line breaks.` | After choosing 1, the description was a,b. | Use nonempty text without commas, then choose 1 to try again. |
| `Choose 1, 2, 3 or 0.` | The menu choice was 9. | Use one of the displayed choices; type each answer after its prompt. |
| `Skipped invalid CSV row 3.` | A practice expenses.csv had the valid header, Tea,2.50 on row 2, and Broken on row 3. | Exit without saving, back up the CSV, then repair row 3 to have a description and positive decimal amount. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Use decimal for stored money-like values, keep file formatting culture-independent, and choose a rounding policy explicitly for real financial applications.
Source: Microsoft Learn, Floating-point numeric types https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types

## Next lesson
**End of C# 101.** No later lesson is required. Keep this practice app as a reference and explain its input, validation, storage and output path to someone else before adding more features.
