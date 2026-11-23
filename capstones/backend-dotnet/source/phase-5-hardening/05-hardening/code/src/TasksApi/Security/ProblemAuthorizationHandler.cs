using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using TasksApi.Common;

namespace TasksApi.Security;

// Writes the 403 as a problem that says which scope or role was missing. A 401 is left to the default handler,
// which asks the JWT scheme to challenge (see OnChallenge in JwtSetup).
public sealed class ProblemAuthorizationHandler(ILogger<ProblemAuthorizationHandler> logger) : IAuthorizationMiddlewareResultHandler
{
    private readonly AuthorizationMiddlewareResultHandler _default = new();

    public async Task HandleAsync(RequestDelegate next, HttpContext context, AuthorizationPolicy policy,
        PolicyAuthorizationResult result)
    {
        if (result.Forbidden)
        {
            var reason = result.AuthorizationFailure?.FailureReasons.FirstOrDefault()?.Message
                         ?? "You are not allowed to do this.";
            logger.LogWarning("Access denied for user {UserId} on {Method} {Path}: {Reason}",
                context.User.FindFirstValue("sub"), context.Request.Method, context.Request.Path.Value, reason);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status403Forbidden, reason);
            return;
        }
        await _default.HandleAsync(next, context, policy, result);
    }
}
