using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

// DELETE /v1/projects/{projectId} (lead or admin): the database cascades to the project's tasks and comments.
public sealed class DeleteProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<ProjectIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/projects/{projectId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(ProjectIdRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Projects.Where(p => p.Id == req.ProjectId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
