using FastEndpoints;
using TasksApi.Contracts;

namespace TasksApi.Features.Platform;

// GET /v1/me: a stub that always answers as alice. Chapter 3 reads the caller from the access token instead.
public sealed class MeEndpoint : EndpointWithoutRequest<MeDto>
{
    public override void Configure()
    {
        Get("/v1/me");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new MeDto(
            Guid.Parse("a11ce000-0000-4000-8000-000000000001"),
            "alice",
            "alice@tasksteams.test",
            "Alice Admin",
            ["admin"],
            ["tasks:read", "tasks:write", "tasks:admin"],
            []), ct);
}
