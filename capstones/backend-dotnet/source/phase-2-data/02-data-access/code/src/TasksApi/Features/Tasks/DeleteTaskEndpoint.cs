using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class DeleteTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }
}

// DELETE /v1/tasks/{taskId} (lead or admin): If-Match is optional here; when sent, the DELETE itself checks the version.
public sealed class DeleteTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<DeleteTaskRequest>
{
    public override void Configure()
    {
        Delete("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(DeleteTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Lead, ct);
        int? expected = req.IfMatch is null ? null : ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var deleted = await db.Tasks
            .Where(t => t.Id == req.TaskId && (expected == null || t.Version == expected))
            .ExecuteDeleteAsync(ct);
        if (deleted == 0)
        {
            throw expected is null
                ? ProblemException.NotFound("Task")
                : ProblemException.PreconditionFailed("The task changed since you read it.");
        }
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
