namespace Ledger;

public sealed record StockLine(string Sku, int Quantity);

// Not thread-safe on purpose: this demo is single-threaded. A real store would be a database.
public sealed class StockStore
{
    private readonly Dictionary<string, int> levels = new(StringComparer.OrdinalIgnoreCase);

    public int Get(string sku) => levels.TryGetValue(sku, out var level) ? level : 0;

    public void Set(string sku, int level) => levels[sku] = level;

    public IReadOnlyList<StockLine> All() => levels
        .Select(pair => new StockLine(pair.Key.ToUpperInvariant(), pair.Value))
        .OrderBy(line => line.Sku, StringComparer.Ordinal)
        .ToList();
}
