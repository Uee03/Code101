namespace Ledger;

// A command changes state and answers only "did it work?". It never returns data to display.
public interface ICommandHandler<in TCommand>
{
    Task<Result> HandleAsync(TCommand command, CancellationToken ct);
}

// A query returns data and must not change state.
public interface IQueryHandler<in TQuery, TResult>
{
    Task<TResult> HandleAsync(TQuery query, CancellationToken ct);
}
