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

IEnumerable<string> bigSpenders = orders
    .GroupBy(o => o.Customer)
    .Where(g => g.Sum(o => o.Total) > 50m)
    .Select(g => g.Key)
    .OrderBy(name => name);
Console.WriteLine($"Big spenders: {string.Join(", ", bigSpenders)}");

string topCategory = orders
    .GroupBy(o => o.Category)
    .OrderByDescending(g => g.Sum(o => o.Total))
    .First()
    .Key;
Console.WriteLine($"Top category: {topCategory}");

foreach (var month in orders.GroupBy(o => o.Date.Month).OrderBy(g => g.Key))
{
    Console.WriteLine($"Month {month.Key}: {month.Sum(o => o.Total):F2}");
}
