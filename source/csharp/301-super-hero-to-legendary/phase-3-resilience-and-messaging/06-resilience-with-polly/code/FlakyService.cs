namespace Resilience;

public sealed class TransientException(string message) : Exception(message);

// A dependency that fails a fixed number of times and then works.
public sealed class FlakyService(int failuresBeforeSuccess)
{
    private int calls;

    public int Calls => Volatile.Read(ref calls);

    public Task<string> CallAsync(CancellationToken ct)
    {
        var call = Interlocked.Increment(ref calls);
        if (call <= failuresBeforeSuccess)
        {
            throw new TransientException($"call {call} failed");
        }

        return Task.FromResult($"ok on call {call}");
    }
}
