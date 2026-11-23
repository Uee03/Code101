using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class CreateTaskRequest
{
    public Guid ProjectId { get; set; }

    public string Title { get; set; } = "";
    public string? Description { get; set; }
    public string? Priority { get; set; }
    public Guid? AssigneeId { get; set; }
    public DateOnly? DueDate { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateTaskValidator : Validator<CreateTaskRequest>
{
    public CreateTaskValidator()
    {
        RuleFor(x => x.Title).Must(TaskRules.IsTitle).WithMessage("must be between 1 and 200 characters");
        RuleFor(x => x.Description).Must(text => text is null || TaskRules.IsDescription(text))
            .WithMessage("must be at most 10000 characters");
        RuleFor(x => x.Priority).Must(p => p is null || TaskRules.Priorities.Contains(p))
            .WithMessage("must be low, medium, high or urgent");
    }
}

// POST /v1/projects/{projectId}/tasks (any member): an archived project accepts no new tasks.
public sealed class CreateTaskEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Post("/v1/projects/{projectId}/tasks");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateTaskRequest req, CancellationToken ct)
    {
        var teamId = await access.RequireProjectAsync(req.ProjectId, TeamLevel.Member, ct);
        if (await db.Projects.AnyAsync(p => p.Id == req.ProjectId && p.Archived, ct))
        {
            throw ProblemException.Conflict("The project is archived.", "project_archived");
        }
        await access.EnsureAssigneeAsync(teamId, req.AssigneeId, ct);
        var (task, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new TaskItem
            {
                ProjectId = req.ProjectId,
                Title = req.Title.Trim(),
                Description = req.Description ?? "",
                Priority = req.Priority ?? "medium",
                AssigneeId = req.AssigneeId,
                DueDate = req.DueDate,
                CreatedBy = user.Id,
            };
            db.Tasks.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Tasks.AsNoTracking().Where(t => t.Id == entity.Id).Select(Projections.ToTask).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/tasks/{task.Id}", task.Version, replayed);
        await Send.ResponseAsync(task, StatusCodes.Status201Created, ct);
    }
}
