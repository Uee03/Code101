var laptop = new Product("laptop", 90000);
var mouse = new Product("mouse", 2500);
var cable = new Product("cable", 2000);
Console.WriteLine($"laptop: {laptop.Cents()}");
// TODO 2: make pack = new Bundle("starter pack") holding laptop and mouse, and print "starter pack: ..."
// TODO 3: make combo = new Bundle("combo") holding pack and cable, and print "combo: ..."

// TODO 1: write Bundle : IPriced. The constructor takes the name and creates an empty List<IPriced>.
//         Add(child) appends a child and returns this. Cents() returns the sum of the children's Cents().

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
