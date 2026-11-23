using System.Globalization;

namespace Perf;

public static class LineSum
{
    // Easy to read, but Split allocates an array and one string per field on every call.
    public static int SumSplit(string line)
    {
        var total = 0;
        foreach (var part in line.Split(','))
        {
            total += int.Parse(part, CultureInfo.InvariantCulture);
        }

        return total;
    }

    // Same result, same exceptions for bad input, but it slices the original text and allocates nothing.
    public static int SumSpan(ReadOnlySpan<char> line)
    {
        var total = 0;
        while (true)
        {
            var comma = line.IndexOf(',');
            var part = comma < 0 ? line : line[..comma];
            total += int.Parse(part, CultureInfo.InvariantCulture);
            if (comma < 0)
            {
                return total;
            }

            line = line[(comma + 1)..];
        }
    }
}
