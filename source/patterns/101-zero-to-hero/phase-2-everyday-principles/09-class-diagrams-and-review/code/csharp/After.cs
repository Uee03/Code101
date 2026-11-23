using Item = (string Name, int PriceCents, int Quantity);

namespace After;

public interface IDiscountRule
{
    int Apply(int totalCents);
}

public class NoDiscount : IDiscountRule
{
    public int Apply(int totalCents)
    {
        return totalCents;
    }
}

public class PercentDiscount : IDiscountRule
{
    private readonly int _percent;

    public PercentDiscount(int percent)
    {
        _percent = percent;
    }

    public int Apply(int totalCents)
    {
        return totalCents - totalCents * _percent / 100;
    }
}

public interface INotifier
{
    void Notify(string address, string text);
}

public class EmailNotifier : INotifier
{
    public void Notify(string address, string text)
    {
        Console.WriteLine($"Email to {address}: {text}");
    }
}

public class SmsNotifier : INotifier
{
    public void Notify(string address, string text)
    {
        Console.WriteLine($"SMS to {address}: {text}");
    }
}

public class OrderStore
{
    private readonly List<string> _addresses = new();

    public int Count => _addresses.Count;

    public void Save(string address)
    {
        _addresses.Add(address);
        Console.WriteLine($"Saved order for {address}");
    }
}

public class OrderProcessor
{
    private readonly IDiscountRule _discount;
    private readonly INotifier _notifier;
    private readonly OrderStore _store;

    public OrderProcessor(IDiscountRule discount, INotifier notifier, OrderStore store)
    {
        _discount = discount;
        _notifier = notifier;
        _store = store;
    }

    public void Process(string address, List<Item> items)
    {
        int subtotal = 0;
        foreach (var item in items)
        {
            subtotal += item.PriceCents * item.Quantity;
        }
        int total = _discount.Apply(subtotal);
        _notifier.Notify(address, $"order total {total}");
        _store.Save(address);
    }
}
