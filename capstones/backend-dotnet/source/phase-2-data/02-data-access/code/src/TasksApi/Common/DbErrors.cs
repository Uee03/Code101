using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace TasksApi.Common;

// Turns a database error into the problem the contract promises.
public static class DbErrors
{
    // Custom SQLSTATE codes raised by the stored functions in db/schema.sql.
    public const string NotFound = "TS404";
    public const string RuleViolated = "TS409";
    public const string StaleVersion = "TS412";
    public const string InvalidInput = "TS422";

    public static ProblemException? Map(Exception exception)
    {
        if (exception is DbUpdateConcurrencyException)
        {
            return ProblemException.PreconditionFailed("The resource changed since you read it. Fetch it again and retry.");
        }
        for (var inner = exception; inner is not null; inner = inner.InnerException)
        {
            if (inner is PostgresException pg)
            {
                return pg.SqlState switch
                {
                    // Our own functions write messages meant for callers; Postgres messages are not shown.
                    NotFound => new ProblemException(StatusCodes.Status404NotFound, pg.MessageText),
                    RuleViolated => ProblemException.Conflict(pg.MessageText),
                    StaleVersion => ProblemException.PreconditionFailed(pg.MessageText),
                    InvalidInput => ProblemException.Unprocessable(pg.MessageText),
                    PostgresErrorCodes.UniqueViolation => ProblemException.Conflict("A resource with the same name or key already exists."),
                    PostgresErrorCodes.ForeignKeyViolation => ProblemException.Unprocessable("A referenced resource does not exist."),
                    PostgresErrorCodes.CheckViolation => ProblemException.Unprocessable("A value breaks a rule of the database."),
                    _ => null,
                };
            }
        }
        return null;
    }
}
