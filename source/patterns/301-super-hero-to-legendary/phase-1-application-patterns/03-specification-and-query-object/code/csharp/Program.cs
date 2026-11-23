var tasks = new List<TaskItem>
{
    new(1, "Write ADR", "todo", "alice", "2026-03-05"),
    new(2, "Review PR", "in_progress", "alice", "2026-03-02"),
    new(3, "Ship release", "todo", "bob", "2026-03-20"),
    new(4, "Fix login bug", "blocked", "carol", "2026-03-01"),
    new(5, "Plan sprint", "done", "alice", "2026-02-20"),
};

var queryA = new TaskQuery(Statuses: ["todo", "in_progress"], Assignee: "alice", DueBefore: "2026-03-10");
var (sql, parameters) = queryA.ToSql();
Console.WriteLine($"query A sql: {sql}");
Console.WriteLine($"query A params: {Show(parameters)}");
Console.WriteLine($"query A result: {Ids(queryA.RunInMemory(tasks))}");

var queryB = new TaskQuery(Text: "x; DROP TABLE tasks; --");
(sql, parameters) = queryB.ToSql();
Console.WriteLine($"query B sql: {sql}");
Console.WriteLine($"query B params: {Show(parameters)}");
Console.WriteLine($"query B result: {Ids(queryB.RunInMemory(tasks))}");

var overdue = new DueBeforeSpec("2026-03-03").And(new StatusSpec("done").Not());
Console.WriteLine($"overdue sql: {overdue.ToSql().Sql}");
Console.WriteLine($"overdue result: {Ids(tasks.Where(overdue.Matches))}");

var longTitles = new PredicateSpec(t => t.Title.Length > 10);
Console.WriteLine($"long titles in memory: {Ids(tasks.Where(longTitles.Matches))}");
try
{
    longTitles.ToSql();
}
catch (NotTranslatableException error)
{
    Console.WriteLine($"long titles to sql: {error.Message}");
}

try
{
    new TaskQuery(Sort: "due; DROP TABLE tasks").ToSql();
}
catch (ArgumentException error)
{
    Console.WriteLine($"bad sort: {error.Message}");
}

static string Show(List<object> values) =>
    "[" + string.Join(", ", values.Select(p => p is string s ? $"'{s}'" : p.ToString())) + "]";

static string Ids(IEnumerable<TaskItem> found) =>
    "[" + string.Join(", ", found.Select(t => t.Id)) + "]";

public sealed record TaskItem(int Id, string Title, string Status, string Assignee, string Due);

public sealed class NotTranslatableException(string message) : Exception(message);

public abstract class Spec
{
    public abstract bool Matches(TaskItem task);

    public abstract (string Sql, List<object> Params) ToSql();

    public Spec And(Spec other) => new CombinedSpec("AND", this, other);

    public Spec Or(Spec other) => new CombinedSpec("OR", this, other);

    public Spec Not() => new NotSpec(this);
}

public sealed class AllSpec : Spec
{
    public override bool Matches(TaskItem task) => true;

    public override (string Sql, List<object> Params) ToSql() => ("1 = 1", new List<object>());
}

public sealed class StatusSpec(string status) : Spec
{
    public override bool Matches(TaskItem task) => task.Status == status;

    public override (string Sql, List<object> Params) ToSql() => ("status = ?", new List<object> { status });
}

public sealed class AssigneeSpec(string assignee) : Spec
{
    public override bool Matches(TaskItem task) => task.Assignee == assignee;

    public override (string Sql, List<object> Params) ToSql() => ("assignee = ?", new List<object> { assignee });
}

public sealed class DueBeforeSpec(string day) : Spec
{
    public override bool Matches(TaskItem task) => string.CompareOrdinal(task.Due, day) < 0;

    public override (string Sql, List<object> Params) ToSql() => ("due < ?", new List<object> { day });
}

public sealed class TitleSpec(string text) : Spec
{
    private readonly string _text = text.ToLowerInvariant();

    public override bool Matches(TaskItem task) => task.Title.ToLowerInvariant().Contains(_text);

    public override (string Sql, List<object> Params) ToSql() => ("lower(title) LIKE ?", new List<object> { $"%{_text}%" });
}

public sealed class PredicateSpec(Func<TaskItem, bool> test) : Spec
{
    public override bool Matches(TaskItem task) => test(task);

    public override (string Sql, List<object> Params) ToSql() =>
        throw new NotTranslatableException("Predicate cannot be turned into SQL");
}

public sealed class CombinedSpec(string op, Spec left, Spec right) : Spec
{
    public override bool Matches(TaskItem task) =>
        op == "AND" ? left.Matches(task) && right.Matches(task) : left.Matches(task) || right.Matches(task);

    public override (string Sql, List<object> Params) ToSql()
    {
        var (leftSql, leftParams) = left.ToSql();
        var (rightSql, rightParams) = right.ToSql();
        return ($"({leftSql} {op} {rightSql})", leftParams.Concat(rightParams).ToList());
    }
}

public sealed class NotSpec(Spec inner) : Spec
{
    public override bool Matches(TaskItem task) => !inner.Matches(task);

    public override (string Sql, List<object> Params) ToSql()
    {
        var (sql, parameters) = inner.ToSql();
        return ($"NOT ({sql})", parameters);
    }
}

public sealed record TaskQuery(
    string[]? Statuses = null,
    string? Assignee = null,
    string? DueBefore = null,
    string? Text = null,
    string Sort = "due",
    int Limit = 10)
{
    private static readonly Dictionary<string, string> Sortable = new() { ["due"] = "due", ["title"] = "title", ["id"] = "id" };

    public Spec ToSpec()
    {
        var parts = new List<Spec>();
        if (Statuses is { Length: > 0 })
        {
            parts.Add(Statuses.Select(s => (Spec)new StatusSpec(s)).Aggregate((a, b) => a.Or(b)));
        }
        if (!string.IsNullOrEmpty(Assignee))
        {
            parts.Add(new AssigneeSpec(Assignee));
        }
        if (!string.IsNullOrEmpty(DueBefore))
        {
            parts.Add(new DueBeforeSpec(DueBefore));
        }
        if (!string.IsNullOrEmpty(Text))
        {
            parts.Add(new TitleSpec(Text));
        }
        return parts.Count == 0 ? new AllSpec() : parts.Aggregate((a, b) => a.And(b));
    }

    public (string Sql, List<object> Params) ToSql()
    {
        if (!Sortable.TryGetValue(Sort, out var column))
        {
            throw new ArgumentException($"cannot sort by {Sort}");
        }
        var (whereSql, parameters) = ToSpec().ToSql();
        parameters.Add(Math.Clamp(Limit, 1, 100));
        return ($"SELECT id, title, status, assignee, due FROM tasks WHERE {whereSql} ORDER BY {column} LIMIT ?", parameters);
    }

    public List<TaskItem> RunInMemory(IEnumerable<TaskItem> tasks)
    {
        var spec = ToSpec();
        Func<TaskItem, string> key = Sort switch
        {
            "title" => t => t.Title,
            "id" => t => t.Id.ToString("D6"),
            _ => t => t.Due,
        };
        return tasks.Where(spec.Matches).OrderBy(key, StringComparer.Ordinal).Take(Math.Clamp(Limit, 1, 100)).ToList();
    }
}
