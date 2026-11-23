using FastEndpoints;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Platform;

// GET /v1/me: who is calling, with the roles and scopes of the token and the teams the user belongs to.
public sealed class MeEndpoint(TasksDbContext db, CurrentUser user) : EndpointWithoutRequest<MeDto>
{
    public override void Configure()
    {
        Get("/v1/me");
        Policies(AccessPolicies.Read);
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var row = await db.Users.AsNoTracking()
            .Where(u => u.Id == user.Id)
            .Select(u => new { u.Username, u.Email, u.DisplayName })
            .SingleAsync(ct);
        var teams = await db.TeamMembers.AsNoTracking()
            .Where(m => m.UserId == user.Id)
            .OrderBy(m => m.Team!.Name)
            .Select(m => new MeTeamDto(m.TeamId, m.Team!.Name, m.Role))
            .ToListAsync(ct);
        var roles = user.Roles.Where(role => role is "admin" or "member").Order().ToList();
        await Send.OkAsync(new MeDto(user.Id, row.Username, row.Email, row.DisplayName, roles, user.Scopes.Order().ToList(), teams), ct);
    }
}
