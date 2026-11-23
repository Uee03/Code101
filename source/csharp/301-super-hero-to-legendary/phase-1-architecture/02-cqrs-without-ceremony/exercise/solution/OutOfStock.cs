namespace Ledger;

public sealed record ListOutOfStock;

public sealed class ListOutOfStockHandler(StockStore store) : IQueryHandler<ListOutOfStock, IReadOnlyList<StockLine>>
{
    public Task<IReadOnlyList<StockLine>> HandleAsync(ListOutOfStock query, CancellationToken ct)
    {
        IReadOnlyList<StockLine> empty = store.All().Where(line => line.Quantity == 0).ToList();
        return Task.FromResult(empty);
    }
}
