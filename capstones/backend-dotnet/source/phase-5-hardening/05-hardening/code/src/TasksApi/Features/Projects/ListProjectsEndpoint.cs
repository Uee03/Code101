using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class ListProjectsRequest
{
    public Guid TeamId { get; set; }
    public bool Archived { get; set; }
    public string? Sort { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/teams/{teamId}/projects: archived projects are hidden unless archived=true.
public sealed class ListProjectsEndpoint(TasksDbContext db, TeamAccess access)
    : Endpoint<ListProjectsRequest, Paged<ProjectDto>>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/projects");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListProjectsRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var descending = Paging.CheckSort(req.Sort) == "-createdAt";
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var ordered = db.Projects.AsNoTracking()
            .Where(p => p.TeamId == req.TeamId && p.Archived == req.Archived)
            .AfterCreatedCursor(req.Cursor, descending)
            .OrderByCreated(descending);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToProject), limit,
            p => Paging.CreatedCursor(p.CreatedAt, p.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
