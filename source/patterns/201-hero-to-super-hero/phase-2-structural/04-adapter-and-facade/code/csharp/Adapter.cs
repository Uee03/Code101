namespace AdapterDemo;

public interface ITemperatureSource
{
    int Celsius();
}

public class CelsiusSensor : ITemperatureSource
{
    private readonly int _degrees;

    public CelsiusSensor(int degrees)
    {
        _degrees = degrees;
    }

    public int Celsius() => _degrees;
}

public class FahrenheitSensor
{
    private readonly int _degrees;

    public FahrenheitSensor(int degrees)
    {
        _degrees = degrees;
    }

    public int ReadF() => _degrees;
}

public class FahrenheitAdapter : ITemperatureSource
{
    private readonly FahrenheitSensor _sensor;

    public FahrenheitAdapter(FahrenheitSensor sensor)
    {
        _sensor = sensor;
    }

    public int Celsius() => (_sensor.ReadF() - 32) * 5 / 9;
}

public static class Demo
{
    public static string Report(ITemperatureSource source) => $"{source.Celsius()} C";

    public static void Run()
    {
        Console.WriteLine(Report(new CelsiusSensor(20)));
        Console.WriteLine(Report(new FahrenheitAdapter(new FahrenheitSensor(212))));
        Console.WriteLine(Report(new FahrenheitAdapter(new FahrenheitSensor(50))));
    }
}
