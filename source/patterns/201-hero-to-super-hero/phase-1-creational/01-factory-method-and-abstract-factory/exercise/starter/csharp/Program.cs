var printers = new Dictionary<string, Printer>
{
    ["plain"] = new PlainPrinter(),
    // TODO 3: add ["shout"] = new ShoutPrinter(),
};
foreach (var name in new[] { "plain", "shout" })
{
    printers[name].PrintLine("hello");
}

// TODO 1: write ShoutFormatter (implements IFormatter): Format returns the text in upper case followed by "!".
// TODO 2: write ShoutPrinter (extends Printer): CreateFormatter returns a new ShoutFormatter.

interface IFormatter
{
    string Format(string text);
}

class PlainFormatter : IFormatter
{
    public string Format(string text) => text;
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
