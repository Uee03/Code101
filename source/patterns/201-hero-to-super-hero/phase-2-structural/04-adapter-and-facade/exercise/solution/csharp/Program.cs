FinishBuild(new ConsoleNotifier());
FinishBuild(new SmsNotifier(new SmsClient(), "+100"));

static void FinishBuild(INotifier notifier) => notifier.Send("Build finished");

interface INotifier
{
    void Send(string message);
}

class ConsoleNotifier : INotifier
{
    public void Send(string message) => Console.WriteLine($"Console: {message}");
}

class SmsClient
{
    public void SendSms(string number, string text) => Console.WriteLine($"SMS to {number}: {text}");
}

class SmsNotifier : INotifier
{
    private readonly SmsClient _client;
    private readonly string _number;

    public SmsNotifier(SmsClient client, string number)
    {
        _client = client;
        _number = number;
    }

    public void Send(string message) => _client.SendSms(_number, message);
}
