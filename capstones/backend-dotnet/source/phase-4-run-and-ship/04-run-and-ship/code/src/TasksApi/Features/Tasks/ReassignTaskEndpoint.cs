using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class ReassignTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    // Optional<T> so that a missing assigneeId (an error) differs from an explicit null (unassign).
    public Optional<Guid?> AssigneeId { get; set; }
}

public sealed class ReassignTaskValidator : Validator<ReassignTaskRequest>
{
    public ReassignTaskValidator()
    {
        RuleFor(x => x.AssigneeId.IsSet).Equal(true).OverridePropertyName("AssigneeId")
            .WithMessage("is required; send null to unassign");
    }
}

// POST /v1/tasks/{taskId}/reassign (lead or admin): the stored function also checks the new assignee is in the team.
public sealed class ReassignTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<ReassignTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/reassign");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(ReassignTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Tasks
            .FromSql($"SELECT * FROM reassign_task({req.TaskId}, {req.AssigneeId.Value}, {user.Id}, {expected})")
            .AsNoTracking()
            .ToListAsync(ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, task.Version);
        await Send.OkAsync(task, ct);
    }
}
