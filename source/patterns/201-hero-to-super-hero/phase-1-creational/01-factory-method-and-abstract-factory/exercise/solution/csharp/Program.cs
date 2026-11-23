var printers = new Dictionary<string, Printer>
{
    ["plain"] = new PlainPrinter(),
    ["shout"] = new ShoutPrinter(),
};
foreach (var name in new[] { "plain", "shout" })
{
    printers[name].PrintLine("hello");
}

interface IFormatter
{
    string Format(string text);
}

class PlainFormatter : IFormatter
{
    public string Format(string text) => text;
}

class ShoutFormatter : IFormatter
{
    public string Format(string text) => text.ToUpperInvariant() + "!";
}

abstract class Printer
{
    public void PrintLine(string text) => Console.WriteLine(CreateFormatter().Format(text));

    protected abstract IFormatter CreateFormatter();
}

class PlainPrinter : Printer
{
    protected override IFormatter CreateFormatter() => new PlainFormatter();
}

class ShoutPrinter : Printer
{
    protected override IFormatter CreateFormatter() => new ShoutFormatter();
}
