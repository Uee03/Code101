namespace Before;

public static class Discounts
{
    public static int DiscountedTotal(string customerType, int totalCents)
    {
        if (customerType == "regular")
        {
            return totalCents;
        }
        else if (customerType == "vip")
        {
            return totalCents - totalCents * 20 / 100;
        }
        else if (customerType == "student")
        {
            return totalCents - totalCents * 10 / 100;
        }
        return totalCents;
    }
}
