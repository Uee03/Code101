namespace Orders.Domain;

public sealed record OrderLine(string Sku, int Quantity, int UnitPriceCents);

public sealed class Order
{
    private readonly List<OrderLine> lines;

    private Order(int id, string customer, List<OrderLine> lines)
    {
        Id = id;
        Customer = customer;
        this.lines = lines;
    }

    public int Id { get; }

    public string Customer { get; }

    public IReadOnlyList<OrderLine> Lines => lines;

    public int TotalCents => lines.Sum(line => line.Quantity * line.UnitPriceCents);

    public static Order Place(int id, string customer, IEnumerable<OrderLine> lines)
    {
        if (string.IsNullOrWhiteSpace(customer))
        {
            throw new ArgumentException("A customer is required.", nameof(customer));
        }

        var copy = lines.ToList();
        if (copy.Count == 0)
        {
            throw new ArgumentException("An order needs at least one line.", nameof(lines));
        }

        return new Order(id, customer.Trim(), copy);
    }
}
