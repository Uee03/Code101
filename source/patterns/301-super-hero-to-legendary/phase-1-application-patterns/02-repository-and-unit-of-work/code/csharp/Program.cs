var db = new Database();
var seed = new UnitOfWork(db);
seed.Tasks.Save(new TaskItem(1, "Write ADR", "todo", "alice"));
seed.Tasks.Save(new TaskItem(2, "Review PR", "in_progress", "alice"));
seed.Tasks.Save(new TaskItem(3, "Ship release", "todo", "bob"));
seed.Commit();
Console.WriteLine($"seeded {db.Tasks.Count} tasks");

db.FailOnId = 2;
var failing = new UnitOfWork(db);
ReassignOpenTasks(failing, "alice", "dave");
try
{
    failing.Commit();
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"failed: {error.Message}");
}
Console.WriteLine($"after rollback: task 1 is still {db.Tasks[1].Assignee}");
db.FailOnId = null;

var uow = new UnitOfWork(db);
ReassignOpenTasks(uow, "alice", "carol");
Console.WriteLine($"before commit: repo says {uow.Tasks.Get(1)!.Assignee}, database says {db.Tasks[1].Assignee}");
uow.Commit();
Console.WriteLine($"after commit: database says {db.Tasks[1].Assignee}");
Console.WriteLine($"open tasks for carol: [{string.Join(", ", uow.Tasks.OpenFor("carol").Select(t => t.Id))}]");

static int ReassignOpenTasks(UnitOfWork uow, string source, string target)
{
    var moved = 0;
    foreach (var task in uow.Tasks.OpenFor(source))
    {
        uow.Tasks.Save(task with { Assignee = target });
        moved++;
    }
    return moved;
}

public sealed record TaskItem(int Id, string Title, string Status, string Assignee);

public sealed class Database
{
    public Dictionary<int, TaskItem> Tasks { get; set; } = new();
    public int? FailOnId { get; set; }

    public void Write(TaskItem task)
    {
        if (task.Id == FailOnId)
        {
            throw new InvalidOperationException($"write failed for task {task.Id}");
        }
        Tasks[task.Id] = task;
    }
}

public sealed class TaskRepository(Database db, SortedDictionary<int, TaskItem> pending)
{
    public TaskItem? Get(int id) => pending.TryGetValue(id, out var task) ? task : db.Tasks.GetValueOrDefault(id);

    public void Save(TaskItem task) => pending[task.Id] = task;

    public List<TaskItem> OpenFor(string assignee)
    {
        var merged = new SortedDictionary<int, TaskItem>(db.Tasks);
        foreach (var (id, task) in pending)
        {
            merged[id] = task;
        }
        return merged.Values.Where(t => t.Assignee == assignee && t.Status != "done").ToList();
    }
}

public sealed class UnitOfWork
{
    private readonly Database _db;
    private readonly SortedDictionary<int, TaskItem> _pending = new();

    public UnitOfWork(Database db)
    {
        _db = db;
        Tasks = new TaskRepository(db, _pending);
    }

    public TaskRepository Tasks { get; }

    public void Commit()
    {
        var backup = new Dictionary<int, TaskItem>(_db.Tasks);
        try
        {
            foreach (var task in _pending.Values)
            {
                _db.Write(task);
            }
        }
        catch
        {
            _db.Tasks = backup;
            throw;
        }
        finally
        {
            _pending.Clear();
        }
    }
}
