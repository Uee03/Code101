Console.WriteLine(Compose("2026-03-01").Pay(5));
Console.WriteLine(Compose("2000-01-01").Pay(5));

static Checkout Compose(string day)
{
    var clock = new Clock(day);
    var printer = new ReceiptPrinter(clock);
    return new Checkout(printer);
}

class Clock(string day)
{
    public string Today() => day;
}

class ReceiptPrinter(Clock clock)
{
    public string Render(string text) => $"{clock.Today()}: {text}";
}

class Checkout(ReceiptPrinter printer)
{
    public string Pay(int amount) => printer.Render($"paid {amount}");
}
