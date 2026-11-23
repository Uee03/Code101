namespace SingletonDemo;

public sealed class Settings
{
    private static readonly Lazy<Settings> LazyInstance = new(() => new Settings());

    private Settings()
    {
    }

    public static Settings Instance => LazyInstance.Value;

    public int TaxPercent { get; set; } = 20;
}

public static class Demo
{
    public static int TotalWithTax(int netCents) => netCents + netCents * Settings.Instance.TaxPercent / 100;

    public static void Run()
    {
        Settings first = Settings.Instance;
        Settings second = Settings.Instance;
        Console.WriteLine($"same instance: {object.ReferenceEquals(first, second)}");
        Console.WriteLine($"total: {TotalWithTax(1000)}");
        first.TaxPercent = 0;
        Console.WriteLine($"total after a change elsewhere: {TotalWithTax(1000)}");
    }
}
