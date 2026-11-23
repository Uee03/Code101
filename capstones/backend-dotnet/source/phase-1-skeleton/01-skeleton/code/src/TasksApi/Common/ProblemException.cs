namespace TasksApi.Common;

// Thrown from anywhere in the request pipeline; ProblemExceptionHandler turns it into an RFC 9457 response.
public sealed class ProblemException(int status, string detail, string? code = null) : Exception(detail)
{
    public int Status { get; } = status;
    public string? Code { get; } = code;

    public static ProblemException BadRequest(string detail) => new(StatusCodes.Status400BadRequest, detail);
    public static ProblemException NotFound(string what) => new(StatusCodes.Status404NotFound, $"{what} was not found.");
    public static ProblemException Forbidden(string detail) => new(StatusCodes.Status403Forbidden, detail);
    public static ProblemException Conflict(string detail, string? code = null) => new(StatusCodes.Status409Conflict, detail, code);
    public static ProblemException Unprocessable(string detail) => new(StatusCodes.Status422UnprocessableEntity, detail);
    public static ProblemException PreconditionFailed(string detail) => new(StatusCodes.Status412PreconditionFailed, detail);
    public static ProblemException PreconditionRequired() =>
        new(StatusCodes.Status428PreconditionRequired, "The If-Match header is required for this request.");
}
