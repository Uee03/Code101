using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
int guests = 4;
decimal pricePerGuest = 3.50m;
decimal total = guests * pricePerGuest;
Console.WriteLine($"Total: {total:F2}");
