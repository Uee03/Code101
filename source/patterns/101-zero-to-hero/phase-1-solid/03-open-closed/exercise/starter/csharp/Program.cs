foreach (string method in new[] { "standard", "express" })
{
    Console.WriteLine($"{method}: {ShippingCents(method)}");
}

// TODO 1: make an interface IShippingRule with a method int CostCents().
// TODO 2: make classes StandardShipping (400 cents) and ExpressShipping (1200 cents) that implement it.
// TODO 3: put one object of each in a Dictionary<string, IShippingRule> named rules, keyed "standard" and "express".
//         Then print the costs with rules[method].CostCents() and delete ShippingCents.

static int ShippingCents(string method)
{
    if (method == "standard")
    {
        return 400;
    }
    if (method == "express")
    {
        return 1200;
    }
    return 0;
}
