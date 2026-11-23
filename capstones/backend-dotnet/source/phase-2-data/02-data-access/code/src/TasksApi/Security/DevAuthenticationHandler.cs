using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace TasksApi.Security;

// A stand-in for real sign-in, used only in chapter 2: every request is alice, the admin, holding all three scopes.
// Chapter 3 deletes this class and validates real Keycloak tokens instead.
public sealed class DevAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger,
    UrlEncoder encoder) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Dev";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var identity = new ClaimsIdentity(
        [
            new Claim("sub", "a11ce000-0000-4000-8000-000000000001"),
            new Claim("preferred_username", "alice"),
            new Claim("email", "alice@tasksteams.test"),
            new Claim("name", "Alice Admin"),
            new Claim("scope", "openid tasks:read tasks:write tasks:admin"),
            new Claim("realm_access", """{"roles":["admin"]}""", "JSON"),
        ], SchemeName);
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
