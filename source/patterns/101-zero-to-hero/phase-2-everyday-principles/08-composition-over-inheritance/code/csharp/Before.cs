namespace Before;

public abstract class Notifier
{
    public abstract string Send(string message);
}

public class EmailNotifier : Notifier
{
    public override string Send(string message)
    {
        return $"Email: {message}";
    }
}

public class UrgentEmailNotifier : EmailNotifier
{
    public override string Send(string message)
    {
        return base.Send($"URGENT {message}");
    }
}

public class SmsNotifier : Notifier
{
    public override string Send(string message)
    {
        return $"SMS: {message}";
    }
}

public class UrgentSmsNotifier : SmsNotifier
{
    public override string Send(string message)
    {
        return base.Send($"URGENT {message}");
    }
}
