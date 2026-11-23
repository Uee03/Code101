using System.Globalization;
using System.Text.RegularExpressions;

try
{
    new TaskManager(null, "tasks.db").Report();
}
catch (ConfigException error)
{
    Console.WriteLine($"god object: cannot build a report: {error.Message}");
}
Console.WriteLine($"split: {Reports.Build(["todo", "done", "todo"])}");

var legacy = new AnemicTask("Old", "cancelled");
Importer.ImportTasks([legacy]);
Console.WriteLine($"anemic: importer completed a cancelled task, status={legacy.Status}");
var rich = new RichTask("Old", "cancelled");
try
{
    rich.Complete();
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"rich: rejected: {error.Message}");
}

Console.WriteLine($"hammer: regex accepts 2026-13-45: {Dates.RegexAccepts("2026-13-45")}");
Console.WriteLine($"right tool: date parser accepts 2026-13-45: {Dates.ParserAccepts("2026-13-45")}");

try
{
    new LocatorReport().Run();
}
catch (KeyNotFoundException error)
{
    Console.WriteLine($"service locator: found out at run time: {error.Message}");
}
var needs = typeof(InjectedReport).GetConstructors()[0].GetParameters().Select(p => p.Name);
Console.WriteLine($"constructor injection: dependencies visible: {string.Join(", ", needs)}");

Settings.Instance.Currency = "USD";
Console.WriteLine($"singleton: second test sees {Settings.Instance.Currency} (leaked from the first)");
Console.WriteLine($"injected: second test sees {new Settings().Currency}");

public class ConfigException(string message) : Exception(message);

public class TaskManager
{
    private readonly List<string> _statuses = new();

    public TaskManager(string? smtpHost, string dbPath)
    {
        if (string.IsNullOrEmpty(smtpHost))
        {
            throw new ConfigException("smtp_host is required");
        }
        DbPath = dbPath;
    }

    public string DbPath { get; }

    public string Report()
    {
        var open = _statuses.Count(s => s != "done");
        return $"{open} open of {_statuses.Count}";
    }
}

public static class Reports
{
    public static string Build(List<string> statuses)
    {
        var open = statuses.Count(s => s != "done");
        return $"{open} open of {statuses.Count}";
    }
}

public class AnemicTask(string title, string status)
{
    public string Title { get; set; } = title;
    public string Status { get; set; } = status;
}

public static class Importer
{
    public static void ImportTasks(List<AnemicTask> tasks)
    {
        foreach (var task in tasks)
        {
            task.Status = "done";
        }
    }
}

public class RichTask(string title, string status)
{
    public string Title { get; } = title;
    public string Status { get; private set; } = status;

    public void Complete()
    {
        if (Status == "cancelled")
        {
            throw new InvalidOperationException("a cancelled task cannot be completed");
        }
        Status = "done";
    }
}

public static class Dates
{
    public static bool RegexAccepts(string text) => Regex.IsMatch(text, @"^\d{4}-\d{2}-\d{2}\z");

    public static bool ParserAccepts(string text) =>
        DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _);
}

public static class Locator
{
    public static Dictionary<string, object> Services { get; } = new();

    public static T Get<T>(string name) =>
        Services.TryGetValue(name, out var service) ? (T)service : throw new KeyNotFoundException($"{name} is not registered");
}

public interface IMailer
{
    string Send(string text);
}

public class LocatorReport
{
    public string Run() => Locator.Get<IMailer>("mailer").Send("report");
}

public class InjectedReport(IMailer mailer)
{
    public string Run() => mailer.Send("report");
}

public class Settings
{
    private static Settings? _instance;

    public static Settings Instance => _instance ??= new Settings();

    public string Currency { get; set; } = "EUR";
}
