namespace After;

public interface IDiscountRule
{
    int Apply(int totalCents);
}

public class NoDiscount : IDiscountRule
{
    public int Apply(int totalCents)
    {
        return totalCents;
    }
}

public class PercentDiscount : IDiscountRule
{
    private readonly int _percent;

    public PercentDiscount(int percent)
    {
        _percent = percent;
    }

    public int Apply(int totalCents)
    {
        return totalCents - totalCents * _percent / 100;
    }
}

public static class Pricing
{
    public static int FinalTotal(IDiscountRule rule, int totalCents)
    {
        return rule.Apply(totalCents);
    }
}
