namespace Outbox;

public sealed record SagaStep(string Name, Func<Task> Execute, Func<Task> Compensate);

// An orchestrated saga: run the steps in order; if one fails, undo the finished ones in reverse order.
public sealed class SagaRunner(Action<string> log)
{
    public async Task<bool> RunAsync(IReadOnlyList<SagaStep> steps)
    {
        var finished = new Stack<SagaStep>();
        foreach (var step in steps)
        {
            try
            {
                log($"saga step: {step.Name}");
                await step.Execute();
                finished.Push(step);
            }
            catch (Exception ex)
            {
                log($"saga step {step.Name} failed: {ex.Message}");
                while (finished.Count > 0)
                {
                    var undo = finished.Pop();
                    log($"saga compensate: {undo.Name}");
                    await undo.Compensate();
                }

                return false;
            }
        }

        return true;
    }
}
