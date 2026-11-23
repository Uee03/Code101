using FastEndpoints;
using FluentValidation;
using TasksApi.Contracts;

namespace TasksApi.Features.Teams;

public sealed class CreateTeamRequest
{
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public Guid? LeadUserId { get; set; }
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

// POST /v1/teams: a stub that validates the body and answers as if the team was saved. Chapter 2 stores it.
public sealed class CreateTeamEndpoint : Endpoint<CreateTeamRequest, TeamDto>
{
    public override void Configure()
    {
        Post("/v1/teams");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CreateTeamRequest req, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var team = new TeamDto(Guid.NewGuid(), req.Name.Trim(), req.Description ?? "", 1,
            Guid.Parse("a11ce000-0000-4000-8000-000000000001"), 1, now, now);
        HttpContext.Response.Headers.ETag = $"\"{team.Version}\"";
        HttpContext.Response.Headers.Location = $"/v1/teams/{team.Id}";
        await Send.ResponseAsync(team, StatusCodes.Status201Created, ct);
    }
}
