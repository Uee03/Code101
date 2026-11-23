using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

decimal price = 80.00m;

IDiscount[] offers =
[
    new PercentOff(10m),
    new FixedOff(15m),
    new CappedDiscount(new PercentOff(50m), 20m),
];

foreach (IDiscount offer in offers)
{
    Console.WriteLine($"{offer.Name}: {offer.Apply(price):F2}");
}

IDiscount best = offers[0];
foreach (IDiscount offer in offers)
{
    if (offer.Apply(price) < best.Apply(price))
    {
        best = offer;
    }
}

Console.WriteLine($"Best for {price:F2}: {best.Name}");

Discount flat = new FixedOff(500m);
Console.WriteLine($"{flat.Describe()} -> {flat.Apply(price):F2}");
