Console.WriteLine(Compose("2026-03-01").Pay(5));
// TODO 2: print a second line that uses Compose with the day "2000-01-01".

static Checkout Compose(string day)
{
    // TODO 1: create one Clock for the given day and one ReceiptPrinter that uses it.
    //         Return a Checkout that uses the printer. This method is the composition root.
    throw new NotImplementedException();
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
