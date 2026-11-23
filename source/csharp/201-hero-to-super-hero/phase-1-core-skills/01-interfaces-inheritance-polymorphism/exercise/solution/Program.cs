using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

IDiscount rule = new ThresholdOff(50m, 12m);
Console.WriteLine($"{rule.Name}: {rule.Apply(80m):F2}");
Console.WriteLine($"{rule.Name}: {rule.Apply(30m):F2}");

IDiscount capped = new CappedDiscount(rule, 5m);
Console.WriteLine($"{capped.Name}: {capped.Apply(80m):F2}");
