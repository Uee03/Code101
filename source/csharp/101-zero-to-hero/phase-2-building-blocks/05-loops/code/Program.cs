for (int box = 1; box <= 3; box++)
{
    Console.WriteLine($"Pack box {box}");
}
foreach (char letter in "BAG")
{
    Console.WriteLine($"Label letter: {letter}");
}
int remaining = 2;
while (remaining > 0)
{
    Console.WriteLine($"Checks left: {remaining}");
    remaining--;
}
for (int number = 1; number <= 6; number++)
{
    if (number == 2)
    {
        continue;
    }
    if (number == 5)
    {
        break;
    }
    Console.WriteLine($"Keep {number}");
}
