public sealed class GetNoteRequest
{
    public int Id { get; set; }
}

public sealed class CreateNoteRequest
{
    public string Title { get; set; } = "";
}
