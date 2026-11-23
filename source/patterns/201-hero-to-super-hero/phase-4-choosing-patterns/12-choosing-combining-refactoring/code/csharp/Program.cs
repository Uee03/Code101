var cases = new (string Label, List<Item> Items, string Shipping, string? Coupon, string Email)[]
{
    ("welcome coupon", new List<Item> { new Item("pen", 150, 4), new Item("book", 1200, 1) }, "standard", "WELCOME10", "ana@example.com"),
    ("capped coupon", new List<Item> { new Item("cable", 400, 1) }, "pickup", "FIVEOFF", "bo@example.com"),
    ("no coupon", new List<Item> { new Item("lamp", 2500, 2) }, "express", null, "cy@example.com"),
    ("empty cart", new List<Item>(), "standard", null, "di@example.com"),
    ("unknown shipping", new List<Item> { new Item("pen", 150, 1) }, "drone", null, "ed@example.com"),
};

foreach (var (label, items, shipping, coupon, email) in cases)
{
    var old = Before.Shop.Checkout(items, shipping, coupon, email);
    var current = After.Shop.PlaceOrder(items, shipping, coupon, email);
    Console.WriteLine($"--- {label} ---");
    foreach (var line in current)
    {
        Console.WriteLine(line);
    }
    Console.WriteLine($"same as before: {old.SequenceEqual(current)}");
}
