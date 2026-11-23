using System.Text.Json;

namespace RoleCheck;

public static class Audience
{
    public static bool Includes(string audienceClaimJson, string expected)
    {
        try
        {
            using var document = JsonDocument.Parse(audienceClaimJson);
            var root = document.RootElement;
            return root.ValueKind switch
            {
                JsonValueKind.String => root.GetString() == expected,
                JsonValueKind.Array => root.EnumerateArray().Any(item => item.ValueKind == JsonValueKind.String && item.GetString() == expected),
                _ => false,
            };
        }
        catch (JsonException)
        {
            return false;
        }
    }
}
