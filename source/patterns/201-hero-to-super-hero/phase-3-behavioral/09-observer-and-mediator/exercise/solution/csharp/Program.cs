var thermometer = new Thermometer();
thermometer.Subscribe(new Display());
thermometer.Subscribe(new FreezeWarning());
thermometer.SetTemperature(5);
thermometer.SetTemperature(-3);

interface IListener
{
    void Update(int degrees);
}

class Thermometer
{
    private readonly List<IListener> _listeners = new();

    public void Subscribe(IListener listener)
    {
        _listeners.Add(listener);
    }

    public void SetTemperature(int degrees)
    {
        foreach (var listener in _listeners.ToArray())
        {
            listener.Update(degrees);
        }
    }
}

class Display : IListener
{
    public void Update(int degrees) => Console.WriteLine($"display: {degrees} C");
}

class FreezeWarning : IListener
{
    public void Update(int degrees)
    {
        if (degrees < 0)
        {
            Console.WriteLine("warning: freezing");
        }
    }
}
