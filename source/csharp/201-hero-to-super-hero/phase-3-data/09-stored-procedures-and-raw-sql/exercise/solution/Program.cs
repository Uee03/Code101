using Dapper;
using Microsoft.EntityFrameworkCore;
using Npgsql;

string connectionString = Environment.GetEnvironmentVariable("NOTES_CONNECTION")
    ?? throw new InvalidOperationException("Set the NOTES_CONNECTION environment variable (see .env.example).");

await using var connection = new NpgsqlConnection(connectionString);

// Start from a known state so that every run prints the same numbers.
await connection.ExecuteAsync("UPDATE notes SET archived = false");

IEnumerable<NoteRow> found = await connection.QueryAsync<NoteRow>(
    "SELECT id, title, archived FROM search_notes(@term)",
    new { term = "milk" });
Console.WriteLine($"Dapper search 'milk': {string.Join(", ", found.Select(n => n.Title))}");

await connection.ExecuteAsync("CALL archive_notes_older_than(@days)", new { days = 30 });
long archivedCount = await connection.ExecuteScalarAsync<long>("SELECT count(*) FROM notes WHERE archived");
Console.WriteLine($"Archived after CALL: {archivedCount}");

await using var context = new RawContext(connectionString);

string term = "report";
List<NoteRow> viaEf = await context.Database
    .SqlQuery<NoteRow>($"""SELECT id AS "Id", title AS "Title", archived AS "Archived" FROM search_notes({term})""")
    .ToListAsync();
Console.WriteLine($"EF SqlQuery 'report': {string.Join(", ", viaEf.Select(n => n.Title))}");

int olderThanDays = 5;
await context.Database.ExecuteSqlAsync($"CALL archive_notes_older_than({olderThanDays})");
archivedCount = await connection.ExecuteScalarAsync<long>("SELECT count(*) FROM notes WHERE archived");
Console.WriteLine($"Archived after EF CALL: {archivedCount}");

string hostile = "x' OR '1'='1";

// NEVER do this: the text becomes part of the SQL command itself.
string unsafeSql = "SELECT id, title, archived FROM notes WHERE title = '" + hostile + "'";
List<NoteRow> leaked = (await connection.QueryAsync<NoteRow>(unsafeSql)).ToList();
Console.WriteLine($"Unsafe concatenation returned {leaked.Count} rows");

List<NoteRow> safe = (await connection.QueryAsync<NoteRow>(
    "SELECT id, title, archived FROM notes WHERE title = @title",
    new { title = hostile })).ToList();
Console.WriteLine($"Parameterized query returned {safe.Count} rows");

IEnumerable<NoteRow> calls = await connection.QueryAsync<NoteRow>(
    "SELECT id, title, archived FROM search_notes(@term)",
    new { term = "call" });
Console.WriteLine($"Dapper search 'call': {string.Join(", ", calls.Select(n => n.Title))}");

string pattern = "%milk%";
int milkCount = await context.Database
    .SqlQuery<int>($"""SELECT count(*)::int AS "Value" FROM notes WHERE title ILIKE {pattern}""")
    .SingleAsync();
Console.WriteLine($"Notes about milk: {milkCount}");

List<NoteRow> viaEfSafe = await context.Database
    .SqlQuery<NoteRow>($"""SELECT id AS "Id", title AS "Title", archived AS "Archived" FROM notes WHERE title = {hostile}""")
    .ToListAsync();
Console.WriteLine($"EF parameterized query returned {viaEfSafe.Count} rows");
