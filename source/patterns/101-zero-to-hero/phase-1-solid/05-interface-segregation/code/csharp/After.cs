namespace After;

public interface IEmailSender
{
    string SendEmail(string to, string text);
}

public interface ISmsSender
{
    string SendSms(string to, string text);
}

public interface IPushSender
{
    string SendPush(string to, string text);
}

public class EmailNotifier : IEmailSender
{
    public string SendEmail(string to, string text)
    {
        return $"Email to {to}: {text}";
    }
}

public class PhoneNotifier : ISmsSender, IPushSender
{
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
    public static string NotifyShipped(IEmailSender sender, string address)
    {
        return sender.SendEmail(address, "Order shipped");
    }
}
