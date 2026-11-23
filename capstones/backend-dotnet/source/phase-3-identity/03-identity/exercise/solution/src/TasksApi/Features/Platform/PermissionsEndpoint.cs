using FastEndpoints;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed record PermissionsResponse(Guid Id, bool IsAdmin, bool CanWrite);

// GET /v1/me/permissions: answered from the token's claims alone.
public sealed class PermissionsEndpoint(CurrentUser user) : EndpointWithoutRequest<PermissionsResponse>
{
    public override void Configure()
    {
        Get("/v1/me/permissions");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(CancellationToken ct) =>
        await Send.OkAsync(new PermissionsResponse(user.Id, user.IsAdmin, user.Scopes.Contains("tasks:write")), ct);
}
