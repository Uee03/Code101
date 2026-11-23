namespace Caching;

public sealed record Product(int Id, string Name, int PriceCents);

// Stands in for a database: every load takes about 50 ms and is counted.
public sealed class SlowCatalog
{
    private int loads;

    public int Loads => Volatile.Read(ref loads);

    public int PriceCents { get; set; } = 1000;

    public async Task<Product> LoadAsync(int id, CancellationToken ct)
    {
        Interlocked.Increment(ref loads);
        await Task.Delay(50, ct);
        return new Product(id, $"Product {id}", PriceCents);
    }
}
