var laptop = new Product("laptop", 90000);
var mouse = new Product("mouse", 2500);
var cable = new Product("cable", 2000);
Console.WriteLine($"laptop: {laptop.Cents()}");
var pack = new Bundle("starter pack").Add(laptop).Add(mouse);
Console.WriteLine($"starter pack: {pack.Cents()}");
var combo = new Bundle("combo").Add(pack).Add(cable);
Console.WriteLine($"combo: {combo.Cents()}");

interface IPriced
{
    int Cents();
}

class Product : IPriced
{
    private readonly int _amount;

    public Product(string name, int amount)
    {
        Name = name;
        _amount = amount;
    }

    public string Name { get; }

    public int Cents() => _amount;
}

class Bundle : IPriced
{
    private readonly List<IPriced> _children = new();

    public Bundle(string name)
    {
        Name = name;
    }

    public string Name { get; }

    public Bundle Add(IPriced child)
    {
        _children.Add(child);
        return this;
    }

    public int Cents() => _children.Sum(child => child.Cents());
}
