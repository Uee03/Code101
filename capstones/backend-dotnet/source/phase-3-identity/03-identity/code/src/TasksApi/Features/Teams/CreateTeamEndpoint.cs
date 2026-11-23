using FastEndpoints;
using FluentValidation;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;
using Microsoft.EntityFrameworkCore;

namespace TasksApi.Features.Teams;

public sealed class CreateTeamRequest
{
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public Guid? LeadUserId { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed class CreateTeamValidator : Validator<CreateTeamRequest>
{
    public CreateTeamValidator()
    {
        RuleFor(x => x.Name)
            .Must(name => name.Trim().Length is >= 1 and <= 80)
            .WithMessage("must be between 1 and 80 characters");
        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("must be at most 500 characters");
    }
}

// POST /v1/teams (admin): the stored function create_team inserts the team and its first lead in one step.
public sealed class CreateTeamEndpoint(TasksDbContext db, CurrentUser user, Idempotency idempotency)
    : Endpoint<CreateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Post("/v1/teams");
        Policies(AccessPolicies.AdminWrite);
    }

    public override async Task HandleAsync(CreateTeamRequest req, CancellationToken ct)
    {
        var (team, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var created = await db.Teams
                .FromSql($"SELECT * FROM create_team({req.Name.Trim()}, {req.Description ?? ""}, {req.LeadUserId ?? user.Id}, {user.Id})")
                .AsNoTracking()
                .ToListAsync(ct);
            return await db.Teams.AsNoTracking().Where(t => t.Id == created[0].Id).Select(Projections.ToTeam).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/teams/{team.Id}", team.Version, replayed);
        await Send.ResponseAsync(team, StatusCodes.Status201Created, ct);
    }
}
