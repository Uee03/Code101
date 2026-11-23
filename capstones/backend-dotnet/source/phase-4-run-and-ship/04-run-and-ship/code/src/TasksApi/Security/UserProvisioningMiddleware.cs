using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using TasksApi.Data;

namespace TasksApi.Security;

// Creates the users row the first time a signed-in user calls the API (R-03). Rows made for the three seed users already exist.
public sealed class UserProvisioningMiddleware(RequestDelegate next)
{
    private static readonly ConcurrentDictionary<Guid, bool> Known = new();

    public async Task InvokeAsync(HttpContext context, TasksDbContext db, CurrentUser user)
    {
        if (context.User.Identity?.IsAuthenticated == true && user.Id != Guid.Empty && !Known.ContainsKey(user.Id))
        {
            var username = Truncate(user.Username, 100);
            var email = user.Email ?? $"{user.Id}@users.invalid";
            var displayName = Truncate(user.DisplayName ?? user.Username, 120);
            await db.Database.ExecuteSqlAsync(
                $"""
                 INSERT INTO users (id, username, email, display_name)
                 VALUES ({user.Id}, {username}, {email}, {displayName})
                 ON CONFLICT DO NOTHING
                 """, context.RequestAborted);
            Known[user.Id] = true;
        }
        await next(context);
    }

    private static string Truncate(string value, int max) => value.Length <= max ? value : value[..max];
}
