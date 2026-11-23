var seen = new List<string>();
var mediator = new Mediator();
mediator.Register<Greet>(request => $"hello {request.Name}");
mediator.AddBehavior((request, next) =>
{
    seen.Add(request.GetType().Name);
    return next(request);
});
mediator.AddBehavior((request, next) => ((string)next(request)!).ToUpperInvariant());
Console.WriteLine(mediator.Send(new Greet("ana")));
Console.WriteLine($"requests seen: {seen.Count}");

record Greet(string Name);

class Mediator
{
    private readonly Dictionary<Type, Func<object, object?>> _handlers = new();
    private readonly List<Func<object, Func<object, object?>, object?>> _behaviors = new();

    public void Register<T>(Func<T, object?> handler) => _handlers[typeof(T)] = request => handler((T)request);

    public void AddBehavior(Func<object, Func<object, object?>, object?> behavior) => _behaviors.Add(behavior);

    public object? Send(object request)
    {
        var call = _handlers[request.GetType()];
        foreach (var behavior in Enumerable.Reverse(_behaviors))
        {
            var current = behavior;
            var next = call;
            call = r => current(r, next);
        }
        return call(request);
    }
}
