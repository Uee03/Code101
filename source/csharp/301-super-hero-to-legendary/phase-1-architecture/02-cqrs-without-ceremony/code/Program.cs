using Ledger;

var ct = CancellationToken.None;
var store = new StockStore();

// Composition by hand: the dependencies are visible and the compiler checks every one of them.
ICommandHandler<ReceiveStock> receive = new LoggingDecorator<ReceiveStock>(new ReceiveStockHandler(store), Console.Out);
ICommandHandler<ShipStock> ship = new LoggingDecorator<ShipStock>(new ShipStockHandler(store), Console.Out);
IQueryHandler<GetStockLevel, int> level = new GetStockLevelHandler(store);
IQueryHandler<ListLowStock, IReadOnlyList<StockLine>> lowStock = new ListLowStockHandler(store);

await receive.HandleAsync(new ReceiveStock("PEN", 10), ct);
await receive.HandleAsync(new ReceiveStock("CUP", 3), ct);
await ship.HandleAsync(new ShipStock("PEN", 7), ct);
await ship.HandleAsync(new ShipStock("PEN", 9), ct);
await receive.HandleAsync(new ReceiveStock("CUP", 0), ct);

Console.WriteLine($"PEN level: {await level.HandleAsync(new GetStockLevel("PEN"), ct)}");
var low = await lowStock.HandleAsync(new ListLowStock(5), ct);
Console.WriteLine($"Low stock (below 5): {string.Join(", ", low.Select(line => $"{line.Sku}={line.Quantity}"))}");
