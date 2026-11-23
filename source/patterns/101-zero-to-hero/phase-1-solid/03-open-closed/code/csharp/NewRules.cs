using After;

namespace NewRules;

public class FlatDiscount : IDiscountRule
{
    private readonly int _cents;

    public FlatDiscount(int cents)
    {
        _cents = cents;
    }

    public int Apply(int totalCents)
    {
        return Math.Max(totalCents - _cents, 0);
    }
}
