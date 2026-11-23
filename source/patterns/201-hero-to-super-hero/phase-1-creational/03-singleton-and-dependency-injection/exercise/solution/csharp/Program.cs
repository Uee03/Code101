var shared = new Logger();
new Greeter(shared).Greet("Ana");
new Greeter(shared).Greet("Bo");
Console.WriteLine(string.Join(", ", shared.Lines));
var other = new Logger();
Console.WriteLine($"other has {other.Lines.Count} lines");

class Logger
{
    public List<string> Lines { get; } = new();

    public void Log(string text) => Lines.Add(text);
}

class Greeter
{
    private readonly Logger _logger;

    public Greeter(Logger logger)
    {
        _logger = logger;
    }

    public string Greet(string name)
    {
        _logger.Log($"greeting {name}");
        return $"Hello, {name}";
    }
}
