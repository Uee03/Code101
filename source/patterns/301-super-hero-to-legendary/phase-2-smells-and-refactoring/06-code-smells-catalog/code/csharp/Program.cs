using SmellyCode;

var maker = new InvoiceMaker();
var items = new List<Item> { new("pen", 150, 2), new("book", 1200, 1) };
Console.WriteLine(maker.MakeInvoice("Ana", "ana@example.com", "1 Main St", "Oslo", "0150", items, "SAVE10", "DE", true));

var manager = new OrderManager();
manager.Add(new Order(1, 100));
manager.Add(new Order(2, 250));
Console.WriteLine(manager.PrintReport());

var (methods, classes) = Scanner.Scan(File.ReadAllLines("Smelly.cs"));
Console.WriteLine($"scanned {methods.Count} functions or methods");
foreach (var method in methods)
{
    var problems = Scanner.Flags(method);
    if (problems.Count > 0)
    {
        Console.WriteLine($"{method.Name}: lines={method.Lines} params={method.Params} nesting={method.Nesting} -> {string.Join(", ", problems)}");
    }
}
foreach (var (name, count) in classes)
{
    if (count > Scanner.MaxMethods)
    {
        Console.WriteLine($"class {name}: methods={count} -> large class");
    }
}
