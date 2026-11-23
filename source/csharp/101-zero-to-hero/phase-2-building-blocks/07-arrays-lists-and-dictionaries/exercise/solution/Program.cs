Dictionary<string, int> scores = new Dictionary<string, int>();
scores["Ada"] = 3;
scores["Ada"] = scores["Ada"] + 2;
if (scores.TryGetValue("Ada", out int score))
{
    Console.WriteLine($"Ada: {score}");
}
