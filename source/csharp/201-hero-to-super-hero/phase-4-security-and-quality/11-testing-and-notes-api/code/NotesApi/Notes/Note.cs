public sealed class Note
{
    public int Id { get; set; }

    public string Title { get; set; } = "";

    public string Body { get; set; } = "";

    public string OwnerId { get; set; } = "";
}

public sealed record CreateNoteRequest(string? Title, string? Body);

public sealed record NoteResponse(int Id, string Title, string Body);
