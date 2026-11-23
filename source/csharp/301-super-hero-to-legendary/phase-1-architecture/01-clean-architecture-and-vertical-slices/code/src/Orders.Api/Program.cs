using FastEndpoints;
using Orders.Api.Infrastructure;
using Orders.Domain;

var builder = WebApplication.CreateBuilder(args);

// The composition root is the only place that knows both the port (IOrderStore) and its adapter.
builder.Services.AddSingleton<IOrderStore, InMemoryOrderStore>();
builder.Services.AddFastEndpoints();

var app = builder.Build();

app.UseFastEndpoints();

app.Run();
