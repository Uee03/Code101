namespace Ledger;

public sealed record GetStockLevel(string Sku);

public sealed record ListLowStock(int Threshold);

public sealed class GetStockLevelHandler(StockStore store) : IQueryHandler<GetStockLevel, int>
{
    public Task<int> HandleAsync(GetStockLevel query, CancellationToken ct) => Task.FromResult(store.Get(query.Sku));
}

public sealed class ListLowStockHandler(StockStore store) : IQueryHandler<ListLowStock, IReadOnlyList<StockLine>>
{
    public Task<IReadOnlyList<StockLine>> HandleAsync(ListLowStock query, CancellationToken ct)
    {
        IReadOnlyList<StockLine> low = store.All().Where(line => line.Quantity < query.Threshold).ToList();
        return Task.FromResult(low);
    }
}
