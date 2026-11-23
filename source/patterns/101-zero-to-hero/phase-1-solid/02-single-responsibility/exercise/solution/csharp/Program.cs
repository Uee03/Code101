var order = new Order("Ben", new List<int> { 500, 250, 125 });
string text = new ReceiptFormatter().Format(order);
new SmsSender().Send(order, text);

class Order
{
    public string Customer { get; }
    public List<int> Prices { get; }

    public Order(string customer, List<int> prices)
    {
        Customer = customer;
        Prices = prices;
    }

    public int Total()
    {
        return Prices.Sum();
    }
}

class ReceiptFormatter
{
    public string Format(Order order)
    {
        return $"Receipt for {order.Customer}: {order.Total()} cents";
    }
}

class SmsSender
{
    public void Send(Order order, string text)
    {
        Console.WriteLine($"SMS to {order.Customer}: {text}");
    }
}
