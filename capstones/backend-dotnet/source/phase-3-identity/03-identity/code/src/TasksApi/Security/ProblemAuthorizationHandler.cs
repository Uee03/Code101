using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Policy;
using TasksApi.Common;

namespace TasksApi.Security;

// Writes the 403 as a problem that says which scope or role was missing. A 401 is left to the default handler,
// which asks the JWT scheme to challenge (see OnChallenge in JwtSetup).
public sealed class ProblemAuthorizationHandler : IAuthorizationMiddlewareResultHandler
{
    private readonly AuthorizationMiddlewareResultHandler _default = new();

    public async Task HandleAsync(RequestDelegate next, HttpContext context, AuthorizationPolicy policy,
        PolicyAuthorizationResult result)
    {
        if (result.Forbidden)
        {
            var reason = result.AuthorizationFailure?.FailureReasons.FirstOrDefault()?.Message
                         ?? "You are not allowed to do this.";
            await ProblemResponses.WriteAsync(context, StatusCodes.Status403Forbidden, reason);
            return;
        }
        await _default.HandleAsync(next, context, policy, result);
    }
}
