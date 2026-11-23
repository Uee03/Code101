Console.WriteLine("Quantity (positive whole number):");
int quantity;
while (true)
{
    string? input = Console.ReadLine();
    if (input is null)
    {
        Console.WriteLine("Input ended.");
        return;
    }
    if (int.TryParse(input, out quantity) && quantity > 0)
    {
        break;
    }
    Console.WriteLine("Please enter a positive whole number:");
}
try
{
    Console.WriteLine("Optional number (try a word):");
    int optional = int.Parse(Console.ReadLine() ?? "");
    Console.WriteLine($"Optional: {optional}");
}
catch (FormatException)
{
    Console.WriteLine("That was not a whole number.");
}
catch (OverflowException)
{
    Console.WriteLine("That whole number is too large or too small.");
}
finally
{
    Console.WriteLine("Finished the optional-number step.");
}
Console.WriteLine($"Accepted: {quantity}");
