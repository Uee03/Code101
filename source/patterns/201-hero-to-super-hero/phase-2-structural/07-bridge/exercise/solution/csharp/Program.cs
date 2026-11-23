new Message(new EmailChannel(), "Hello").Send();
new ReminderMessage(new PushChannel(), "Pay rent").Send();
new ReminderMessage(new EmailChannel(), "Pay rent").Send();

interface IChannel
{
    void Deliver(string text);
}

class EmailChannel : IChannel
{
    public void Deliver(string text) => Console.WriteLine($"Email: {text}");
}

class PushChannel : IChannel
{
    public void Deliver(string text) => Console.WriteLine($"Push: {text}");
}

class Message
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

class ReminderMessage : Message
{
    public ReminderMessage(IChannel channel, string body) : base(channel, body)
    {
    }

    public override void Send() => Channel.Deliver($"Reminder: {Body}");
}
