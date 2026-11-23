using System.Globalization;

namespace TasksApi.Common;

// A strong ETag is the quoted row version, for example "3". If-Match carries the version the client last saw.
public static class ETags
{
    public static string Format(int version) => $"\"{version}\"";

    public static void Set(HttpContext context, int version) => context.Response.Headers.ETag = Format(version);

    // Missing header: 428. Anything that is not a quoted number: 400.
    public static int RequireIfMatch(string? ifMatch)
    {
        if (string.IsNullOrWhiteSpace(ifMatch))
        {
            throw ProblemException.PreconditionRequired();
        }
        var text = ifMatch.Trim();
        if (text.Length > 2 && text[0] == '"' && text[^1] == '"'
            && int.TryParse(text.AsSpan(1, text.Length - 2), NumberStyles.None, CultureInfo.InvariantCulture, out var version))
        {
            return version;
        }
        throw ProblemException.BadRequest("If-Match must be an ETag from this API, for example \"3\".");
    }

    public static void EnsureCurrent(int current, int expected, string what)
    {
        if (current != expected)
        {
            throw ProblemException.PreconditionFailed($"The {what} changed since you read it (current version {current}).");
        }
    }

    // True when the client already holds this version (If-None-Match), so the server can answer 304.
    public static bool IsNotModified(string? ifNoneMatch, int version) =>
        ifNoneMatch is not null && ifNoneMatch.Split(',').Any(tag => tag.Trim() == Format(version));
}
