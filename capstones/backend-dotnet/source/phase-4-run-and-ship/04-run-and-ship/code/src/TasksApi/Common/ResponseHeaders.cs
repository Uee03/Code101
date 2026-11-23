namespace TasksApi.Common;

public static class ResponseHeaders
{
    // Sets Location and, for versioned resources, ETag; adds Idempotent-Replayed when the answer is a replay.
    public static void Created(HttpContext http, string path, int? version, bool replayed)
    {
        http.Response.Headers.Location = $"{http.Request.Scheme}://{http.Request.Host}{path}";
        if (version is { } v)
        {
            ETags.Set(http, v);
        }
        if (replayed)
        {
            http.Response.Headers["Idempotent-Replayed"] = "true";
        }
    }
}
