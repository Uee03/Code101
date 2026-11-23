using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

// DELETE /v1/teams/{teamId} (admin): the database cascades to members, projects, tasks and comments.
public sealed class DeleteTeamEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<TeamIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/teams/{teamId}");
        Policies(AccessPolicies.AdminOnly);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Teams.Where(t => t.Id == req.TeamId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
