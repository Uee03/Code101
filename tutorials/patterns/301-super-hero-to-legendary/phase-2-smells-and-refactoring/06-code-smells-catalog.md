---
track: patterns
level: 301
phase: 2
phase_name: smells-and-refactoring
lesson: 06
title: Code smells catalog (bloaters, couplers, change preventers, dispensables)
time: "70 min for one language, 100 min if you follow both"
prerequisites: [patterns 301 lessons 01 to 05, patterns 101 lesson 01]
versions: { python: "3.10 or newer", dotnet: "11.0 SDK" }
verified: not yet run
source: source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog/
assets: []
---

# 06. Code smells catalog (bloaters, couplers, change preventers, dispensables)

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- name the smell groups (bloaters, object-orientation abusers, change preventers, dispensables, couplers) and recognise a typical example of each
- measure three smells (long method, long parameter list, deep nesting) and one class smell (large class) with a small scanner and explain why thresholds are team agreements, not laws
- explain why a smell is a hint to look, not a verdict
- choose which smell to fix first using the cost of change, not the length of a list

## Recap
1. Patterns 101 lesson 01: what is a code smell? <details><summary>Answer</summary>A pattern in code that is not a bug but hints at a design problem.</details>
2. Lesson 05: which pattern did you use so that a saga's steps could be undone? <details><summary>Answer</summary>Compensating actions, run in reverse order.</details>

## Why it matters
Teams argue about "clean code" because they have no shared words. A **smell** is a shared word: "this function is a long method, it has three reasons to change". The smell catalogue (collected by Martin Fowler and Kent Beck, organised by refactoring.guru into groups, paraphrased here) gives you names; **measurement** gives you evidence. At level 301 you use both, and you know the traps: a metric you optimise becomes a target, and a "smell" in code that never changes is not worth a day of work.

## What you will build
A deliberately smelly module (an invoice function with nine parameters, nested conditions and a 22-line body, plus a class that does six unrelated jobs), a small **scanner** that measures it, and a report. You also write the catalogue into a table you can reuse in code reviews.

## Before you start
- **Prerequisites:** Patterns 301 lessons [01, DI containers and composition roots](../phase-1-application-patterns/01-di-containers-and-composition-roots.md) to [05, domain events, outbox and saga](../phase-1-application-patterns/05-domain-events-outbox-and-saga.md); [Patterns 101 lesson 01, why design matters](../../101-zero-to-hero/phase-1-solid/01-why-design-matters.md).
- Time: 70 minutes for one language, 100 for both.
- Python 3.10+ and/or the .NET 11 SDK. No packages.
- The programs read the file `smelly.py` / `Smelly.cs` from disk, so run them in the folder shown.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/06-code-smells-catalog/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps

