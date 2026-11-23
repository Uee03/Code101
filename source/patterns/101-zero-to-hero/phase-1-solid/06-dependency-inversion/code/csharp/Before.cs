namespace Before;

public class SmtpEmailSender
{
    public void Send(string to, string text)
    {
        Console.WriteLine($"SMTP email to {to}: {text}");
    }
}

public class OrderService
{
    private readonly SmtpEmailSender _sender = new SmtpEmailSender();

    public void PlaceOrder(string customer, string item)
    {
        _sender.Send(customer, $"Thanks for ordering {item}");
    }
}
