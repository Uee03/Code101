namespace TasksApi.Data;

// Builds LIKE patterns from user text. Without escaping, a user could type % or _ and match more than they should.
// Pass EscapeChar as the third argument of EF.Functions.ILike, or the database ignores the backslashes.
public static class Like
{
    public const string EscapeChar = "\\";

    private static string Escape(string text) =>
        text.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_");

    public static string Prefix(string text) => Escape(text) + "%";

    public static string Contains(string text) => "%" + Escape(text) + "%";
}
