using FastEndpoints;

public sealed class GetNoteEndpoint(NoteStore store) : Endpoint<GetNoteRequest, Note>
{
    public override void Configure()
    {
        Get("/notes/{id}");
        AllowAnonymous();
    }

    public override async Task HandleAsync(GetNoteRequest req, CancellationToken ct)
    {
        Note? note = store.Find(req.Id);
        if (note is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        await Send.OkAsync(note, ct);
    }
}
