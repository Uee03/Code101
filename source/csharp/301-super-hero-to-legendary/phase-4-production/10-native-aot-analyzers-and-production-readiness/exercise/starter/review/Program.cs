using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseDeveloperExceptionPage();
app.UseCors();

const string connectionString = "Host=db;Database=shop;Username=postgres;Password=postgres";

app.MapGet("/debug/config", (IConfiguration configuration) =>
    configuration.AsEnumerable().ToDictionary(pair => pair.Key, pair => pair.Value));

app.MapPost("/orders", async (HttpRequest request, ILogger<Program> logger) =>
{
    using var reader = new StreamReader(request.Body);
    var body = await reader.ReadToEndAsync();
    logger.LogInformation("Order received: {Body} from {Authorization}", body, request.Headers.Authorization);

    var client = new HttpClient();
    var response = client.PostAsync("https://payments.internal/charge", new StringContent(body)).Result;
    for (var attempt = 0; attempt < 10 && !response.IsSuccessStatusCode; attempt++)
    {
        response = client.PostAsync("https://payments.internal/charge", new StringContent(body)).Result;
    }

    return Results.Ok(await response.Content.ReadAsStringAsync());
});

app.Run();
