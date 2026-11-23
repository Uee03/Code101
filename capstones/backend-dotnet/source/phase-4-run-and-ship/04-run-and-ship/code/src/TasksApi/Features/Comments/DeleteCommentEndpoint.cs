using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Comments;

// DELETE /v1/comments/{commentId}: the author may delete their own comment; otherwise a team lead or an admin is needed.
public sealed class DeleteCommentEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access) : Endpoint<CommentIdRequest>
{
    public override void Configure()
    {
        Delete("/v1/comments/{commentId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CommentIdRequest req, CancellationToken ct)
    {
        var comment = await db.Comments.AsNoTracking()
            .Where(c => c.Id == req.CommentId)
            .Select(c => new { c.AuthorId, TeamId = c.TaskItem!.Project!.TeamId })
            .SingleOrDefaultAsync(ct) ?? throw ProblemException.NotFound("Comment");
        await access.RequireTeamAsync(comment.TeamId, comment.AuthorId == user.Id ? TeamLevel.Member : TeamLevel.Lead, ct, "Comment");
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        await db.Comments.Where(c => c.Id == req.CommentId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
