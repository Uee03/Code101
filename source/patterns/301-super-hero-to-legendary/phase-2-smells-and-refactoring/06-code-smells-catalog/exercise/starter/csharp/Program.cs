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
    // TODO 2: print "<name>: branches=<n> -> too many branches" when branches is above MaxBranches,
    //         otherwise "<name>: branches=<n> -> ok".
    Console.WriteLine($"{name}: branches={branches}");
}

static int CountBranches(string code)
{
    // TODO 1: return how many times a C# if statement starts in the text (try Regex.Matches).
    return 0;
}
