using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using TasksApi.Common;
using TasksApi.Security;

namespace TasksApi.Data;

// Idempotency-Key support for the create operations. The key row is written inside the same transaction as the new
// resource, so either both exist or neither does. A second request with the same key waits on the first one's row,
// then finds the stored response and replays it.
public sealed class Idempotency(TasksDbContext db, CurrentUser user)
{
    public async Task<(T Value, bool Replayed)> RunAsync<T>(HttpContext http, string? key, object request,
        Func<Task<T>> create, CancellationToken ct)
    {
        await using var transaction = await db.BeginWriteAsync(user.Id, ct);
        if (key is not null)
        {
            var hash = Hash(http, request);
            var stored = await ReserveAsync(key, hash, ct);
            if (stored is not null)
            {
                return (JsonSerializer.Deserialize<T>(stored, JsonSerializerOptions.Web)!, true);
            }
            var created = await create();
            var body = JsonSerializer.Serialize(created, JsonSerializerOptions.Web);
            await db.Database.ExecuteSqlAsync(
                $"UPDATE idempotency_keys SET status_code = 201, response_body = {body}::jsonb WHERE user_id = {user.Id} AND key = {key}",
                ct);
            await transaction.CommitAsync(ct);
            return (created, false);
        }
        var value = await create();
        await transaction.CommitAsync(ct);
        return (value, false);
    }

    // Returns the stored response body for a replay, or null when this request is the first one with the key.
    private async Task<string?> ReserveAsync(string key, string hash, CancellationToken ct)
    {
        if (key.Length is < 8 or > 128)
        {
            throw ProblemException.Unprocessable("The Idempotency-Key must be 8 to 128 characters long.");
        }
        // A key whose 24 hours are over counts as new: the upsert resets it.
        var reserved = await db.Database.ExecuteSqlAsync(
            $"""
             INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES ({user.Id}, {key}, {hash})
             ON CONFLICT (user_id, key) DO UPDATE
                SET request_hash = EXCLUDED.request_hash, status_code = NULL, response_body = NULL,
                    created_at = now(), expires_at = now() + interval '24 hours'
              WHERE idempotency_keys.expires_at < now()
             """, ct);
        if (reserved == 1)
        {
            return null;
        }
        var row = await db.IdempotencyKeys.AsNoTracking().SingleAsync(k => k.UserId == user.Id && k.Key == key, ct);
        if (row.RequestHash != hash)
        {
            throw ProblemException.Unprocessable("The Idempotency-Key was already used with a different request.");
        }
        return row.ResponseBody ?? throw ProblemException.Conflict("A request with this Idempotency-Key is still being processed.");
    }

    private static string Hash(HttpContext http, object request)
    {
        var text = $"{http.Request.Method} {http.Request.Path}\n{JsonSerializer.Serialize(request, request.GetType(), JsonSerializerOptions.Web)}";
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text)));
    }
}
