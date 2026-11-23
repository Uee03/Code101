namespace TasksApi.Features.Tasks;

// The allowed values; they match the CHECK constraints on the tasks table.
public static class TaskRules
{
    public static readonly string[] Statuses = ["todo", "in_progress", "blocked", "done", "cancelled"];
    public static readonly string[] Priorities = ["low", "medium", "high", "urgent"];

    public static bool IsTitle(string? title) => title is not null && title.Trim().Length is >= 1 and <= 200;

    public static bool IsDescription(string? text) => text is not null && text.Length <= 10000;
}
