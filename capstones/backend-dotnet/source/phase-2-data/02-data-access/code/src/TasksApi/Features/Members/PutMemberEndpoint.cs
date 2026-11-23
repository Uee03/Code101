using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

public sealed class PutMemberRequest
{
    public Guid TeamId { get; set; }

    public Guid UserId { get; set; }

    public string Role { get; set; } = "";
}

public sealed class PutMemberValidator : Validator<PutMemberRequest>
{
    public PutMemberValidator()
    {
        RuleFor(x => x.Role).Must(role => role is "lead" or "member").WithMessage("must be lead or member");
    }
}

// PUT /v1/teams/{teamId}/members/{userId} (lead or admin): adds the member (201) or changes the role (200).
public sealed class PutMemberEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<PutMemberRequest, MemberDto>
{
    public override void Configure()
    {
        Put("/v1/teams/{teamId}/members/{userId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(PutMemberRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        if (!await db.Users.AnyAsync(u => u.Id == req.UserId, ct))
        {
            throw ProblemException.NotFound("User");
        }
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var member = await db.TeamMembers.SingleOrDefaultAsync(m => m.TeamId == req.TeamId && m.UserId == req.UserId, ct);
        var added = member is null;
        if (member is null)
        {
            db.TeamMembers.Add(new TeamMember { TeamId = req.TeamId, UserId = req.UserId, Role = req.Role });
        }
        else
        {
            if (member.Role == "lead" && req.Role != "lead" && !await HasAnotherLeadAsync(req.TeamId, req.UserId, ct))
            {
                throw ProblemException.Conflict("A team needs at least one lead.", "last_lead");
            }
            member.Role = req.Role;
        }
        await db.SaveChangesAsync(ct);
        var dto = await db.TeamMembers.AsNoTracking()
            .Where(m => m.TeamId == req.TeamId && m.UserId == req.UserId)
            .Select(Projections.ToMember)
            .SingleAsync(ct);
        await transaction.CommitAsync(ct);
        await Send.ResponseAsync(dto, added ? StatusCodes.Status201Created : StatusCodes.Status200OK, ct);
    }

    private Task<bool> HasAnotherLeadAsync(Guid teamId, Guid userId, CancellationToken ct) =>
        db.TeamMembers.AnyAsync(m => m.TeamId == teamId && m.Role == "lead" && m.UserId != userId, ct);
}
