public sealed record Note
{
    public int Id { get; init; }
    public string Title { get; init; } = "";
    public bool Done { get; init; }
}

public sealed class NoteStore
{
    private readonly Lock _gate = new();
    private readonly List<Note> _notes = [new Note { Id = 1, Title = "Learn REPR" }];
    private int _nextId = 2;

    public List<Note> All()
    {
        lock (_gate)
        {
            return [.. _notes];
        }
    }

    public Note? Find(int id)
    {
        lock (_gate)
        {
            return _notes.Find(n => n.Id == id);
        }
    }

    public Note Add(string title)
    {
        lock (_gate)
        {
            var note = new Note { Id = _nextId++, Title = title };
            _notes.Add(note);
            return note;
        }
    }

    public bool Remove(int id)
    {
        lock (_gate)
        {
            return _notes.RemoveAll(n => n.Id == id) > 0;
        }
    }
}
