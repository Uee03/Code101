string[] kinds = { "regular", "child", "senior", "student" };
// TODO 4: for each kind print "<kind>: <TicketPrice(kind, 1000)>". Then print
//         "Check passed: new pricing equals old pricing" if every kind gives the same result as OldTicketPrice,
//         otherwise print "Check FAILED".

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

// TODO 1: write an interface IPricing with int Price(int baseCents).
//         Then write Regular, Child, Senior and Student, each returning the same value as its branch above.
// TODO 2: make a Dictionary<string, IPricing> named pricing from the kind name to a pricing object.
// TODO 3: write TicketPrice(string kind, int baseCents) that looks the kind up in the dictionary (no if chain).
