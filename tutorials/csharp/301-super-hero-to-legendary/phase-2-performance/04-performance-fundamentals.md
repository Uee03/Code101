---
track: csharp
level: 301
phase: 2
phase_name: performance
lesson: 04
title: "Performance fundamentals"
time: 70-90 min
prerequisites: [csharp 301.1.01, csharp 201.1.03, csharp 201.1.04]
versions: { dotnet_sdk: "11.0.100", target_framework: "net11.0", BenchmarkDotNet: "0.15.8" }
verified: not yet run
source: source/csharp/301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals/
assets: []
---

# 04. Performance fundamentals

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Write a BenchmarkDotNet benchmark with a baseline, parameters and the memory diagnoser, and run it in Release.
- Explain why `string.Split` allocates, why `ReadOnlySpan<char>` does not, and the rules that come with spans.
- Decide when `ValueTask<T>` is worth its restrictions.
- Follow the loop "check correctness, measure, change one thing, measure again" and record results without inventing numbers.

## Recap
1. (Lesson 02) What does a decorator add to a handler, and what must it keep the same?
   <details><summary>Answer</summary>One cross-cutting concern (logging here); it keeps the same interface so callers do not change.</details>
2. (Lesson 03) Why is `Money` a class and not a `record struct`?
   <details><summary>Answer</summary>A struct can be `default`, bypassing validation. (This lesson revisits the cost of that choice: classes allocate.)</details>

## Why it matters
Performance work has two failure modes: ignoring it until production hurts, and "optimizing" by feel. The second is worse, because it trades readable code for changes that may not matter, or that make things slower. A senior engineer's skill here is **measurement discipline**: know what to measure, measure in a way that cannot lie, and stop when the numbers say stop.

## What you will build
A small console project, `Perf`, with: two functions that sum a comma-separated line (one with `Split`, one with spans), a correctness check, an allocation probe and two BenchmarkDotNet benchmark classes (spans, and `Task` against `ValueTask`). **This lesson publishes no timings.** Your machine, runtime build, CPU and background load decide the numbers, so you will produce your own and record them in a table you fill in.

