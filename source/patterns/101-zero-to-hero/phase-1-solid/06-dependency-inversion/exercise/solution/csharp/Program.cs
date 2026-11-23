var stamper = new InvoiceStamper(new FixedClock(new DateOnly(2026, 1, 15)));
Console.WriteLine(stamper.Stamp(7));

interface IClock
{
    DateOnly Today();
}

class SystemClock : IClock
{
    public DateOnly Today()
    {
        return DateOnly.FromDateTime(DateTime.Now);
    }
}

class FixedClock : IClock
{
    private readonly DateOnly _day;

    public FixedClock(DateOnly day)
    {
        _day = day;
    }

    public DateOnly Today()
    {
        return _day;
    }
}

class InvoiceStamper
{
    private readonly IClock _clock;

    public InvoiceStamper(IClock clock)
    {
        _clock = clock;
    }

    public string Stamp(int number)
    {
        DateOnly today = _clock.Today();
        return $"Invoice {number} issued {today:yyyy-MM-dd}";
    }
}
