using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Shop.Contracts;

namespace Shop.Billing;

// Nothing outside this assembly can name this class: the only way in is IBillingApi.
internal sealed class BillingService : IBillingApi
{
    private int charges;

    public Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken ct)
    {
        var number = Interlocked.Increment(ref charges);
        return Task.FromResult(new ChargeResult(request.OrderId, "Paid", $"chg-{number}"));
    }
}

public static class BillingModule
{
    public static IServiceCollection AddBillingModule(this IServiceCollection services) =>
        services.AddSingleton<IBillingApi, BillingService>();

    // The same endpoint is hosted by the monolith (no policy) or by the Billing service (with a policy).
    public static IEndpointRouteBuilder MapBillingEndpoints(this IEndpointRouteBuilder endpoints, string? requiredPolicy)
    {
        var charges = endpoints.MapPost("/billing/charges", async (ChargeRequest request, IBillingApi billing, CancellationToken ct) =>
        {
            if (request.AmountCents <= 0)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]> { ["amountCents"] = ["must be positive"] });
            }

            return Results.Ok(await billing.ChargeAsync(request, ct));
        });

        if (requiredPolicy is not null)
        {
            charges.RequireAuthorization(requiredPolicy);
        }

        return endpoints;
    }
}
