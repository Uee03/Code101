using System.Text.Json.Serialization;

var builder = WebApplication.CreateSlimBuilder(args);

// Native AOT cannot generate serialization code at run time, so the serializer uses code generated at build time.
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonContext.Default);
});

var app = builder.Build();

var stock = new Dictionary<int, StockItem>
{
    [1] = new(1, "Pen", 120),
    [2] = new(2, "Cup", 0),
};

// Liveness: the process answers. Do not check dependencies here, or one outage restarts every instance.
app.MapGet("/healthz", () => Results.Text("ok"));

app.MapGet("/stock/{id:int}", (int id) =>
    stock.TryGetValue(id, out var item) ? Results.Ok(item) : Results.NotFound());

app.Run();

public sealed record StockItem(int Id, string Name, int Quantity);

[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(StockItem))]
internal sealed partial class AppJsonContext : JsonSerializerContext
{
}
