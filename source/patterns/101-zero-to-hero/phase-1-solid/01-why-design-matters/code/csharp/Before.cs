using Item = (string Name, int PriceCents, int Quantity);

namespace Before;

public static class Invoicing
{
    public static void Checkout(List<Item> items, string email)
    {
        int total = 0;
        foreach (var item in items)
        {
            total = total + item.PriceCents * item.Quantity;
        }
        if (total > 2500)
        {
            total = total - total * 10 / 100;
        }
        Console.WriteLine("INVOICE");
        foreach (var item in items)
        {
            int line = item.PriceCents * item.Quantity;
            Console.WriteLine(item.Name + " x" + item.Quantity + " = " + (line / 100) + "." + (line % 100).ToString("D2"));
        }
        Console.WriteLine("Total: " + (total / 100) + "." + (total % 100).ToString("D2"));
        Console.WriteLine("Email sent to " + email);
    }
}
