using System.Diagnostics.CodeAnalysis;

public enum ErrorKind
{
    NotFound,
    Conflict,
}

public sealed record Error(ErrorKind Kind, string Code, string Message);

public sealed class Result<T>
{
    private Result(T? value, Error? error)
    {
        Value = value;
        Error = error;
    }

    public T? Value { get; }

    public Error? Error { get; }

    [MemberNotNullWhen(true, nameof(Value))]
    [MemberNotNullWhen(false, nameof(Error))]
    public bool IsSuccess => Error is null;

    public static Result<T> Ok(T value) => new(value, null);

    public static Result<T> Fail(Error error) => new(default, error);

    public Result<TOut> Map<TOut>(Func<T, TOut> convert)
    {
        // TODO: when this result failed, return a failed Result<TOut> with the same Error;
        // otherwise return Ok with convert(Value).
        throw new NotImplementedException();
    }

    public TOut Match<TOut>(Func<T, TOut> onOk, Func<Error, TOut> onError)
    {
        // TODO: call onOk with the value on success, onError with the error on failure.
        throw new NotImplementedException();
    }
}
