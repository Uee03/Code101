using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

// GET /v1/projects/{projectId}: a project of one of the caller's teams, with its ETag.
public sealed class GetProjectEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<ProjectIdRequest, ProjectDto>
{
    public override void Configure()
    {
        Get("/v1/projects/{projectId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ProjectIdRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);
        var project = await db.Projects.AsNoTracking().Where(p => p.Id == req.ProjectId).Select(Projections.ToProject).SingleAsync(ct);
        ETags.Set(HttpContext, project.Version);
        await Send.OkAsync(project, ct);
    }
}
