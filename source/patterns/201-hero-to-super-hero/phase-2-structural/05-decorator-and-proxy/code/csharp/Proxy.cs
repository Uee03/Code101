namespace ProxyDemo;

public interface IForecast
{
    string Get(string city);
}

public class SlowForecast : IForecast
{
    public int Calls { get; private set; }

    public string Get(string city)
    {
        Calls++;
        Console.WriteLine($"(slow call for {city})");
        return $"forecast for {city}";
    }
}

public class CachingForecast : IForecast
{
    private readonly IForecast _real;
    private readonly Dictionary<string, string> _cache = new();

    public CachingForecast(IForecast real)
    {
        _real = real;
    }

    public string Get(string city)
    {
        if (!_cache.ContainsKey(city))
        {
            _cache[city] = _real.Get(city);
        }
        return _cache[city];
    }
}

public class GuardedForecast : IForecast
{
    private readonly IForecast _real;
    private readonly string _role;

    public GuardedForecast(IForecast real, string role)
    {
        _real = real;
        _role = role;
    }

    public string Get(string city)
    {
        if (_role != "member")
        {
            throw new UnauthorizedAccessException("members only");
        }
        return _real.Get(city);
    }
}

public static class Demo
{
    public static void Run()
    {
        var real = new SlowForecast();
        var cached = new CachingForecast(real);
        Console.WriteLine(cached.Get("Oslo"));
        Console.WriteLine(cached.Get("Oslo"));
        Console.WriteLine(cached.Get("Rome"));
        Console.WriteLine($"real calls: {real.Calls}");
        var guarded = new GuardedForecast(real, "guest");
        try
        {
            guarded.Get("Oslo");
        }
        catch (UnauthorizedAccessException error)
        {
            Console.WriteLine($"Denied: {error.Message}");
        }
    }
}
