namespace FactoryMethodDemo;

public interface ITransport
{
    string Deliver(string cargo);
}

public class Truck : ITransport
{
    public string Deliver(string cargo) => $"Truck carries {cargo} by road";
}

public class Ship : ITransport
{
    public string Deliver(string cargo) => $"Ship carries {cargo} by sea";
}

public abstract class Logistics
{
    public string PlanDelivery(string cargo)
    {
        ITransport transport = CreateTransport();
        return $"Plan: {transport.Deliver(cargo)}";
    }

    protected abstract ITransport CreateTransport();
}

public class RoadLogistics : Logistics
{
    protected override ITransport CreateTransport() => new Truck();
}

public class SeaLogistics : Logistics
{
    protected override ITransport CreateTransport() => new Ship();
}

public static class Demo
{
    public static void Run()
    {
        var planners = new Dictionary<string, Logistics>
        {
            ["road"] = new RoadLogistics(),
            ["sea"] = new SeaLogistics(),
        };
        foreach (var mode in new[] { "road", "sea" })
        {
            Console.WriteLine(planners[mode].PlanDelivery("5 crates"));
        }
    }
}
