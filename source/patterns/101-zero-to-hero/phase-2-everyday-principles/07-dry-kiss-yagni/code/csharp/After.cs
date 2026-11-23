using Item = (string Name, int PriceCents, int Quantity);

namespace After;

public static class Totals
{
    private const int DiscountThresholdCents = 2500;
    private const int DiscountPercent = 10;

    public static int TotalCents(List<Item> items)
    {
        int total = 0;
        foreach (var item in items)
        {
            total += item.PriceCents * item.Quantity;
        }
        if (total > DiscountThresholdCents)
        {
            total -= total * DiscountPercent / 100;
        }
        return total;
    }
}
