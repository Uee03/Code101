using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed class ProblemExceptionHandler(ILogger<ProblemExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        switch (exception)
        {
            case ProblemException problem:
                await ProblemResponses.WriteAsync(context, problem.Status, problem.Message, problem.Code);
                break;
            case BadHttpRequestException bad:
                await ProblemResponses.WriteAsync(context, bad.StatusCode, "The request could not be read.");
                break;
            default:
                logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
                await ProblemResponses.WriteAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
                break;
        }
        return true;
    }
}
