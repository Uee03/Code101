using System.Text.Json;

namespace RoleCheck;

public static class Audience
{
    // TODO: return true when the "aud" claim, given as JSON text, names the expected audience.
    // A JWT "aud" claim is either a JSON string or a JSON array of strings. Anything else, or invalid JSON, means false.
    public static bool Includes(string audienceClaimJson, string expected)
    {
        return false;
    }
}
