using Sales;

var order = Order.Start(1, "EUR");
order.AddLine("BOOK", 2, Money.Of(1250, "EUR"));
order.AddLine("PEN", 10, Money.Of(150, "EUR"));
Console.WriteLine($"Total: {order.Total}");

TryRule("USD line", () => order.AddLine("MUG", 1, Money.Of(500, "USD")));
TryRule("quantity 100", () => order.AddLine("MUG", 100, Money.Of(500, "EUR")));

order.Submit();
Console.WriteLine($"Status: {order.Status}");
TryRule("add after submit", () => order.AddLine("MUG", 1, Money.Of(500, "EUR")));
TryRule("empty order", () => Order.Start(2, "EUR").Submit());

Console.WriteLine($"Money equality: {Money.Of(100, "EUR") == Money.Of(100, "EUR")}");

// In a real app the repository saves the aggregate first, then the events are published.
foreach (var domainEvent in order.PullEvents())
{
    var text = domainEvent switch
    {
        OrderLineAdded added => $"event OrderLineAdded: {added.Quantity} x {added.Sku}",
        OrderSubmitted submitted => $"event OrderSubmitted: total {submitted.Total}",
        _ => $"event {domainEvent.GetType().Name}",
    };
    Console.WriteLine(text);
}

static void TryRule(string name, Action action)
{
    try
    {
        action();
        Console.WriteLine($"{name}: allowed (unexpected)");
    }
    catch (DomainException ex)
    {
        Console.WriteLine($"{name}: rejected ({ex.Message})");
    }
}
