public class Counter
{
    private int count;
    public string Name { get; }
    public int Count => count;

    public Counter(string name, int startingCount)
    {
        Name = name;
        count = startingCount;
    }

    public void Add(int amount)
    {
        if (amount > 0)
        {
            count = count + amount;
        }
    }
}
