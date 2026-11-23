namespace BridgeDemo;

public interface IChannel
{
    void Deliver(string text);
}

public class EmailChannel : IChannel
{
    public void Deliver(string text) => Console.WriteLine($"Email: {text}");
}

public class SmsChannel : IChannel
{
    public void Deliver(string text) => Console.WriteLine($"SMS: {text}");
}

public class Message
{
    protected readonly IChannel Channel;
    protected readonly string Body;

    public Message(IChannel channel, string body)
    {
        Channel = channel;
        Body = body;
    }

    public virtual void Send() => Channel.Deliver(Body);
}

public class UrgentMessage : Message
{
    public UrgentMessage(IChannel channel, string body) : base(channel, body)
    {
    }

    public override void Send() => Channel.Deliver($"URGENT: {Body}");
}

public static class Demo
{
    public static void Run()
    {
        var channels = new IChannel[] { new EmailChannel(), new SmsChannel() };
        foreach (var channel in channels)
        {
            new Message(channel, "Meeting at 10").Send();
            new UrgentMessage(channel, "Server down").Send();
        }
    }
}
