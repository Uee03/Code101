var chain = new MinLength();
chain.SetNext(new HasDigit());
foreach (var password in new[] { "short", "abcdefgh", "abcdefg1" })
{
    Console.WriteLine($"{password}: {chain.Verify(password)}");
}

class Check
{
    private Check? _next;

    public Check SetNext(Check check)
    {
        _next = check;
        return check;
    }

    public string Verify(string password)
    {
        string? problem = Problem(password);
        if (problem != null)
        {
            return problem;
        }
        if (_next != null)
        {
            return _next.Verify(password);
        }
        return "ok";
    }

    protected virtual string? Problem(string password) => null;
}

class MinLength : Check
{
    protected override string? Problem(string password) => password.Length < 8 ? "too short" : null;
}

class HasDigit : Check
{
    protected override string? Problem(string password) => password.Any(char.IsDigit) ? null : "needs a digit";
}
