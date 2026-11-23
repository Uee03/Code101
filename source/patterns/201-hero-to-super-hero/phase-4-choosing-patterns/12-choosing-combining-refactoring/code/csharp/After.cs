namespace After;

public record Order(List<Item> Items, string Shipping, string? Coupon, string Email);

public interface IDiscount
{
    int Amount(int subtotal);
}

public class NoDiscount : IDiscount
{
    public int Amount(int subtotal) => 0;
}

public class PercentOff : IDiscount
{
    private readonly int _percent;

    public PercentOff(int percent)
    {
        _percent = percent;
    }

    public int Amount(int subtotal) => subtotal * _percent / 100;
}

public class FlatOff : IDiscount
{
    private readonly int _cents;

    public FlatOff(int cents)
    {
        _cents = cents;
    }

    public int Amount(int subtotal) => Math.Min(_cents, subtotal);
}

public interface IShippingOption
{
    int Cost();
}

public class FlatShipping : IShippingOption
{
    private readonly int _cents;

    public FlatShipping(int cents)
    {
        _cents = cents;
    }

    public int Cost() => _cents;
}

public static class Catalog
{
    public static readonly Dictionary<string, IDiscount> Discounts = new()
    {
        ["WELCOME10"] = new PercentOff(10),
        ["FIVEOFF"] = new FlatOff(500),
    };

    public static readonly Dictionary<string, IShippingOption> Shipping = new()
    {
        ["pickup"] = new FlatShipping(0),
        ["standard"] = new FlatShipping(500),
        ["express"] = new FlatShipping(1500),
    };
}

public abstract class Rule
{
    private Rule? _next;

    public Rule SetNext(Rule rule)
    {
        _next = rule;
        return rule;
    }

    public string? Check(Order order)
    {
        string? problem = Problem(order);
        if (problem != null)
        {
            return problem;
        }
        if (_next != null)
        {
            return _next.Check(order);
        }
        return null;
    }

    protected abstract string? Problem(Order order);
}

public class NotEmpty : Rule
{
    protected override string? Problem(Order order) => order.Items.Count == 0 ? "cart is empty" : null;
}

public class PositiveQuantities : Rule
{
    protected override string? Problem(Order order)
    {
        foreach (var item in order.Items)
        {
            if (item.Quantity <= 0)
            {
                return $"bad quantity for {item.Name}";
            }
        }
        return null;
    }
}

public class KnownShipping : Rule
{
    protected override string? Problem(Order order) =>
        Catalog.Shipping.ContainsKey(order.Shipping) ? null : $"unknown shipping {order.Shipping}";
}

public interface IListener
{
    string OrderPlaced(string email, int total);
}

public class EmailNotice : IListener
{
    public string OrderPlaced(string email, int total) => $"email to {email}: order total {total}";
}

public class AuditLog : IListener
{
    public string OrderPlaced(string email, int total) => "log: order placed";
}

public class Checkout
{
    private readonly Rule _rules;
    private readonly List<IListener> _listeners;

    public Checkout(Rule rules, List<IListener> listeners)
    {
        _rules = rules;
        _listeners = listeners;
    }

    public List<string> Place(Order order)
    {
        string? problem = _rules.Check(order);
        if (problem != null)
        {
            return new List<string> { $"error: {problem}" };
        }
        int subtotal = order.Items.Sum(item => item.Price * item.Quantity);
        if (!Catalog.Discounts.TryGetValue(order.Coupon ?? "", out IDiscount? discountRule))
        {
            discountRule = new NoDiscount();
        }
        int discount = discountRule.Amount(subtotal);
        int shipping = Catalog.Shipping[order.Shipping].Cost();
        int taxable = subtotal - discount;
        int tax = taxable * 20 / 100;
        int total = taxable + tax + shipping;
        var lines = new List<string>
        {
            $"subtotal: {subtotal}",
            $"discount: {discount}",
            $"shipping: {shipping}",
            $"tax: {tax}",
            $"total: {total}",
        };
        foreach (var listener in _listeners)
        {
            lines.Add(listener.OrderPlaced(order.Email, total));
        }
        return lines;
    }
}

public static class Shop
{
    public static List<string> PlaceOrder(List<Item> items, string shipping, string? coupon, string email)
    {
        var rules = new NotEmpty();
        rules.SetNext(new PositiveQuantities()).SetNext(new KnownShipping());
        var checkout = new Checkout(rules, new List<IListener> { new EmailNotice(), new AuditLog() });
        return checkout.Place(new Order(items, shipping, coupon, email));
    }
}
