using Polly;
using Polly.Fallback;

namespace Resilience;

public static class Fallbacks
{
    public static ResiliencePipeline<string> Create() =>
        new ResiliencePipelineBuilder<string>()
            .AddFallback(new FallbackStrategyOptions<string>
            {
                ShouldHandle = new PredicateBuilder<string>().Handle<TransientException>(),
                FallbackAction = _ => Outcome.FromResultAsValueTask("default price list"),
            })
            .Build();
}
