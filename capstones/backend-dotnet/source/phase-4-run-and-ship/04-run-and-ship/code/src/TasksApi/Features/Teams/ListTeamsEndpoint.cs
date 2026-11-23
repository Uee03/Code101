using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed class ListTeamsRequest
{
    public string? Q { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/teams: the caller's teams (admins see every team), filtered by name prefix and paged by cursor.
public sealed class ListTeamsEndpoint(TasksDbContext db, CurrentUser user) : Endpoint<ListTeamsRequest, Paged<TeamDto>>
{
    public override void Configure()
    {
        Get("/v1/teams");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListTeamsRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var descending = Paging.CheckSort(req.Sort) == "-createdAt";
        var query = db.Teams.AsNoTracking();
        if (!user.IsAdmin)
        {
            query = query.Where(t => t.Members.Any(m => m.UserId == user.Id));
        }
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Prefix(req.Q.Trim());
            query = query.Where(t => EF.Functions.ILike(t.Name, pattern, Like.EscapeChar));
        }
        var ordered = query.AfterCreatedCursor(req.Cursor, descending).OrderByCreated(descending);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToTeam), limit,
            t => Paging.CreatedCursor(t.CreatedAt, t.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
