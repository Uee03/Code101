var order = new Order("Ben", new List<int> { 500, 250, 125 });
order.SendConfirmation();

// TODO 1: make a class ReceiptFormatter with Format(Order order) that returns the receipt text.
// TODO 2: make a class SmsSender with Send(Order order, string text) that prints the SMS line.
// TODO 3: remove ReceiptText and SendConfirmation from Order, then change the two lines at the
//         top so the formatter and the sender do those jobs. The output must not change.

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

    public string ReceiptText()
    {
        return $"Receipt for {Customer}: {Total()} cents";
    }

    public void SendConfirmation()
    {
        Console.WriteLine($"SMS to {Customer}: {ReceiptText()}");
    }
}
