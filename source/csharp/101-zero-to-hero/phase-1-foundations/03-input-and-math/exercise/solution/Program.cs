using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine("Bill (use a dot):");
double bill = double.Parse(Console.ReadLine() ?? "");
Console.WriteLine("People (positive whole number):");
int people = int.Parse(Console.ReadLine() ?? "");
Console.WriteLine($"Share: {bill / people:F2}");
