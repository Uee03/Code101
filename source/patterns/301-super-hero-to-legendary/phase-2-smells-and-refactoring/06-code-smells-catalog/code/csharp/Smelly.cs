namespace SmellyCode;

public record Item(string Name, int Price, int Qty);

public record Order(int Id, int Amount);

public class InvoiceMaker
{
    public string MakeInvoice(string name, string email, string street, string city, string zipCode, List<Item> items, string coupon, string country, bool express)
    {
        var total = 0;
        foreach (var item in items)
        {
            total += item.Price * item.Qty;
        }
        if (coupon == "SAVE10")
        {
            total -= total / 10;
        }
        else if (coupon == "SAVE20")
        {
            total -= total / 5;
        }
        if (country == "DE")
        {
            total += total * 19 / 100;
        }
        else if (country == "FR")
        {
            total += total * 20 / 100;
        }
        if (express)
        {
            if (country == "US")
            {
                if (total > 10000)
                {
                    total += 0;
                }
                else
                {
                    total += 2500;
                }
            }
            else
            {
                total += 4000;
            }
        }
        var address = $"{street}, {zipCode} {city}";
        return $"Invoice for {name} <{email}>\n{address}\nTotal: {total}";
    }

    public string Label(int orderId, int amount)
    {
        return $"#{orderId}: {amount}";
    }
}

public class OrderManager
{
    private readonly List<Order> _orders = new();

    public void Add(Order order)
    {
        _orders.Add(order);
    }

    public int Total()
    {
        return _orders.Sum(o => o.Amount);
    }

    public string ToCsv()
    {
        return string.Join("\n", _orders.Select(o => $"{o.Id},{o.Amount}"));
    }

    public string SendEmail(string address)
    {
        return $"mailed {_orders.Count} orders to {address}";
    }

    public string PrintReport()
    {
        return $"{_orders.Count} orders, total {Total()}";
    }

    public void ApplyTax(int rate)
    {
        for (var i = 0; i < _orders.Count; i++)
        {
            _orders[i] = _orders[i] with { Amount = _orders[i].Amount + _orders[i].Amount * rate / 100 };
        }
    }
}
