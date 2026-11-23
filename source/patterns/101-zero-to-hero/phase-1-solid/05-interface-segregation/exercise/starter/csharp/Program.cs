var shop = new ShopCatalog(new Dictionary<string, int> { ["mug"] = 800 });
var partner = new PartnerCatalog(new Dictionary<string, int> { ["mug"] = 750 });
ShowPrice(shop, "mug");
ShowPrice(partner, "mug");
shop.SetPrice("mug", 900);
ShowPrice(shop, "mug");
partner.SetPrice("mug", 1);
ShowPrice(partner, "mug");

// TODO 1: split ICatalog into two small interfaces: IPriceReader (GetPrice) and IPriceWriter (SetPrice).
// TODO 2: ShopCatalog implements both. PartnerCatalog implements only IPriceReader and loses its empty SetPrice.
// TODO 3: ShowPrice asks for an IPriceReader.
// TODO 4: delete the two lines that call partner.SetPrice and the ShowPrice after it.
//         The compiler would refuse them now, which is the point.

static void ShowPrice(ICatalog catalog, string product)
{
    Console.WriteLine($"{product}: {catalog.GetPrice(product)}");
}

interface ICatalog
{
    int GetPrice(string product);

    void SetPrice(string product, int cents);
}

class ShopCatalog : ICatalog
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

class PartnerCatalog : ICatalog
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

    public void SetPrice(string product, int cents)
    {
    }
}
