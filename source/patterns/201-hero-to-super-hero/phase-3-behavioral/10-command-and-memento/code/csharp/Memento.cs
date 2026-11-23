namespace MementoDemo;

public record Snapshot(int Hp, int Gold, IReadOnlyList<string> Items);

public class Player
{
    public Player(int hp, int gold, List<string> items)
    {
        Hp = hp;
        Gold = gold;
        Items = items;
    }

    public int Hp { get; set; }

    public int Gold { get; set; }

    public List<string> Items { get; private set; }

    public Snapshot Save() => new Snapshot(Hp, Gold, Items.ToArray());

    public void Restore(Snapshot snapshot)
    {
        Hp = snapshot.Hp;
        Gold = snapshot.Gold;
        Items = new List<string>(snapshot.Items);
    }

    public string Describe() => $"hp={Hp} gold={Gold} items={string.Join(", ", Items)}";
}

public static class Demo
{
    public static void Run()
    {
        var player = new Player(100, 0, new List<string> { "sword" });
        var saved = new Stack<Snapshot>();
        saved.Push(player.Save());
        player.Hp = 70;
        player.Items.Add("map");
        saved.Push(player.Save());
        player.Hp = 10;
        player.Gold = 25;
        Console.WriteLine(player.Describe());
        player.Restore(saved.Pop());
        Console.WriteLine(player.Describe());
        player.Restore(saved.Pop());
        Console.WriteLine(player.Describe());
    }
}
