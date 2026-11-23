var events = new List<(int Id, int Points)> { (1, 5), (2, 3), (1, 5), (2, 3), (3, 1) };

var board = new Scoreboard();
var duplicates = 0;
foreach (var (id, points) in events)
{
    if (!board.Apply(id, points))
    {
        duplicates++;
    }
}
Console.WriteLine($"total points: {board.Total}");
Console.WriteLine($"duplicates ignored: {duplicates}");

class Scoreboard
{
    private readonly HashSet<int> _applied = new();

    public int Total { get; private set; }

    public bool Apply(int id, int points)
    {
        if (!_applied.Add(id))
        {
            return false;
        }
        Total += points;
        return true;
    }
}
