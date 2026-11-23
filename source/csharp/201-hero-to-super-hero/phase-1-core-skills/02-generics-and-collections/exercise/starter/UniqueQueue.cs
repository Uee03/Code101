public class UniqueQueue<T> where T : notnull
{
    private readonly Queue<T> _queue = new();
    private readonly HashSet<T> _members = new();

    public int Count => _queue.Count;

    public bool Enqueue(T item)
    {
        // TODO: return false when item is already queued; otherwise remember it, enqueue it and return true.
        return false;
    }

    public T Dequeue()
    {
        // TODO: take the next item out of the queue, forget it, and return it.
        throw new NotImplementedException();
    }
}
