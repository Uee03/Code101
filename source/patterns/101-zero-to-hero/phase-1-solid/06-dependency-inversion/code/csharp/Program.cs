Console.WriteLine("--- before ---");
new Before.OrderService().PlaceOrder("ana@example.com", "Notebook");

Console.WriteLine("--- after ---");
new After.OrderService(new After.SmtpEmailSender()).PlaceOrder("ana@example.com", "Notebook");
new After.OrderService(new After.SmsSender()).PlaceOrder("+100", "Notebook");

var fake = new After.FakeSender();
new After.OrderService(fake).PlaceOrder("test@example.com", "Notebook");
if (fake.Sent.Count == 1 && fake.Sent[0] == ("test@example.com", "Thanks for ordering Notebook"))
{
    Console.WriteLine("Check passed: the fake saw exactly one message");
}
else
{
    Console.WriteLine("Check FAILED");
}
