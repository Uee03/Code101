using Microsoft.Data.Sqlite;

namespace Outbox;

public sealed record OutboxMessage(long Id, string Type, string Payload);

public sealed class Database(string connectionString)
{
    public SqliteConnection Open()
    {
        var connection = new SqliteConnection(connectionString);
        connection.Open();
        return connection;
    }

    public void CreateSchema()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = """
            CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS outbox (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                payload TEXT NOT NULL,
                processed INTEGER NOT NULL DEFAULT 0);
            CREATE TABLE IF NOT EXISTS inbox (message_id INTEGER PRIMARY KEY);
            """;
        command.ExecuteNonQuery();
    }

    public long CountUnprocessed()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM outbox WHERE processed = 0";
        return (long)command.ExecuteScalar()!;
    }

    public List<OutboxMessage> ReadPending()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, type, payload FROM outbox WHERE processed = 0 ORDER BY id LIMIT 10";
        using var reader = command.ExecuteReader();
        var messages = new List<OutboxMessage>();
        while (reader.Read())
        {
            messages.Add(new OutboxMessage(reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
        }

        return messages;
    }

    public void MarkProcessed(long messageId)
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE outbox SET processed = 1 WHERE id = $id";
        command.Parameters.AddWithValue("$id", messageId);
        command.ExecuteNonQuery();
    }
}
