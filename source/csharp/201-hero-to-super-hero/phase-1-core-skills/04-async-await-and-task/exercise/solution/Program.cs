static async Task<int> SquareAsync(int n, CancellationToken ct = default)
{
    await Task.Delay(50, ct);
    return n * n;
}

int[] inputs = [1, 2, 3, 4];

int[] squares = await Task.WhenAll(inputs.Select(x => SquareAsync(x)));
Console.WriteLine($"Squares: {string.Join(", ", squares)}");

using var cts = new CancellationTokenSource(10);
try
{
    await Task.WhenAll(inputs.Select(x => SquareAsync(x, cts.Token)));
}
catch (OperationCanceledException)
{
    Console.WriteLine("Cancelled");
}
