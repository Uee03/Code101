using Item = (string Name, int PriceCents, int Quantity);

namespace After;

public static class Invoicing
{
    private const int DiscountThresholdCents = 2500;
    private const int DiscountPercent = 10;

    public static string FormatMoney(int cents)
    {
        return $"{cents / 100}.{cents % 100:D2}";
    }

    public static int Subtotal(List<Item> items)
    {
        int total = 0;
        foreach (var item in items)
        {
            total += item.PriceCents * item.Quantity;
        }
        return total;
    }

    public static int ApplyDiscount(int total)
    {
        if (total > DiscountThresholdCents)
        {
            return total - total * DiscountPercent / 100;
        }
        return total;
    }

    public static List<string> InvoiceLines(List<Item> items, int total)
    {
        var lines = new List<string> { "INVOICE" };
        foreach (var item in items)
        {
            lines.Add($"{item.Name} x{item.Quantity} = {FormatMoney(item.PriceCents * item.Quantity)}");
        }
        lines.Add($"Total: {FormatMoney(total)}");
        return lines;
    }

    public static void SendEmail(string address)
    {
        Console.WriteLine($"Email sent to {address}");
    }

    public static void Checkout(List<Item> items, string email)
    {
        int total = ApplyDiscount(Subtotal(items));
        foreach (string line in InvoiceLines(items, total))
        {
            Console.WriteLine(line);
        }
        SendEmail(email);
    }
}
