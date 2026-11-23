var manager = new BookingManager();
manager.Book("adult", "email", "ana@example.com", 2);
manager.Book("child", "sms", "+100", 3);

// Mixed review. The class below breaks several principles from this track.
// TODO 1: write down which smells you see (which of S, O, D, and which of DRY, KISS, YAGNI).
// TODO 2: make an interface IPriceRule with SeatCents(), and AdultPrice (1000) and ChildPrice (500).
// TODO 3: make an interface INotifier with Notify(string address, string text), and EmailNotifier and SmsNotifier.
// TODO 4: make a class BookingStore whose Save(string address) prints "Booking saved for <address>".
// TODO 5: change BookingManager so its constructor receives an IPriceRule, an INotifier and a BookingStore,
//         and Book(string address, int seats) uses them. Wire the objects together at the top. The output must not change.
// TODO 6: draw the result as a Mermaid class diagram in a file diagram.md.

class BookingManager
{
    public void Book(string ticketKind, string channel, string address, int seats)
    {
        int price;
        if (ticketKind == "adult")
        {
            price = 1000;
        }
        else if (ticketKind == "child")
        {
            price = 500;
        }
        else
        {
            price = 1000;
        }
        int total = price * seats;
        if (channel == "email")
        {
            Console.WriteLine($"Email to {address}: booking for {seats} seat(s), total {total}");
        }
        else if (channel == "sms")
        {
            Console.WriteLine($"SMS to {address}: booking for {seats} seat(s), total {total}");
        }
        Console.WriteLine($"Booking saved for {address}");
    }
}
