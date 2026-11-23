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

    public override LightState Next() => new Yellow();
}

class Yellow : LightState
{
    public override string Color => "yellow";

    public override LightState Next() => new Red();
}

class Light
{
    private LightState _state = new Red();

    public string Color() => _state.Color;

    public void Advance()
    {
        _state = _state.Next();
    }
}
