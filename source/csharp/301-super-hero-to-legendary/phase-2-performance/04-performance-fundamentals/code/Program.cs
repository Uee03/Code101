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
