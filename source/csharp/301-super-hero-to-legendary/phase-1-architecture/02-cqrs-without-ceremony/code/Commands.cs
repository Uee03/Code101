namespace Ledger;

public sealed record ReceiveStock(string Sku, int Quantity);

public sealed record ShipStock(string Sku, int Quantity);

public sealed class ReceiveStockHandler(StockStore store) : ICommandHandler<ReceiveStock>
{
    public Task<Result> HandleAsync(ReceiveStock command, CancellationToken ct)
    {
        if (command.Quantity <= 0)
        {
            return Task.FromResult(Result.Fail("Quantity must be positive."));
        }

        store.Set(command.Sku, store.Get(command.Sku) + command.Quantity);
        return Task.FromResult(Result.Ok());
    }
}

public sealed class ShipStockHandler(StockStore store) : ICommandHandler<ShipStock>
{
    public Task<Result> HandleAsync(ShipStock command, CancellationToken ct)
    {
        var available = store.Get(command.Sku);
        if (command.Quantity <= 0 || command.Quantity > available)
        {
            return Task.FromResult(Result.Fail($"Only {available} in stock, cannot ship {command.Quantity}."));
        }

        store.Set(command.Sku, available - command.Quantity);
        return Task.FromResult(Result.Ok());
    }
}
