Console.WriteLine("--- before ---");
var oldNotifiers = new List<Before.INotifier> { new Before.EmailNotifier(), new Before.PhoneNotifier() };
foreach (var notifier in oldNotifiers)
{
    string result = Before.Shipping.NotifyShipped(notifier, "ana@example.com");
    Console.WriteLine($"Result: '{result}'");
}

Console.WriteLine("--- after ---");
var email = new After.EmailNotifier();
var phone = new After.PhoneNotifier();
Console.WriteLine(After.Shipping.NotifyShipped(email, "ana@example.com"));
Console.WriteLine(phone.SendSms("+100", "Order shipped"));
Console.WriteLine(phone.SendPush("ana-phone", "Order shipped"));
// After.Shipping.NotifyShipped(phone, "ana@example.com");  // the compiler refuses this line
