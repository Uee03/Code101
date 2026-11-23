using FastEndpoints;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Contracts;
using TasksApi.Data;
using TasksApi.Security;

namespace TasksApi.Features.Projects;

public sealed class UpdateProjectRequest
{
    public Guid ProjectId { get; set; }

    [FromHeader("If-Match", IsRequired = false)]
    public string? IfMatch { get; set; }

    public Optional<string> Name { get; set; }
    public Optional<string> Description { get; set; }
    public Optional<bool?> Archived { get; set; }
}

public sealed class UpdateProjectValidator : Validator<UpdateProjectRequest>
{
    public UpdateProjectValidator()
    {
        RuleFor(x => x).Must(x => x.Name.IsSet || x.Description.IsSet || x.Archived.IsSet)
            .WithMessage("send at least one of name, description and archived");
        When(x => x.Name.IsSet, () => RuleFor(x => x.Name.Value)
            .Must(name => name is not null && name.Trim().Length is >= 1 and <= 120)
            .OverridePropertyName("Name").WithMessage("must be between 1 and 120 characters"));
        When(x => x.Description.IsSet, () => RuleFor(x => x.Description.Value)
            .Must(text => text is not null && text.Length <= 2000)
            .OverridePropertyName("Description").WithMessage("must be at most 2000 characters"));
        When(x => x.Archived.IsSet, () => RuleFor(x => x.Archived.Value)
            .NotNull().OverridePropertyName("Archived").WithMessage("must be true or false"));
    }
}

// PATCH /v1/projects/{projectId} (lead or admin): rename, describe, archive or restore; guarded by If-Match.
public sealed class UpdateProjectEndpoint(TasksDbContext db, CurrentUser user, TeamAccess access)
    : Endpoint<UpdateProjectRequest, ProjectDto>
{
    public override void Configure()
    {
        Patch("/v1/projects/{projectId}");
        Policies(AccessPolicies.Write);
    }

    public override async Task HandleAsync(UpdateProjectRequest req, CancellationToken ct)
    {
        await access.RequireProjectAsync(req.ProjectId, TeamLevel.Lead, ct);
        var expected = ETags.RequireIfMatch(req.IfMatch);
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        var project = await db.Projects.SingleAsync(p => p.Id == req.ProjectId, ct);
        ETags.EnsureCurrent(project.Version, expected, "project");
        if (req.Name.IsSet)
        {
            project.Name = req.Name.Value!.Trim();
        }
        if (req.Description.IsSet)
        {
            project.Description = req.Description.Value!;
        }
        if (req.Archived.IsSet)
        {
            project.Archived = req.Archived.Value!.Value;
        }
        await db.SaveChangesAsync(ct);
        var updated = await db.Projects.AsNoTracking().Where(p => p.Id == req.ProjectId).Select(Projections.ToProject).SingleAsync(ct);
        await transaction.CommitAsync(ct);
        ETags.Set(HttpContext, updated.Version);
        await Send.OkAsync(updated, ct);
    }
}