### Step 1. Make the lesson folders
**PowerShell, starting folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/patterns301/lesson06/python" -Force | Out-Null
New-Item -ItemType Directory -Path "$HOME/code101/patterns301/lesson06/csharp" -Force | Out-Null
Set-Location "$HOME/code101/patterns301/lesson06"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/patterns301/lesson06/python ~/code101/patterns301/lesson06/csharp
cd ~/code101/patterns301/lesson06
code .
```
Expected result: VS Code opens `lesson06` with empty `python` and `csharp` folders.

### Step 2. The catalogue (read it first, then find each smell in the code)
| Group | What they have in common | Smells (short meaning) |
|---|---|---|
| **Bloaters** | Code that grew too big to handle | Long method (does many things), Large class (many jobs), Primitive obsession (strings and ints instead of small types such as `Money`), Long parameter list, Data clumps (the same three values travel together everywhere: `street, city, zip`) |
| **Object-orientation abusers** | Misuse of classes and inheritance | Switch statements (the same `if country == ...` ladder in many places), Temporary field (set only in some situations), Refused bequest (a subclass ignores what it inherits), Alternative classes with different interfaces |
| **Change preventers** | One change forces many edits | Divergent change (one class changes for many unrelated reasons), Shotgun surgery (one reason changes many classes), Parallel inheritance hierarchies |
| **Dispensables** | Code that adds nothing | Comments that explain bad code, Duplicate code, Lazy class, Data class (only fields, no behaviour), Dead code, Speculative generality ("we might need it") |
| **Couplers** | Too much coupling between classes | Feature envy (a method uses another class's data more than its own), Inappropriate intimacy (classes reach into each other's internals), Message chains (`a.b().c().d()`), Middle man (a class that only delegates) |

Where you have already met them: *Switch statements* was lesson 03 of level 101 (Open/Closed), *Data class* and *Anemic model* come back in lesson 08, *Speculative generality* is YAGNI (101 lesson 07), *Shotgun surgery* is what a missing abstraction costs in lesson 07 of this level.

### Step 3. The smelly module and the scanner: Python
**File: `~/code101/patterns301/lesson06/python/smelly.py`**
```python
def make_invoice(name, email, street, city, zip_code, items, coupon, country, express):
    total = 0
    for item in items:
        total += item[1] * item[2]
    if coupon == "SAVE10":
        total -= total // 10
    elif coupon == "SAVE20":
        total -= total // 5
    if country == "DE":
        total += total * 19 // 100
    elif country == "FR":
        total += total * 20 // 100
    if express:
        if country == "US":
            if total > 10000:
                total += 0
            else:
                total += 2500
        else:
            total += 4000
    address = f"{street}, {zip_code} {city}"
    return f"Invoice for {name} <{email}>\n{address}\nTotal: {total}"


def label(order_id, amount):
    return f"#{order_id}: {amount}"


class OrderManager:
    def __init__(self):
        self.orders = []

    def add(self, order):
        self.orders.append(order)

    def total(self):
        return sum(o["amount"] for o in self.orders)

    def to_csv(self):
        return "\n".join(f"{o['id']},{o['amount']}" for o in self.orders)

    def send_email(self, address):
        return f"mailed {len(self.orders)} orders to {address}"

    def print_report(self):
        return f"{len(self.orders)} orders, total {self.total()}"

    def apply_tax(self, rate):
        for o in self.orders:
            o["amount"] += o["amount"] * rate // 100
```
Count the smells yourself before you read on: `make_invoice` has a **long method** (22 lines), a **long parameter list** (9), **data clumps** (`street, city, zip_code`), **primitive obsession** (items are tuples, the country is a string), **switch statements** (the country and coupon ladders), a **dead branch** (`total += 0`: dispensable), **magic numbers** (`19`, `20`, `2500`, `4000`) and **deep nesting**. `OrderManager` is a **large class** with at least four reasons to change: storage (`add`), reporting (`print_report`, `to_csv`), mail (`send_email`) and tax rules (`apply_tax`): **divergent change** waiting to happen.

**File: `~/code101/patterns301/lesson06/python/scanner.py`**
```python
import ast
from pathlib import Path

MAX_LINES = 20
MAX_PARAMS = 4
MAX_NESTING = 2
MAX_METHODS = 5


