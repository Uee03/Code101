using System.Text.RegularExpressions;

public sealed record Measurement(string Name, int Lines, int Params, int Nesting);

public static class Scanner
{
    public const int MaxLines = 20;
    public const int MaxParams = 4;
    public const int MaxNesting = 2;
    public const int MaxMethods = 5;

    private static readonly Regex ClassLine = new(@"^(public |internal )?(sealed )?class (\w+)");
    private static readonly Regex MethodLine = new(@"^( +)(public|private|internal|protected)( static)? [\w<>\[\]?]+ (\w+)\((.*)\)$");

    public static (List<Measurement> Methods, List<(string Name, int Count)> Classes) Scan(string[] lines)
    {
        var methods = new List<Measurement>();
        var classes = new List<(string Name, int Count)>();
        string? current = null;
        var count = 0;
        for (var i = 0; i < lines.Length; i++)
        {
            var classMatch = ClassLine.Match(lines[i]);
            if (classMatch.Success)
            {
                if (current is not null)
                {
                    classes.Add((current, count));
                }
                current = classMatch.Groups[3].Value;
                count = 0;
                continue;
            }
            var match = MethodLine.Match(lines[i]);
            if (!match.Success)
            {
                continue;
            }
            var indent = match.Groups[1].Length;
            var end = i + 1;
            while (end < lines.Length && lines[end] != new string(' ', indent) + "}")
            {
                end++;
            }
            var deepest = lines[i..(end + 1)].Where(l => l.Trim().Length > 0).Max(l => l.Length - l.TrimStart().Length);
            var parameters = match.Groups[5].Value.Trim().Length == 0 ? 0 : match.Groups[5].Value.Split(',').Length;
            methods.Add(new Measurement(match.Groups[4].Value, end - i + 1, parameters, Math.Max(0, (deepest - indent) / 4 - 1)));
            count++;
        }
        if (current is not null)
        {
            classes.Add((current, count));
        }
        return (methods, classes);
    }

    public static List<string> Flags(Measurement measurement)
    {
        var found = new List<string>();
        if (measurement.Lines > MaxLines)
        {
            found.Add("long method");
        }
        if (measurement.Params > MaxParams)
        {
            found.Add("long parameter list");
        }
        if (measurement.Nesting > MaxNesting)
        {
            found.Add("deep nesting");
        }
        return found;
    }
}
