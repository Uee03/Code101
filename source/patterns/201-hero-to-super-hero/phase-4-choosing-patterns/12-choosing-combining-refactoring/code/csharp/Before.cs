namespace Before;

public static class Shop
{
    public static List<string> Checkout(List<Item> items, string shipping, string? coupon, string email)
    {
        var lines = new List<string>();
        if (items.Count == 0)
        {
            return new List<string> { "error: cart is empty" };
        }
        foreach (var item in items)
        {
            if (item.Quantity <= 0)
            {
                return new List<string> { $"error: bad quantity for {item.Name}" };
            }
        }
        int subtotal = 0;
        foreach (var item in items)
        {
            subtotal += item.Price * item.Quantity;
        }
        lines.Add($"subtotal: {subtotal}");
        int discount = 0;
        if (coupon == "WELCOME10")
        {
            discount = subtotal * 10 / 100;
        }
        else if (coupon == "FIVEOFF")
        {
            discount = Math.Min(500, subtotal);
        }
        lines.Add($"discount: {discount}");
        int ship;
        if (shipping == "pickup")
        {
            ship = 0;
        }
        else if (shipping == "standard")
        {
            ship = 500;
        }
        else if (shipping == "express")
        {
            ship = 1500;
        }
        else
        {
            return new List<string> { $"error: unknown shipping {shipping}" };
        }
        lines.Add($"shipping: {ship}");
        int taxable = subtotal - discount;
        int tax = taxable * 20 / 100;
        lines.Add($"tax: {tax}");
        int total = taxable + tax + ship;
        lines.Add($"total: {total}");
        lines.Add($"email to {email}: order total {total}");
        lines.Add("log: order placed");
        return lines;
    }
}
