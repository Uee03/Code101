using System.Diagnostics;
using System.Security.Claims;

namespace TasksApi.Common;

// One log line per request, as structured fields: method, path, status, time, user id and trace id.
// It logs the path but never the query string, headers or body, so tokens, search terms and personal data stay out of the logs.
public sealed class RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var started = Stopwatch.GetTimestamp();
        try
        {
            await next(context);
        }
        finally
        {
            logger.LogInformation("{Method} {Path} {Status} {ElapsedMs}ms user={UserId} trace={TraceId}",
                context.Request.Method, context.Request.Path.Value, context.Response.StatusCode,
                (long)Stopwatch.GetElapsedTime(started).TotalMilliseconds,
                context.User.FindFirstValue("sub") ?? "-", Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier);
        }
    }
}
