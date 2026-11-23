using FastEndpoints;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed record PermissionsResponse(Guid Id, bool IsAdmin, bool CanWrite);

// TODO: GET /v1/me/permissions tells the caller what the token allows, without a database call.
//   1. Configure(): Get the route above and require the Read policy (AccessPolicies.Read).
//   2. HandleAsync(): answer with user.Id, user.IsAdmin and whether user.Scopes contains "tasks:write".
public sealed class PermissionsEndpoint(CurrentUser user) : EndpointWithoutRequest<PermissionsResponse>
{
    public override void Configure()
    {
    }

    public override Task HandleAsync(CancellationToken ct) => Task.CompletedTask;
}