def measure(function, lines):
    start, end = function.lineno, function.end_lineno
    own_lines = [line for line in lines[start - 1:end] if line.strip()]
    def_indent = len(lines[start - 1]) - len(lines[start - 1].lstrip())
    deepest = max(len(line) - len(line.lstrip()) for line in own_lines)
    params = [a.arg for a in function.args.args if a.arg != "self"]
    return {
        "name": function.name,
        "lines": end - start + 1,
        "params": len(params),
        "nesting": max(0, (deepest - def_indent) // 4 - 1),
    }


def scan(path):
    source = Path(path).read_text(encoding="utf-8")
    lines = source.splitlines()
    functions, classes = [], []
    for node in ast.parse(source).body:
        if isinstance(node, ast.FunctionDef):
            functions.append(measure(node, lines))
        elif isinstance(node, ast.ClassDef):
            methods = [m for m in node.body if isinstance(m, ast.FunctionDef) and not m.name.startswith("__")]
            functions.extend(measure(m, lines) for m in methods)
            classes.append((node.name, len(methods)))
    return functions, classes


def flags(measurement):
    found = []
    if measurement["lines"] > MAX_LINES:
        found.append("long method")
    if measurement["params"] > MAX_PARAMS:
        found.append("long parameter list")
    if measurement["nesting"] > MAX_NESTING:
        found.append("deep nesting")
    return found
```
Notes: `ast` is Python's own parser, so parameter counts and line ranges (`lineno`, `end_lineno`) are exact. Nesting is read from **indentation** because the parser stores `elif` as an `if` nested in the `else` of the previous `if`, which would wrongly count a flat ladder as deep. The scanner counts non-dunder methods (methods whose names do not start with `__`) and skips `self`.

**File: `~/code101/patterns301/lesson06/python/main.py`**
```python
from pathlib import Path

import smelly
from scanner import MAX_METHODS, flags, scan


def main():
    items = [("pen", 150, 2), ("book", 1200, 1)]
    print(smelly.make_invoice("Ana", "ana@example.com", "1 Main St", "Oslo", "0150", items, "SAVE10", "DE", True))

    manager = smelly.OrderManager()
    manager.add({"id": 1, "amount": 100})
    manager.add({"id": 2, "amount": 250})
    print(manager.print_report())

    functions, classes = scan(Path(__file__).with_name("smelly.py"))
    print(f"scanned {len(functions)} functions or methods")
    for item in functions:
        problems = flags(item)
        if problems:
            print(f"{item['name']}: lines={item['lines']} params={item['params']} nesting={item['nesting']} -> {', '.join(problems)}")
    for name, count in classes:
        if count > MAX_METHODS:
            print(f"class {name}: methods={count} -> large class")


main()
```

### Step 4. C#
**File: `~/code101/patterns301/lesson06/csharp/Lesson.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net11.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

</Project>
```

**File: `~/code101/patterns301/lesson06/csharp/Smelly.cs`**
```csharp
namespace SmellyCode;

public record Item(string Name, int Price, int Qty);

public record Order(int Id, int Amount);

public class InvoiceMaker
{
    public string MakeInvoice(string name, string email, string street, string city, string zipCode, List<Item> items, string coupon, string country, bool express)
    {
        var total = 0;
        foreach (var item in items)
        {
            total += item.Price * item.Qty;
        }
        if (coupon == "SAVE10")
        {
            total -= total / 10;
        }
        else if (coupon == "SAVE20")
        {
            total -= total / 5;
        }
        if (country == "DE")
        {
            total += total * 19 / 100;
        }
        else if (country == "FR")
        {
            total += total * 20 / 100;
        }
        if (express)
        {
            if (country == "US")
            {
                if (total > 10000)
                {
                    total += 0;
                }
                else
                {
                    total += 2500;
                }
            }
            else
            {
                total += 4000;
            }
        }
        var address = $"{street}, {zipCode} {city}";
        return $"Invoice for {name} <{email}>\n{address}\nTotal: {total}";
    }

    public string Label(int orderId, int amount)
    {
        return $"#{orderId}: {amount}";
    }
}

public class OrderManager
{
    private readonly List<Order> _orders = new();

    public void Add(Order order)
    {
        _orders.Add(order);
    }

    public int Total()
    {
        return _orders.Sum(o => o.Amount);
    }

    public string ToCsv()
    {
        return string.Join("\n", _orders.Select(o => $"{o.Id},{o.Amount}"));
    }

    public string SendEmail(string address)
    {
        return $"mailed {_orders.Count} orders to {address}";
    }

    public string PrintReport()
    {
        return $"{_orders.Count} orders, total {Total()}";
    }

    public void ApplyTax(int rate)
    {
        for (var i = 0; i < _orders.Count; i++)
        {
            _orders[i] = _orders[i] with { Amount = _orders[i].Amount + _orders[i].Amount * rate / 100 };
        }
    }
}
```
Same smells, C# syntax. The C# method is longer in lines (44) only because every block has braces on their own lines: **line counts are not comparable across languages**; compare a team's code only against the same language.

**File: `~/code101/patterns301/lesson06/csharp/Scanner.cs`**
```csharp
using System.Text.RegularExpressions;

public sealed record Measurement(string Name, int Lines, int Params, int Nesting);

public static class Scanner
{
    public const int MaxLines = 20;
    public const int MaxParams = 4;
    public const int MaxNesting = 2;
    public const int MaxMethods = 5;

    private static readonly Regex ClassLine = new(@"^(public |internal )?(sealed )?class (\w+)");
    private static readonly Regex MethodLine = new(@"^( +)(public|private|internal|protected)( static)? [\w<>\[\]?]+ (\w+)\((.*)\)$");

    public static (List<Measurement> Methods, List<(string Name, int Count)> Classes) Scan(string[] lines)
    {
        var methods = new List<Measurement>();
        var classes = new List<(string Name, int Count)>();
        string? current = null;
        var count = 0;
        for (var i = 0; i < lines.Length; i++)
        {
            var classMatch = ClassLine.Match(lines[i]);
            if (classMatch.Success)
            {
                if (current is not null)
                {
                    classes.Add((current, count));
                }
                current = classMatch.Groups[3].Value;
                count = 0;
                continue;
            }
            var match = MethodLine.Match(lines[i]);
            if (!match.Success)
            {
                continue;
            }
            var indent = match.Groups[1].Length;
            var end = i + 1;
            while (end < lines.Length && lines[end] != new string(' ', indent) + "}")
            {
                end++;
            }
            var deepest = lines[i..(end + 1)].Where(l => l.Trim().Length > 0).Max(l => l.Length - l.TrimStart().Length);
            var parameters = match.Groups[5].Value.Trim().Length == 0 ? 0 : match.Groups[5].Value.Split(',').Length;
            methods.Add(new Measurement(match.Groups[4].Value, end - i + 1, parameters, Math.Max(0, (deepest - indent) / 4 - 1)));
            count++;
        }
        if (current is not null)
        {
            classes.Add((current, count));
        }
        return (methods, classes);
    }

    public static List<string> Flags(Measurement measurement)
    {
        var found = new List<string>();
        if (measurement.Lines > MaxLines)
        {
            found.Add("long method");
        }
        if (measurement.Params > MaxParams)
        {
            found.Add("long parameter list");
        }
        if (measurement.Nesting > MaxNesting)
        {
            found.Add("deep nesting");
        }
        return found;
    }
}
```
This scanner is a **heuristic**, not a parser: two regular expressions recognise class and method lines, and the method ends at the first line that is exactly the method's indent plus `}`. It works for this file's formatting and will break on others (expression-bodied members, attributes, generics with commas in parameters). For real projects use the Roslyn analyzers or the metrics of your IDE; the point here is the *measurement habit*.

**File: `~/code101/patterns301/lesson06/csharp/Program.cs`**
```csharp
using SmellyCode;

