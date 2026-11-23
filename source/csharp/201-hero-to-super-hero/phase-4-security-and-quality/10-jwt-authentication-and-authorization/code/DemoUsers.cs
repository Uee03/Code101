public sealed record DemoUser(string Role, string[] Permissions);

public static class DemoUsers
{
    public static readonly IReadOnlyDictionary<string, DemoUser> All = new Dictionary<string, DemoUser>
    {
        ["ada"] = new("user", ["notes:read"]),
        ["grace"] = new("user", ["notes:read", "notes:write"]),
        ["root"] = new("admin", ["notes:read", "notes:write"]),
    };
}
