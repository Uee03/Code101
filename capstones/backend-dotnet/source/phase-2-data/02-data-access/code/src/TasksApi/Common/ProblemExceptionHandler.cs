using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed class ProblemExceptionHandler(ILogger<ProblemExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext context, Exception exception, CancellationToken cancellationToken)
    {
        var problem = exception as ProblemException ?? DbErrors.Map(exception);
        if (problem is not null)
        {
            await ProblemResponses.WriteAsync(context, problem.Status, problem.Message, problem.Code);
        }
        else if (exception is BadHttpRequestException bad)
        {
            await ProblemResponses.WriteAsync(context, bad.StatusCode, "The request could not be read.");
        }
        else
        {
            logger.LogError(exception, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
            await ProblemResponses.WriteAsync(context, StatusCodes.Status500InternalServerError, "An unexpected error occurred.");
        }
        return true;
    }
}
