var stamper = new InvoiceStamper();
Console.WriteLine(stamper.Stamp(7));

// TODO 1: make an interface IClock with a method DateOnly Today().
// TODO 2: make SystemClock (Today() returns DateOnly.FromDateTime(DateTime.Now)) and FixedClock
//         (its constructor receives a DateOnly and Today() returns it).
// TODO 3: give InvoiceStamper a constructor that receives an IClock and use _clock.Today() in Stamp.
// TODO 4: change the first line so the stamper is created with new FixedClock(new DateOnly(2026, 1, 15)).

class InvoiceStamper
{
    public string Stamp(int number)
    {
        DateOnly today = DateOnly.FromDateTime(DateTime.Now);
        return $"Invoice {number} issued {today:yyyy-MM-dd}";
    }
}
