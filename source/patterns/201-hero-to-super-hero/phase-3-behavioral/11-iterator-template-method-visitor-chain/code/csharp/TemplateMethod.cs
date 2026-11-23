namespace TemplateMethodDemo;

public abstract class Report
{
    public IReadOnlyList<string> Render((string Name, int Quantity)[] rows)
    {
        var lines = new List<string> { Header() };
        foreach (var (name, quantity) in rows)
        {
            lines.Add(FormatRow(name, quantity));
        }
        lines.AddRange(Footer());
        return lines;
    }

    protected abstract string Header();

    protected abstract string FormatRow(string name, int quantity);

    protected virtual IEnumerable<string> Footer() => Array.Empty<string>();
}

public class CsvReport : Report
{
    protected override string Header() => "name,qty";

    protected override string FormatRow(string name, int quantity) => $"{name},{quantity}";
}

public class TextReport : Report
{
    protected override string Header() => "== Report ==";

    protected override string FormatRow(string name, int quantity) => $"{name} x{quantity}";

    protected override IEnumerable<string> Footer() => new[] { "== end ==" };
}

public static class Demo
{
    public static void Run()
    {
        var rows = new[] { ("apple", 3), ("pear", 5) };
        Console.WriteLine("[csv]");
        foreach (var line in new CsvReport().Render(rows))
        {
            Console.WriteLine(line);
        }
        Console.WriteLine("[text]");
        foreach (var line in new TextReport().Render(rows))
        {
            Console.WriteLine(line);
        }
    }
}
