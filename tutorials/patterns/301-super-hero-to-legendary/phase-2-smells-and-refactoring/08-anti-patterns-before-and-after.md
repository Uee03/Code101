---
track: patterns
level: 301
phase: 2
phase_name: smells-and-refactoring
lesson: 08
title: Anti-patterns with before and after
time: "60 min for one language, 90 min if you follow both"
prerequisites: [patterns 301 lessons 01, 06 and 07]
versions: { python: "3.10 or newer", dotnet: "11.0 SDK" }
verified: not yet run
source: source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/08-anti-patterns-before-and-after/
assets: []
---

# 08. Anti-patterns with before and after

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- recognise five anti-patterns (god object, anemic model, golden hammer, service locator, singleton abuse) in code and in a design discussion
- show for each one a concrete symptom you can observe in a running program, and the smallest fix
- name the situation in which each "anti-pattern" is acceptable
- write a review comment that names the cost, not just the label

## Recap
1. Lesson 01: what is the one place that may use the container? <details><summary>Answer</summary>The composition root.</details>
2. Lesson 07: what proves a refactoring changed structure only? <details><summary>Answer</summary>A characterization (golden master) test that stays green after each move.</details>

## Why it matters
An **anti-pattern** is a common solution that looks reasonable, is used again and again, and produces more harm than good. The word is a label for a *recurring mistake with a known better alternative*; it is not an insult for code you dislike. In reviews, "this is a god object" ends a conversation, while "this class needs the mail server to compute a report, so we cannot test it" starts one. This lesson gives you the second kind of sentence for five classic cases, each as a short before and after.

## What you will build
One program per language with five small before/after pairs, each ending in one printed line that shows the damage (before) or the cure (after):

| # | Anti-pattern | Observable symptom in the output |
|---|---|---|
| 1 | God object | A report cannot be built without a mail server setting |
| 2 | Anemic domain model | An importer completes a cancelled task, because the rule is somewhere else |
| 3 | Golden hammer | A regular expression "accepts" the date `2026-13-45` |
| 4 | Service locator | A missing dependency is found only when the method runs |
| 5 | Singleton abuse | State leaks from one "test" into the next |

## Before you start
- **Prerequisites:** Patterns 301 lessons [01, DI containers and composition roots](../phase-1-application-patterns/01-di-containers-and-composition-roots.md), [06, code smells catalog](06-code-smells-catalog.md) and [07, refactoring moves with tests](07-refactoring-moves-with-tests.md).
- Time: 60 minutes for one language, 90 for both.
- Python 3.10+ and/or the .NET 11 SDK. No packages.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/patterns/301-super-hero-to-legendary/phase-2-smells-and-refactoring/08-anti-patterns-before-and-after/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps

### Step 1. Make the lesson folders
**PowerShell, starting folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/patterns301/lesson08/python" -Force | Out-Null
New-Item -ItemType Directory -Path "$HOME/code101/patterns301/lesson08/csharp" -Force | Out-Null
Set-Location "$HOME/code101/patterns301/lesson08"
code .
```

**macOS/Linux terminal, starting folder: anywhere**
```bash
mkdir -p ~/code101/patterns301/lesson08/python ~/code101/patterns301/lesson08/csharp
cd ~/code101/patterns301/lesson08
code .
```
Expected result: VS Code opens `lesson08` with empty `python` and `csharp` folders.

### Step 2. Python
**File: `~/code101/patterns301/lesson08/python/main.py`**
```python
import inspect
import re
from dataclasses import dataclass
from datetime import date


# 1. God object: one class that needs everything, even for a simple report
class ConfigError(Exception):
    pass


class TaskManager:
    def __init__(self, smtp_host, db_path):
        if not smtp_host:
            raise ConfigError("smtp_host is required")
        self.db_path = db_path
        self.statuses = []

    def report(self):
        open_count = sum(1 for s in self.statuses if s != "done")
        return f"{open_count} open of {len(self.statuses)}"


def build_report(statuses):
    open_count = sum(1 for s in statuses if s != "done")
    return f"{open_count} open of {len(statuses)}"


# 2. Anemic model: rules live outside the data, so a second code path can skip them
@dataclass
class AnemicTask:
    title: str
    status: str = "todo"


