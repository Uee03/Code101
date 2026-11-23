namespace InjectionDemo;

public class Checkout
{
    private readonly int _taxPercent;

    public Checkout(int taxPercent)
    {
        _taxPercent = taxPercent;
    }

    public int Total(int netCents) => netCents + netCents * _taxPercent / 100;
}

public static class Demo
{
    public static void Run()
    {
        var shop = new Checkout(20);
        var check = new Checkout(0);
        Console.WriteLine($"shop total: {shop.Total(1000)}");
        Console.WriteLine($"check total: {check.Total(1000)}");
        Console.WriteLine($"shop total again: {shop.Total(1000)}");
    }
}
