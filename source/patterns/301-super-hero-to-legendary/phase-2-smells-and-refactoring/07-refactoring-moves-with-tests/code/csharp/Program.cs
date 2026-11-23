var cases = Grid().ToList();

Console.WriteLine($"sample quote: {Shipping.FinalCost("fast", new Parcel(5, "eu", true, true, 10000, false))}");
Compare("step 1 (extract functions, parameter object)", Shipping.Step1Cost);
Compare("step 2 (polymorphic carriers, move method)", Shipping.FinalCost);
Compare("broken step (express applied last)", Shipping.BrokenCost, showFirst: true);

var oldText = ErrorText(() => Shipping.LegacyCost(1, "teleport", false, "eu", false, 0, false));
var newText = ErrorText(() => Shipping.FinalCost("teleport", new Parcel(1, "eu", false, false, 0, false)));
Console.WriteLine($"error message preserved: {oldText == newText && oldText != ""}");

static IEnumerable<(int Weight, string Carrier, string Zone, bool Express, bool Insured, bool Fragile)> Grid()
{
    foreach (var weight in new[] { 1, 5, 20 })
    foreach (var carrier in new[] { "post", "fast", "freight" })
    foreach (var zone in new[] { "domestic", "eu", "world" })
    foreach (var express in new[] { false, true })
    foreach (var insured in new[] { false, true })
    foreach (var fragile in new[] { false, true })
    {
        yield return (weight, carrier, zone, express, insured, fragile);
    }
}

void Compare(string name, Func<string, Parcel, int> candidate, bool showFirst = false)
{
    var differences = new List<(string Text, int Expected, int Actual)>();
    foreach (var c in cases)
    {
        var expected = Shipping.LegacyCost(c.Weight, c.Carrier, c.Express, c.Zone, c.Insured, 10000, c.Fragile);
        var actual = candidate(c.Carrier, new Parcel(c.Weight, c.Zone, c.Express, c.Insured, 10000, c.Fragile));
        if (expected != actual)
        {
            differences.Add(($"{c.Weight} kg {c.Carrier} {c.Zone} express={c.Express} insured={c.Insured} fragile={c.Fragile}", expected, actual));
        }
    }
    Console.WriteLine($"{name}: {cases.Count} cases, {differences.Count} differences");
    if (showFirst && differences.Count > 0)
    {
        var first = differences[0];
        Console.WriteLine($"first difference: {first.Text}: legacy {first.Expected}, candidate {first.Actual}");
    }
}

static string ErrorText(Action call)
{
    try
    {
        call();
    }
    catch (ArgumentException error)
    {
        return error.Message;
    }
    return "";
}
