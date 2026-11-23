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
