using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

public sealed class ListUsersRequest
{
    public string? Q { get; set; }
    public int? Limit { get; set; }
    public string? Cursor { get; set; }
}

// GET /v1/users: find users, for example to add a team member. Ordered by id, so the cursor is just the last id.
public sealed class ListUsersEndpoint(TasksDbContext db) : Endpoint<ListUsersRequest, Paged<UserSummaryDto>>
{
    public override void Configure()
    {
        Get("/v1/users");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(ListUsersRequest req, CancellationToken ct)
    {
        var limit = Paging.CheckLimit(req.Limit);
        var query = db.Users.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(req.Q))
        {
            var pattern = Like.Prefix(req.Q.Trim());
            query = query.Where(u => EF.Functions.ILike(u.Username, pattern, Like.EscapeChar)
                                     || EF.Functions.ILike(u.DisplayName, pattern, Like.EscapeChar));
        }
        if (req.Cursor is not null)
        {
            var after = Paging.ParseId(Paging.Decode(req.Cursor).Id);
            query = query.Where(u => u.Id.CompareTo(after) > 0);
        }
        var page = await Paging.ToPageAsync(query.OrderBy(u => u.Id).Select(Projections.ToUser), limit,
            u => Paging.Encode(null, u.Id.ToString()), ct);
        await Send.OkAsync(page, ct);
    }
}
