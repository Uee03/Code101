var thermometer = new Thermometer();
thermometer.Subscribe(new Display());
// TODO 2: subscribe a new FreezeWarning() to the thermometer here
thermometer.SetTemperature(5);
thermometer.SetTemperature(-3);

// TODO 1: write FreezeWarning : IListener whose Update prints "warning: freezing" only when degrees is below 0.

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
