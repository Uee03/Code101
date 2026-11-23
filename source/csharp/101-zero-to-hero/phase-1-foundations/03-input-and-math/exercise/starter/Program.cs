using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine("Bill (use a dot):");
double bill = double.Parse(Console.ReadLine() ?? "");
Console.WriteLine("People (positive whole number):");
int people = int.Parse(Console.ReadLine() ?? "");
// TODO: calculate and print each person's share with F2.
Console.WriteLine("Share: TODO");
