using FastEndpoints;

public sealed class ListNotesEndpoint(NoteStore store) : EndpointWithoutRequest<List<Note>>
{
    public override void Configure()
    {
        Get("/notes");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        await Send.OkAsync(store.All(), ct);
    }
}
