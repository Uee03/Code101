using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

List<Order> orders =
[
    new(1, "Ada", "Books", 25.50m, new DateOnly(2026, 1, 5)),
    new(2, "Grace", "Games", 60.00m, new DateOnly(2026, 1, 7)),
    new(3, "Ada", "Games", 45.00m, new DateOnly(2026, 2, 1)),
    new(4, "Linus", "Books", 12.25m, new DateOnly(2026, 2, 3)),
    new(5, "Grace", "Books", 30.00m, new DateOnly(2026, 2, 10)),
    new(6, "Ada", "Books", 8.50m, new DateOnly(2026, 3, 2)),
];

List<Customer> customers =
[
    new("Ada", "London"),
    new("Grace", "New York"),
    new("Linus", "Helsinki"),
];

IEnumerable<int> bigBooks = orders
    .Where(o => o.Category == "Books" && o.Total > 20m)
    .Select(o => o.Id);
Console.WriteLine($"Books over 20: {string.Join(",", bigBooks)}");

var over40 = from o in orders
             where o.Total > 40m
             select o.Id;
Console.WriteLine($"Over 40 (query syntax): {string.Join(",", over40)}");

var perCustomer = orders
    .GroupBy(o => o.Customer)
    .Select(g => new { Customer = g.Key, Count = g.Count(), Total = g.Sum(o => o.Total) })
    .OrderByDescending(x => x.Total);

foreach (var row in perCustomer)
{
    Console.WriteLine($"{row.Customer}: {row.Total:F2} in {row.Count} order(s)");
}

Console.WriteLine($"Average: {orders.Average(o => o.Total):F2}");
Console.WriteLine($"Any over 50: {orders.Any(o => o.Total > 50m)}");
Console.WriteLine($"All over 10: {orders.All(o => o.Total > 10m)}");

Order? nobody = orders.FirstOrDefault(o => o.Customer == "Zed");
Console.WriteLine($"Zed: {nobody?.Id.ToString() ?? "none"}");

var withCity = orders
    .Join(customers, o => o.Customer, c => c.Name, (o, c) => $"{o.Id}:{c.City}")
    .Take(3);
Console.WriteLine($"Cities: {string.Join(", ", withCity)}");

var page2 = orders.OrderBy(o => o.Date).Skip(2).Take(2).Select(o => o.Id);
Console.WriteLine($"Page 2: {string.Join(",", page2)}");

var numbers = new List<int> { 1, 2, 3 };
IEnumerable<int> evens = numbers.Where(n => n % 2 == 0);
List<int> snapshot = evens.ToList();
numbers.Add(4);
Console.WriteLine($"Live: {string.Join(",", evens)}; snapshot: {string.Join(",", snapshot)}");

int calls = 0;

IEnumerable<int> Source()
{
    calls++;
    yield return 1;
    yield return 2;
}

IEnumerable<int> source = Source();
int count = source.Count();
int sum = source.Sum();
Console.WriteLine($"count={count}, sum={sum}, source ran {calls} time(s)");