var maker = new InvoiceMaker();
var items = new List<Item> { new("pen", 150, 2), new("book", 1200, 1) };
Console.WriteLine(maker.MakeInvoice("Ana", "ana@example.com", "1 Main St", "Oslo", "0150", items, "SAVE10", "DE", true));

var manager = new OrderManager();
manager.Add(new Order(1, 100));
manager.Add(new Order(2, 250));
Console.WriteLine(manager.PrintReport());

var (methods, classes) = Scanner.Scan(File.ReadAllLines("Smelly.cs"));
Console.WriteLine($"scanned {methods.Count} functions or methods");
foreach (var method in methods)
{
    var problems = Scanner.Flags(method);
    if (problems.Count > 0)
    {
        Console.WriteLine($"{method.Name}: lines={method.Lines} params={method.Params} nesting={method.Nesting} -> {string.Join(", ", problems)}");
    }
}
foreach (var (name, count) in classes)
{
    if (count > Scanner.MaxMethods)
    {
        Console.WriteLine($"class {name}: methods={count} -> large class");
    }
}
```

## Run it
Predict first: of the 8 functions and methods scanned, how many will be flagged, and will `OrderManager`'s methods be flagged individually? <details><summary>Answer</summary>One function (`make_invoice` / `MakeInvoice`). Each `OrderManager` method is short; the smell there is the *class*, which the class check reports separately.</details>

**PowerShell, folder: `~/code101/patterns301/lesson06/python`**
```powershell
Set-Location "$HOME/code101/patterns301/lesson06/python"
python main.py
```
**macOS/Linux terminal, folder: `~/code101/patterns301/lesson06/python`**
```bash
cd ~/code101/patterns301/lesson06/python
python3 main.py
```
Expected output, Python (derived by reading the code, not yet run):
```text
Invoice for Ana <ana@example.com>
1 Main St, 0150 Oslo
Total: 5606
2 orders, total 350
scanned 8 functions or methods
make_invoice: lines=22 params=9 nesting=3 -> long method, long parameter list, deep nesting
class OrderManager: methods=6 -> large class
```
**Any terminal, folder: `~/code101/patterns301/lesson06/csharp`** (the program opens `Smelly.cs` in the current folder, so run it from the folder that contains the `.csproj`)
```text
dotnet run --project . --nologo
```
Expected output, C# (derived by reading the code, not yet run):
```text
Invoice for Ana <ana@example.com>
1 Main St, 0150 Oslo
Total: 5606
2 orders, total 350
scanned 8 functions or methods
MakeInvoice: lines=44 params=9 nesting=3 -> long method, long parameter list, deep nesting
class OrderManager: methods=6 -> large class
```
How the total 5606 comes about: items 300 + 1200 = 1500; coupon `SAVE10` takes 150, giving 1350; German tax adds 1350 x 19 / 100 = 256 (integer division), giving 1606; express shipping outside the US adds 4000.

## How it works
- **What the scanner can and cannot see.** It sees size and nesting. It cannot see *duplicate code*, *feature envy*, *shotgun surgery* or *primitive obsession*; those need reading, a clone detector or the change history. **Measure what is cheap, read for the rest.**
- **Thresholds are agreements.** 20 lines, 4 parameters, nesting 2 and 5 methods are this lesson's numbers. Pick yours from your own code base (for example the 90th percentile of today's code) and tighten them as the code improves; never claim a universal number.
- **A smell is a hint.** A long `switch` that maps 40 codes to names is fine and clear. A 15-line method that mixes pricing, mail and storage is not. Look at *reasons to change*, not at line counts.
- **Cost of change decides priority.** Use the change history: `git log --format= --name-only | sort | uniq -c | sort -rn | head` lists the files changed most often (works in a Unix shell; on PowerShell use `git log --format= --name-only | Group-Object | Sort-Object Count -Descending | Select-Object -First 10`). A smell in a hot file costs every week; the same smell in a file nobody touches costs nothing.

### Misconceptions
- **"Zero smells is the goal."** No. The goal is cheap, safe change. A smell you decide to live with, with a reason written in the review, is a decision; a smell nobody noticed is debt.
- **"Comments are always a smell."** Comments that explain *why* (a business rule, a workaround with a ticket link) are valuable; comments that explain *what* confusing code does are the smell. The smell is the confusing code.

### Failure modes of using smells
- **Metric gaming.** Splitting a 25-line method into five 5-line methods that share a dozen mutable variables lowers the score and raises the confusion. Review the result, not the number.
- **Big-bang clean-up.** A week of "fix all smells" with no tests changes behaviour and hides bugs (next lesson: tests first).
- **Style wars.** Using smells to win taste arguments. Tie every smell finding to a concrete cost: bug, delay, onboarding time.
- **False precision.** The scanner above counts lines of code and parameters only; do not publish a "quality score" built from three numbers.

### ADR-0006
- **Context:** the team reviews pull requests by feel and disagrees.
- **Decision:** adopt the five smell group names as review vocabulary; run a metrics check in CI only on files changed in the pull request, with thresholds taken from the current 90th percentile and lowered each quarter; no repository-wide quality score.
- **Consequences:** shared words and a gradual trend, at the price of a CI step and an occasional argument about thresholds. Re-evaluate after two quarters using defect and review-time data, not opinions.

## Try it
**Rung 1, guided.** Copy the `starter` folder of your language to `try06` (copy the folder itself and rename it). Add one more automatic check: **too many branches** (the *conditional complexity* hint of the Switch Statements smell).

**File: `try06/main.py`**
```python
import ast

