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
