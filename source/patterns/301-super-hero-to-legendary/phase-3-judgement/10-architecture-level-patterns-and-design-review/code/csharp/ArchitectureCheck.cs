using System.Text.RegularExpressions;

public static class ArchitectureCheck
{
    private static readonly string[] Layers = ["Domain", "Application", "Adapters"];

    private static readonly Dictionary<string, string[]> Forbidden = new()
    {
        ["Domain"] = ["Application", "Adapters"],
        ["Application"] = ["Adapters"],
        ["Adapters"] = [],
    };

    private static readonly Regex UsingLine = new(@"^using TasksApp\.(\w+)");

    public static List<string> CheckSource(string layer, string source)
    {
        var problems = new List<string>();
        var lines = source.Split('\n');
        for (var i = 0; i < lines.Length; i++)
        {
            var match = UsingLine.Match(lines[i].Trim());
            if (match.Success && Forbidden[layer].Contains(match.Groups[1].Value))
            {
                problems.Add($"{layer.ToLowerInvariant()} must not depend on {match.Groups[1].Value.ToLowerInvariant()} (line {i + 1})");
            }
        }
        return problems;
    }

    public static (int Files, List<string> Problems) CheckTree(string root)
    {
        var files = 0;
        var problems = new List<string>();
        foreach (var layer in Layers)
        {
            foreach (var path in Directory.GetFiles(Path.Combine(root, layer), "*.cs").OrderBy(p => p, StringComparer.Ordinal))
            {
                files++;
                problems.AddRange(CheckSource(layer, File.ReadAllText(path)).Select(p => $"{Path.GetFileName(path)}: {p}"));
            }
        }
        return (files, problems);
    }
}
