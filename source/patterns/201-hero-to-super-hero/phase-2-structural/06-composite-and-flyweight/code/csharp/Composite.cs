namespace CompositeDemo;

public abstract class Node
{
    protected Node(string name)
    {
        Name = name;
    }

    public string Name { get; }

    public abstract int Size();

    public abstract IEnumerable<string> Lines(int depth);
}

public class Document : Node
{
    private readonly int _sizeKb;

    public Document(string name, int sizeKb) : base(name)
    {
        _sizeKb = sizeKb;
    }

    public override int Size() => _sizeKb;

    public override IEnumerable<string> Lines(int depth) =>
        new[] { $"{new string(' ', depth * 2)}{Name} ({Size()})" };
}

public class Folder : Node
{
    private readonly List<Node> _children = new();

    public Folder(string name) : base(name)
    {
    }

    public Folder Add(Node child)
    {
        _children.Add(child);
        return this;
    }

    public override int Size() => _children.Sum(child => child.Size());

    public override IEnumerable<string> Lines(int depth)
    {
        var result = new List<string> { $"{new string(' ', depth * 2)}{Name} ({Size()})" };
        foreach (var child in _children)
        {
            result.AddRange(child.Lines(depth + 1));
        }
        return result;
    }
}

public static class Demo
{
    public static void Run()
    {
        var docs = new Folder("docs").Add(new Document("b.txt", 20)).Add(new Document("c.txt", 30));
        var root = new Folder("root").Add(new Document("a.txt", 10)).Add(docs);
        foreach (var line in root.Lines(0))
        {
            Console.WriteLine(line);
        }
        Console.WriteLine($"docs only: {docs.Size()}");
    }
}
