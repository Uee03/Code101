namespace TasksService;

public class DomainError(string message) : Exception(message);

public sealed record DomainEvent(int Id, string Type, int TaskId, string Actor, string Team);

public class TaskItem(int id, string title, string status, string assignee, string team, string due)
{
    public int Id { get; } = id;
    public string Title { get; } = title;
    public string Status { get; private set; } = status;
    public string Assignee { get; } = assignee;
    public string Team { get; } = team;
    public string Due { get; } = due;
    public List<(string Type, string Actor)> Events { get; } = new();

    public TaskItem Copy() => new(Id, Title, Status, Assignee, Team, Due);

    public void Complete(string actor, bool isLead)
    {
        if (Status == "done")
        {
            throw new DomainError($"task {Id} is already done");
        }
        if (Status == "cancelled")
        {
            throw new DomainError($"task {Id} is cancelled");
        }
        if (actor != Assignee && !isLead)
        {
            throw new DomainError($"{actor} may not complete task {Id}");
        }
        Status = "done";
        Events.Add(("TaskCompleted", actor));
    }
}

public class Database(IEnumerable<TaskItem> tasks)
{
    public Dictionary<int, TaskItem> Tasks { get; } = tasks.ToDictionary(t => t.Id);
    public Dictionary<string, string> Leads { get; } = new() { ["platform"] = "carol" };
    public List<(DomainEvent Event, bool Published)> Outbox { get; } = new();
}

public sealed class TaskRepository(UnitOfWork uow)
{
    public TaskItem? Get(int taskId)
    {
        if (!uow.Loaded.ContainsKey(taskId))
        {
            if (!uow.Db.Tasks.TryGetValue(taskId, out var original))
            {
                return null;
            }
            uow.Loaded[taskId] = original.Copy();
        }
        return uow.Loaded[taskId];
    }

    public List<TaskItem> Overdue(string today) =>
        uow.Db.Tasks.Values
            .Where(t => (t.Status == "todo" || t.Status == "in_progress") && string.CompareOrdinal(t.Due, today) < 0)
            .OrderBy(t => t.Id)
            .ToList();
}

public sealed class UnitOfWork
{
    public UnitOfWork(Database db)
    {
        Db = db;
        Tasks = new TaskRepository(this);
    }

    public Database Db { get; }
    public Dictionary<int, TaskItem> Loaded { get; } = new();
    public TaskRepository Tasks { get; }

    public void Commit()
    {
        foreach (var task in Loaded.Values)
        {
            Db.Tasks[task.Id] = task;
            foreach (var (type, actor) in task.Events)
            {
                var domainEvent = new DomainEvent(Db.Outbox.Count + 1, type, task.Id, actor, task.Team);
                Db.Outbox.Add((domainEvent, false));
            }
            task.Events.Clear();
        }
        Loaded.Clear();
    }
}

public sealed class Relay(Database db, List<Action<DomainEvent>> handlers)
{
    public int RunOnce()
    {
        var published = 0;
        for (var i = 0; i < db.Outbox.Count; i++)
        {
            var (domainEvent, isPublished) = db.Outbox[i];
            if (isPublished)
            {
                continue;
            }
            foreach (var handler in handlers)
            {
                handler(domainEvent);
            }
            db.Outbox[i] = (domainEvent, true);
            published++;
        }
        return published;
    }
}

public sealed class Notifier(Dictionary<string, string> leads)
{
    private readonly HashSet<int> _seen = new();

    public void Handle(DomainEvent domainEvent)
    {
        if (!_seen.Add(domainEvent.Id))
        {
            return;
        }
        Console.WriteLine($"notify lead {leads[domainEvent.Team]}: task {domainEvent.TaskId} completed by {domainEvent.Actor} (event {domainEvent.Id})");
    }
}
