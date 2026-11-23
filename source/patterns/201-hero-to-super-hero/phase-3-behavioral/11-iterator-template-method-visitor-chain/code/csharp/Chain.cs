namespace ChainDemo;

public class Handler
{
    private readonly string _name;
    private readonly int _limit;
    private Handler? _next;

    public Handler(string name, int limit)
    {
        _name = name;
        _limit = limit;
    }

    public Handler SetNext(Handler handler)
    {
        _next = handler;
        return handler;
    }

    public string Handle(int amount)
    {
        if (amount <= _limit)
        {
            return $"{amount}: approved by {_name}";
        }
        if (_next != null)
        {
            return _next.Handle(amount);
        }
        return $"{amount}: nobody can approve";
    }
}

public static class Demo
{
    public static void Run()
    {
        var manager = new Handler("manager", 100);
        manager.SetNext(new Handler("director", 1000)).SetNext(new Handler("ceo", 10000));
        foreach (var amount in new[] { 50, 500, 5000, 50000 })
        {
            Console.WriteLine(manager.Handle(amount));
        }
    }
}
