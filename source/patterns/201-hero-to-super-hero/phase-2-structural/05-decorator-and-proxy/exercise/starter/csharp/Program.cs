IPrice basePrice = new BasePrice(1000);
Console.WriteLine($"base: {basePrice.Cents()}");
Console.WriteLine($"taxed: {new Tax(basePrice, 20).Cents()}");
// TODO 3: build feeLast = new Fee(new Tax(new Discount(basePrice, 10), 20), 500)
//         and feeFirst = new Tax(new Fee(new Discount(basePrice, 10), 500), 20)
//         and print them as "fee last: ..." and "fee first: ..."

// TODO 1: write Discount : IPrice with a constructor (IPrice inner, int percent); Cents() returns the inner price minus percent of it.
// TODO 2: write Fee : IPrice with a constructor (IPrice inner, int extraCents); Cents() returns the inner price plus extraCents.

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
