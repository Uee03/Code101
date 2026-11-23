using Microsoft.AspNetCore.Http.HttpResults;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<NoteStore>();

var app = builder.Build();

app.MapGet("/notes", (NoteStore store) => store.All());
app.MapGet("/notes/{id:int}", GetNote);
app.MapPost("/notes", CreateNote);

app.Run();

static Results<Ok<Note>, NotFound> GetNote(int id, NoteStore store)
{
    Note? note = store.Find(id);
    if (note is null)
    {
        return TypedResults.NotFound();
    }

    return TypedResults.Ok(note);
}

static Created<Note> CreateNote(CreateNoteRequest request, NoteStore store)
{
    Note created = store.Add(request.Title);
    return TypedResults.Created($"/notes/{created.Id}", created);
}
