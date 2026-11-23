public class UniqueQueue<T> where T : notnull
{
    private readonly Queue<T> _queue = new();
    private readonly HashSet<T> _members;

    public UniqueQueue(IEqualityComparer<T>? comparer = null)
    {
        _members = new HashSet<T>(comparer);
    }

    public int Count => _queue.Count;

    public bool Enqueue(T item)
    {
        if (!_members.Add(item))
        {
            return false;
        }

        _queue.Enqueue(item);
        return true;
    }

    public T Dequeue()
    {
        T item = _queue.Dequeue();
        _members.Remove(item);
        return item;
    }
}
