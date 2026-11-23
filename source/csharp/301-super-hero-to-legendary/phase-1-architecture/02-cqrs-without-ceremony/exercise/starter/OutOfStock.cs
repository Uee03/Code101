namespace Ledger;

public sealed record ListOutOfStock;

// TODO: return every SKU whose level is exactly 0, in the order StockStore.All() returns them.
public sealed class ListOutOfStockHandler(StockStore store) : IQueryHandler<ListOutOfStock, IReadOnlyList<StockLine>>
{
    public Task<IReadOnlyList<StockLine>> HandleAsync(ListOutOfStock query, CancellationToken ct)
    {
        IReadOnlyList<StockLine> none = [];
        return Task.FromResult(none);
    }
}
