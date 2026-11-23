using Item = (string Name, int PriceCents, int Quantity);

var items = new List<Item> { ("Notebook", 1200, 2), ("Pen", 150, 4) };

Console.WriteLine("--- before ---");
Console.WriteLine($"Invoice: {Before.Totals.InvoiceTotal(items)}");
Console.WriteLine($"Receipt: {Before.Totals.ReceiptTotal(items)}");

Console.WriteLine("--- after ---");
Console.WriteLine($"Invoice: {After.Totals.TotalCents(items)}");
Console.WriteLine($"Receipt: {After.Totals.TotalCents(items)}");

Console.WriteLine("--- lookalikes ---");
Console.WriteLine("Username 'al': " + Describe(Lookalikes.Validation.UsernameProblem("al")));
Console.WriteLine("Title with 30 letters: " + Describe(Lookalikes.Validation.ProductTitleProblem(new string('x', 30))));

static string Describe(string problem)
{
    if (problem == "")
    {
        return "ok";
    }
    return problem;
}