## Before you start
- **Prerequisites:** [C# 301 lesson 01, clean architecture and vertical slices](../phase-1-architecture/01-clean-architecture-and-vertical-slices.md); C# 201 lessons [03, LINQ](../../201-hero-to-super-hero/phase-1-core-skills/03-linq.md) and [04, async/await and Task](../../201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md).
- Tools: .NET SDK **11.0.100**; a terminal; a machine that is **plugged in**, with other heavy programs closed (laptops on battery saver give noisy results).
- Time: 70-90 minutes. Benchmark runs take minutes; plan the wait.
- Folder: create `lesson04` as in lesson 01 Step 1 (only `lesson04`, files directly inside) and copy `global.json` from lesson 01 Step 2.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-2-performance/04-performance-fundamentals/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. The project
**File: `Perf.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net11.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="BenchmarkDotNet" Version="0.15.8" />
  </ItemGroup>

</Project>
```
`BenchmarkDotNet` 0.15.8 was the newest stable release when this lesson was written. Packages restore from NuGet on the first build, so you need internet access once. There is no lockfile to copy: it is created by the first `dotnet restore` if you enable `RestorePackagesWithLockFile` (lesson 10 discusses this).

### Step 2. Two implementations of the same job
**File: `LineSum.cs`**
```csharp
using System.Globalization;

namespace Perf;

public static class LineSum
{
    // Easy to read, but Split allocates an array and one string per field on every call.
    public static int SumSplit(string line)
    {
        var total = 0;
        foreach (var part in line.Split(','))
        {
            total += int.Parse(part, CultureInfo.InvariantCulture);
        }

        return total;
    }

    // Same result, same exceptions for bad input, but it slices the original text and allocates nothing.
    public static int SumSpan(ReadOnlySpan<char> line)
    {
        var total = 0;
        while (true)
        {
            var comma = line.IndexOf(',');
            var part = comma < 0 ? line : line[..comma];
            total += int.Parse(part, CultureInfo.InvariantCulture);
            if (comma < 0)
            {
                return total;
            }

            line = line[(comma + 1)..];
        }
    }
}
```
A `ReadOnlySpan<char>` is a **view** (pointer plus length) over memory that already exists. Slicing it with `line[..comma]` creates another view, not a new string. `CultureInfo.InvariantCulture` makes parsing independent of the machine's regional settings, which is also a correctness rule. The loop structure (instead of `while (!line.IsEmpty)`) is deliberate: an empty last field, as in `"1,2,"`, must fail in both versions exactly the same way. A faster function that accepts input the slower one rejects is a behavior change, not an optimization.

### Step 3. Benchmarks
**File: `Benchmarks.cs`**
```csharp
using BenchmarkDotNet.Attributes;

namespace Perf;

// Benchmark classes must be public and not sealed. MemoryDiagnoser adds the allocated-bytes column.
[MemoryDiagnoser]
public class SumBenchmarks
{
    private string line = "";

    [Params(10, 1000)]
    public int Count;

    [GlobalSetup]
    public void Setup() => line = string.Join(',', Enumerable.Range(1, Count));

    [Benchmark(Baseline = true)]
    public int Split() => LineSum.SumSplit(line);

    [Benchmark]
    public int Span() => LineSum.SumSpan(line);
}

[MemoryDiagnoser]
public class CacheHitBenchmarks
{
    private readonly Dictionary<int, int> cache = new() { [1] = 42 };

    [Benchmark(Baseline = true)]
    public Task<int> TaskResult() => GetWithTask(1);

    [Benchmark]
    public ValueTask<int> ValueTaskResult() => GetWithValueTask(1);

    private Task<int> GetWithTask(int key) =>
        cache.TryGetValue(key, out var value) ? Task.FromResult(value) : LoadSlowAsync(key);

    private ValueTask<int> GetWithValueTask(int key) =>
        cache.TryGetValue(key, out var value) ? new ValueTask<int>(value) : new ValueTask<int>(LoadSlowAsync(key));

    private static async Task<int> LoadSlowAsync(int key)
    {
        await Task.Delay(10);
        return key;
    }
}
```
What each attribute does:
- `[Benchmark]` marks a method to measure; `Baseline = true` makes the other methods report a **Ratio** against it.
- `[Params(10, 1000)]` runs every benchmark once per value, so you see how cost scales (a speedup at 10 items may vanish or grow at 1000).
- `[GlobalSetup]` runs once per parameter set, outside the measured time.
- Each benchmark **returns** its result. BenchmarkDotNet consumes it, which stops the JIT from deleting "dead" code that nobody uses.
- `[MemoryDiagnoser]` reports allocations per operation (the `Allocated` column) and garbage collections (`Gen0`, `Gen1`, `Gen2` per 1000 operations).

The second class measures the **hit path** of a cache that returns a `Task<int>` against one that returns a `ValueTask<int>`. The miss path awaits real asynchronous work. The question it answers is narrow: "when most calls finish synchronously, what does returning a `Task` cost?" If most calls are misses, the answer changes.

### Step 4. The entry point
**File: `Program.cs`**
```csharp
using BenchmarkDotNet.Running;
using Perf;

// Step 1 of every optimization: prove the two versions agree. A fast wrong answer is not an optimization.
if (args.Contains("--check"))
{
    const string line = "10,20,30";
    Console.WriteLine($"Split: {LineSum.SumSplit(line)}");
    Console.WriteLine($"Span: {LineSum.SumSpan(line)}");
    Console.WriteLine($"Same result: {LineSum.SumSplit(line) == LineSum.SumSpan(line)}");
    return;
}

// A quick look at allocated bytes on this thread. It is a sanity check, not a benchmark: it has no warm-up or statistics.
if (args.Contains("--alloc"))
{
    var text = string.Join(',', Enumerable.Range(1, 1000));
    LineSum.SumSplit(text);
    LineSum.SumSpan(text);

    var before = GC.GetAllocatedBytesForCurrentThread();
    LineSum.SumSplit(text);
    var split = GC.GetAllocatedBytesForCurrentThread() - before;

    before = GC.GetAllocatedBytesForCurrentThread();
    LineSum.SumSpan(text);
    var span = GC.GetAllocatedBytesForCurrentThread() - before;

    Console.WriteLine($"Split allocated {split} bytes, Span allocated {span} bytes (numbers depend on your machine and runtime).");
    return;
}

// Everything else goes to BenchmarkDotNet, for example: --filter "*SumBenchmarks*"
BenchmarkSwitcher.FromAssembly(typeof(SumBenchmarks).Assembly).Run(args);
```
`BenchmarkSwitcher` lets you choose benchmark classes from the command line with `--filter`. The two small modes before it run in milliseconds and answer different questions: `--check` proves equivalence; `--alloc` gives a rough allocated-bytes comparison without the benchmark harness. The warm-up calls before the measured ones make the JIT compile both methods first, so compilation is not counted.

## Run it
All commands run in `lesson04`. **Always use `-c Release`** for anything you measure.

**1. Correctness first.**
```text
dotnet run --project . -c Release --nologo -- --check
```
The `--` separates `dotnet run` options from your program's arguments. Expected output (not yet run; derived from the code):
```text
Split: 60
Span: 60
Same result: True
```

**2. Predict, then probe allocations.** Which of the two will report 0 allocated bytes, and why might the other report a number of several kilobytes for 1000 fields?
```text
dotnet run --project . -c Release --nologo -- --alloc
```
The output has this shape; the byte counts are yours to read and write down (they vary with runtime and machine, so none are printed here):
```text
Split allocated <bytes> bytes, Span allocated <bytes> bytes (numbers depend on your machine and runtime).
```
Expect `Split` to be clearly larger than `Span`: it creates an array and a string per field. If `Span` is not 0, do not panic; the runtime or tiered compilation can allocate on first calls, and this probe is not a benchmark.

**3. The real benchmark.** This takes several minutes. Close other programs.
```text
dotnet run --project . -c Release --nologo -- --filter "*SumBenchmarks*"
```
BenchmarkDotNet prints environment information, then a summary table. The columns typically look like this (the cells are the numbers you must record yourself):

| Method | Count | Mean | Error | StdDev | Ratio | Gen0 | Allocated | Alloc Ratio |
|---|---|---|---|---|---|---|---|---|
| Split | 10 | _yours_ | _yours_ | _yours_ | 1.00 | _yours_ | _yours_ | 1.00 |
| Span | 10 | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ |
| Split | 1000 | _yours_ | _yours_ | _yours_ | 1.00 | _yours_ | _yours_ | 1.00 |
| Span | 1000 | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ | _yours_ |

Repeat with `--filter "*CacheHitBenchmarks*"`. Results are also written to a `BenchmarkDotNet.Artifacts` folder next to where you ran the command; keep it out of version control.

## How it works
**Where allocations come from.** Every `new` of a class (and every string, array, boxed value, closure and LINQ enumerator) takes memory from the managed heap. The garbage collector (GC) reclaims it later. Short-lived garbage is cheap per object, but it is not free: it consumes allocation throughput, pushes data out of CPU caches and triggers collections that pause or slow threads. Large objects (about 85,000 bytes and up) go to the **large object heap**, which is collected less often and can fragment. Allocation is usually the first thing to look at in a hot path, because it is easy to measure and often easy to remove.

**Span rules (why they exist).** `Span<T>` and `ReadOnlySpan<T>` are `ref struct` types: they may point into the stack, so they cannot live on the heap. Consequences: they cannot be fields of a normal class, cannot be captured by lambdas, and cannot be used across an `await` in an async method. When you need that, use `Memory<T>` (a heap-friendly handle) and take a span from it inside the synchronous part of the code.

**`ValueTask<T>` rules.** A `ValueTask<T>` can wrap a result with no allocation when the operation completes synchronously. The price is a stricter contract: await it **once**, do not await it from several places, do not call `.Result` or `.GetAwaiter().GetResult()` on one that is not complete, and convert it to a `Task` with `.AsTask()` if you need to share it. Microsoft's guidance is to default to `Task` and use `ValueTask` for measured hot paths where most calls complete synchronously.

**The measurement loop** (write this on a card):
1. Define the question and the metric (time, allocations, throughput, p99 latency).
2. Prove the new code gives the same answers (`--check`).
3. Measure the **baseline** in Release, on a quiet machine.
4. Change **one** thing.
5. Measure again; keep the change only if the difference is larger than the run-to-run noise (the `Error` and `StdDev` columns) **and** matters to the user or the budget.

**Misconception:** "Span is always faster." A span removes allocations; whether that is faster depends on how much time the allocation really cost in your workload. For ten short fields in a path that runs once per request, the difference is invisible next to a database call.

### ADR-004: Optimize the measured hot path only
| Field | Content |
|---|---|
| Context | A line parser runs inside a batch import. Profiling (not guessing) shows parsing as the top allocator. |
| Decision | Replace `Split` with the span version **in that one function**, behind the same public signature, with a `--check`-style test for equivalence. Leave the rest of the code readable. |
| Consequences | + Fewer allocations where it matters. - A less obvious function that needs a comment and a test. - Future maintainers must keep both behaviors identical. |
| Revisit when | The import is replaced, or a profile shows a different top cost. |

## When not to use this
- **Before you have a problem:** if no requirement or measurement says the code is slow, readable code wins.
- **On cold code:** a startup routine that runs once, an admin endpoint called ten times a day.
- **When I/O dominates:** a database round trip or an HTTP call costs orders of magnitude more than a string split. Fix the round trip (batching, caching, lesson 05) first.
- **Micro-benchmarks as proof of production speed:** they measure one function with warm caches and a quiet CPU. They tell you which of two **implementations** is better in isolation, not what your system will do.

## Failure modes
- **Benchmarking in Debug or with a debugger attached:** the numbers are meaningless. BenchmarkDotNet warns when the assembly is not optimized.
- **Dead-code elimination:** a benchmark whose result is discarded may be optimized away and report absurdly small times. Always return the value.
- **Measuring setup:** allocation of test data inside the benchmark method counts as the benchmark. Use `[GlobalSetup]`.
- **One data size:** an algorithm that wins at 10 items can lose at 1,000,000. Use `[Params]`.
- **Noise taken as signal:** a difference smaller than `Error`/`StdDev` is not a result. Repeat, and compare confidence intervals.
- **Span in the wrong place:** compile errors about ref structs and `await` are the compiler protecting you, not a bug to work around with `unsafe`.
- **ValueTask double await:** the failure is intermittent and data-dependent, the worst kind. If you cannot guarantee a single await, use `Task`.
- **Optimizing the wrong layer:** a 20 percent faster parser inside a request that spends 98 percent of its time waiting for a database changes nothing a user can feel.

## Measurements to take
Fill this table in your own notes for each change (one row per run). Never copy numbers from another machine.

| Date | Commit | Change | Metric | Baseline | After | Noise (Error/StdDev) | Keep? |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

Also take these, in production, before you optimize anything:
- **p50, p95, p99 latency** per endpoint (lesson 08 shows how to emit them).
- **Allocation rate** and **GC pause time** with `dotnet-counters monitor` (the `System.Runtime` counters) or your metrics backend.
- **A CPU profile** of the real workload, with `dotnet-trace` or your IDE's profiler, before choosing what to benchmark.

## Production checklist
- [ ] A performance budget exists for each user-visible operation (for example "p95 under N ms"), written down by the team, not by this lesson.
- [ ] Every optimization has an equivalence test and a recorded before/after measurement.
- [ ] Benchmarks live in a separate project and never run in CI as pass/fail gates on shared runners (noisy). Run them on demand or on dedicated hardware.
- [ ] Hot paths avoid LINQ closures, `string.Split`, boxing and `params` arrays **only where a profile points**.
- [ ] `ValueTask` is used only on measured hot paths and every consumer awaits exactly once.
- [ ] Server GC or workstation GC and `TieredPGO`/`TieredCompilation` settings are deliberate, tested choices, not defaults copied from a blog.

## Try it
Compare two ways to build a long comma-separated string.
1. **Guided.** Copy your finished `lesson04` to `exercise04`. Add the starter file below, complete the TODO in `Builder`, then run `--filter "*JoinBenchmarks*"`.

**File: `JoinBenchmarks.cs`**
```csharp
using BenchmarkDotNet.Attributes;

namespace Perf;

[MemoryDiagnoser]
public class JoinBenchmarks
{
    [Params(10, 1000)]
    public int Count;

    [Benchmark(Baseline = true)]
    public string PlusEquals()
    {
        var text = "";
        for (var i = 0; i < Count; i++)
        {
            text += i;
            text += ',';
        }

        return text;
    }

    [Benchmark]
    public string Builder()
    {
        // TODO: build the same text with a StringBuilder (using System.Text) and return builder.ToString().
        return "";
    }
}
```
Goal: fill the results table above for both `Count` values. Do both versions return the same text? Add a `--check`-style line to `Program.cs` that proves it before you trust the benchmark.

2. **Change.** Add a third benchmark, `JoinWithString`, that uses `string.Join(',', Enumerable.Range(0, Count))` (note: no trailing comma, so adjust your equivalence check). Which of the three would you pick for a hot path, and what evidence did you use?
3. **Stretch.** Pick one function from your own code that you suspect is slow. Before benchmarking, write down the expected answer and the metric. After measuring, was your guess right? What does that tell you about guessing?

<details><summary>Solution (rung 1)</summary>

**File: `JoinBenchmarks.cs`**
```csharp
using System.Text;
using BenchmarkDotNet.Attributes;

namespace Perf;

[MemoryDiagnoser]
public class JoinBenchmarks
{
    [Params(10, 1000)]
    public int Count;

    [Benchmark(Baseline = true)]
    public string PlusEquals()
    {
        var text = "";
        for (var i = 0; i < Count; i++)
        {
            text += i;
            text += ',';
        }

        return text;
    }

    [Benchmark]
    public string Builder()
    {
        var builder = new StringBuilder();
        for (var i = 0; i < Count; i++)
        {
            builder.Append(i).Append(',');
        }

        return builder.ToString();
    }
}
```
Both versions produce `0,1,2,...,` with a trailing comma, so they can be compared for equality. The `+=` version creates a new string on every append (quadratic copying as `Count` grows); the builder appends into a growing buffer. Your table, not this text, tells you the size of the difference on your machine; expect the gap to be larger at `Count = 1000` than at 10, and check that your numbers agree.
</details>

## Check yourself
1. Why must benchmarks run with `-c Release`?
   <details><summary>Answer</summary>Debug builds disable optimizations, so you would measure code that never runs in production; BenchmarkDotNet also warns about non-optimized assemblies.</details>
2. **Find the bug.** A benchmark method is `public void Parse() { LineSum.SumSplit(line); }` and reports 0.2 ns. What is wrong?
   <details><summary>Answer</summary>The result is discarded, so the JIT may remove the call (dead-code elimination). Return the value.</details>
3. Why can't a `ReadOnlySpan<char>` be used across an `await`?
   <details><summary>Answer</summary>It is a ref struct that may point to the stack; an async method's state machine lives on the heap, so the compiler forbids it. Use `Memory<T>` instead.</details>
4. When is `ValueTask<T>` the right return type?
   <details><summary>Answer</summary>On a measured hot path where most calls complete synchronously and every consumer awaits the result exactly once.</details>
5. What does `Ratio` mean in the table?
   <details><summary>Answer</summary>The mean of that benchmark divided by the mean of the baseline; below 1.00 is faster than the baseline, above is slower.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| A warning that the assembly which defines benchmarks is non-optimized (typical message) | You ran without `-c Release`, or with a debugger attached. | Run `dotnet run --project . -c Release --nologo -- --filter "*SumBenchmarks*"` from a terminal. |
| A validation error about the benchmark class needing to be public and not sealed (typical message) | You made the class `sealed` or `internal`. | Use `public class` without `sealed`. |
| Nothing happens, or the program prints only the `--check` result | You passed `--check` or `--alloc`; those modes return before BenchmarkDotNet starts. | Pass `--filter` (or no argument to choose from a menu). |
| BenchmarkDotNet cannot build for `net11.0` (typical message mentioning a runtime moniker or the toolchain) | The installed BenchmarkDotNet version may not know a newly released runtime. | Check the BenchmarkDotNet release notes for a newer version, or try `--inProcess` while you wait (less isolated, so less trustworthy). |
| `dotnet run` reports the argument `--filter` is unknown | You forgot the `--` that separates `dotnet run` options from your program's arguments. | Write `dotnet run ... -- --filter "..."`. |

## Best practice
Measure before and after, in Release, with a baseline, and keep only changes that exceed the noise and matter to a requirement. Source: BenchmarkDotNet documentation https://benchmarkdotnet.org/articles/overview.html and Microsoft Learn, ASP.NET Core best practices (minimize allocations on hot code paths) https://learn.microsoft.com/aspnet/core/fundamentals/best-practices

## Going further
- BenchmarkDotNet "How it works" and "Good practices": https://benchmarkdotnet.org/articles/guides/good-practices.html
- Microsoft Learn: `Span<T>` usage guidelines https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines
- Lesson 05 removes round trips with caches; lesson 08 gives you the production latency and GC metrics that tell you what to benchmark.

## Summary
- You wrote benchmarks with a baseline, parameters and the memory diagnoser, and ran them in Release.
- You explained allocation sources, span restrictions and the `ValueTask` contract.
- You proved equivalence before measuring, and recorded results in a table without invented numbers.
- You listed when not to optimize and the failure modes of benchmarking.

## Next lesson
05. Caching: `IMemoryCache`, `HybridCache`, a distributed cache and the hardest part, invalidation.
