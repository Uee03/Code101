namespace Outbox;

public sealed class BrokerException(string message) : Exception(message);

// The consumer side. Delivery is at-least-once, so the consumer must be idempotent: the inbox remembers message ids.
public sealed class Inbox(Database database)
{
    private int handled;

    public int Handled => Volatile.Read(ref handled);

    public void Handle(long messageId)
    {
        using var connection = database.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "INSERT OR IGNORE INTO inbox (message_id) VALUES ($id)";
        command.Parameters.AddWithValue("$id", messageId);

        // One row inserted means "first time". The business effect belongs here, in the same transaction as this insert.
        if (command.ExecuteNonQuery() == 1)
        {
            Interlocked.Increment(ref handled);
        }
    }
}

// A fake message broker that misbehaves on purpose, once per message.
public sealed class FlakyBroker(Inbox inbox)
{
    private readonly object gate = new();
    private readonly HashSet<long> seen = [];
    private int rawDeliveries;

    public int RawDeliveries
    {
        get
        {
            lock (gate)
            {
                return rawDeliveries;
            }
        }
    }

    public void Publish(long messageId)
    {
        lock (gate)
        {
            var firstAttempt = seen.Add(messageId);

            // Message 1, first attempt: the broker is down and nothing is delivered.
            if (messageId == 1 && firstAttempt)
            {
                throw new BrokerException("broker unavailable");
            }

            rawDeliveries++;
            inbox.Handle(messageId);

            // Message 2, first attempt: delivered, but the acknowledgement is lost, so the publisher thinks it failed.
            if (messageId == 2 && firstAttempt)
            {
                throw new BrokerException("acknowledgement lost");
            }
        }
    }
}
