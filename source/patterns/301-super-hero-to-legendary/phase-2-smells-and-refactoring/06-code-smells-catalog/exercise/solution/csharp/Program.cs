using System.Text.RegularExpressions;

const int MaxBranches = 2;
var methods = new List<(string Name, string Code)>
{
    ("Price", """
        if (kind == "a") { return qty * 3; }
        else if (kind == "b") { return qty * 4; }
        else if (kind == "c") { return qty * 5; }
        return 0;
        """),
    ("Double", "return x * 2;"),
};

foreach (var (name, code) in methods)
{
    var branches = CountBranches(code);
    var verdict = branches > MaxBranches ? "too many branches" : "ok";
    Console.WriteLine($"{name}: branches={branches} -> {verdict}");
}

static int CountBranches(string code)
{
    return Regex.Matches(code, @"\bif \(").Count;
}
