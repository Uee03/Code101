using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class UpdateTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Title { get; set; }
    public Optional<string> Description { get; set; }
    public Optional<string> Status { get; set; }
    public Optional<string> Priority { get; set; }
    public Optional<Guid?> AssigneeId { get; set; }
    public Optional<DateOnly?> DueDate { get; set; }
}

public sealed class UpdateTaskValidator : Validator<UpdateTaskRequest>
{
    public UpdateTaskValidator()
    {
        RuleFor(x => x)
            .Must(x => x.Title.IsSet || x.Description.IsSet || x.Status.IsSet || x.Priority.IsSet || x.AssigneeId.IsSet || x.DueDate.IsSet)
            .WithMessage("send at least one field to change");
        When(x => x.Title.IsSet, () => RuleFor(x => x.Title.Value).Must(TaskRules.IsTitle)
            .OverridePropertyName("Title").WithMessage("must be between 1 and 200 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value).Must(TaskRules.IsDescription)
            .OverridePropertyName("Description").WithMessage("must be at most 10000 characters"));
        When(x => x.Status.IsSet, () => RuleFor(x => x.Status.Value)
            .Must(s => s is not null && TaskRules.Statuses.Contains(s))
            .OverridePropertyName("Status").WithMessage("must be todo, in_progress, blocked, done or cancelled"));
        When(x => x.Priority.IsSet, () => RuleFor(x => x.Priority.Value)
            .Must(p => p is not null && TaskRules.Priorities.Contains(p))
            .OverridePropertyName("Priority").WithMessage("must be low, medium, high or urgent"));
    }
}

// PATCH /v1/tasks/{taskId} (any member): JSON Merge Patch. A field that is absent stays; null clears assigneeId and dueDate.
// If-Match is checked twice: against the row we just read (a clear 412) and again by the UPDATE itself (version = expected).
public sealed class UpdateTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Patch("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateTaskRequest req, CancellationToken ct)
    {
        var teamId = await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        if (req.AssigneeId.IsSet)
        {
            await access.EnsureAssigneeAsync(teamId, req.AssigneeId.Value, ct);
        }
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var task = await db.Tasks.SingleAsync(t => t.Id == req.TaskId, ct);
        ETags.EnsureCurrent(task.Version, expected, "task");
        if (req.Title.IsSet)
        {
            task.Title = req.Title.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            task.Description = req.Description.Value!;
        }
        if (req.Status.IsSet)
        {
            task.Status = req.Status.Value!;
        }
        if (req.Priority.IsSet)
        {
            task.Priority = req.Priority.Value!;
        }
        if (req.AssigneeId.IsSet)
        {
            task.AssigneeId = req.AssigneeId.Value;
        }
        if (req.DueDate.IsSet)
        {
            task.DueDate = req.DueDate.Value;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
