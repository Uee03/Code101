namespace Before;

public interface INotifier
{
    string SendEmail(string to, string text);

    string SendSms(string to, string text);

    string SendPush(string to, string text);
}

public class EmailNotifier : INotifier
{
    public string SendEmail(string to, string text)
    {
        return $"Email to {to}: {text}";
    }

    public string SendSms(string to, string text)
    {
        return "";
    }

    public string SendPush(string to, string text)
    {
        return "";
    }
}

public class PhoneNotifier : INotifier
{
    public string SendEmail(string to, string text)
    {
        return "";
    }

    public string SendSms(string to, string text)
    {
        return $"SMS to {to}: {text}";
    }

    public string SendPush(string to, string text)
    {
        return $"Push to {to}: {text}";
    }
}

public static class Shipping
{
    public static string NotifyShipped(INotifier notifier, string address)
    {
        return notifier.SendEmail(address, "Order shipped");
    }
}
