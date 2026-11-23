public interface IDiscount
{
    string Name { get; }

    decimal Apply(decimal price);
}

public abstract class Discount : IDiscount
{
    public abstract string Name { get; }

    public decimal Apply(decimal price)
    {
        decimal off = Calculate(price);
        return Math.Clamp(price - off, 0m, price);
    }

    protected abstract decimal Calculate(decimal price);

    public virtual string Describe() => $"Discount: {Name}";
}

public sealed class PercentOff(decimal percent) : Discount
{
    public override string Name => $"{percent}% off";

    protected override decimal Calculate(decimal price) => price * percent / 100m;
}

public sealed class FixedOff(decimal amount) : Discount
{
    public override string Name => $"{amount:F2} off";

    protected override decimal Calculate(decimal price) => amount;

    public override string Describe() => base.Describe() + " (flat amount)";
}

public sealed class CappedDiscount(IDiscount inner, decimal maxOff) : IDiscount
{
    public string Name => $"{inner.Name} (max {maxOff:F2} off)";

    public decimal Apply(decimal price)
    {
        decimal discounted = inner.Apply(price);
        return Math.Max(discounted, price - maxOff);
    }
}