def import_tasks(tasks):
    for task in tasks:
        task.status = "done"


class Task:
    def __init__(self, title, status="todo"):
        self.title = title
        self._status = status

    @property
    def status(self):
        return self._status

    def complete(self):
        if self._status == "cancelled":
            raise ValueError("a cancelled task cannot be completed")
        self._status = "done"


# 3. Golden hammer: a regular expression for a job a parser does better
def regex_accepts(text):
    return re.fullmatch(r"\d{4}-\d{2}-\d{2}", text) is not None


def parser_accepts(text):
    try:
        date.fromisoformat(text)
        return True
    except ValueError:
        return False


# 4. Service locator: dependencies hidden inside methods
class Locator:
    services = {}

    @classmethod
    def get(cls, name):
        if name not in cls.services:
            raise LookupError(f"{name} is not registered")
        return cls.services[name]


class LocatorReport:
    def run(self):
        return Locator.get("mailer").send("report")


class InjectedReport:
    def __init__(self, mailer):
        self.mailer = mailer

    def run(self):
        return self.mailer.send("report")


# 5. Singleton abuse: global state shared by every test
class Settings:
    _instance = None

    def __init__(self):
        self.currency = "EUR"

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = Settings()
        return cls._instance


def main():
    try:
        TaskManager(None, "tasks.db").report()
    except ConfigError as error:
        print(f"god object: cannot build a report: {error}")
    print(f"split: {build_report(['todo', 'done', 'todo'])}")

    legacy = AnemicTask("Old", "cancelled")
    import_tasks([legacy])
    print(f"anemic: importer completed a cancelled task, status={legacy.status}")
    rich = Task("Old", "cancelled")
    try:
        rich.complete()
    except ValueError as error:
        print(f"rich: rejected: {error}")

    print(f"hammer: regex accepts 2026-13-45: {regex_accepts('2026-13-45')}")
    print(f"right tool: date parser accepts 2026-13-45: {parser_accepts('2026-13-45')}")

    try:
        LocatorReport().run()
    except LookupError as error:
        print(f"service locator: found out at run time: {error}")
    needs = [name for name in inspect.signature(InjectedReport.__init__).parameters if name != "self"]
    print(f"constructor injection: dependencies visible: {', '.join(needs)}")

    Settings.instance().currency = "USD"
    print(f"singleton: second test sees {Settings.instance().currency} (leaked from the first)")
    print(f"injected: second test sees {Settings().currency}")


main()
```

### Step 3. C#
**File: `~/code101/patterns301/lesson08/csharp/Lesson.csproj`**
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

**File: `~/code101/patterns301/lesson08/csharp/Program.cs`**
```csharp
using System.Globalization;
using System.Text.RegularExpressions;

try
{
    new TaskManager(null, "tasks.db").Report();
}
catch (ConfigException error)
{
    Console.WriteLine($"god object: cannot build a report: {error.Message}");
}
Console.WriteLine($"split: {Reports.Build(["todo", "done", "todo"])}");

var legacy = new AnemicTask("Old", "cancelled");
Importer.ImportTasks([legacy]);
Console.WriteLine($"anemic: importer completed a cancelled task, status={legacy.Status}");
var rich = new RichTask("Old", "cancelled");
try
{
    rich.Complete();
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"rich: rejected: {error.Message}");
}

Console.WriteLine($"hammer: regex accepts 2026-13-45: {Dates.RegexAccepts("2026-13-45")}");
Console.WriteLine($"right tool: date parser accepts 2026-13-45: {Dates.ParserAccepts("2026-13-45")}");

try
{
    new LocatorReport().Run();
}
catch (KeyNotFoundException error)
{
    Console.WriteLine($"service locator: found out at run time: {error.Message}");
}
var needs = typeof(InjectedReport).GetConstructors()[0].GetParameters().Select(p => p.Name);
Console.WriteLine($"constructor injection: dependencies visible: {string.Join(", ", needs)}");

Settings.Instance.Currency = "USD";
Console.WriteLine($"singleton: second test sees {Settings.Instance.Currency} (leaked from the first)");
Console.WriteLine($"injected: second test sees {new Settings().Currency}");

public class ConfigException(string message) : Exception(message);

