Console.WriteLine(EmailGreeting("  Ana Silva "));
Console.WriteLine(SmsGreeting("  Ana Silva "));
Console.WriteLine(Initials("  Ana Silva "));

// TODO 1 (DRY): the cleaning step name.Trim() is repeated. Move it into a method CleanName(name)
//               and call it from the greetings.
// TODO 2 (YAGNI): delete the method nobody calls.
// TODO 3 (KISS): rewrite Initials with a plain foreach loop over name.Split(' ', StringSplitOptions.RemoveEmptyEntries).
//                The output must not change.

static string EmailGreeting(string name)
{
    return "Hello " + name.Trim() + ", welcome!";
}

static string SmsGreeting(string name)
{
    return "Hello " + name.Trim() + "!";
}

static string GreetingAsXml(string name)
{
    return "<greeting>" + name.Trim() + "</greeting>";
}

static string Initials(string name)
{
    return string.Join("", name.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(part => char.ToUpper(part[0])));
}
