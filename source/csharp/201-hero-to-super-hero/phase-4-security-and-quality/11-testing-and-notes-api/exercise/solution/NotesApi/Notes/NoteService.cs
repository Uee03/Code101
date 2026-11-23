using Microsoft.Extensions.Options;

public interface INoteRepository
{
    Task<Note?> FindAsync(int id, CancellationToken ct);

    Task<bool> TitleExistsAsync(string title, CancellationToken ct);

    Task AddAsync(Note note, CancellationToken ct);

    Task<IReadOnlyList<Note>> ListAsync(int skip, int take, CancellationToken ct);
}

public sealed class NoteService(INoteRepository repository, IOptions<NotesOptions> options)
{
    public async Task<Result<Note>> CreateAsync(string title, string body, CancellationToken ct)
    {
        string cleanTitle = title.Trim();
        if (await repository.TitleExistsAsync(cleanTitle, ct))
        {
            return Result<Note>.Fail(new Error(
                ErrorKind.Conflict,
                "note.duplicate_title",
                $"A note titled '{cleanTitle}' already exists."));
        }

        var note = new Note { Title = cleanTitle, Body = body, OwnerId = "demo-user" };
        await repository.AddAsync(note, ct);
        return Result<Note>.Ok(note);
    }

    public async Task<Result<Note>> GetAsync(int id, CancellationToken ct)
    {
        Note? note = await repository.FindAsync(id, ct);
        if (note is null)
        {
            return Result<Note>.Fail(new Error(
                ErrorKind.NotFound,
                "note.not_found",
                $"Note {id} was not found."));
        }

        return Result<Note>.Ok(note);
    }

    public Task<IReadOnlyList<Note>> ListAsync(int page, CancellationToken ct)
    {
        int size = options.Value.PageSize;
        return repository.ListAsync((page - 1) * size, size, ct);
    }
}
