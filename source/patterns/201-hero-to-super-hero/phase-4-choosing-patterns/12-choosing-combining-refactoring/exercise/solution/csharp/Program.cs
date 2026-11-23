string[] kinds = { "regular", "child", "senior", "student" };
var pricing = new Dictionary<string, IPricing>
{
    ["regular"] = new Regular(),
    ["child"] = new Child(),
    ["senior"] = new Senior(),
    ["student"] = new Student(),
};

int TicketPrice(string kind, int baseCents) => pricing[kind].Price(baseCents);

foreach (var kind in kinds)
{
    Console.WriteLine($"{kind}: {TicketPrice(kind, 1000)}");
}
if (kinds.All(kind => TicketPrice(kind, 1000) == OldTicketPrice(kind, 1000)))
{
    Console.WriteLine("Check passed: new pricing equals old pricing");
}
else
{
    Console.WriteLine("Check FAILED");
}

static int OldTicketPrice(string kind, int baseCents)
{
    if (kind == "child")
    {
        return baseCents / 2;
    }
    else if (kind == "senior")
    {
        return baseCents * 70 / 100;
    }
    else if (kind == "student")
    {
        return baseCents - 250;
    }
    return baseCents;
}

interface IPricing
{
    int Price(int baseCents);
}

class Regular : IPricing
{
    public int Price(int baseCents) => baseCents;
}

class Child : IPricing
{
    public int Price(int baseCents) => baseCents / 2;
}

class Senior : IPricing
{
    public int Price(int baseCents) => baseCents * 70 / 100;
}

class Student : IPricing
{
    public int Price(int baseCents) => baseCents - 250;
}
