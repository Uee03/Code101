Console.WriteLine("--- before ---");
var oldPayments = new List<Before.PaymentMethod> { new Before.CardPayment(), new Before.GiftCardPayment() };
foreach (var payment in oldPayments)
{
    try
    {
        Console.WriteLine(Before.Orders.CancelOrder(payment, 1500));
    }
    catch (NotSupportedException error)
    {
        Console.WriteLine($"Crash: {error.Message}");
    }
}

Console.WriteLine("--- after ---");
var card = new After.CardPayment();
var gift = new After.GiftCardPayment();
var payables = new List<After.IPayable> { card, gift };
foreach (var payable in payables)
{
    Console.WriteLine(payable.Pay(1500));
}
Console.WriteLine(After.Orders.CancelOrder(card, 1500));
// After.Orders.CancelOrder(gift, 1500);  // the compiler refuses this line
