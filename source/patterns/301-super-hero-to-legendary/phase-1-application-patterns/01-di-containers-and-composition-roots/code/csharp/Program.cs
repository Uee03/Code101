using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();
services.AddSingleton<IClock>(new FixedClock("2026-03-01"));
services.AddSingleton<ITaskRepository, InMemoryTaskRepository>();
services.AddTransient<IMailer, ConsoleMailer>();
services.AddScoped(_ => new RequestContext("alice"));
services.AddTransient<TaskService>();

var options = new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true };
using var provider = services.BuildServiceProvider(options);
Console.WriteLine("validate: 0 problem(s)");

for (var number = 1; number <= 2; number++)
{
    using var scope = provider.CreateScope();
    var service = scope.ServiceProvider.GetRequiredService<TaskService>();
    Console.WriteLine(service.Create($"Write ADR {number}"));
}

using var scopeA = provider.CreateScope();
using var scopeB = provider.CreateScope();
var repoShared = ReferenceEquals(provider.GetRequiredService<ITaskRepository>(), provider.GetRequiredService<ITaskRepository>());
var mailerShared = ReferenceEquals(provider.GetRequiredService<IMailer>(), provider.GetRequiredService<IMailer>());
var inOneScope = ReferenceEquals(scopeA.ServiceProvider.GetRequiredService<RequestContext>(), scopeA.ServiceProvider.GetRequiredService<RequestContext>());
var acrossScopes = ReferenceEquals(scopeA.ServiceProvider.GetRequiredService<RequestContext>(), scopeB.ServiceProvider.GetRequiredService<RequestContext>());
Console.WriteLine($"singleton repo shared: {repoShared}");
Console.WriteLine($"transient mailer shared: {mailerShared}");
Console.WriteLine($"scoped context shared in one scope: {inOneScope}");
Console.WriteLine($"scoped context shared across scopes: {acrossScopes}");

var broken = new ServiceCollection();
broken.AddScoped(_ => new RequestContext("alice"));
broken.AddSingleton<ReportCache>();
Console.WriteLine($"captive: container refused to build: {Refuses(broken)}");

var loop = new ServiceCollection();
loop.AddTransient<Alpha>();
loop.AddTransient<Beta>();
Console.WriteLine($"cycle: container refused to build: {Refuses(loop)}");

static bool Refuses(IServiceCollection collection)
{
    try
    {
        collection.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true });
        return false;
    }
    catch (AggregateException)
    {
        return true;
    }
}

public interface IClock
{
    string Today();
}

public sealed class FixedClock(string day) : IClock
{
    public string Today() => day;
}

public interface IMailer
{
    void Send(string text);
}

public sealed class ConsoleMailer : IMailer
{
    public void Send(string text) => Console.WriteLine($"mail: {text}");
}

public interface ITaskRepository
{
    int Add(string title);
}

public sealed class InMemoryTaskRepository : ITaskRepository
{
    private readonly List<string> _titles = new();

    public int Add(string title)
    {
        _titles.Add(title);
        return _titles.Count;
    }
}

public sealed record RequestContext(string User);

public sealed class TaskService(ITaskRepository repo, IClock clock, IMailer mailer, RequestContext context)
{
    public string Create(string title)
    {
        var taskId = repo.Add(title);
        mailer.Send($"task {taskId} created");
        return $"{context.User} created task {taskId} '{title}' on {clock.Today()}";
    }
}

public sealed class ReportCache(RequestContext context)
{
    public RequestContext Context => context;
}

public sealed class Alpha(Beta beta)
{
    public Beta Beta => beta;
}

public sealed class Beta(Alpha alpha)
{
    public Alpha Alpha => alpha;
}