public class TaskManager
{
    private readonly List<string> _statuses = new();

    public TaskManager(string? smtpHost, string dbPath)
    {
        if (string.IsNullOrEmpty(smtpHost))
        {
            throw new ConfigException("smtp_host is required");
        }
        DbPath = dbPath;
    }

    public string DbPath { get; }

    public string Report()
    {
        var open = _statuses.Count(s => s != "done");
        return $"{open} open of {_statuses.Count}";
    }
}

public static class Reports
{
    public static string Build(List<string> statuses)
    {
        var open = statuses.Count(s => s != "done");
        return $"{open} open of {statuses.Count}";
    }
}

public class AnemicTask(string title, string status)
{
    public string Title { get; set; } = title;
    public string Status { get; set; } = status;
}

public static class Importer
{
    public static void ImportTasks(List<AnemicTask> tasks)
    {
        foreach (var task in tasks)
        {
            task.Status = "done";
        }
    }
}

public class RichTask(string title, string status)
{
    public string Title { get; } = title;
    public string Status { get; private set; } = status;

    public void Complete()
    {
        if (Status == "cancelled")
        {
            throw new InvalidOperationException("a cancelled task cannot be completed");
        }
        Status = "done";
    }
}

public static class Dates
{
    public static bool RegexAccepts(string text) => Regex.IsMatch(text, @"^\d{4}-\d{2}-\d{2}\z");

    public static bool ParserAccepts(string text) =>
        DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _);
}

public static class Locator
{
    public static Dictionary<string, object> Services { get; } = new();

    public static T Get<T>(string name) =>
        Services.TryGetValue(name, out var service) ? (T)service : throw new KeyNotFoundException($"{name} is not registered");
}

public interface IMailer
{
    string Send(string text);
}

public class LocatorReport
{
    public string Run() => Locator.Get<IMailer>("mailer").Send("report");
}

public class InjectedReport(IMailer mailer)
{
    public string Run() => mailer.Send("report");
}

public class Settings
{
    private static Settings? _instance;

    public static Settings Instance => _instance ??= new Settings();

