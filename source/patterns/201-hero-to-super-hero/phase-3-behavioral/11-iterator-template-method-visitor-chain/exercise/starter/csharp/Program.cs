var chain = new MinLength();
// TODO 2: chain.SetNext(new HasDigit());
foreach (var password in new[] { "short", "abcdefgh", "abcdefg1" })
{
    Console.WriteLine($"{password}: {chain.Verify(password)}");
}

// TODO 1: write HasDigit : Check. Problem() returns "needs a digit" when the password has no digit, otherwise null.
//         Hint: password.Any(char.IsDigit)

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
