namespace Sales;

public enum OrderStatus
{
    Draft,
    Submitted,
}

// Local entity inside the Order aggregate: it is identified by its SKU within one order only.
public sealed record OrderLine(string Sku, int Quantity, Money UnitPrice)
{
    public Money Subtotal => UnitPrice.Times(Quantity);
}

// Domain events are facts in the past tense. Other parts of the system react to them.
public sealed record OrderLineAdded(int OrderId, string Sku, int Quantity) : IDomainEvent;

public sealed record OrderSubmitted(int OrderId, Money Total) : IDomainEvent;

// The aggregate root: the only way to change an order and the boundary of one consistency rule set.
public sealed class Order : AggregateRoot
{
    public const int MaxLines = 3;

    private readonly List<OrderLine> lines = [];

    private Order(int id, string currency)
    {
        Id = id;
        Currency = currency;
    }

    public int Id { get; }

    public string Currency { get; }

    public OrderStatus Status { get; private set; } = OrderStatus.Draft;

    public IReadOnlyList<OrderLine> Lines => lines;

    public Money Total => lines.Aggregate(Money.Zero(Currency), (sum, line) => sum.Add(line.Subtotal));

    public static Order Start(int id, string currency)
    {
        Money.Zero(currency);
        return new Order(id, currency);
    }

    public void AddLine(string sku, int quantity, Money unitPrice)
    {
        EnsureDraft();

        if (unitPrice.Currency != Currency)
        {
            throw new DomainException($"Prices must be in {Currency}.");
        }

        if (quantity is < 1 or > 99)
        {
            throw new DomainException("Quantity must be between 1 and 99.");
        }

        if (lines.Any(line => line.Sku == sku))
        {
            throw new DomainException($"{sku} is already on the order.");
        }

        if (lines.Count >= MaxLines)
        {
            throw new DomainException($"An order can have at most {MaxLines} lines.");
        }

        lines.Add(new OrderLine(sku, quantity, unitPrice));
        Raise(new OrderLineAdded(Id, sku, quantity));
    }

    public void Submit()
    {
        EnsureDraft();

        if (lines.Count == 0)
        {
            throw new DomainException("Cannot submit an empty order.");
        }

        Status = OrderStatus.Submitted;
        Raise(new OrderSubmitted(Id, Total));
    }

    private void EnsureDraft()
    {
        if (Status != OrderStatus.Draft)
        {
            throw new DomainException("A submitted order cannot change.");
        }
    }
}
