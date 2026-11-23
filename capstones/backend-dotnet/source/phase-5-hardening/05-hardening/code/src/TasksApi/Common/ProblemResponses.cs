using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;
using FluentValidation.Results;
using Microsoft.AspNetCore.Diagnostics;

namespace TasksApi.Common;

public sealed record FieldError(string Pointer, string Detail);

// RFC 9457 problem details. Null members are left out of the JSON.
public sealed record ProblemBody(
    string Type,
    string Title,
    int Status,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Detail,
    string Instance,
    string TraceId,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] string? Code,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] IReadOnlyList<FieldError>? Errors);

public static class ProblemResponses
{
    private const string TypeBase = "https://code101.example/problems/";
    private const string ContentType = "application/problem+json";
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private static (string Slug, string Title) Describe(int status) => status switch
    {
        400 => ("bad-request", "Bad request"),
        401 => ("unauthorized", "Unauthorized"),
        403 => ("forbidden", "Forbidden"),
        404 => ("not-found", "Not found"),
        409 => ("conflict", "Conflict"),
        412 => ("precondition-failed", "Precondition failed"),
        405 => ("bad-request", "Method not allowed"),
        413 => ("payload-too-large", "Payload too large"),
        415 => ("bad-request", "Unsupported media type"),
        422 => ("validation-error", "Validation failed"),
        428 => ("precondition-required", "Precondition required"),
        429 => ("rate-limited", "Too many requests"),
        >= 500 => ("internal-error", "Internal server error"),
        _ => ("bad-request", "Request failed"),
    };

    public static ProblemBody Build(HttpContext context, int status, string? detail = null, string? code = null,
        IReadOnlyList<FieldError>? errors = null)
    {
        var (slug, title) = Describe(status);
        var traceId = Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier;
        return new ProblemBody(TypeBase + slug, title, status, detail, context.Request.Path, traceId, code, errors);
    }

    public static Task WriteAsync(HttpContext context, int status, string? detail = null, string? code = null,
        IReadOnlyList<FieldError>? errors = null)
    {
        context.Response.StatusCode = status;
        return context.Response.WriteAsJsonAsync(Build(context, status, detail, code, errors), Json, ContentType,
            context.RequestAborted);
    }

    // Called for responses that have a status code but no body, for example an unknown route (404).
    public static Task WriteStatusCodeAsync(StatusCodeContext context)
    {
        var http = context.HttpContext;
        return WriteAsync(http, http.Response.StatusCode);
    }

    // Plugged into FastEndpoints. A rule of ours that fails becomes a 422 with errors[]. A failure without an error code
    // did not come from our rules: the JSON, a route value or a query value could not be read, which is a 400.
    public static object ValidationProblem(List<ValidationFailure> failures, HttpContext context, int status)
    {
        if (failures.All(f => string.IsNullOrEmpty(f.ErrorCode)))
        {
            status = StatusCodes.Status400BadRequest;
            context.Response.StatusCode = status;
        }
        var errors = failures
            .Where(f => f.PropertyName != "SerializerErrors")
            .Select(f => new FieldError(ToPointer(f.PropertyName),
                status == StatusCodes.Status400BadRequest ? "is unknown or has the wrong type" : f.ErrorMessage))
            .ToList();
        var detail = status == StatusCodes.Status400BadRequest
            ? "The request could not be read: the JSON is malformed, or a field, path value or query value is unknown or has the wrong type."
            : "One or more fields are invalid.";
        return Build(context, status, detail, errors: errors.Count == 0 ? null : errors);
    }

    // "Name" becomes "/name", "Items[0].Title" becomes "/items[0]/title"; a failure about the whole body has no name and becomes "".
    private static string ToPointer(string propertyName) =>
        propertyName.Length == 0
            ? ""
            : "/" + string.Join('/', propertyName.Split('.').Select(JsonNamingPolicy.CamelCase.ConvertName));
}
