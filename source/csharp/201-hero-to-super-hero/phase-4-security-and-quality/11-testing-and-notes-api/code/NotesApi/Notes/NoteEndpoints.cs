using FluentValidation;
using FluentValidation.Results;

public static class NoteEndpoints
{
    public static void MapNoteEndpoints(this IEndpointRouteBuilder app)
    {
        RouteGroupBuilder group = app.MapGroup("/notes");
        group.MapGet("/", ListNotes);
        group.MapGet("/{id:int}", GetNote);
        group.MapPost("/", CreateNote);
    }

    private static async Task<IResult> ListNotes(NoteService service, CancellationToken ct, int page = 1)
    {
        IReadOnlyList<Note> notes = await service.ListAsync(Math.Max(page, 1), ct);
        return TypedResults.Ok(notes.Select(n => n.ToResponse()));
    }

    private static async Task<IResult> GetNote(int id, NoteService service, CancellationToken ct)
    {
        Result<Note> result = await service.GetAsync(id, ct);
        if (!result.IsSuccess)
        {
            return result.Error.ToProblem();
        }

        return TypedResults.Ok(result.Value.ToResponse());
    }

    private static async Task<IResult> CreateNote(
        CreateNoteRequest request,
        IValidator<CreateNoteRequest> validator,
        NoteService service,
        CancellationToken ct)
    {
        ValidationResult validation = await validator.ValidateAsync(request, ct);
        if (!validation.IsValid)
        {
            return TypedResults.ValidationProblem(validation.ToDictionary());
        }

        Result<Note> result = await service.CreateAsync(request.Title!, request.Body ?? "", ct);
        if (!result.IsSuccess)
        {
            return result.Error.ToProblem();
        }

        NoteResponse response = result.Value.ToResponse();
        return TypedResults.Created($"/notes/{response.Id}", response);
    }
}
