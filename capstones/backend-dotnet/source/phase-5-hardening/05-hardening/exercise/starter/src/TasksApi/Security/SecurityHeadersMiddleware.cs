namespace TasksApi.Security;

// Adds the browser-facing protections to every response, including errors (OnStarting runs when the response begins).
public sealed class SecurityHeadersMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers.XContentTypeOptions = "nosniff";
            headers.XFrameOptions = "DENY";
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            headers["Referrer-Policy"] = "no-referrer";
            headers.CacheControl = "no-store";
            // TODO: also send  Permissions-Policy: geolocation=(), camera=(), microphone=()
            //       so a browser never lets this origin use those features.
            if (context.Request.IsHttps)
            {
                headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
            }
            return Task.CompletedTask;
        });
        return next(context);
    }
}
