using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

// GET /v1/teams/{teamId}: a team the caller belongs to (or any team for an admin), with its ETag.
public sealed class GetTeamEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamDto>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var team = await db.Teams.AsNoTracking().Where(t => t.Id == req.TeamId).Select(Projections.ToTeam).SingleAsync(ct);
        ETags.Set(HttpContext, team.Version);
        await Send.OkAsync(team, ct);
    }
}
