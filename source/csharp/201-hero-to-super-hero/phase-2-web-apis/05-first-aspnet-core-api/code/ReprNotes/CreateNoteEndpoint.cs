using FastEndpoints;

public sealed class CreateNoteEndpoint(NoteStore store) : Endpoint<CreateNoteRequest, Note>
{
    public override void Configure()
    {
        Post("/notes");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CreateNoteRequest req, CancellationToken ct)
    {
        Note created = store.Add(req.Title);
        await Send.CreatedAtAsync<GetNoteEndpoint>(new { id = created.Id }, created, cancellation: ct);
    }
}
