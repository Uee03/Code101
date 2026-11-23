using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

public sealed class RemoveMemberRequest
{
    public Guid TeamId { get; set; }
    public Guid UserId { get; set; }
}

// DELETE /v1/teams/{teamId}/members/{userId} (lead or admin): the last lead of a team cannot be removed.
public sealed class RemoveMemberEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<RemoveMemberRequest>
{
    public override void Configure()
    {
        Delete("/v1/teams/{teamId}/members/{userId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(RemoveMemberRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var member = await db.TeamMembers.SingleOrDefaultAsync(m => m.TeamId == req.TeamId && m.UserId == req.UserId, ct)
                     ?? throw ProblemException.NotFound("Member");
        if (member.Role == "lead"
            && !await db.TeamMembers.AnyAsync(m => m.TeamId == req.TeamId && m.Role == "lead" && m.UserId != req.UserId, ct))
        {
            throw ProblemException.Conflict("A team needs at least one lead.", "last_lead");
        }
        db.TeamMembers.Remove(member);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.NoContentAsync(ct);
    }
}
