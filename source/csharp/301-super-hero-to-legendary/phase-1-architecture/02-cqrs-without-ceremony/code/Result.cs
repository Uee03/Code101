namespace Ledger;

public readonly record struct Result(bool IsSuccess, string? Error)
{
    public static Result Ok() => new(true, null);

    public static Result Fail(string error) => new(false, error);
}
