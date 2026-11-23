using Item = (string Name, int PriceCents, int Quantity);

namespace Before;

public class OrderProcessor
{
    public void Process(string customerType, string channel, string address, List<Item> items)
    {
        int total = 0;
        foreach (var item in items)
        {
            total += item.PriceCents * item.Quantity;
        }
        if (customerType == "vip")
        {
            total = total - total * 20 / 100;
        }
        else if (customerType == "student")
        {
            total = total - total * 10 / 100;
        }
        if (channel == "email")
        {
            Console.WriteLine($"Email to {address}: order total {total}");
        }
        else if (channel == "sms")
        {
            Console.WriteLine($"SMS to {address}: order total {total}");
        }
        Console.WriteLine($"Saved order for {address}");
    }
}
