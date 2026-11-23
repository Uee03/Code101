var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<NoteStore>();
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();
