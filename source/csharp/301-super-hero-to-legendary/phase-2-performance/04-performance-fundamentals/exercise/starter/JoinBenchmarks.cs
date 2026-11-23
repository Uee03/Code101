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
