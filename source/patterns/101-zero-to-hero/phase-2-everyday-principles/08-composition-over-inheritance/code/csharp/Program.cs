Console.WriteLine("--- before: 2 channels ---");
var oldNotifiers = new List<Before.Notifier>
{
    new Before.EmailNotifier(),
    new Before.UrgentEmailNotifier(),
    new Before.SmsNotifier(),
    new Before.UrgentSmsNotifier(),
};
foreach (var notifier in oldNotifiers)
{
    Console.WriteLine(notifier.Send("Server down"));
}

Console.WriteLine("--- after: 3 channels ---");
var channels = new List<After.IChannel> { new After.EmailChannel(), new After.SmsChannel(), new After.SlackChannel() };
var tones = new List<After.ITone> { new After.PlainTone(), new After.UrgentTone() };
foreach (var channel in channels)
{
    foreach (var tone in tones)
    {
        Console.WriteLine(new After.Notifier(channel, tone).Send("Server down"));
    }
}
