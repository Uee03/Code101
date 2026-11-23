using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string? note = null;
Console.WriteLine($"Note: {note ?? "(none)"}");
Console.WriteLine($"Note length: {note?.Length ?? 0}");
Receipt original = new Receipt("Lunch", 12.50m);
Receipt same = new Receipt("Lunch", 12.50m);
Receipt revised = original with { Amount = 13.00m };
Console.WriteLine($"Same values: {original == same}");
Console.WriteLine($"Original: {original.Amount:F2}; revised: {revised.Amount:F2}");
