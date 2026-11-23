namespace After;

public interface IMessageSender
{
    void Send(string to, string text);
}

public class SmtpEmailSender : IMessageSender
{
    public void Send(string to, string text)
    {
        Console.WriteLine($"SMTP email to {to}: {text}");
    }
}

public class SmsSender : IMessageSender
{
    public void Send(string to, string text)
    {
        Console.WriteLine($"SMS to {to}: {text}");
    }
}

public class FakeSender : IMessageSender
{
    public List<(string To, string Text)> Sent { get; } = new();

    public void Send(string to, string text)
    {
        Sent.Add((to, text));
    }
}

public class OrderService
{
    private readonly IMessageSender _sender;

    public OrderService(IMessageSender sender)
    {
        _sender = sender;
    }

    public void PlaceOrder(string customer, string item)
    {
        _sender.Send(customer, $"Thanks for ordering {item}");
    }
}
