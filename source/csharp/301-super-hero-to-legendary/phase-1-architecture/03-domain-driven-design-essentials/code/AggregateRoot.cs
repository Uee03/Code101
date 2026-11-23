namespace Sales;

public interface IDomainEvent
{
}

// The base of every aggregate root: it records what happened and lets the caller collect it after saving.
public abstract class AggregateRoot
{
    private readonly List<IDomainEvent> events = [];

    protected void Raise(IDomainEvent domainEvent) => events.Add(domainEvent);

    public IReadOnlyList<IDomainEvent> PullEvents()
    {
        var copy = events.ToList();
        events.Clear();
        return copy;
    }
}
