IPrice basePrice = new BasePrice(1000);
Console.WriteLine($"base: {basePrice.Cents()}");
Console.WriteLine($"taxed: {new Tax(basePrice, 20).Cents()}");
var feeLast = new Fee(new Tax(new Discount(basePrice, 10), 20), 500);
var feeFirst = new Tax(new Fee(new Discount(basePrice, 10), 500), 20);
Console.WriteLine($"fee last: {feeLast.Cents()}");
Console.WriteLine($"fee first: {feeFirst.Cents()}");

interface IPrice
{
    int Cents();
}

class BasePrice : IPrice
{
    private readonly int _amount;

    public BasePrice(int amount)
    {
        _amount = amount;
    }

    public int Cents() => _amount;
}

class Tax : IPrice
{
    private readonly IPrice _inner;
    private readonly int _percent;

    public Tax(IPrice inner, int percent)
    {
        _inner = inner;
        _percent = percent;
    }

    public int Cents()
    {
        int net = _inner.Cents();
        return net + net * _percent / 100;
    }
}

class Discount : IPrice
{
    private readonly IPrice _inner;
    private readonly int _percent;

    public Discount(IPrice inner, int percent)
    {
        _inner = inner;
        _percent = percent;
    }

    public int Cents()
    {
        int gross = _inner.Cents();
        return gross - gross * _percent / 100;
    }
}

class Fee : IPrice
{
    private readonly IPrice _inner;
    private readonly int _extraCents;

    public Fee(IPrice inner, int extraCents)
    {
        _inner = inner;
        _extraCents = extraCents;
    }

    public int Cents() => _inner.Cents() + _extraCents;
}
