namespace Outbox;

public static class SagaDemo
{
    public static async Task<bool> ShippingFailsAsync(Action<string> log)
    {
        // TODO: build three SagaStep values: reserve-stock and charge-payment succeed (their Compensate does nothing),
        // and ship-order throws new InvalidOperationException("carrier unavailable"). Run them with a SagaRunner
        // and return its result.
        await Task.CompletedTask;
        return true;
    }
}
