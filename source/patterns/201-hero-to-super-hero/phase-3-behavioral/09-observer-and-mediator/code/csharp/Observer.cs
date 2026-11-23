namespace ObserverDemo;

public interface IPriceObserver
{
    void Update(int price);
}

public class PriceFeed
{
    private readonly List<IPriceObserver> _observers = new();

    public void Subscribe(IPriceObserver observer)
    {
        _observers.Add(observer);
    }

    public void Unsubscribe(IPriceObserver observer)
    {
        _observers.Remove(observer);
    }

    public void SetPrice(int price)
    {
        foreach (var observer in _observers.ToArray())
        {
            observer.Update(price);
        }
    }
}

public class PriceLogger : IPriceObserver
{
    public void Update(int price) => Console.WriteLine($"log: price is {price}");
}

public class PriceAlert : IPriceObserver
{
    private readonly int _limit;

    public PriceAlert(int limit)
    {
        _limit = limit;
    }

    public void Update(int price)
    {
        if (price > _limit)
        {
            Console.WriteLine($"ALERT: price {price} is above {_limit}");
        }
    }
}

public static class Demo
{
    public static void Run()
    {
        var feed = new PriceFeed();
        var logger = new PriceLogger();
        var alert = new PriceAlert(110);
        feed.Subscribe(logger);
        feed.Subscribe(alert);
        feed.SetPrice(100);
        feed.SetPrice(120);
        feed.Unsubscribe(logger);
        feed.SetPrice(130);
    }
}
