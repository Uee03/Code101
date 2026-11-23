using Microsoft.Extensions.Options;
using Shop.Billing;
using Shop.Contracts;
using Shop.Host.Remote;

var builder = WebApplication.CreateBuilder(args);

// One setting decides where billing lives. Nothing else in this file or in the order code changes.
if (builder.Configuration["Billing:Mode"] == "Remote")
{
    builder.Services.Configure<RemoteBillingOptions>(builder.Configuration.GetSection("Billing:Remote"));
    builder.Services.AddSingleton(TimeProvider.System);
    builder.Services.AddSingleton<ServiceTokenProvider>();
    builder.Services.AddTransient<ServiceTokenHandler>();
    builder.Services.AddHttpClient("token");
    builder.Services.AddHttpClient<IBillingApi, HttpBillingApi>((services, client) =>
            client.BaseAddress = new Uri(services.GetRequiredService<IOptions<RemoteBillingOptions>>().Value.BaseAddress))
        .AddHttpMessageHandler<ServiceTokenHandler>();
}
else
{
    builder.Services.AddBillingModule();
}

var app = builder.Build();
var lastOrderId = 0;

app.MapPost("/orders", async (CreateOrder request, IBillingApi billing, CancellationToken ct) =>
{
    if (string.IsNullOrWhiteSpace(request.Customer) || request.AmountCents <= 0)
    {
        return Results.ValidationProblem(new Dictionary<string, string[]> { ["order"] = ["customer and a positive amountCents are required"] });
    }

    var orderId = Interlocked.Increment(ref lastOrderId);
    var charge = await billing.ChargeAsync(new ChargeRequest(orderId, request.AmountCents), ct);
    return Results.Created($"/orders/{orderId}", new OrderResponse(orderId, request.Customer.Trim(), charge.Status, charge.Reference));
});

app.Run();

public sealed record CreateOrder(string Customer, int AmountCents);

public sealed record OrderResponse(int Id, string Customer, string PaymentStatus, string ChargeReference);
