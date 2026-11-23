using Polly.CircuitBreaker;
using Polly.RateLimiting;
using Polly.Timeout;
using Resilience;

var ct = CancellationToken.None;

// 1. Retry: the dependency fails twice, then works.
var flaky = new FlakyService(failuresBeforeSuccess: 2);
var retry = Pipelines.Retry(Console.WriteLine);
var answer = await retry.ExecuteAsync(async token => await flaky.CallAsync(token), ct);
Console.WriteLine($"retry demo: {answer} ({flaky.Calls} calls)");

// 2. Timeout: the work would take 5 seconds, the pipeline gives it 100 ms.
try
{
    await Pipelines.Timeout().ExecuteAsync(async token => await Task.Delay(TimeSpan.FromSeconds(5), token), ct);
}
catch (TimeoutRejectedException)
{
    Console.WriteLine("timeout demo: TimeoutRejectedException after the 100 ms limit");
}

// 3. Circuit breaker: the dependency is down. After 4 failures the circuit opens and calls 5 and 6 never reach it.
var provider = new CircuitBreakerStateProvider();
var breaker = Pipelines.CircuitBreaker(provider);
var down = new FlakyService(failuresBeforeSuccess: int.MaxValue);
for (var i = 1; i <= 6; i++)
{
    try
    {
        await breaker.ExecuteAsync(async token => await down.CallAsync(token), ct);
    }
    catch (TransientException)
    {
        Console.WriteLine($"breaker call {i}: dependency failed");
    }
    catch (BrokenCircuitException)
    {
        Console.WriteLine($"breaker call {i}: rejected without calling the dependency");
    }
}

Console.WriteLine($"dependency calls: {down.Calls}, circuit state: {provider.CircuitState}");

// After the break duration (1 second) the next call is a probe. A healthy answer closes the circuit.
await Task.Delay(TimeSpan.FromMilliseconds(1200), ct);
var healthy = new FlakyService(failuresBeforeSuccess: 0);
var probe = await breaker.ExecuteAsync(async token => await healthy.CallAsync(token), ct);
Console.WriteLine($"after the break duration: {probe}, circuit {provider.CircuitState}");

// 4. Bulkhead: five callers arrive together. Two run, one waits in the queue, two are turned away.
var bulkhead = Pipelines.Bulkhead();
var callers = Enumerable.Range(1, 5).Select(async _ =>
{
    try
    {
        await bulkhead.ExecuteAsync(async token => await Task.Delay(200, token), ct);
        return true;
    }
    catch (RateLimiterRejectedException)
    {
        return false;
    }
});
var outcomes = await Task.WhenAll(callers);
Console.WriteLine($"bulkhead: {outcomes.Count(done => done)} completed, {outcomes.Count(done => !done)} rejected");

// 5. All together, in the recommended order.
var combinedFlaky = new FlakyService(failuresBeforeSuccess: 2);
var combined = await Pipelines.Combined().ExecuteAsync(async token => await combinedFlaky.CallAsync(token), ct);
Console.WriteLine($"combined demo: {combined}");
