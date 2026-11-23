var store = new Dictionary<int, StoredTask>();
var view = new OpenTasksView();
var mediator = BuildMediator(store, view);

Attempt(() => $"created task {mediator.Send(new CreateTask("Write ADR", "alice"))}");
Attempt(() => $"created task {mediator.Send(new CreateTask("Review PR", "alice"))}");
Attempt(() => $"created task {mediator.Send(new CreateTask("", "alice"))}");
Attempt(() =>
{
    mediator.Send(new CompleteTask(1));
    return "completed task 1";
});
Attempt(() =>
{
    mediator.Send(new CompleteTask(1));
    return "completed task 1";
});
Attempt(() => "open for alice: " + string.Join(", ", mediator.Send(new OpenTasksFor("alice"))));

view.Paused = true;
Attempt(() => $"created task {mediator.Send(new CreateTask("Ship", "alice"))}");
Attempt(() => "stale read: " + string.Join(", ", mediator.Send(new OpenTasksFor("alice"))));
view.Paused = false;
view.CatchUp();
Attempt(() => "after catch-up: " + string.Join(", ", mediator.Send(new OpenTasksFor("alice"))));

Attempt(() =>
{
    mediator.Register<CreateTask, int>(_ => 0);
    return null;
});
Attempt(() =>
{
    mediator.Send(new Unknown());
    return null;
});

static Mediator BuildMediator(Dictionary<int, StoredTask> store, OpenTasksView view)
{
    var mediator = new Mediator();
    mediator.AddBehavior((request, next) =>
    {
        Console.WriteLine($"[log] {request.GetType().Name}");
        return next(request);
    });
    mediator.AddBehavior((request, next) =>
    {
        if (request is CreateTask create && string.IsNullOrWhiteSpace(create.Title))
        {
            throw new InvalidRequestException("title is required");
        }
        return next(request);
    });

    mediator.Register<CreateTask, int>(command =>
    {
        var taskId = store.Count + 1;
        store[taskId] = new StoredTask(command.Title, "todo", command.Assignee);
        view.Publish("created", taskId, command.Title, command.Assignee);
        return taskId;
    });
    mediator.Register<CompleteTask, Unit>(command =>
    {
        if (!store.TryGetValue(command.TaskId, out var task))
        {
            throw new DomainException($"task {command.TaskId} not found");
        }
        if (task.Status == "done")
        {
            throw new DomainException($"task {command.TaskId} is already done");
        }
        task.Status = "done";
        view.Publish("completed", command.TaskId, task.Title, task.Assignee);
        return default;
    });
    mediator.Register<OpenTasksFor, List<string>>(query => view.TitlesFor(query.Assignee));
    return mediator;
}

static void Attempt(Func<string?> action)
{
    try
    {
        var message = action();
        if (message is not null)
        {
            Console.WriteLine(message);
        }
    }
    catch (Exception error) when (error is InvalidRequestException or DomainException or KeyNotFoundException or InvalidOperationException)
    {
        Console.WriteLine($"rejected: {error.Message}");
    }
}

public class InvalidRequestException(string message) : Exception(message);

public class DomainException(string message) : Exception(message);

public readonly record struct Unit;

public interface IRequest<TResponse>
{
}

public sealed record CreateTask(string Title, string Assignee) : IRequest<int>;

public sealed record CompleteTask(int TaskId) : IRequest<Unit>;

public sealed record OpenTasksFor(string Assignee) : IRequest<List<string>>;

public sealed record Unknown : IRequest<Unit>;

public sealed class StoredTask(string title, string status, string assignee)
{
    public string Title { get; } = title;
    public string Status { get; set; } = status;
    public string Assignee { get; } = assignee;
}

public sealed class Mediator
{
    private readonly Dictionary<Type, Func<object, object?>> _handlers = new();
    private readonly List<Func<object, Func<object, object?>, object?>> _behaviors = new();

    public void Register<TRequest, TResponse>(Func<TRequest, TResponse> handler) where TRequest : IRequest<TResponse>
    {
        if (!_handlers.TryAdd(typeof(TRequest), request => handler((TRequest)request)))
        {
            throw new InvalidOperationException($"handler already registered for {typeof(TRequest).Name}");
        }
    }

    public void AddBehavior(Func<object, Func<object, object?>, object?> behavior) => _behaviors.Add(behavior);

    public TResponse Send<TResponse>(IRequest<TResponse> request)
    {
        if (!_handlers.TryGetValue(request.GetType(), out var handler))
        {
            throw new KeyNotFoundException($"no handler for {request.GetType().Name}");
        }
        var call = handler;
        foreach (var behavior in Enumerable.Reverse(_behaviors))
        {
            var current = behavior;
            var next = call;
            call = r => current(r, next);
        }
        return (TResponse)call(request)!;
    }
}

public sealed class OpenTasksView
{
    private readonly Dictionary<string, SortedDictionary<int, string>> _rows = new();
    private readonly List<(string Kind, int TaskId, string Title, string Assignee)> _pending = new();

    public bool Paused { get; set; }

    public void Publish(string kind, int taskId, string title, string assignee)
    {
        _pending.Add((kind, taskId, title, assignee));
        if (!Paused)
        {
            CatchUp();
        }
    }

    public void CatchUp()
    {
        foreach (var (kind, taskId, title, assignee) in _pending)
        {
            if (!_rows.TryGetValue(assignee, out var rows))
            {
                rows = new SortedDictionary<int, string>();
                _rows[assignee] = rows;
            }
            if (kind == "created")
            {
                rows[taskId] = title;
            }
            else
            {
                rows.Remove(taskId);
            }
        }
        _pending.Clear();
    }

    public List<string> TitlesFor(string assignee) =>
        _rows.TryGetValue(assignee, out var rows) ? rows.Values.ToList() : new List<string>();
}
