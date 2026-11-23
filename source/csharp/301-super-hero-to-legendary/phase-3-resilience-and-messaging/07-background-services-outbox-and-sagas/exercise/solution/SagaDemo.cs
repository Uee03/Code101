namespace Outbox;

public static class SagaDemo
{
    public static async Task<bool> ShippingFailsAsync(Action<string> log)
    {
        var saga = new SagaRunner(log);
        return await saga.RunAsync(
        [
            new SagaStep("reserve-stock", () => Task.CompletedTask, () => Task.CompletedTask),
            new SagaStep("charge-payment", () => Task.CompletedTask, () => Task.CompletedTask),
            new SagaStep("ship-order", () => throw new InvalidOperationException("carrier unavailable"), () => Task.CompletedTask),
        ]);
    }
}