SOURCE = '''
def price(kind, qty):
    if kind == "a":
        return qty * 3
    elif kind == "b":
        return qty * 4
    elif kind == "c":
        return qty * 5
    return 0


def double(x):
    return x * 2
'''

MAX_BRANCHES = 2


def count_branches(function):
    # TODO 1: return how many ast.If nodes are inside the function (ast.walk visits every node).
    return 0


for node in ast.parse(SOURCE).body:
    if isinstance(node, ast.FunctionDef):
        branches = count_branches(node)
        # TODO 2: print "<name>: branches=<n> -> too many branches" when branches is above MAX_BRANCHES,
        #         otherwise "<name>: branches=<n> -> ok".
        print(f"{node.name}: branches={branches}")
```

**File: `try06/Program.cs`** (with the plain `Lesson.csproj` from this lesson)
```csharp
using System.Text.RegularExpressions;

const int MaxBranches = 2;
var methods = new List<(string Name, string Code)>
{
    ("Price", """
        if (kind == "a") { return qty * 3; }
        else if (kind == "b") { return qty * 4; }
        else if (kind == "c") { return qty * 5; }
        return 0;
        """),
    ("Double", "return x * 2;"),
};

foreach (var (name, code) in methods)
{
    var branches = CountBranches(code);
    // TODO 2: print "<name>: branches=<n> -> too many branches" when branches is above MaxBranches,
    //         otherwise "<name>: branches=<n> -> ok".
    Console.WriteLine($"{name}: branches={branches}");
}

