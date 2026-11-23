var forbidden = new Dictionary<string, string[]>
{
    ["domain"] = ["application", "adapters"],
    // TODO 1: add the rule for "application": it must not depend on "adapters".
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
    // TODO 2: print "<layer> imports <names>: ok" when bad is empty, otherwise
    //         "<layer> imports <names>: forbidden (<bad names>)". Join several names with ", ".
    Console.WriteLine($"{layer} {imported.Length} {bad.Count}");
}
