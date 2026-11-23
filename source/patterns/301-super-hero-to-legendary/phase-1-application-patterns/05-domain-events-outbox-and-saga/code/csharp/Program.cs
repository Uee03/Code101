var store = new Store();
store.Tasks[1] = new StoredTask("PLAT");
store.Tasks[2] = new StoredTask("PLAT");
store.Tasks[3] = new StoredTask("DOCS");
var bus = new EventBus();

var notify = new Idempotent("notify", e => Console.WriteLine($"notify: task {e.TaskId} completed (event {e.Id})"));
var progress = new Idempotent("progress", e =>
{
    var inProject = store.Tasks.Values.Where(t => t.Project == e.Project).ToList();
    if (inProject.All(t => t.Status == "done"))
    {
        bus.Publish(new DomainEvent(100, "ProjectCompleted", 0, e.Project));
    }
});
bus.Subscribe("TaskCompleted", notify.Handle);
bus.Subscribe("TaskCompleted", progress.Handle);
bus.Subscribe("ProjectCompleted", e => Console.WriteLine($"lead: project {e.Project} completed"));
var relay = new Relay(store, bus);

try
{
    CompleteTask(store, 1, failBeforeCommit: true);
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"failed: {error.Message}");
}
Console.WriteLine($"after failure: task 1 is {store.Tasks[1].Status}, outbox rows: {store.Outbox.Count}");

CompleteTask(store, 1);
Console.WriteLine($"after commit: task 1 is {store.Tasks[1].Status}, outbox rows: {store.Outbox.Count}");

try
{
    relay.RunOnce(crashAfterPublish: true);
}
catch (InvalidOperationException error)
{
    Console.WriteLine($"relay: {error.Message}");
}
Console.WriteLine($"event 1 published flag: {store.Outbox[0].Published}");
relay.RunOnce();
Console.WriteLine($"event 1 published flag: {store.Outbox[0].Published}");

CompleteTask(store, 2);
relay.RunOnce();

ShowSaga(fail: true);
ShowSaga(fail: false);

static void CompleteTask(Store store, int taskId, bool failBeforeCommit = false)
{
    store.InTransaction(() =>
    {
        var task = store.Tasks[taskId];
        task.Status = "done";
        store.AddEvent("TaskCompleted", taskId, task.Project);
        if (failBeforeCommit)
        {
            throw new InvalidOperationException("crash before commit");
        }
    });
}

static void ShowSaga(bool fail)
{
    var context = new SagaContext { Fail = fail };
    var saga = new Saga(
    [
        new SagaStep("freeze_tasks", c => c.Frozen = true, c => c.Frozen = false),
        new SagaStep("notify_members", c => c.Mails.Add("archiving"), c => c.Mails.Add("archive cancelled")),
        new SagaStep("mark_archived", c =>
        {
            if (c.Fail)
            {
                throw new InvalidOperationException("archive flag rejected");
            }
        }, _ => { }),
    ]);
    var ok = saga.Run(context);
    Console.WriteLine($"saga result: {ok}, frozen={context.Frozen}, mails={string.Join(", ", context.Mails)}");
}

public sealed record DomainEvent(int Id, string Type, int TaskId, string Project);

public sealed class EventBus
{
    private readonly Dictionary<string, List<Action<DomainEvent>>> _handlers = new();

    public void Subscribe(string eventType, Action<DomainEvent> handler)
    {
        if (!_handlers.TryGetValue(eventType, out var list))
        {
            list = new List<Action<DomainEvent>>();
            _handlers[eventType] = list;
        }
        list.Add(handler);
    }

    public void Publish(DomainEvent domainEvent)
    {
        if (_handlers.TryGetValue(domainEvent.Type, out var list))
        {
            foreach (var handler in list)
            {
                handler(domainEvent);
            }
        }
    }
}

public sealed class Idempotent(string name, Action<DomainEvent> handler)
{
    private readonly HashSet<int> _seen = new();

    public void Handle(DomainEvent domainEvent)
    {
        if (!_seen.Add(domainEvent.Id))
        {
            Console.WriteLine($"{name}: skipped duplicate event {domainEvent.Id}");
            return;
        }
        handler(domainEvent);
    }
}

public sealed class StoredTask(string project)
{
    public string Project { get; } = project;
    public string Status { get; set; } = "todo";
}

public sealed class OutboxRow(DomainEvent domainEvent)
{
    public DomainEvent Event { get; } = domainEvent;
    public bool Published { get; set; }
}

public sealed class Store
{
    private int _nextEventId = 1;

    public Dictionary<int, StoredTask> Tasks { get; private set; } = new();
    public List<OutboxRow> Outbox { get; private set; } = new();

    public void AddEvent(string type, int taskId, string project)
    {
        Outbox.Add(new OutboxRow(new DomainEvent(_nextEventId, type, taskId, project)));
        _nextEventId++;
    }

    public void InTransaction(Action work)
    {
        var tasksBackup = Tasks.ToDictionary(p => p.Key, p => new StoredTask(p.Value.Project) { Status = p.Value.Status });
        var outboxBackup = Outbox.Select(r => new OutboxRow(r.Event) { Published = r.Published }).ToList();
        var idBackup = _nextEventId;
        try
        {
            work();
        }
        catch
        {
            Tasks = tasksBackup;
            Outbox = outboxBackup;
            _nextEventId = idBackup;
            throw;
        }
    }
}

public sealed class Relay(Store store, EventBus bus)
{
    public void RunOnce(bool crashAfterPublish = false)
    {
        foreach (var row in store.Outbox)
        {
            if (row.Published)
            {
                continue;
            }
            bus.Publish(row.Event);
            if (crashAfterPublish)
            {
                throw new InvalidOperationException("crashed after publish, before marking");
            }
            row.Published = true;
        }
    }
}

public sealed class SagaContext
{
    public bool Fail { get; init; }
    public bool Frozen { get; set; }
    public List<string> Mails { get; } = new();
}

public sealed record SagaStep(string Name, Action<SagaContext> Action, Action<SagaContext> Compensate);

public sealed class Saga(IReadOnlyList<SagaStep> steps)
{
    public bool Run(SagaContext context)
    {
        var done = new List<SagaStep>();
        foreach (var step in steps)
        {
            try
            {
                step.Action(context);
                Console.WriteLine($"saga: {step.Name} done");
                done.Add(step);
            }
            catch (InvalidOperationException error)
            {
                Console.WriteLine($"saga: {step.Name} failed ({error.Message})");
                foreach (var finished in Enumerable.Reverse(done))
                {
                    finished.Compensate(context);
                    Console.WriteLine($"saga: {finished.Name} compensated");
                }
                return false;
            }
        }
        return true;
    }
}
