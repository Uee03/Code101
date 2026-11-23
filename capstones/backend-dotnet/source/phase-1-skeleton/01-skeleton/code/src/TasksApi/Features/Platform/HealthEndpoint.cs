using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record HealthResponse(string Status, string Version);

// GET /health: liveness. Public, so Docker and load balancers can call it without a token.
public sealed class HealthEndpoint : EndpointWithoutRequest<HealthResponse>
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new HealthResponse("ok", "1.0.0"), ct);
}
