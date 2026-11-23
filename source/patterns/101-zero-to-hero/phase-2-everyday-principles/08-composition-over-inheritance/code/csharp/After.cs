namespace After;

public interface IChannel
{
    string Deliver(string text);
}

public class EmailChannel : IChannel
{
    public string Deliver(string text)
    {
        return $"Email: {text}";
    }
}

public class SmsChannel : IChannel
{
    public string Deliver(string text)
    {
        return $"SMS: {text}";
    }
}

public class SlackChannel : IChannel
{
    public string Deliver(string text)
    {
        return $"Slack: {text}";
    }
}

public interface ITone
{
    string Decorate(string message);
}

public class PlainTone : ITone
{
    public string Decorate(string message)
    {
        return message;
    }
}

public class UrgentTone : ITone
{
    public string Decorate(string message)
    {
        return $"URGENT {message}";
    }
}

public class Notifier
{
    private readonly IChannel _channel;
    private readonly ITone _tone;

    public Notifier(IChannel channel, ITone tone)
    {
        _channel = channel;
        _tone = tone;
    }

    public string Send(string message)
    {
        return _channel.Deliver(_tone.Decorate(message));
    }
}
