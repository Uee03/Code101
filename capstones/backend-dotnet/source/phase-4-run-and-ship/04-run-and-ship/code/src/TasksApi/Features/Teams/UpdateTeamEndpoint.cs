using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Teams;

public sealed class UpdateTeamRequest
{
    public Guid TeamId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Name { get; set; }
    public Optional<string> Description { get; set; }
}

public sealed class UpdateTeamValidator : Validator<UpdateTeamRequest>
{
    public UpdateTeamValidator()
    {
        RuleFor(x => x).Must(x => x.Name.IsSet || x.Description.IsSet)
            .WithMessage("send at least one of name and description");
        When(x => x.Name.IsSet, () => RuleFor(x => x.Name.Value)
            .Must(name => name is not null && name.Trim().Length is >= 1 and <= 80)
            .OverridePropertyName("Name").WithMessage("must be between 1 and 80 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value)
            .Must(text => text is not null && text.Length <= 500)
            .OverridePropertyName("Description").WithMessage("must be at most 500 characters"));
    }
}

// PATCH /v1/teams/{teamId} (lead or admin): JSON Merge Patch guarded by If-Match.
public sealed class UpdateTeamEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Patch("/v1/teams/{teamId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateTeamRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var team = await db.Teams.SingleAsync(t => t.Id == req.TeamId, ct);
        ETags.EnsureCurrent(team.Version, expected, "team");
        if (req.Name.IsSet)
        {
            team.Name = req.Name.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            team.Description = req.Description.Value!;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Teams.AsNoTracking().Where(t => t.Id == req.TeamId).Select(Projections.ToTeam).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
