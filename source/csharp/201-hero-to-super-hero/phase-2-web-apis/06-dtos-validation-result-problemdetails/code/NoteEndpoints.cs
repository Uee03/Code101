using FluentValidation;
using FluentValidation.Results;

public static class NoteEndpoints
{
    public static void MapNoteEndpoints(this IEndpointRouteBuilder app)
    {
        RouteGroupBuilder group = app.MapGroup("/notes");
        group.MapPost("/", CreateNote);
        group.MapGet("/{id:int}", GetNote);

        app.MapGet("/boom", Boom);
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

        Result<Note> result = service.Create(request.Title!, request.Body ?? "");
        if (!result.IsSuccess)
        {
            return result.Error.ToProblem();
        }

        NoteResponse response = result.Value.ToResponse();
        return TypedResults.Created($"/notes/{response.Id}", response);
    }

    private static IResult GetNote(int id, NoteService service)
    {
        Result<Note> result = service.Get(id);
        if (!result.IsSuccess)
        {
            return result.Error.ToProblem();
        }

        return TypedResults.Ok(result.Value.ToResponse());
    }

    private static IResult Boom() => throw new InvalidOperationException("secret internal detail");
}
