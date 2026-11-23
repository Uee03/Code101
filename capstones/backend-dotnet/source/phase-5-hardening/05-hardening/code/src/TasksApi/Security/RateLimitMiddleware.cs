using System.Collections.Concurrent;
using System.Security.Claims;
using Microsoft.Extensions.Options;
using TasksApi.Common;

namespace TasksApi.Security;

public sealed class RateLimitOptions
{
    public int AuthenticatedLimit { get; init; } = 100;
    public int AnonymousLimit { get; init; } = 30;
    public int WindowSeconds { get; init; } = 60;
}

// A fixed-window limiter: 100 requests per 60 seconds per signed-in user, 30 per client address when anonymous (R-14).
// ASP.NET Core also ships a limiter (AddRateLimiter), but it cannot tell us how many requests are left or when the
// window ends, and the contract wants RateLimit-Limit, RateLimit-Remaining and RateLimit-Reset on every response.
// The counters live in memory, so with several API instances each one counts separately; use a shared store then.
public sealed class RateLimitMiddleware(RequestDelegate next, IOptions<RateLimitOptions> options,
    ILogger<RateLimitMiddleware> logger, TimeProvider time)
{
    private sealed class Window(DateTimeOffset start)
    {
        public DateTimeOffset Start = start;
        public int Count;
    }

    private readonly RateLimitOptions _options = options.Value;
    private readonly ConcurrentDictionary<string, Window> _windows = new();
    private long _requests;

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path == "/health")
        {
            await next(context);
            return;
        }
        var subject = context.User.FindFirstValue("sub");
        var key = subject is null ? $"ip:{context.Connection.RemoteIpAddress}" : $"user:{subject}";
        var limit = subject is null ? _options.AnonymousLimit : _options.AuthenticatedLimit;
        var span = TimeSpan.FromSeconds(_options.WindowSeconds);
        var now = time.GetUtcNow();
        SweepSometimes(now, span);

        var window = _windows.GetOrAdd(key, _ => new Window(now));
        int count;
        DateTimeOffset start;
        lock (window)
        {
            if (now - window.Start >= span)
            {
                window.Start = now;
                window.Count = 0;
            }
            count = ++window.Count;
            start = window.Start;
        }
        var reset = Math.Max(1, (int)Math.Ceiling((start + span - now).TotalSeconds));
        var remaining = Math.Max(0, limit - count);
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers["RateLimit-Limit"] = limit.ToString();
            headers["RateLimit-Remaining"] = remaining.ToString();
            headers["RateLimit-Reset"] = reset.ToString();
            if (count > limit)
            {
                headers.RetryAfter = reset.ToString();
            }
            return Task.CompletedTask;
        });

        if (count > limit)
        {
            logger.LogWarning("Rate limit exceeded for {Key} on {Method} {Path}", key, context.Request.Method, context.Request.Path);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status429TooManyRequests,
                $"Too many requests. Try again in {reset} seconds.");
            return;
        }
        await next(context);
    }

    // Forget windows that ended long ago, so one-off visitors do not fill the dictionary forever.
    private void SweepSometimes(DateTimeOffset now, TimeSpan span)
    {
        if (Interlocked.Increment(ref _requests) % 1000 != 0)
        {
            return;
        }
        foreach (var (key, window) in _windows)
        {
            if (now - window.Start > span * 2)
            {
                _windows.TryRemove(key, out _);
            }
        }
    }
}
