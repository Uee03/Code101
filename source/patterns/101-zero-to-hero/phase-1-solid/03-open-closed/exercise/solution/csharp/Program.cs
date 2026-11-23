var rules = new Dictionary<string, IShippingRule>
{
    ["standard"] = new StandardShipping(),
    ["express"] = new ExpressShipping(),
};

foreach (string method in new[] { "standard", "express" })
{
    Console.WriteLine($"{method}: {rules[method].CostCents()}");
}

interface IShippingRule
{
    int CostCents();
}

class StandardShipping : IShippingRule
{
    public int CostCents()
    {
        return 400;
    }
}

class ExpressShipping : IShippingRule
{
    public int CostCents()
    {
        return 1200;
    }
}
