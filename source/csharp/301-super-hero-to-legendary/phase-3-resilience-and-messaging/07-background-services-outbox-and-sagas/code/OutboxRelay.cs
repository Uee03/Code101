using Microsoft.Extensions.Hosting;

namespace Outbox;

// Polls the outbox table and publishes what it finds. A row is marked processed only AFTER a successful publish.
public sealed class OutboxRelay(Database database, FlakyBroker broker) : BackgroundService
{
    private int failures;

    public int Failures => Volatile.Read(ref failures);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(50));
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    DrainOnce();
                }
                catch (BrokerException)
                {
                    // Leave the row unprocessed; the next tick tries again. Real code logs and counts this.
                    Interlocked.Increment(ref failures);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // The host is stopping. Unprocessed rows stay in the table for the next start.
        }
    }

    private void DrainOnce()
    {
        foreach (var message in database.ReadPending())
        {
            broker.Publish(message.Id);
            database.MarkProcessed(message.Id);
        }
    }
}
