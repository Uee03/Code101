public sealed record Note(int Id, string Title, string Body, string OwnerId);

public sealed class NoteService
{
    private readonly Lock _gate = new();
    private readonly List<Note> _notes = [];
    private int _nextId = 1;

    public Result<Note> Create(string title, string body)
    {
        lock (_gate)
        {
            if (_notes.Any(n => n.Title.Equals(title, StringComparison.OrdinalIgnoreCase)))
            {
                return Result<Note>.Fail(new Error(
                    ErrorKind.Conflict,
                    "note.duplicate_title",
                    $"A note titled '{title}' already exists."));
            }

            var note = new Note(_nextId++, title, body, "demo-user");
            _notes.Add(note);
            return Result<Note>.Ok(note);
        }
    }

    public Result<Note> Get(int id)
    {
        lock (_gate)
        {
            Note? note = _notes.Find(n => n.Id == id);
            if (note is null)
            {
                return Result<Note>.Fail(new Error(
                    ErrorKind.NotFound,
                    "note.not_found",
                    $"Note {id} was not found."));
            }

            return Result<Note>.Ok(note);
        }
    }
}
