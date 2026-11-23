using Microsoft.Extensions.Options;

public sealed class InstanceCounter
{
    private int _singleton;
    private int _scoped;
    private int _transient;

    public int Singleton => _singleton;

    public int Scoped => _scoped;

    public int Transient => _transient;

    public void CountSingleton() => Interlocked.Increment(ref _singleton);

    public void CountScoped() => Interlocked.Increment(ref _scoped);

    public void CountTransient() => Interlocked.Increment(ref _transient);
}

public sealed class SingletonService
{
    public SingletonService(InstanceCounter counter) => counter.CountSingleton();
}

public sealed class ScopedService
{
    public ScopedService(InstanceCounter counter) => counter.CountScoped();
}

public sealed class TransientService
{
    public TransientService(InstanceCounter counter) => counter.CountTransient();
}

public sealed class LifetimeProbe(SingletonService singleton, ScopedService scoped, TransientService transient)
{
    public SingletonService Singleton { get; } = singleton;

    public ScopedService Scoped { get; } = scoped;

    public TransientService Transient { get; } = transient;
}

public interface ITitleFormatter
{
    string Format(string title);
}

public sealed class UpperTitleFormatter : ITitleFormatter
{
    public string Format(string title) => title.ToUpperInvariant();
}

public sealed class TitleService(IOptions<NotesOptions> options, ITitleFormatter formatter)
{
    public string Heading() => formatter.Format(options.Value.Title);
}
