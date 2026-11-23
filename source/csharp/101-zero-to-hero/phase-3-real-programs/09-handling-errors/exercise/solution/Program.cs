Console.WriteLine("Age (0-130):");
while (true)
{
    string? input = Console.ReadLine();
    if (input is null)
    {
        Console.WriteLine("Input ended.");
        return;
    }
    if (int.TryParse(input, out int age) && age >= 0 && age <= 130)
    {
        Console.WriteLine($"Age: {age}");
        break;
    }
    Console.WriteLine("Try an age from 0 to 130:");
}
