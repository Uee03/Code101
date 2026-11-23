using FluentValidation;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<NoteService>();
builder.Services.AddValidatorsFromAssemblyContaining<CreateNoteValidator>();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.MapNoteEndpoints();

app.Run();
