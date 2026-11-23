using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Data;

namespace TasksApi.Features.Platform;

public sealed record HealthResponse(string Status, string Version, string Database);

// GET /health: liveness plus a database check. Public, so Docker and load balancers can call it without a token.
public sealed class HealthEndpoint(TasksDbContext db) : EndpointWithoutRequest<HealthResponse>
{
    public override void Configure()
    {
        Get("/health");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var up = true;
        try
        {
            await db.Database.ExecuteSqlAsync($"SELECT 1", ct);
        }
        catch (Exception) when (!ct.IsCancellationRequested)
        {
            up = false;
        }
        await Send.ResponseAsync(new HealthResponse(up ? "ok" : "degraded", "1.0.0", up ? "up" : "down"),
            up ? StatusCodes.Status200OK : StatusCodes.Status503ServiceUnavailable, ct);
    }
}
