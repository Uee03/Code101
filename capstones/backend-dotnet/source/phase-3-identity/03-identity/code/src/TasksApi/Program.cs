using System.Security.Claims;
using System.Text.Json.Serialization;
using FastEndpoints;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Data;
using TasksApi.Security;

var builder = WebApplication.CreateBuilder(args);

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

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseAuthentication();
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
