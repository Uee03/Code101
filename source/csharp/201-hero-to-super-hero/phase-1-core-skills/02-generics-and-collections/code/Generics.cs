public interface IEntity
{
    int Id { get; }
}

public record Note(int Id, string Title) : IEntity;

public class InMemoryRepository<T> where T : class, IEntity
{
    private readonly Dictionary<int, T> _items = new();

    public void Add(T item)
    {
        if (!_items.TryAdd(item.Id, item))
        {
            throw new InvalidOperationException($"Id {item.Id} already exists.");
        }
    }

    public T? Find(int id) => _items.GetValueOrDefault(id);

    public IReadOnlyCollection<T> All() => _items.Values;
}

public static class Pick
{
    public static T LargestBy<T, TKey>(IEnumerable<T> source, Func<T, TKey> key)
        where TKey : IComparable<TKey>
    {
        using IEnumerator<T> e = source.GetEnumerator();
        if (!e.MoveNext())
        {
            throw new InvalidOperationException("The sequence is empty.");
        }

        T best = e.Current;
        TKey bestKey = key(best);
        while (e.MoveNext())
        {
            TKey candidate = key(e.Current);
            if (candidate.CompareTo(bestKey) > 0)
            {
                best = e.Current;
                bestKey = candidate;
            }
        }

        return best;
    }
}
