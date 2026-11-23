namespace Lookalikes;

public static class Validation
{
    public static string LengthProblem(string text, int minimum, int maximum)
    {
        if (text.Length < minimum || text.Length > maximum)
        {
            return $"must be {minimum} to {maximum} characters";
        }
        return "";
    }

    public static string UsernameProblem(string name)
    {
        return LengthProblem(name, 3, 20);
    }

    public static string ProductTitleProblem(string title)
    {
        return LengthProblem(title, 3, 60);
    }
}
