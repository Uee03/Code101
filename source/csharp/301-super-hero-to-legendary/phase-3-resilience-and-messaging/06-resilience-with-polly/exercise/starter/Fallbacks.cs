using Polly;

namespace Resilience;

public static class Fallbacks
{
    public static ResiliencePipeline<string> Create()
    {
        // TODO: AddFallback(new FallbackStrategyOptions<string> { ... }) so that a TransientException is replaced
        // by the text "default price list". Use PredicateBuilder<string>().Handle<TransientException>() and
        // FallbackAction = _ => Outcome.FromResultAsValueTask("...").
        return new ResiliencePipelineBuilder<string>().Build();
    }
}