    public string Currency { get; set; } = "EUR";
}
```

## Run it
Predict first: the god-object `TaskManager` is constructed with `smtp_host = None` just to build a report. Which line prints, and does the report text appear? <details><summary>Answer</summary>`god object: cannot build a report: smtp_host is required`. The constructor fails before `report()` is called, so the report text never appears for the god object; the split version prints it.</details>

**PowerShell, folder: `~/code101/patterns301/lesson08/python`**
```powershell
Set-Location "$HOME/code101/patterns301/lesson08/python"
python main.py
```
**macOS/Linux terminal, folder: `~/code101/patterns301/lesson08/python`**
```bash
cd ~/code101/patterns301/lesson08/python
python3 main.py
```
**Any terminal, folder: `~/code101/patterns301/lesson08/csharp`**
```text
dotnet run --project . --nologo
```
Expected output (derived by reading the code, not yet run; identical for Python and C#):
```text
god object: cannot build a report: smtp_host is required
split: 2 open of 3
anemic: importer completed a cancelled task, status=done
rich: rejected: a cancelled task cannot be completed
hammer: regex accepts 2026-13-45: True
right tool: date parser accepts 2026-13-45: False
service locator: found out at run time: mailer is not registered
constructor injection: dependencies visible: mailer
singleton: second test sees USD (leaked from the first)
injected: second test sees EUR
```

## How it works
### 1. God object
**Symptom:** a class that changes for many reasons and drags every configuration with it. **Why it appears:** the class is the obvious home for the next feature ("it already has the tasks"). **Cost:** you cannot construct it for one small job, tests need a mail server, merge conflicts concentrate in one file. **Fix:** split by reason to change; the report became a pure function of the data. **When it is fine:** at the start of a prototype, as long as you split before the second team joins.

### 2. Anemic domain model
**Symptom:** classes with only data and getters/setters, and rules in "services" and importers. **Cost:** every code path that forgets the rule breaks an invariant: the importer completed a cancelled task. **Fix:** put the rule where the data lives (`Task.complete()`), make the state private, expose behaviour. **When it is fine:** simple CRUD with almost no rules, or transaction scripts where the logic is genuinely procedural. Martin Fowler calls the anemic model an anti-pattern for *rich* domains; for forms over data it is just honest. Do not build a rich model for a table editor.

### 3. Golden hammer
**Symptom:** "if all you have is a hammer": the favourite tool (regex, an event bus, a microservice, the ORM, a mediator) used for everything. The regex accepted a date that does not exist; a date parser would not. **Fix:** ask what the problem *is* (validate a calendar date) before choosing the tool. **Check:** can you name one alternative you rejected and why? **When it is fine:** a team that knows one tool deeply can ship faster than one that chases perfect tools; the anti-pattern is *not looking*.

### 4. Service locator
**Symptom:** classes pull dependencies from a global registry inside methods. The constructor gives no hint, and a missing registration shows up only when that line runs, maybe in production at 3 a.m. **Fix:** constructor injection: the constructor signature lists the dependencies (`mailer`), a missing one fails at construction or start-up (lesson 01). **When it is fine:** inside the composition root and in framework glue where you cannot control construction (a plug-in loader, a middleware that resolves per-request services).

### 5. Singleton abuse
**Symptom:** a global instance with mutable state. One test sets the currency to USD and the next test, which assumed the default, sees USD. Tests that pass alone and fail together, or only in a certain order, are the classic sign. **Fix:** create one instance in the composition root and pass it in; a *container-managed* singleton lifetime gives "one instance" without a global. **When it is fine:** truly process-wide, effectively immutable objects (a configuration loaded once at start, a static logger factory, a `Random` seeded once), and even then prefer to inject them.

### Failure modes of anti-pattern hunting
- **Labels instead of costs.** "This is an anti-pattern" without a symptom is an opinion. Always attach an observed cost.
- **Dogma.** Calling every static method a singleton, or every shared class a god object. Check change frequency first (lesson 06).
- **Cure worse than disease.** Splitting a 300-line class into 12 tiny classes that all know each other (*inappropriate intimacy*) is a new anti-pattern. Run the code metrics and the golden master from lesson 07.
- **Fixing in the wrong order.** Replace service locator with injection first: it makes dependencies visible, which makes the god object and the singletons easy to see.
- **Big-bang rewrite.** Fix at the seam you are touching for a feature (the *boy-scout* rule); keep a list of known debts with an owner.

### ADR-0008
- **Context:** The legacy API has a `TaskManager` of 1,800 lines, global `Settings.instance()` and a locator used in 40 places.
- **Decision:** do not rewrite. For every change in an area: (1) inject `Settings` through the constructor, (2) replace locator calls with constructor parameters, (3) extract the report and the importer rule into small objects, each with a characterization test. Track remaining locator calls as a number on the team board.
- **Consequences:** progress is visible and incremental; the old code and the new code coexist for months; new code must not add locator calls (enforced by a review rule, later a lint rule).

## Try it
**Rung 1, guided.** Copy the `starter` folder of your language to `try08` (copy the folder itself and rename it). Replace a singleton counter with an injected one. Before your fix the program prints `counter is 1` and then `counter is 2`: state leaked between "tests".

**File: `try08/main.py`**
```python
class Counter:
    _instance = None

    def __init__(self):
        self.value = 0

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = Counter()
        return cls._instance


def hit():
    # TODO 1: receive a Counter as a parameter, increment that counter and stop using Counter.instance().
    Counter.instance().value += 1


def run_test(name):
    # TODO 2: create a new Counter here and pass it to hit.
    hit()
    # TODO 3: print the value of the counter you created instead of the shared one.
    print(f"{name}: counter is {Counter.instance().value}")


run_test("test one")
run_test("test two")
```

**File: `try08/Program.cs`** (with the `Lesson.csproj` from this lesson)
```csharp
RunTest("test one");
RunTest("test two");

static void Hit()
{
    // TODO 1: receive a Counter as a parameter, increment that counter and stop using Counter.Instance.
    Counter.Instance.Value++;
}

static void RunTest(string name)
{
    // TODO 2: create a new Counter here and pass it to Hit.
    Hit();
    // TODO 3: print the value of the counter you created instead of the shared one.
    Console.WriteLine($"{name}: counter is {Counter.Instance.Value}");
}

class Counter
{
    private static Counter? _instance;

