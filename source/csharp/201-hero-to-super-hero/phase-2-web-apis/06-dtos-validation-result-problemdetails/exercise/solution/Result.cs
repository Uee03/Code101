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
        if (!IsSuccess)
        {
            return Result<TOut>.Fail(Error);
        }

        return Result<TOut>.Ok(convert(Value));
    }

    public TOut Match<TOut>(Func<T, TOut> onOk, Func<Error, TOut> onError)
    {
        if (!IsSuccess)
        {
            return onError(Error);
        }

        return onOk(Value);
    }
}
