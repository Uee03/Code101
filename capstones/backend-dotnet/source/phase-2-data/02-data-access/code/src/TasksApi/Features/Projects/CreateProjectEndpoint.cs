using System.Text.RegularExpressions;
using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class CreateProjectRequest
{
    public Guid TeamId { get; set; }

    public string Key { get; set; } = "";
    public string Name { get; set; } = "";
    public string? Description { get; set; }

    [FromHeader("Idempotency-Key", IsRequired = false)]
    public string? IdempotencyKey { get; set; }
}

public sealed partial class CreateProjectValidator : Validator<CreateProjectRequest>
{
    public CreateProjectValidator()
    {
        RuleFor(x => x.Key).Matches(KeyPattern()).WithMessage("must be 2 to 10 characters: A to Z first, then A to Z or 0 to 9");
        RuleFor(x => x.Name).Must(name => name.Trim().Length is >= 1 and <= 120).WithMessage("must be between 1 and 120 characters");
        RuleFor(x => x.Description).MaximumLength(2000).WithMessage("must be at most 2000 characters");
    }

    [GeneratedRegex("^[A-Z][A-Z0-9]{1,9}$")]
    private static partial Regex KeyPattern();
}

// POST /v1/teams/{teamId}/projects (lead or admin): a duplicate key in the team is a 409 from the unique constraint.
public sealed class CreateProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access, Idempotency idempotency)
    : Endpoint<CreateProjectRequest, ProjectDto>
{
    public override void Configure()
    {
        Post("/v1/teams/{teamId}/projects");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(CreateProjectRequest req, CancellationToken ct)
    {
        await access.RequireTeamAsync(req.TeamId, TeamLevel.Lead, ct);
        var (project, replayed) = await idempotency.RunAsync(HttpContext, req.IdempotencyKey, req, async () =>
        {
            var entity = new Project
            {
                TeamId = req.TeamId,
                Key = req.Key,
                Name = req.Name.Trim(),
                Description = req.Description ?? "",
                CreatedBy = user.Id,
            };
            db.Projects.Add(entity);
            await db.SaveChangesAsync(ct);
            return await db.Projects.AsNoTracking().Where(p => p.Id == entity.Id).Select(Projections.ToProject).SingleAsync(ct);
        }, ct);
        ResponseHeaders.Created(HttpContext, $"/v1/projects/{project.Id}", project.Version, replayed);
        await Send.ResponseAsync(project, StatusCodes.Status201Created, ct);
    }
}
