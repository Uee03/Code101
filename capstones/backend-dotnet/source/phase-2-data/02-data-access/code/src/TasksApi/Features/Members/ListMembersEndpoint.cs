using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Members;

// GET /v1/teams/{teamId}/members: ordered by join time, then user id; the cursor holds both.
public sealed class ListMembersEndpoint(TasksDbContext db, TeamAccess access) : Endpoint<PagedRequest, Paged<MemberDto>>
{
    public override void Configure()
    {
        Get("/v1/teams/{teamId}/members");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(PagedRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Member, ct);
        var query = db.TeamMembers.AsNoTracking().Where(m => m.TeamId == req.TeamId);
        if (req.Cursor is not null)
        {
            var data = Paging.Decode(req.Cursor);
            var joined = Paging.ParseTime(data.Value);
            var userId = Paging.ParseId(data.Id);
            query = query.Where(m => m.JoinedAt > joined || (m.JoinedAt == joined && m.UserId.CompareTo(userId) > 0));
        }
        var page = await Paging.ToPageAsync(query.OrderBy(m => m.JoinedAt).ThenBy(m => m.UserId).Select(Projections.ToMember),
            limit, m => Paging.Encode(Paging.FormatTime(m.JoinedAt), m.UserId.ToString()), ct);
        await Send.OkAsync(page, ct);
    }
}
