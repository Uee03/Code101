using Microsoft.AspNetCore.Authorization;

namespace TasksApi.Security;

// Names of the authorization policies. Effective permission is the intersection of the token's scope and the user's role.
public static class AccessPolicies
{
    public const string Read = "TasksRead";
    public const string Write = "TasksWrite";
    public const string AdminWrite = "AdminWrite";
    public const string AdminOnly = "AdminOnly";

    public static void Add(AuthorizationOptions options)
    {
        options.AddPolicy(Read, p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:read")));
        options.AddPolicy(Write, p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:write")));
        options.AddPolicy(AdminWrite,
            p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:write", "admin")));
        options.AddPolicy(AdminOnly,
            p => p.RequireAuthenticatedUser().AddRequirements(new TokenRequirement("tasks:admin", "admin")));
    }
}

public sealed record TokenRequirement(string Scope, string? Role = null) : IAuthorizationRequirement;

public sealed class TokenRequirementHandler : AuthorizationHandler<TokenRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, TokenRequirement requirement)
    {
        var user = CurrentUser.From(context.User);
        if (!user.Scopes.Contains(requirement.Scope))
        {
            context.Fail(new AuthorizationFailureReason(this, $"The scope '{requirement.Scope}' is required."));
        }
        else if (requirement.Role is not null && !user.Roles.Contains(requirement.Role))
        {
            context.Fail(new AuthorizationFailureReason(this, $"The '{requirement.Role}' role is required."));
        }
        else
        {
            context.Succeed(requirement);
        }
        return Task.CompletedTask;
    }
}
