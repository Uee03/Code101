using TasksService;

var db = new Database(
[
    new TaskItem(1, "Write ADR", "in_progress", "alice", "platform", "2026-03-05"),
    new TaskItem(2, "Review PR", "todo", "alice", "platform", "2026-03-02"),
    new TaskItem(3, "Ship release", "todo", "bob", "platform", "2026-03-20"),
    new TaskItem(4, "Old chore", "cancelled", "bob", "platform", "2026-02-01"),
]);
var auditLog = new List<string>();
var notifier = new Notifier(db.Leads);
var relay = new Relay(db, [notifier.Handle]);
var complete = Audited((actor, taskId) => CompleteTask(new UnitOfWork(db), actor, taskId), auditLog);

foreach (var (actor, taskId) in new[] { ("alice", 1), ("bob", 2), ("carol", 2), ("alice", 1), ("bob", 4) })
{
    try
    {
        Console.WriteLine(complete(actor, taskId));
    }
    catch (DomainError error)
    {
        Console.WriteLine($"rejected: {error.Message}");
    }
}

var first = relay.RunOnce();
var second = relay.RunOnce();
Console.WriteLine($"relay published {first} events, then {second} on the second run");
var overdue = new UnitOfWork(db).Tasks.Overdue("2026-03-25");
Console.WriteLine($"overdue as of 2026-03-25: [{string.Join(", ", overdue.Select(t => t.Id))}]");
foreach (var line in auditLog)
{
    Console.WriteLine(line);
}

var typeCount = typeof(TaskItem).Assembly.GetTypes().Count(t => t.Namespace == "TasksService" && !t.IsNested);
Console.WriteLine($"types in this design: {typeCount}");

static string CompleteTask(UnitOfWork uow, string actor, int taskId)
{
    var task = uow.Tasks.Get(taskId) ?? throw new DomainError($"task {taskId} not found");
    task.Complete(actor, uow.Db.Leads.GetValueOrDefault(task.Team) == actor);
    uow.Commit();
    return $"task {taskId} completed by {actor}";
}

static Func<string, int, string> Audited(Func<string, int, string> handler, List<string> log) => (actor, taskId) =>
{
    try
    {
        var result = handler(actor, taskId);
        log.Add($"audit: {actor} complete_task {taskId} ok");
        return result;
    }
    catch (DomainError)
    {
        log.Add($"audit: {actor} complete_task {taskId} rejected");
        throw;
    }
};
