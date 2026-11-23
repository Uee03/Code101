using System.Security.Claims;
using System.Text.Json.Serialization;
using FastEndpoints;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

var builder = WebApplication.CreateBuilder(args);

// Logs as one JSON object per line, easy for a log collector to read. Request logging adds the user id and trace id.
builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();

// Limits that stop one client from using all the server's memory or connections (OWASP API4).
builder.WebHost.ConfigureKestrel(kestrel =>
{
    kestrel.AddServerHeader = false;
    kestrel.Limits.MaxRequestBodySize = 1_048_576;
    kestrel.Limits.MaxRequestHeadersTotalSize = 32 * 1024;
    kestrel.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(15);
});

builder.Services.AddDbContext<TasksDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddHttpContextAccessor();
// FastEndpoints creates every endpoint once at startup, when there is no request yet, so the user may be missing here.
builder.Services.AddScoped(services =>
    CurrentUser.From(services.GetRequiredService<IHttpContextAccessor>().HttpContext?.User ?? new ClaimsPrincipal()));
builder.Services.AddScoped<TeamAccess>();
builder.Services.AddScoped<Idempotency>();

builder.Services.AddKeycloakJwt(builder.Configuration);
builder.Services.AddAuthorization(AccessPolicies.Add);
builder.Services.AddSingleton<IAuthorizationHandler, TokenRequirementHandler>();
builder.Services.AddSingleton<IAuthorizationMiddlewareResultHandler, ProblemAuthorizationHandler>();

builder.Services.Configure<RateLimitOptions>(builder.Configuration.GetSection("RateLimit"));
builder.Services.AddSingleton(TimeProvider.System);

// Only the two local web clients may call the API from a browser.
builder.Services.AddCors(cors => cors.AddDefaultPolicy(policy => policy
    .WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [])
    .WithMethods("GET", "POST", "PUT", "PATCH", "DELETE")
    .WithHeaders("Authorization", "Content-Type", "If-Match", "If-None-Match", "Idempotency-Key")
    .WithExposedHeaders("ETag", "Location", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset", "Retry-After",
        "Idempotent-Replayed")));

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseCors();
app.UseAuthentication();
app.UseMiddleware<RateLimitMiddleware>();
app.UseAuthorization();
app.UseMiddleware<UserProvisioningMiddleware>();
app.UseFastEndpoints(config =>
{
    config.Errors.StatusCode = StatusCodes.Status422UnprocessableEntity;
    config.Errors.ContentType = "application/problem+json";
    config.Errors.ResponseBuilder = ProblemResponses.ValidationProblem;
    config.Serializer.Options.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
});

app.Run();
