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
    // TODO 1: add a HashSet<int> field that remembers the ids already applied.

    public int Total { get; private set; }

    public bool Apply(int id, int points)
    {
        // TODO 2: if the id was applied before, return false without changing Total.
        //         Otherwise remember the id, add the points and return true.
        Total += points;
        return true;
    }
}
