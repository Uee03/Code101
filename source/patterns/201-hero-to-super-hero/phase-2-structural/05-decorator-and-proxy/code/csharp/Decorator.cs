namespace DecoratorDemo;

public interface ISink
{
    void Write(string text);
}

public class ConsoleSink : ISink
{
    public void Write(string text) => Console.WriteLine(text);
}

public abstract class SinkDecorator : ISink
{
    protected readonly ISink Inner;

    protected SinkDecorator(ISink inner)
    {
        Inner = inner;
    }

    public abstract void Write(string text);
}

public class UpperSink : SinkDecorator
{
    public UpperSink(ISink inner) : base(inner)
    {
    }

    public override void Write(string text) => Inner.Write(text.ToUpperInvariant());
}

public class PrefixSink : SinkDecorator
{
    private readonly string _prefix;

    public PrefixSink(ISink inner, string prefix) : base(inner)
    {
        _prefix = prefix;
    }

    public override void Write(string text) => Inner.Write(_prefix + text);
}

public class CountingSink : SinkDecorator
{
    public int Count { get; private set; }

    public CountingSink(ISink inner) : base(inner)
    {
    }

    public override void Write(string text)
    {
        Count++;
        Inner.Write(text);
    }
}

public static class Demo
{
    public static void Run()
    {
        var console = new ConsoleSink();
        ISink a = new UpperSink(new PrefixSink(console, "[app] "));
        ISink b = new PrefixSink(new UpperSink(console), "[app] ");
        a.Write("hello");
        b.Write("hello");
        var counted = new CountingSink(console);
        counted.Write("one");
        counted.Write("two");
        Console.WriteLine($"writes counted: {counted.Count}");
    }
}
