var shop = new ShopCatalog(new Dictionary<string, int> { ["mug"] = 800 });
var partner = new PartnerCatalog(new Dictionary<string, int> { ["mug"] = 750 });
ShowPrice(shop, "mug");
ShowPrice(partner, "mug");
shop.SetPrice("mug", 900);
ShowPrice(shop, "mug");

static void ShowPrice(IPriceReader catalog, string product)
{
    Console.WriteLine($"{product}: {catalog.GetPrice(product)}");
}

interface IPriceReader
{
    int GetPrice(string product);
}

interface IPriceWriter
{
    void SetPrice(string product, int cents);
}

class ShopCatalog : IPriceReader, IPriceWriter
{
    private readonly Dictionary<string, int> _prices;

    public ShopCatalog(Dictionary<string, int> prices)
    {
        _prices = prices;
    }

    public int GetPrice(string product)
    {
        return _prices[product];
    }

    public void SetPrice(string product, int cents)
    {
        _prices[product] = cents;
    }
}

class PartnerCatalog : IPriceReader
{
    private readonly Dictionary<string, int> _prices;

    public PartnerCatalog(Dictionary<string, int> prices)
    {
        _prices = prices;
    }

    public int GetPrice(string product)
    {
        return _prices[product];
    }
}
