using Item = (string Name, int PriceCents, int Quantity);

namespace Before;

public static class Totals
{
    public static int InvoiceTotal(List<Item> items, string currency = "EUR", string rounding = "HALF_UP")
    {
        int total = items.Aggregate(0, (acc, item) => acc + item.PriceCents * item.Quantity);
        return total > 2500 ? total - total * 10 / 100 : total;
    }

    public static int ReceiptTotal(List<Item> items)
    {
        int total = 0;
        foreach (var item in items)
        {
            total += item.PriceCents * item.Quantity;
        }
        if (total > 2500)
        {
            total = total - total * 10 / 100;
        }
        return total;
    }

    public static string ExportInvoiceToXml(List<Item> items)
    {
        return "<invoice/>";
    }
}
