public sealed class FakeNoteRepository : INoteRepository
{
    private readonly List<Note> _notes = [];
    private int _nextId = 1;

    public Task<Note?> FindAsync(int id, CancellationToken ct) =>
        Task.FromResult(_notes.Find(n => n.Id == id));

    public Task<bool> TitleExistsAsync(string title, CancellationToken ct) =>
        Task.FromResult(_notes.Any(n => n.Title.Equals(title, StringComparison.OrdinalIgnoreCase)));

    public Task AddAsync(Note note, CancellationToken ct)
    {
        note.Id = _nextId++;
        _notes.Add(note);
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<Note>> ListAsync(int skip, int take, CancellationToken ct) =>
        Task.FromResult<IReadOnlyList<Note>>(_notes.OrderBy(n => n.Id).Skip(skip).Take(take).ToList());
}
