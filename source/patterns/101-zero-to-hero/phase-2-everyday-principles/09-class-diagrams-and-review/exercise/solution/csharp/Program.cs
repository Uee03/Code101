var store = new BookingStore();
new BookingManager(new AdultPrice(), new EmailNotifier(), store).Book("ana@example.com", 2);
new BookingManager(new ChildPrice(), new SmsNotifier(), store).Book("+100", 3);

interface IPriceRule
{
    int SeatCents();
}

class AdultPrice : IPriceRule
{
    public int SeatCents()
    {
        return 1000;
    }
}

class ChildPrice : IPriceRule
{
    public int SeatCents()
    {
        return 500;
    }
}

interface INotifier
{
    void Notify(string address, string text);
}

class EmailNotifier : INotifier
{
    public void Notify(string address, string text)
    {
        Console.WriteLine($"Email to {address}: {text}");
    }
}

class SmsNotifier : INotifier
{
    public void Notify(string address, string text)
    {
        Console.WriteLine($"SMS to {address}: {text}");
    }
}

class BookingStore
{
    public void Save(string address)
    {
        Console.WriteLine($"Booking saved for {address}");
    }
}

class BookingManager
{
    private readonly IPriceRule _priceRule;
    private readonly INotifier _notifier;
    private readonly BookingStore _store;

    public BookingManager(IPriceRule priceRule, INotifier notifier, BookingStore store)
    {
        _priceRule = priceRule;
        _notifier = notifier;
        _store = store;
    }

    public void Book(string address, int seats)
    {
        int total = _priceRule.SeatCents() * seats;
        _notifier.Notify(address, $"booking for {seats} seat(s), total {total}");
        _store.Save(address);
    }
}
