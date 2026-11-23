using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Tasks;

public sealed class GetTaskRequest
{
    public Guid TaskId { get; set; }

    [FromHeader("If-None-Match", IsRequired = false)]
    public string? IfNoneMatch { get; set; }
}

// GET /v1/tasks/{taskId}: answers 304 with no body when the client's If-None-Match is still the current ETag.
public sealed class GetTaskEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<GetTaskRequest, TaskDto>
{
    public override void Configure()
    {
        Get("/v1/tasks/{taskId}");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(GetTaskRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var task = await db.Tasks.AsNoTracking().Where(t => t.Id == req.TaskId).Select(Projections.ToTask).SingleAsync(ct);
        ETags.Set(HttpContext, task.Version);
        if (ETags.IsNotModified(req.IfNoneMatch, task.Version))
        {
            HttpContext.Response.StatusCode = StatusCodes.Status304NotModified;
            await HttpContext.Response.CompleteAsync();
            return;
        }
        await Send.OkAsync(task, ct);
    }
}
