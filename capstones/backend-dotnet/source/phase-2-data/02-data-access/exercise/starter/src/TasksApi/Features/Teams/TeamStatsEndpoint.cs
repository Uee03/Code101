using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed record TeamStatsResponse(IReadOnlyDictionary<string, int> ByStatus);

// TODO: GET /v1/teams/{teamId}/task-stats answers how many tasks the team has in each status,
// for example {"byStatus":{"todo":2,"done":1}}.
//   1. Configure(): Get the route above and require the Read policy (AccessPolicies.Read).
//   2. HandleAsync(): call access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct) first, so a non-member gets 404.
//   3. Query db.Tasks (AsNoTracking) for tasks whose Project.TeamId is req.TeamId, GroupBy Status,
//      Select the key and g.Count(), and ToListAsync(ct).
//   4. Send the rows as a dictionary with Send.OkAsync.
public sealed class TeamStatsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamStatsResponse>
{
    public override void Configure()
    {
    }

    public override Task HandleAsync(TeamIdRequest req, CancellationToken ct) => Task.CompletedTask;
}
