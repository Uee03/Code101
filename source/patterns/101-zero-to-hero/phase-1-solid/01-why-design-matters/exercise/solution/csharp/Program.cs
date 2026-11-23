using Item = (string Name, int PriceCents, int Quantity);

var cart = new List<Item> { ("Mug", 800, 3), ("Plate", 1250, 2) };

OrderSummary(cart, "FR");
OrderSummary(cart, "US");

static int Subtotal(List<Item> items)
{
    int total = 0;
    foreach (var item in items)
    {
        total += item.PriceCents * item.Quantity;
    }
    return total;
}

static int ShippingCents(string country)
{
    const int NearbyShippingCents = 500;
    const int FarShippingCents = 1500;
    if (country == "DE" || country == "FR")
    {
        return NearbyShippingCents;
    }
    return FarShippingCents;
}

static void OrderSummary(List<Item> items, string country)
{
    int total = Subtotal(items) + ShippingCents(country);
    Console.WriteLine("Order total: " + (total / 100) + "." + (total % 100).ToString("D2"));
}
