using Item = (string Name, int PriceCents, int Quantity);

var cart = new List<Item> { ("Mug", 800, 3), ("Plate", 1250, 2) };

// TODO 1: write a static method Subtotal(List<Item> items) that returns the sum of price * quantity.
// TODO 2: write a static method ShippingCents(string country): 500 for "DE" or "FR", otherwise 1500.
//         Give 500 and 1500 names (const values) so nobody has to guess what they mean.
// TODO 3: rewrite OrderSummary to use both helpers. The printed lines must not change.

OrderSummary(cart, "FR");
OrderSummary(cart, "US");

static void OrderSummary(List<Item> items, string country)
{
    int total = 0;
    foreach (var item in items)
    {
        total = total + item.PriceCents * item.Quantity;
    }
    if (country == "DE")
    {
        total = total + 500;
    }
    else if (country == "FR")
    {
        total = total + 500;
    }
    else
    {
        total = total + 1500;
    }
    Console.WriteLine("Order total: " + (total / 100) + "." + (total % 100).ToString("D2"));
}
