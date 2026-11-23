using FastEndpoints;

namespace TasksApi.Features.Platform;

public sealed record PingResponse(bool Pong);

// GET /v1/ping: the smallest possible endpoint.
public sealed class PingEndpoint : EndpointWithoutRequest<PingResponse>
{
    public override void Configure()
    {
        Get("/v1/ping");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new PingResponse(true), ct);
}
