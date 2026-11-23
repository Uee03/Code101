int count = 0;
for (int number = 1; number <= 6; number++)
{
    if (number % 2 == 0)
    {
        count++;
    }
}
Console.WriteLine($"Even numbers: {count}");
