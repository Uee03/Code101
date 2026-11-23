using System.Globalization;

CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
string item = "Notebook";
int quantity = 3;
double weight = 0.25;
decimal unitPrice = 2.50m;
bool inStock = true;
var shelf = "A2";
quantity = quantity + 1;
decimal total = quantity * unitPrice;
Console.WriteLine($"Item: {item}");
Console.WriteLine($"Quantity: {quantity}");
Console.WriteLine($"Weight each: {weight} kg");
Console.WriteLine($"Price each: {unitPrice:F2}");
Console.WriteLine($"In stock: {inStock}");
Console.WriteLine($"Shelf: {shelf}");
Console.WriteLine($"Total: {total:F2}");
