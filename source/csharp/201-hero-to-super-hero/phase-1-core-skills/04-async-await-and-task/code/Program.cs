using System.Diagnostics;

static async Task<string> FetchAsync(string name, int delayMs, CancellationToken ct = default)
{
    await Task.Delay(delayMs, ct);
    return $"{name} done";
}

static async Task FailAsync()
{
    await Task.Delay(10);
    throw new InvalidOperationException("boom");
}

var sw = Stopwatch.StartNew();
string a = await FetchAsync("A", 300);
string b = await FetchAsync("B", 300);
TimeSpan sequential = sw.Elapsed;
Console.WriteLine($"{a}, {b}");

sw.Restart();
string[] results = await Task.WhenAll(FetchAsync("A", 300), FetchAsync("B", 300));
TimeSpan concurrent = sw.Elapsed;
Console.WriteLine(string.Join(", ", results));
Console.WriteLine($"Concurrent faster than sequential: {concurrent < sequential}");

using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(100));
try
{
    await FetchAsync("slow", 5000, cts.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Cancelled after the timeout");
}

try
{
    await FailAsync();
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"Caught: {ex.Message}");
}

Task both = Task.WhenAll(FailAsync(), FailAsync());
try
{
    await both;
}
catch (InvalidOperationException)
{
    Console.WriteLine($"WhenAll failures: {both.Exception!.InnerExceptions.Count}");
}

long total = await Task.Run(() =>
{
    long running = 0;
    for (int i = 1; i <= 1_000_000; i++)
    {
        running += i;
    }

    return running;
});
Console.WriteLine($"CPU work on the thread pool: {total}");
