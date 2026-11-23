using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using TasksApi.Contracts;
using TasksApi.Data;

namespace TasksApi.Common;

// What a cursor holds: the sort value of the last item (when the sort has one) and its id.
public sealed record CursorData(string? Value, string Id);

// Keyset pagination: "give me the rows after the last one you saw", which stays stable while rows are added.
public static class Paging
{
    public const int DefaultLimit = 25;
    public const int MaxLimit = 100;

    public static int CheckLimit(int? limit) => limit switch
    {
        null => DefaultLimit,
        >= 1 and <= MaxLimit => limit.Value,
        _ => throw ProblemException.BadRequest($"limit must be between 1 and {MaxLimit}."),
    };

    // sort is "-createdAt" (the default), "createdAt", or any value in extra.
    public static string CheckSort(string? sort, params string[] extra)
    {
        sort ??= "-createdAt";
        return sort is "-createdAt" or "createdAt" || extra.Contains(sort)
            ? sort
            : throw ProblemException.BadRequest("sort is not one of the allowed values.");
    }

    public static string Encode(string? value, string id) =>
        WebEncoders.Base64UrlEncode(JsonSerializer.SerializeToUtf8Bytes(new CursorData(value, id), JsonSerializerOptions.Web));

    public static CursorData Decode(string cursor)
    {
        try
        {
            var data = JsonSerializer.Deserialize<CursorData>(WebEncoders.Base64UrlDecode(cursor), JsonSerializerOptions.Web);
            return data is { Id.Length: > 0 } ? data : throw new FormatException();
        }
        catch (Exception ex) when (ex is FormatException or JsonException)
        {
            throw ProblemException.BadRequest("The cursor is not valid.");
        }
    }

    public static string FormatTime(DateTimeOffset value) => value.UtcDateTime.ToString("O", CultureInfo.InvariantCulture);

    public static string CreatedCursor(DateTimeOffset createdAt, Guid id) => Encode(FormatTime(createdAt), id.ToString());

    public static DateTimeOffset ParseTime(string? value) =>
        DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var time)
            ? time
            : throw ProblemException.BadRequest("The cursor is not valid.");

    public static Guid ParseId(string id) =>
        Guid.TryParse(id, out var guid) ? guid : throw ProblemException.BadRequest("The cursor is not valid.");

    // Rows after the cursor in createdAt order, ties broken by id.
    public static IQueryable<T> AfterCreatedCursor<T>(this IQueryable<T> query, string? cursor, bool descending)
        where T : class, ICreated
    {
        if (cursor is null)
        {
            return query;
        }
        var data = Decode(cursor);
        var at = ParseTime(data.Value);
        var id = ParseId(data.Id);
        return descending
            ? query.Where(x => x.CreatedAt < at || (x.CreatedAt == at && x.Id.CompareTo(id) < 0))
            : query.Where(x => x.CreatedAt > at || (x.CreatedAt == at && x.Id.CompareTo(id) > 0));
    }

    public static IOrderedQueryable<T> OrderByCreated<T>(this IQueryable<T> query, bool descending)
        where T : class, ICreated =>
        descending
            ? query.OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id)
            : query.OrderBy(x => x.CreatedAt).ThenBy(x => x.Id);

    // Reads limit + 1 rows: the extra row only tells us whether another page exists.
    public static async Task<Paged<TDto>> ToPageAsync<TRow, TDto>(IQueryable<TRow> ordered, int limit,
        Func<TRow, string> cursorOf, Func<TRow, TDto> map, CancellationToken ct)
    {
        var rows = await ordered.Take(limit + 1).ToListAsync(ct);
        var next = rows.Count > limit ? cursorOf(rows[limit - 1]) : null;
        return new Paged<TDto>(rows.Take(limit).Select(map).ToList(), new PageInfo(limit, next));
    }

    public static Task<Paged<T>> ToPageAsync<T>(IQueryable<T> ordered, int limit, Func<T, string> cursorOf,
        CancellationToken ct) =>
        ToPageAsync(ordered, limit, cursorOf, row => row, ct);
}
