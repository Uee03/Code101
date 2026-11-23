using Polly;
using Polly.CircuitBreaker;
using Polly.RateLimiting;
using Polly.Retry;

namespace Resilience;

public static class Pipelines
{
    private static RetryStrategyOptions RetryOptions(Action<string> log) => new()
    {
        MaxRetryAttempts = 3,
        Delay = TimeSpan.FromMilliseconds(20),
        BackoffType = DelayBackoffType.Exponential,
        UseJitter = false,
        ShouldHandle = new PredicateBuilder().Handle<TransientException>(),
        OnRetry = args =>
        {
            log($"retry {args.AttemptNumber + 1} after {args.Outcome.Exception?.Message}");
            return default;
        },
    };

    private static CircuitBreakerStrategyOptions BreakerOptions(int minimumThroughput, CircuitBreakerStateProvider? provider) => new()
    {
        FailureRatio = 0.5,
        MinimumThroughput = minimumThroughput,
        SamplingDuration = TimeSpan.FromSeconds(10),
        BreakDuration = TimeSpan.FromSeconds(1),
        ShouldHandle = new PredicateBuilder().Handle<TransientException>(),
        StateProvider = provider,
    };

    // Retry: ask again after a growing delay. Jitter is off here only so the demo is repeatable; turn it on in production.
    public static ResiliencePipeline Retry(Action<string> log) =>
        new ResiliencePipelineBuilder().AddRetry(RetryOptions(log)).Build();

    // Timeout: stop waiting after a fixed time by cancelling the token you pass to the work.
    public static ResiliencePipeline Timeout() =>
        new ResiliencePipelineBuilder().AddTimeout(TimeSpan.FromMilliseconds(100)).Build();

    // Circuit breaker: after enough recent failures, stop calling the dependency for a while.
    public static ResiliencePipeline CircuitBreaker(CircuitBreakerStateProvider provider) =>
        new ResiliencePipelineBuilder().AddCircuitBreaker(BreakerOptions(4, provider)).Build();

    // Bulkhead: at most 2 calls run at once, 1 may wait, everything else is rejected immediately.
    public static ResiliencePipeline Bulkhead() =>
        new ResiliencePipelineBuilder().AddConcurrencyLimiter(permitLimit: 2, queueLimit: 1).Build();

    // The order matters: the first strategy added is the outermost one.
    public static ResiliencePipeline Combined() =>
        new ResiliencePipelineBuilder()
            .AddConcurrencyLimiter(permitLimit: 10, queueLimit: 10)
            .AddTimeout(TimeSpan.FromSeconds(2))
            .AddRetry(RetryOptions(_ => { }))
            .AddCircuitBreaker(BreakerOptions(10, null))
            .AddTimeout(TimeSpan.FromMilliseconds(200))
            .Build();
}
