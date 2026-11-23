var shared = new Logger();
new Greeter(shared).Greet("Ana");
new Greeter(shared).Greet("Bo");
Console.WriteLine(string.Join(", ", shared.Lines));
var other = new Logger();
Console.WriteLine($"other has {other.Lines.Count} lines");

// TODO 1: give Greeter a constructor that receives a Logger and stores it in _logger.
// TODO 2: make Greet call _logger.Log(...) instead of Logger.Instance.Log(...).
// TODO 3: delete the static Instance property from Logger: nobody needs it any more.

class Logger
{
    public static Logger Instance { get; } = new Logger();

    public List<string> Lines { get; } = new();

    public void Log(string text) => Lines.Add(text);
}

class Greeter
{
    public string Greet(string name)
    {
        Logger.Instance.Log($"greeting {name}");
        return $"Hello, {name}";
    }
}
