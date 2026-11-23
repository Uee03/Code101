namespace PrototypeDemo;

public class Unit
{
    public string Name { get; set; }
    public int Hp { get; }
    public List<string> Items { get; }

    public Unit(string name, int hp, List<string> items)
    {
        Name = name;
        Hp = hp;
        Items = items;
    }

    public Unit Clone() => new Unit(Name, Hp, new List<string>(Items));

    public Unit ShallowCopy() => (Unit)MemberwiseClone();

    public string Describe() => $"{Name} hp={Hp} items={string.Join(", ", Items)}";
}

public static class Demo
{
    public static void Run()
    {
        var archer = new Unit("archer", 30, new List<string> { "bow" });
        var registry = new Dictionary<string, Unit> { ["archer"] = archer };

        Unit scout = registry["archer"].Clone();
        scout.Name = "scout";
        scout.Items.Add("map");
        Console.WriteLine(archer.Describe());
        Console.WriteLine(scout.Describe());

        Unit shallow = archer.ShallowCopy();
        shallow.Items.Add("torch");
        Console.WriteLine(archer.Describe());
    }
}