    public static Counter Instance => _instance ??= new Counter();

    public int Value { get; set; }
}
```
Expected output after your fix:
```text
test one: counter is 1
test two: counter is 1
```

**Rung 2, change.** Write one more "test" that expects the counter to start at 0 and runs *first*, then move it to the end. Which design makes the result independent of the order?

**Rung 3, stretch (no single answer).** Pick one anti-pattern from your own code base. Write the review comment as: symptom you observed, cost you measured or can estimate, smallest fix, and the condition under which you would leave it alone.

<details><summary>Solution</summary>

**File: `exercise/solution/python/main.py`**
```python
class Counter:
    def __init__(self):
        self.value = 0


def hit(counter):
    counter.value += 1


def run_test(name):
    counter = Counter()
    hit(counter)
    print(f"{name}: counter is {counter.value}")


run_test("test one")
run_test("test two")
```

**File: `exercise/solution/csharp/Program.cs`**
```csharp
RunTest("test one");
RunTest("test two");

static void Hit(Counter counter)
{
    counter.Value++;
}

static void RunTest(string name)
{
    var counter = new Counter();
    Hit(counter);
    Console.WriteLine($"{name}: counter is {counter.Value}");
}

class Counter
{
    public int Value { get; set; }
}
```
Rung 2 answer: with an injected counter each test builds its own, so order cannot matter. With the singleton the first test that runs decides the starting value for all the others.
</details>

## Check yourself
1. Why can the importer complete a cancelled task in the anemic version but not in the rich one? <details><summary>Answer</summary>In the anemic version `status` is a public field any code can set; in the rich version it is private and only `complete()` changes it, and `complete()` enforces the rule.</details>
2. Give two situations in which a service locator is acceptable. <details><summary>Answer</summary>The composition root, and framework glue (plug-in loading, middleware) where you do not control construction.</details>
3. The regex "accepts 2026-13-45". Is the regex wrong? <details><summary>Answer</summary>No, it checks the shape as designed; it is the wrong tool for validating a calendar date.</details>
4. Which output line shows a singleton problem and why does it appear only with several tests? <details><summary>Answer</summary>`singleton: second test sees USD ...`; global state survives between tests, so the order and the number of tests matter.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Test two prints `counter is 2` | Still using the shared instance (a TODO is missing) | Do TODO 1 to 3: create the counter inside `run_test`, pass it, print it |
| Both tests print `counter is 0` | You printed a new counter instead of the one you incremented | Print the same object you passed to `hit` |
| C# error CS7036 "There is no argument given that corresponds to the required parameter 'counter'" (typical message) | You changed `Hit(Counter counter)` but not the call | Pass the counter in `RunTest` |
| Python `TypeError: hit() missing 1 required positional argument: 'counter'` (typical message) | Same | Pass the counter |
| Reviewers dislike a "singleton" in the container | Confusion between the global singleton and the singleton *lifetime* | Explain: one instance created by the root, never reached through a global |

## Best practice
Name the cost, not the label: describe the observable symptom, the smallest fix, and the condition under which you would leave the code alone. Source: Anemic Domain Model, Martin Fowler https://martinfowler.com/bliki/AnemicDomainModel.html ; Dependency injection guidelines, Microsoft Learn https://learn.microsoft.com/dotnet/core/extensions/dependency-injection/guidelines ; Singleton (criticism section), refactoring.guru https://refactoring.guru/design-patterns/singleton ; Code smells, refactoring.guru https://refactoring.guru/refactoring/smells

## Going further
- Golden Hammer and other classic anti-patterns: https://sourcemaking.com/antipatterns
- Capstone use: the platform backends keep rules (such as "a cancelled task cannot be completed", enforced by the `complete_task` stored function and the `TS409` error) next to the data on purpose; see `capstones/platform/TDD.md`.

## Summary
- You saw five anti-patterns produce an observable symptom, and removed three of them with small changes.
- You wrote down for each when it is acceptable.
- You separated labels from costs in review comments.
- You planned an incremental clean-up with an ADR instead of a rewrite.

## Next lesson
09. Choosing patterns in one service: a decision framework, the cost of abstraction, and a realistic Tasks and Teams service that combines patterns from this level on purpose, starting phase 3.