static int CountBranches(string code)
{
    // TODO 1: return how many times a C# if statement starts in the text (try Regex.Matches).
    return 0;
}
```
Expected output after your fix (Python names are lower case, C# names start with a capital letter):
```text
price: branches=3 -> too many branches
double: branches=0 -> ok
```
and in C#:
```text
Price: branches=3 -> too many branches
Double: branches=0 -> ok
```

**Rung 2, change.** Run the lesson's scanner on one of your own files (copy the scanner next to it and change the path). Which flagged function would you refactor first, and what does `git log` say about how often its file changes?

**Rung 3, stretch (no single answer).** Pick one smell the scanner cannot see (duplicate code or feature envy) and design a measurement: what would you count, what threshold, what false positives would you expect?

<details><summary>Solution</summary>

**File: `exercise/solution/python/main.py`**
```python
import ast

SOURCE = '''
def price(kind, qty):
    if kind == "a":
        return qty * 3
    elif kind == "b":
        return qty * 4
    elif kind == "c":
        return qty * 5
    return 0


def double(x):
    return x * 2
'''

MAX_BRANCHES = 2


def count_branches(function):
    return sum(isinstance(node, ast.If) for node in ast.walk(function))


for node in ast.parse(SOURCE).body:
    if isinstance(node, ast.FunctionDef):
        branches = count_branches(node)
        verdict = "too many branches" if branches > MAX_BRANCHES else "ok"
        print(f"{node.name}: branches={branches} -> {verdict}")
