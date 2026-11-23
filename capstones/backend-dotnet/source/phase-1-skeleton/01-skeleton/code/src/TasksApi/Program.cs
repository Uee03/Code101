using System.Text.Json.Serialization;
using FastEndpoints;
using TasksApi.Common;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddFastEndpoints();
builder.Services.AddExceptionHandler<ProblemExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages(ProblemResponses.WriteStatusCodeAsync);
app.UseFastEndpoints(config =>
{
    config.Errors.StatusCode = StatusCodes.Status422UnprocessableEntity;
    config.Errors.ContentType = "application/problem+json";
    config.Errors.ResponseBuilder = ProblemResponses.ValidationProblem;
    config.Serializer.Options.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
});

app.Run();
