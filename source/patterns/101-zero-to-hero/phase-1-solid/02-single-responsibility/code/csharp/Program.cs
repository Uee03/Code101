using Item = (string Name, int PriceCents, int Quantity);

var items = new List<Item> { ("Notebook", 1200, 2), ("Pen", 150, 4) };

Console.WriteLine("--- before ---");
var database = new List<string>();
var oldInvoice = new Before.Invoice(1, "ana@example.com", items);
Console.WriteLine(oldInvoice.ToText());
oldInvoice.Save(database);
oldInvoice.SendEmail();
Console.WriteLine($"Stored invoices: {database.Count}");

Console.WriteLine("--- after ---");
var formatter = new After.InvoiceTextFormatter();
var store = new After.InvoiceStore();
var sender = new After.EmailSender();
var invoice = new After.Invoice(1, "ana@example.com", items);
Console.WriteLine(formatter.Format(invoice));
store.Save(invoice);
sender.SendInvoice(invoice);
Console.WriteLine($"Stored invoices: {store.Count}");
