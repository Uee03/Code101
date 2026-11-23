Console.WriteLine("Score (0-100):");
int score = int.Parse(Console.ReadLine() ?? "");
if (score < 0 || score > 100)
{
    Console.WriteLine("Invalid score");
}
else if (score < 50)
{
    Console.WriteLine("Fail");
}
else if (score < 75)
{
    Console.WriteLine("Pass");
}
else
{
    Console.WriteLine("Merit");
}
