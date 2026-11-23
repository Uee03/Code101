---
track: csharp
level: 101
phase: 1
phase_name: foundations
lesson: 02
title: "Variables and types"
time: 35-40 min
prerequisites: [101.1.01]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-1-foundations/02-variables-and-types/
assets: []
---

# 02. Variables and types

## Why it matters
A shop label has spaces for the product name, quantity and price. Variables give a program similar labelled spaces; types prevent you from putting a sentence in the quantity space.

## What you will build
A stock label for notebooks. It remembers text, counts, a weight, a price and a yes/no answer, then calculates the stock value.

## Before you start
- Complete lesson 01; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 35-40 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-1-foundations/02-variables-and-types/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson02` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson02`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson02`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson02` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson02`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
The planned values are Notebook, 3 items, 0.25 kilograms each, 2.50 per item, in stock, shelf A2. We add one item before calculating the total: the expected quantity is four.

| C# type | Kind of value | Here |
|---|---|---|
| `string` | text in double quotes | item name |
| `int` | whole number | quantity |
| `double` | approximate fractional number | weight |
| `decimal` | base-ten decimal number, with m suffix | unit price |
| `bool` | true or false | availability |
| `var` | infer the type from the initial value | shelf becomes a string |

A **variable** is a named place for a value; its **type** limits what it can hold. A **declaration** introduces it; **initialization** gives its first value. `=` is **assignment**, storing the right-hand value. A **literal** is a value written directly, such as `2.50m`.

Before typing: `$"...{quantity}..."` uses **string interpolation**, inserting values into text. `:F2` is a **format specifier**, displaying two digits after the decimal point without changing the stored value. A **namespace** groups related types; `using System.Globalization;` makes the culture tools available by short names. **Culture** means regional text/number rules. Copy the culture setup unchanged so our examples use a dot for decimals everywhere; there is no culture exercise here.

var is not a freely changing type: a variable inferred as string must still hold strings. decimal and double are different numeric types; do not casually mix them.

### Step 5. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string item = "Notebook";
int quantity = 3;
double weight = 0.25;
decimal unitPrice = 2.50m;
bool inStock = true;
var shelf = "A2";
quantity = quantity + 1;
decimal total = quantity * unitPrice;
Console.WriteLine($"Item: {item}");
Console.WriteLine($"Quantity: {quantity}");
Console.WriteLine($"Weight each: {weight} kg");
Console.WriteLine($"Price each: {unitPrice:F2}");
Console.WriteLine($"In stock: {inStock}");
Console.WriteLine($"Shelf: {shelf}");
Console.WriteLine($"Total: {total:F2}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson02` (or `source/csharp/101-zero-to-hero/phase-1-foundations/02-variables-and-types/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson02"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson02"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson02` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Item: Notebook
Quantity: 4
Weight each: 0.25 kg
Price each: 2.50
In stock: True
Shelf: A2
Total: 10.00
```


## How it works
1. A **variable** is a named place for a value. A **declaration** gives its type and name; **initialization** gives its first value. `=` means **assignment**: store the value on the right.
2. `using System.Globalization;` makes the culture tools available by short names. A **namespace** groups related types, like a labelled drawer. **Culture** is a set of regional number and text rules. Setting CurrentCulture to InvariantCulture makes examples use a dot for decimals regardless of your region; it is not a rule that all user interfaces must use English-style numbers.
3. The next declarations fill the label. `2.50m` is a decimal **literal**, a value written directly in code. Without m it would be double. true and false are lowercase keywords.
4. `quantity = quantity + 1` reads the old value, adds one, and stores the result. `*` multiplies the updated quantity by the unit price; int can be used in decimal multiplication.
5. The dollar sign before an interpolated string enables **string interpolation**: braces insert values into text. `:F2` is a **format specifier**: display two digits after the decimal point. It changes the display, not the stored number. Boolean display uses True/False even though the keywords are lowercase.

## Try it
Calculate an event budget for four guests at 3.50 each, using the supplied values. Print the total with two fractional digits. Keep the culture setup.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-1-foundations/02-variables-and-types/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise02`**. Do not copy starter *into* an existing exercise02 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise02` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise02; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise02`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise02/Program.cs` (starter)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
int guests = 4;
decimal pricePerGuest = 3.50m;
// TODO: calculate total from guests and pricePerGuest; print it with F2.
Console.WriteLine("Total: TODO");
```

The starter can warn that guests and pricePerGuest are unused until you complete the calculation. A **warning** does not stop the program (the starter still prints `Total: TODO`); an **error** stops the build. Those warnings disappear when the variables are used.
4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise02"`; macOS/Linux `cd "$HOME/code101/csharp/exercise02"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise02` (terminal)**
```powershell
dotnet run --project . --nologo
```
Unchanged starter output (before your work):

**Captured starter output**
```text
Total: TODO
```

<details><summary>Solution</summary>

Keep `global.json` and `Lesson.csproj` unchanged from lesson 01. Replace only the C# files shown below to compare.

**File: `~/code101/csharp/exercise02/Program.cs` (solution)**
```csharp
using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
int guests = 4;
decimal pricePerGuest = 3.50m;
decimal total = guests * pricePerGuest;
Console.WriteLine($"Total: {total:F2}");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Total: 14.00
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. Predict the Quantity and Total lines: quantity starts at 3, then the code adds 1; each item costs 2.50.
   <details><summary>Answer</summary>Quantity: 4 and Total: 10.00. The multiplication uses the updated quantity.</details>
2. Why does the price end with m?
   <details><summary>Answer</summary>It makes the literal decimal rather than double.</details>
3. Can var shelf = "A2" later accept 7?
   <details><summary>Answer</summary>No. Its inferred type is string.</details>
4. What does F2 change?
   <details><summary>Answer</summary>The displayed fractional digits, not the stored value.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0029: Cannot implicitly convert type 'string' to 'int'` | The quantity declaration became int quantity = "three". | Use the number 3 without quotes or declare a string. |
| `error CS1002: ; expected` | The last WriteLine lost its semicolon. | Restore the semicolon and save. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Use decimal when base-ten precision matters, such as currency amounts; use double for approximate measurements. Formatting is not a money-rounding policy.
Source: Microsoft Learn, Floating-point numeric types https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types

## Next lesson
**[03. Input and math](03-input-and-math.md)**: ask the user for values and calculate with them.
