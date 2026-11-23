namespace FlyweightDemo;

public record TreeType(string Name, string Color);

public class TreeTypeFactory
{
    private readonly Dictionary<(string, string), TreeType> _cache = new();

    public int Count => _cache.Count;

    public TreeType Get(string name, string color)
    {
        if (!_cache.TryGetValue((name, color), out TreeType? kind))
        {
            kind = new TreeType(name, color);
            _cache[(name, color)] = kind;
        }
        return kind;
    }
}

public class Tree
{
    public Tree(int x, int y, TreeType kind)
    {
        X = x;
        Y = y;
        Kind = kind;
    }

    public int X { get; }

    public int Y { get; }

    public TreeType Kind { get; }

    public string Draw() => $"{Kind.Name} ({Kind.Color}) at {X},{Y}";
}

public static class Demo
{
    public static void Run()
    {
        var factory = new TreeTypeFactory();
        var forest = new List<Tree>
        {
            new Tree(1, 2, factory.Get("oak", "green")),
            new Tree(3, 4, factory.Get("oak", "green")),
            new Tree(5, 6, factory.Get("pine", "dark green")),
            new Tree(7, 8, factory.Get("oak", "green")),
            new Tree(9, 10, factory.Get("pine", "dark green")),
        };
        foreach (var tree in forest)
        {
            Console.WriteLine(tree.Draw());
        }
        Console.WriteLine($"trees: {forest.Count}, shared types: {factory.Count}");
        Console.WriteLine($"same object: {object.ReferenceEquals(forest[0].Kind, forest[1].Kind)}");
    }
}
