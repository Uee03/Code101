using System.Text.Json;

namespace Outbox;

public sealed class OrderService(Database database)
{
    // The order row and the outbox row are written in ONE transaction: both happen or neither does.
    public long Place(string customer)
    {
        using var connection = database.Open();
        using var transaction = connection.BeginTransaction();

        using var insertOrder = connection.CreateCommand();
        insertOrder.Transaction = transaction;
        insertOrder.CommandText = "INSERT INTO orders (customer) VALUES ($customer) RETURNING id";
        insertOrder.Parameters.AddWithValue("$customer", customer);
        var orderId = (long)insertOrder.ExecuteScalar()!;

        using var insertMessage = connection.CreateCommand();
        insertMessage.Transaction = transaction;
        insertMessage.CommandText = "INSERT INTO outbox (type, payload) VALUES ('OrderPlaced', $payload)";
        insertMessage.Parameters.AddWithValue("$payload", JsonSerializer.Serialize(new { orderId, customer }));
        insertMessage.ExecuteNonQuery();

        transaction.Commit();
        return orderId;
    }
}
