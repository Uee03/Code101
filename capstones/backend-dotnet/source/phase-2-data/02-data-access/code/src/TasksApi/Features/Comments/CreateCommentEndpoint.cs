using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

public sealed class CreateCommentRequest
{
    public Guid TaskId { get; set; }

    public string Body { get; set; } = "";

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateCommentValidator : Validator<CreateCommentRequest>
{
    public CreateCommentValidator()
    {
        RuleFor(x => x.Body).Must(body => body.Trim().Length is >= 1 and <= 2000)
            .WithMessage("must be between 1 and 2000 characters");
    }
}

// POST /v1/tasks/{taskId}/comments (any member): the author is always the caller.
public sealed class CreateCommentEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateCommentRequest, CommentDto>
{
    public override void Configure()
    {
        Post("/v1/tasks/{taskId}/comments");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateCommentRequest req, CancellationToken ct)
    {
        await access.RequireTaskAsync(req.TaskId, TeamLevel.Member, ct);
        var (comment, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new Comment { TaskId = req.TaskId, AuthorId = user.Id, Body = req.Body.Trim() };
            db.Comments.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Comments.AsNoTracking().Where(c => c.Id == entity.Id).Select(Projections.ToComment).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/comments/{comment.Id}", null, replayed);
        await Send.ResponseAsync(comment, StatusCodes.Status201Created, ct);
    }
}
