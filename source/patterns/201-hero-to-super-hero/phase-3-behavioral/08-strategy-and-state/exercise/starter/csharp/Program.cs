var light = new Light();
for (int i = 0; i < 4; i++)
{
    Console.WriteLine(light.Color());
    light.Advance();
}

abstract class LightState
{
    public abstract string Color { get; }

    public abstract LightState Next();
}

class Red : LightState
{
    public override string Color => "red";

    public override LightState Next() => new Green();
}

class Green : LightState
{
    public override string Color => "green";

    // TODO 1: return a new Yellow() instead of throwing
    public override LightState Next() => throw new NotImplementedException("TODO 1");
}

// TODO 2: write Yellow : LightState. Its Color is "yellow" and Next() returns a new Red().

class Light
{
    private LightState _state = new Red();

    public string Color() => _state.Color;

    public void Advance()
    {
        _state = _state.Next();
    }
}
