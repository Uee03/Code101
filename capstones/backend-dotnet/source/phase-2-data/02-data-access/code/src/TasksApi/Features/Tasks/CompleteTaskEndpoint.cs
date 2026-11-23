using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class CompleteTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }
}

// POST /v1/tasks/{taskId}/complete (any member): the stored function locks the row, checks the version and the rules.
public sealed class CompleteTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<CompleteTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/complete");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CompleteTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Tasks
            .FromSql($"SELECT * FROM complete_task({req.TaskId}, {user.Id}, {expected})")
            .AsNoTracking()
            .ToListAsync(ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, task.Version);
        await Send.OkAsync(task, ct);
    }
}
