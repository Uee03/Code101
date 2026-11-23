---
track: csharp
level: 101
phase: 3
phase_name: real-programs
lesson: 10
title: "Classes and objects"
time: 45-55 min
prerequisites: [101.3.09]
versions: { dotnet_sdk: "11.0.100 (latestPatch in 11.0.1xx)", target_framework: "net11.0" }
verified: 2026-11-23 on Windows 11, .NET SDK 11.0.100
source: source/csharp/101-zero-to-hero/phase-3-real-programs/10-classes-and-objects/
assets: []
---

# 10. Classes and objects

## Why it matters
A mechanical counter keeps its own count and offers a button that changes it. A class can bundle stored information with the operations allowed to change it.

## What you will build
Two independent counters, one for tickets and one for drinks. Only the ticket counter increases.

## Before you start
- Complete lessons 01 through 09; use the .NET SDK and editor installed in lesson 01.
- Tools: SDK **11.0.100** (or later 11.0.1xx patch), **net11.0**, and the editor from [lesson 01](../phase-1-foundations/01-hello-csharp.md). Windows execution verified; macOS/Linux routes are documentation-based.
- Time: 45-55 min, including typing, running and the exercise.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/101-zero-to-hero/phase-3-real-programs/10-classes-and-objects/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Type the Steps in your own folder; the optional repository is only for comparison. Keep exercises separate.

## Steps
### Step 1. Make your lesson folder
Repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), changing **only** `lesson01` to `lesson10` in both folder commands for your OS. Run them from any terminal folder. Expected result: no printed text; current folder is `~/code101/csharp/lesson10`. For the per-user Linux install, repeat lesson 01's two export lines in each new terminal.

### Step 2. Open the folder and copy the SDK pin
In VS Code choose **File > Open Folder** and open `~/code101/csharp/lesson10`. Trust only your own folder. In your file manager open your `~/code101/csharp/lesson01`, select **only** `global.json` and `Lesson.csproj`, and copy (Ctrl+C on Windows/Linux, Command+C on macOS). Open `lesson10` beside it and paste (Ctrl+V / Command+V). Do not copy Program.cs, bin or obj.

### Step 3. Keep the identical project settings
Both copied files are **identical** to lesson 01, Steps 6-8: no SDK, target-framework or other setting changes. No `dotnet new` command is needed. The differences in this lesson are its folder name (`lesson10`) and the C# files shown below. Save edits with Ctrl+S / Command+S; a dot on the tab means unsaved changes.

### Step 4. Plan the instructions
Think of this lesson as four parts: the blueprint and its stored values, construction, controlled reading, and controlled updates.

A **class** is a blueprint; an **object**, also called an **instance**, is one particular value made from it. Its **state** is its current stored information. A **field** stores one part of that information. A **constructor** sets up a new instance; `new` creates space for it and runs that constructor.

**public** permits access from other code; **private** limits access to the declaring class. A **property** controls reading or changing information. A **getter** is the part that reads a property. `Name { get; }` is read-only to callers, with storage supplied by C# (an **auto-property**). `Count => count` is a **computed property**: its getter returns the expression on the right, here the field. That shorthand is an **expression-bodied getter**. Notice lowercase `count` is the private field; uppercase `Count` is the public property. C# treats them as different names.

An **instance method** acts on one particular object. **Encapsulation** keeps stored values and their update rules together; outside code will use Add instead of directly changing count. These ideas work as one small model, not eight separate exercises.

Put the blueprint in Counter.cs and top-level instructions in Program.cs, both beside Lesson.csproj. The project automatically includes C# files in its folder; no import of Counter.cs or explicit file list is needed. Avoid extra copies of Program.cs here: they would also be compiled.

### Step 5. Create Counter.cs
In VS Code Explorer choose **New File**. Put `Counter.cs` directly beside Lesson.csproj, not inside bin or obj. Paste or type all the following, then save. This defines a type used by the main program.

**File: `Counter.cs`**
```csharp
public class Counter
{
    private int count;
    public string Name { get; }
    public int Count => count;

    public Counter(string name, int startingCount)
    {
        Name = name;
        count = startingCount;
    }

    public void Add(int amount)
    {
        if (amount > 0)
        {
            count = count + amount;
        }
    }
}
```

### Step 6. Write the complete program
Create Program.cs beside Lesson.csproj. Enter the full file below, including its punctuation. Save it before running. The numbered explanation in How it works follows its execution.

**File: `Program.cs`**
```csharp
Counter first = new Counter("Tickets", 2);
Counter second = new Counter("Drinks", 0);
first.Add(3);
Console.WriteLine($"{first.Name}: {first.Count}");
Console.WriteLine($"{second.Name}: {second.Count}");
```

## Run it
Use the external terminal from Step 1, or VS Code **Terminal > New Terminal**. Check the current folder is `~/code101/csharp/lesson10` (or `source/csharp/101-zero-to-hero/phase-3-real-programs/10-classes-and-objects/code` inside the optional repository copy). If you are lost, recover with Set-Location on Windows or cd on macOS/Linux:

**Folder: `any folder` (terminal)**
```powershell
Set-Location "$HOME/code101/csharp/lesson10"
```
**Folder: `any folder` (terminal)**
```bash
cd "$HOME/code101/csharp/lesson10"
```
Run this identical command on all three operating systems from the folder containing Lesson.csproj:

**Folder: `~/code101/csharp/lesson10` (terminal)**
```powershell
dotnet run --project . --nologo
```
No keyboard input is needed after starting this program.

Expected output, captured from a real run (program output only; your terminal also echoes the answers you type):

**Captured output**
```text
Tickets: 5
Drinks: 0
```


