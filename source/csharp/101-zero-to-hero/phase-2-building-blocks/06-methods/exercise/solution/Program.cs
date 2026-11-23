using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine($"Delivery: {DeliveryPrice(3):F2}");

static decimal DeliveryPrice(int boxes)
{
    return 2.00m + boxes * 1.50m;
}
