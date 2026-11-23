using Item = (string Name, int PriceCents, int Quantity);

namespace After;

public class Invoice
{
    public int Number { get; }
    public string CustomerEmail { get; }
    public List<Item> Items { get; }

    public Invoice(int number, string customerEmail, List<Item> items)
    {
        Number = number;
        CustomerEmail = customerEmail;
        Items = items;
    }

    public int TotalCents()
    {
        int total = 0;
        foreach (var item in Items)
        {
            total += item.PriceCents * item.Quantity;
        }
        return total;
    }
}

public class InvoiceTextFormatter
{
    public string Format(Invoice invoice)
    {
        var lines = new List<string> { $"Invoice {invoice.Number}" };
        foreach (var item in invoice.Items)
        {
            lines.Add($"{item.Name} x{item.Quantity}");
        }
        lines.Add($"Total cents: {invoice.TotalCents()}");
        return string.Join("\n", lines);
    }
}

public class InvoiceStore
{
    private readonly List<Invoice> _saved = new();

    public int Count => _saved.Count;

    public void Save(Invoice invoice)
    {
        _saved.Add(invoice);
    }
}

public class EmailSender
{
    public void SendInvoice(Invoice invoice)
    {
        Console.WriteLine($"Email to {invoice.CustomerEmail}: invoice {invoice.Number}");
    }
}
