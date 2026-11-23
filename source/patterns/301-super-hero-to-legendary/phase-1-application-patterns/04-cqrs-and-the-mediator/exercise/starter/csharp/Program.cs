var seen = new List<string>();
var mediator = new Mediator();
mediator.Register<Greet>(request => $"hello {request.Name}");
mediator.AddBehavior((request, next) =>
{
    seen.Add(request.GetType().Name);
    return next(request);
});
// TODO 3: add a behavior that calls next(request) and returns the result in upper case (cast it to string first).
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
        // TODO 1: wrap call with every behavior so that _behaviors[0] runs first and the handler runs last.
        //         A behavior is a function (request, next) that calls next(request).
        // TODO 2: remember to copy the loop variables into new variables before the lambda uses them.
        return call(request);
    }
}
