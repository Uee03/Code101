var carriers = new List<ICarrier> { new PostCarrier(), new CourierCarrier() };
var speeds = new List<ISpeed> { new StandardSpeed(), new ExpressSpeed() };
foreach (var carrier in carriers)
{
    foreach (var speed in speeds)
    {
        Console.WriteLine(new Shipping(carrier, speed).CostCents());
    }
}

interface ICarrier
{
    int BaseCents();
}

class PostCarrier : ICarrier
{
    public int BaseCents()
    {
        return 300;
    }
}

class CourierCarrier : ICarrier
{
    public int BaseCents()
    {
        return 800;
    }
}

interface ISpeed
{
    int SurchargeCents();
}

class StandardSpeed : ISpeed
{
    public int SurchargeCents()
    {
        return 0;
    }
}

class ExpressSpeed : ISpeed
{
    public int SurchargeCents()
    {
        return 500;
    }
}

class Shipping
{
    private readonly ICarrier _carrier;
    private readonly ISpeed _speed;

    public Shipping(ICarrier carrier, ISpeed speed)
    {
        _carrier = carrier;
        _speed = speed;
    }

    public int CostCents()
    {
        return _carrier.BaseCents() + _speed.SurchargeCents();
    }
}
