Console.WriteLine(EmailGreeting("  Ana Silva "));
Console.WriteLine(SmsGreeting("  Ana Silva "));
Console.WriteLine(Initials("  Ana Silva "));

static string CleanName(string name)
{
    return name.Trim();
}

static string EmailGreeting(string name)
{
    return "Hello " + CleanName(name) + ", welcome!";
}

static string SmsGreeting(string name)
{
    return "Hello " + CleanName(name) + "!";
}

static string Initials(string name)
{
    string letters = "";
    foreach (string part in name.Split(' ', StringSplitOptions.RemoveEmptyEntries))
    {
        letters += char.ToUpper(part[0]);
    }
    return letters;
}
