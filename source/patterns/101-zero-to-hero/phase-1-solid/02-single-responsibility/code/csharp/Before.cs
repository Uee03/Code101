using Item = (string Name, int PriceCents, int Quantity);

namespace Before;

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

    public string ToText()
    {
        var lines = new List<string> { $"Invoice {Number}" };
        foreach (var item in Items)
        {
            lines.Add($"{item.Name} x{item.Quantity}");
        }
        lines.Add($"Total cents: {TotalCents()}");
        return string.Join("\n", lines);
    }

    public void Save(List<string> database)
    {
        database.Add(ToText());
    }

    public void SendEmail()
    {
        Console.WriteLine($"Email to {CustomerEmail}: invoice {Number}");
    }
}
