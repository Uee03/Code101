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

// TODO 1: names of customers whose orders add up to more than 50, sorted A to Z.
IEnumerable<string> bigSpenders = Enumerable.Empty<string>();
Console.WriteLine($"Big spenders: {string.Join(", ", bigSpenders)}");

// TODO 2: the category with the highest total revenue.
string topCategory = "?";
Console.WriteLine($"Top category: {topCategory}");
