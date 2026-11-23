const int total = 5000;
string[] customers = { "regular", "vip", "student", "employee" };

Console.WriteLine("--- before ---");
foreach (string customer in customers)
{
    Console.WriteLine($"{customer}: {Before.Discounts.DiscountedTotal(customer, total)}");
}

Console.WriteLine("--- after ---");
var rules = new Dictionary<string, After.IDiscountRule>
{
    ["regular"] = new After.NoDiscount(),
    ["vip"] = new After.PercentDiscount(20),
    ["student"] = new After.PercentDiscount(10),
    ["employee"] = new NewRules.FlatDiscount(500),
};
foreach (string customer in customers)
{
    Console.WriteLine($"{customer}: {After.Pricing.FinalTotal(rules[customer], total)}");
}
