using System.Security.Claims;
using System.Text.Json;

namespace TasksApi.Security;

// The caller, read from the claims of the access token (or of the stand-in identity in chapter 2).
public sealed class CurrentUser
{
    public Guid Id { get; private init; }
    public string Username { get; private init; } = "";
    public string? Email { get; private init; }
    public string? DisplayName { get; private init; }
    public IReadOnlySet<string> Roles { get; private init; } = new HashSet<string>();
    public IReadOnlySet<string> Scopes { get; private init; } = new HashSet<string>();

    public bool IsAdmin => Roles.Contains("admin");

    public static CurrentUser From(ClaimsPrincipal principal)
    {
        var subject = principal.FindFirstValue("sub");
        return new CurrentUser
        {
            Id = Guid.TryParse(subject, out var id) ? id : Guid.Empty,
            Username = principal.FindFirstValue("preferred_username") ?? subject ?? "",
            Email = principal.FindFirstValue("email"),
            DisplayName = principal.FindFirstValue("name"),
            Roles = RealmRoles(principal.FindFirstValue("realm_access")),
            Scopes = (principal.FindFirstValue("scope") ?? "").Split(' ', StringSplitOptions.RemoveEmptyEntries).ToHashSet(),
        };
    }

    // Keycloak puts realm roles in the claim realm_access, a JSON object: {"roles":["admin"]}.
    private static HashSet<string> RealmRoles(string? realmAccess)
    {
        var roles = new HashSet<string>();
        if (string.IsNullOrEmpty(realmAccess))
        {
            return roles;
        }
        using var document = JsonDocument.Parse(realmAccess);
        if (document.RootElement.TryGetProperty("roles", out var list) && list.ValueKind == JsonValueKind.Array)
        {
            foreach (var role in list.EnumerateArray())
            {
                if (role.GetString() is { } name)
                {
                    roles.Add(name);
                }
            }
        }
        return roles;
    }
}
