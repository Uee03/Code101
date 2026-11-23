using Item = (string Name, int PriceCents, int Quantity);

var items = new List<Item> { ("Notebook", 1200, 2), ("Pen", 150, 4) };
const string email = "ana@example.com";

Console.WriteLine("--- before ---");
Before.Invoicing.Checkout(items, email);
Console.WriteLine("--- after ---");
After.Invoicing.Checkout(items, email);
