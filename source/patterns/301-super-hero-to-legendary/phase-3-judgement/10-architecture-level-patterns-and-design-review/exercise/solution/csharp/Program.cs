var forbidden = new Dictionary<string, string[]>
{
    ["domain"] = ["application", "adapters"],
    ["application"] = ["adapters"],
};

var samples = new List<(string Layer, string[] Imported)>
{
    ("domain", ["application"]),
    ("application", ["domain"]),
    ("application", ["adapters"]),
    ("adapters", ["application", "domain"]),
};

foreach (var (layer, imported) in samples)
{
    var bad = imported.Where(name => forbidden.GetValueOrDefault(layer, []).Contains(name)).ToList();
    var names = string.Join(", ", imported);
    if (bad.Count > 0)
    {
        Console.WriteLine($"{layer} imports {names}: forbidden ({string.Join(", ", bad)})");
    }
    else
    {
        Console.WriteLine($"{layer} imports {names}: ok");
    }
}
