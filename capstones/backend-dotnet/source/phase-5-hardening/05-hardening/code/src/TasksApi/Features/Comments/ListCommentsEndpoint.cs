using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

// GET /v1/tasks/{taskId}/comments: oldest first, so a conversation reads from the top.
public sealed class ListCommentsEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<PagedRequest, Paged<CommentDto>>
{
    public override void Configure()
    {
        Get("/v1/tasks/{taskId}/comments");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(PagedRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var ordered = db.Comments.AsNoTracking()
            .Where(c => c.TaskId == req.TaskId)
            .AfterCreatedCursor(req.Cursor, descending: false)
            .OrderByCreated(descending: false);
        var page = await Paging.ToPageAsync(ordered.Select(Projections.ToComment), limit,
            c => Paging.CreatedCursor(c.CreatedAt, c.Id), ct);
        await Send.OkAsync(page, ct);
    }
}
