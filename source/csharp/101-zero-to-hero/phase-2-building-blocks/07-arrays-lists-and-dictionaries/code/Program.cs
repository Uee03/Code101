string[] shelves = { "Top", "Bottom" };
Console.WriteLine($"First shelf: {shelves[0]}; shelf count: {shelves.Length}");
shelves[1] = "Middle";
Console.WriteLine($"Second shelf: {shelves[1]}");
List<string> items = new List<string> { "Rice", "Tea" };
items.Add("Soap");
items.Remove("Tea");
Console.WriteLine($"Items: {items.Count}");
foreach (string item in items)
{
    Console.WriteLine(item);
}
Dictionary<string, int> stock = new Dictionary<string, int>();
stock["Rice"] = 2;
stock["Rice"] = stock["Rice"] + 1;
stock["Soap"] = 1;
if (stock.TryGetValue("Rice", out int rice))
{
    Console.WriteLine($"Rice in stock: {rice}");
}
if (!stock.TryGetValue("Tea", out int tea))
{
    Console.WriteLine("Tea has no entry.");
}