## How it works
1. public class Counter defines a type other files in this project can use. private int count is a field accessible only inside Counter. Each object gets its own count; it is not shared.
2. public string Name { get; } is a read-only auto-property. C# supplies its storage; the constructor assigns its value. Callers can read it but cannot set it afterward.
3. public int Count => count is a computed read-only property. Here => means its getter returns the expression on the right, not a switch arm. Each read exposes the current field without permitting direct changes.
4. The constructor has the same name as the class and no return type, not even void. new Counter creates space for an object and calls its constructor with initial values. We accept the shown starting counts as valid for this small example.
5. Add is an **instance method**: it runs on a particular object. Unlike lesson 06's static helpers, Add belongs to one Counter object and is called through first or second. It accepts only positive increments. first.Add(3) changes first from 2 to 5; second remains at zero. **Encapsulation** keeps state and rules together instead of letting unrelated code alter fields freely.
6. Program.cs contains entry instructions; Counter.cs contains a type definition, not another top-level program. A property read has no parentheses, unlike a method call. **public** permits access from other code; **private** restricts it to the declaring type.

## Try it
The starter includes a complete SavingsJar class with a private balance, Name and Balance properties, constructor and Deposit method. In Program.cs deposit five units into the Trip jar and print Trip: 5. Keep the class file unchanged; practise using an object. Its int balance field starts at zero automatically even though no initial value is written. Local variables, unlike fields, must be assigned before reading.

1. With the optional repository: open `source/csharp/101-zero-to-hero/phase-3-real-programs/10-classes-and-objects/exercise`. In your file manager **copy the `starter` folder into `~/code101/csharp` and rename the copy `exercise10`**. Do not copy starter *into* an existing exercise10 folder; preserve any previous exercise elsewhere first. Do not open solution yet.
2. Without the repository: repeat [lesson 01, Step 5](../phase-1-foundations/01-hello-csharp.md#step-5-make-your-lesson-folder), replacing `lesson01` with `exercise10` in both OS-specific commands. Copy **only** `global.json` and `Lesson.csproj` from your lesson01 folder into exercise10; they are identical. Create the starter C# files shown below there.
3. In VS Code choose **File > Open Folder**, open `~/code101/csharp/exercise10`, and save the files. Make changes only in this exercise folder, not in the main lesson folder.

**File: `~/code101/csharp/exercise10/SavingsJar.cs` (starter)**
```csharp
public class SavingsJar
{
    private int balance;
    public string Name { get; }
    public int Balance => balance;

    public SavingsJar(string name)
    {
        Name = name;
    }

    public void Deposit(int amount)
    {
        if (amount > 0)
        {
            balance = balance + amount;
        }
    }
}
```

**File: `~/code101/csharp/exercise10/Program.cs` (starter)**
```csharp
SavingsJar jar = new SavingsJar("Trip");
// TODO: deposit 5 and print Trip: 5.
Console.WriteLine("TODO");
```

4. In your terminal first enter the exercise folder: PowerShell `Set-Location "$HOME/code101/csharp/exercise10"`; macOS/Linux `cd "$HOME/code101/csharp/exercise10"`. Then run (all operating systems):

**Folder: `~/code101/csharp/exercise10` (terminal)**
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

Keep `SavingsJar.cs` identical to the starter above; only Program.cs changes.

**File: `~/code101/csharp/exercise10/Program.cs` (solution)**
```csharp
SavingsJar jar = new SavingsJar("Trip");
jar.Deposit(5);
Console.WriteLine($"{jar.Name}: {jar.Balance}");
```

Run the same command in the exercise folder. Captured solution output:

**Captured output**
```text
Trip: 5
```

The solution follows the task directly: compare each changed instruction with the rule in the task and trace its values from top to bottom. The unchanged setup is shared with the main example.

</details>

## Check yourself
1. first.Add(3) runs. Predict the Drinks line: does second change too?
   <details><summary>Answer</summary>Drinks: 0. Each object has its own count.</details>
2. Why is count private?
   <details><summary>Answer</summary>Only Counter can change it directly, keeping updates behind its rules.</details>
3. What is special about a constructor?
   <details><summary>Answer</summary>Its name matches the class and it has no return type.</details>
4. Why can callers read Count but not assign it?
   <details><summary>Answer</summary>It has only a getter, an expression-bodied getter here.</details>

## Common mistakes
These messages and symptoms were triggered using this lesson's project. Compiler paths and positions are omitted; `<project>` replaces a local path. **Errors** stop the build; **warnings** allow it to run. Read the first useful message before follow-on errors. Lines starting `at` after an exception form a **stack trace**, the chain of calls that led to the problem; start with the first exception line.

| Symptom or error text | Cause | Fix |
|---|---|---|
| `error CS0122: 'Counter.count' is inaccessible due to its protection level` | Program.cs tried to read first.count instead of first.Name. | Read first.Count for the count; use first.Add(...) to change it. |
| `error CS0103: The name 'console' does not exist in the current context` | console was typed with a lowercase c. | Use Console with capital C. |
| `Couldn't find a project to run. Ensure a project exists in ., or pass the path to the project using --project.` | dotnet run was started outside the folder containing Lesson.csproj. | Use the Set-Location / cd recovery command in Run it, then run again. |

If output still looks like an older version, look for a dot on the editor tab: it means **unsaved changes**. Save with Ctrl+S (Windows/Linux) or Command+S (macOS), then run again. If dotnet reports no project, use Set-Location / cd to the folder containing Lesson.csproj; do not run from the parent folder.

## Best practice
Expose behaviour and properties rather than public mutable fields, so the object can keep its own update rules consistent.
Source: Microsoft Learn, Classes https://learn.microsoft.com/dotnet/csharp/fundamentals/types/classes

## Next lesson
**[11. Null safety and records](11-null-safety-and-records.md)**: make missing values explicit and model data with records.
