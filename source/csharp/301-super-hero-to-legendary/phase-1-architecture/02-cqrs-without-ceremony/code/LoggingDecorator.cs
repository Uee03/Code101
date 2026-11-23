namespace Ledger;

// A decorator wraps a handler of the same interface and adds one cross-cutting concern.
public sealed class LoggingDecorator<TCommand>(ICommandHandler<TCommand> inner, TextWriter output) : ICommandHandler<TCommand>
{
    public async Task<Result> HandleAsync(TCommand command, CancellationToken ct)
    {
        var result = await inner.HandleAsync(command, ct);
        var name = typeof(TCommand).Name;
        output.WriteLine(result.IsSuccess ? $"{name}: ok" : $"{name}: failed ({result.Error})");
        return result;
    }
}
