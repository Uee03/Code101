using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;

IDiscount rule = new ThresholdOff(50m, 12m);
Console.WriteLine($"{rule.Name}: {rule.Apply(80m):F2}");
Console.WriteLine($"{rule.Name}: {rule.Apply(30m):F2}");
