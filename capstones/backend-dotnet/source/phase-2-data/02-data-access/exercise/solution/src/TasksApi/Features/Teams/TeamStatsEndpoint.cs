using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed record TeamStatsResponse(IReadOnlyDictionary<string, int> ByStatus);

// GET /v1/teams/{teamId}/task-stats: one GROUP BY query, so the counting happens in the database.
public sealed class TeamStatsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<TeamIdRequest, TeamStatsResponse>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/task-stats");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(TeamIdRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var rows = await db.Tasks.AsNoTracking()
            .Where(t => t.Project!.TeamId == req.TeamId)
            .GroupBy(t => t.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        await Send.OkAsync(new TeamStatsResponse(rows.ToDictionary(r => r.Status, r => r.Count)), ct);
    }
}