```

**File: `exercise/solution/csharp/Program.cs`**
```csharp
using System.Text.RegularExpressions;

const int MaxBranches = 2;
var methods = new List<(string Name, string Code)>
{
    ("Price", """
        if (kind == "a") { return qty * 3; }
        else if (kind == "b") { return qty * 4; }
        else if (kind == "c") { return qty * 5; }
        return 0;
        """),
    ("Double", "return x * 2;"),
};

foreach (var (name, code) in methods)
{
    var branches = CountBranches(code);
    var verdict = branches > MaxBranches ? "too many branches" : "ok";
    Console.WriteLine($"{name}: branches={branches} -> {verdict}");
}

static int CountBranches(string code)
{
    return Regex.Matches(code, @"\bif \(").Count;
}
```
In Python, `elif` is an `If` nested in the `else` of the previous `If`, so the ladder of three conditions gives three `If` nodes. Rung 3 sketch for duplicate code: hash normalised blocks of 6 or more lines (identifiers replaced by a placeholder) and count identical hashes; expect false positives for generated code and test data.
</details>

## Check yourself
1. `make_invoice` has nine parameters; name two smells that follow from that and the refactoring each one hints at. <details><summary>Answer</summary>Long parameter list and data clumps; introduce a parameter object (for example `Address`) and replace several values by one (lesson 07).</details>
2. Why does the Python scanner read nesting from indentation and not from the syntax tree? <details><summary>Answer</summary>An `elif` is stored as an `if` nested in the previous `else`, so a flat ladder would be counted as deeply nested.</details>
3. A function has 30 lines but one clear job and no churn in two years. Fix it now? <details><summary>Answer</summary>Probably not; the cost of a change is near zero. Spend the time on a smaller smell in a hot file.</details>
4. Which two smells here can the scanner not detect at all? <details><summary>Answer</summary>Primitive obsession and data clumps (and others such as feature envy): they need reading or history analysis.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `FileNotFoundException` mentioning `Smelly.cs` (typical .NET message) | The C# program was started from a folder without `Smelly.cs` | Run `dotnet run --project .` in the folder that contains the project and `Smelly.cs` |
| `ModuleNotFoundError: No module named 'smelly'` (typical Python message) | You ran `main.py` from another folder or renamed a file | Run it from the `python` folder; keep the three file names |
| The scanner reports other numbers than the lesson | Blank lines or a different indent in your copy | Keep four spaces per level and the exact file contents |
| Everything is flagged | Thresholds too low for your code | Take thresholds from your own percentiles |
| `IndexOutOfRangeException` or wrong line counts in C# (typical) | The file uses a style the heuristic does not know (expression-bodied members) | Keep the lesson's style or use Roslyn analyzers |

## Best practice
Use smell names as shared vocabulary, measure what is cheap to measure, and rank fixes by how often the code changes. Source: Code smells catalog, refactoring.guru https://refactoring.guru/refactoring/smells ; Refactoring catalog https://refactoring.guru/refactoring/catalog

## Going further
- Compare with the SourceMaking smell list (cross-check): https://sourcemaking.com/refactoring/smells
- Next lesson turns the three flagged smells of `make_invoice` into small safe steps.

## Summary
- You named the five smell groups and found examples of most of them in one small module.
- You measured long method, long parameter list, deep nesting and large class with a scanner, and read why the thresholds are only agreements.
- You listed the failure modes of smell-driven work (gaming, big-bang clean-ups, false precision).
- You chose by cost of change, with an ADR.

## Next lesson
07. Refactoring moves with tests as a safety net: extract, move, replace conditional with polymorphism and introduce parameter object, each protected by a golden-master test.
