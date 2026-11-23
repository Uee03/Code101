FinishBuild(new ConsoleNotifier());
// TODO 2: call FinishBuild with new SmsNotifier(new SmsClient(), "+100")

static void FinishBuild(INotifier notifier) => notifier.Send("Build finished");

// TODO 1: write SmsNotifier : INotifier. Its constructor receives an SmsClient and a phone number.
//         Its Send(message) calls SendSms(number, message) on the client.

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
