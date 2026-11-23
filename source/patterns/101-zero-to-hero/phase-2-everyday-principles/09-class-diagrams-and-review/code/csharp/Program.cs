using Item = (string Name, int PriceCents, int Quantity);

var items = new List<Item> { ("Notebook", 1200, 2), ("Pen", 150, 4) };

Console.WriteLine("--- before ---");
var oldProcessor = new Before.OrderProcessor();
oldProcessor.Process("vip", "email", "ana@example.com", items);
oldProcessor.Process("student", "sms", "+100", items);
oldProcessor.Process("regular", "email", "bo@example.com", items);

Console.WriteLine("--- after ---");
var store = new After.OrderStore();
var vipByEmail = new After.OrderProcessor(new After.PercentDiscount(20), new After.EmailNotifier(), store);
var studentBySms = new After.OrderProcessor(new After.PercentDiscount(10), new After.SmsNotifier(), store);
var regularByEmail = new After.OrderProcessor(new After.NoDiscount(), new After.EmailNotifier(), store);
vipByEmail.Process("ana@example.com", items);
studentBySms.Process("+100", items);
regularByEmail.Process("bo@example.com", items);
Console.WriteLine($"Stored orders: {store.Count}");
