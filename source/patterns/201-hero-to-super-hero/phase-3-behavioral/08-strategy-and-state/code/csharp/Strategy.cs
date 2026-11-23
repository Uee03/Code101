namespace StrategyDemo;

public interface IShipping
{
    int Cost(int weightGrams);
}

public class Pickup : IShipping
{
    public int Cost(int weightGrams) => 0;
}

public class Standard : IShipping
{
    public int Cost(int weightGrams) => 500;
}

public class Express : IShipping
{
    public int Cost(int weightGrams) => 1000 + weightGrams / 10;
}

public class Order
{
    private readonly int _weightGrams;

    public Order(int weightGrams, IShipping shipping)
    {
        _weightGrams = weightGrams;
        Shipping = shipping;
    }

    public IShipping Shipping { get; set; }

    public int ShippingCents() => Shipping.Cost(_weightGrams);
}

public static class Demo
{
    public static void Run()
    {
        var order = new Order(2500, new Pickup());
        Console.WriteLine($"pickup: {order.ShippingCents()}");
        order.Shipping = new Standard();
        Console.WriteLine($"standard: {order.ShippingCents()}");
        order.Shipping = new Express();
        Console.WriteLine($"express: {order.ShippingCents()}");
    }
}
