using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine($"Delivery: {DeliveryPrice(3):F2}");

static decimal DeliveryPrice(int boxes)
{
    // TODO: return a base fee of 2.00m plus 1.50m per box.
    return 0m;
}
