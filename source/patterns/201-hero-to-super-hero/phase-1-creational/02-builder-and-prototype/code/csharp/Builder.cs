namespace BuilderDemo;

public record Computer(string Cpu, int RamGb, int StorageGb, string? Gpu)
{
    public string Describe()
    {
        string gpu = Gpu ?? "no GPU";
        return $"{Cpu}, {RamGb} GB RAM, {StorageGb} GB storage, {gpu}";
    }
}

public class ComputerBuilder
{
    private string _cpu = "basic CPU";
    private int _ramGb = 8;
    private int _storageGb = 256;
    private string? _gpu;

    public ComputerBuilder WithCpu(string cpu)
    {
        _cpu = cpu;
        return this;
    }

    public ComputerBuilder WithRam(int ramGb)
    {
        _ramGb = ramGb;
        return this;
    }

    public ComputerBuilder WithStorage(int storageGb)
    {
        _storageGb = storageGb;
        return this;
    }

    public ComputerBuilder WithGpu(string gpu)
    {
        _gpu = gpu;
        return this;
    }

    public Computer Build()
    {
        if (_ramGb < 4)
        {
            throw new InvalidOperationException("at least 4 GB RAM is required");
        }
        return new Computer(_cpu, _ramGb, _storageGb, _gpu);
    }
}

public static class Director
{
    public static Computer OfficePc(ComputerBuilder builder) => builder.WithRam(16).Build();

    public static Computer GamingPc(ComputerBuilder builder) =>
        builder.WithCpu("fast CPU").WithRam(32).WithStorage(2000).WithGpu("big GPU").Build();
}

public static class Demo
{
    public static void Run()
    {
        Console.WriteLine($"office: {Director.OfficePc(new ComputerBuilder()).Describe()}");
        Console.WriteLine($"gaming: {Director.GamingPc(new ComputerBuilder()).Describe()}");
        try
        {
            new ComputerBuilder().WithRam(2).Build();
        }
        catch (InvalidOperationException error)
        {
            Console.WriteLine($"Rejected: {error.Message}");
        }
    }
}
