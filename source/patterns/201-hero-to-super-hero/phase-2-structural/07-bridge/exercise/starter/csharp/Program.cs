new Message(new EmailChannel(), "Hello").Send();
// TODO 3: send new ReminderMessage(new PushChannel(), "Pay rent") and then new ReminderMessage(new EmailChannel(), "Pay rent")

// TODO 1: write PushChannel : IChannel whose Deliver prints "Push: " followed by the text.
// TODO 2: write ReminderMessage : Message whose Send delivers "Reminder: " followed by the body.

interface IChannel
{
    void Deliver(string text);
}

class EmailChannel : IChannel
{
    public void Deliver(string text) => Console.WriteLine($"Email: {text}");
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
