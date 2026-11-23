using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();
// TODO 1: register IGreeter so that the implementation is EnglishGreeter (one shared instance).
// TODO 2: register RequestId so that every scope gets its own instance, shared inside the scope.

using ServiceProvider provider = services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true });

RequestId? fromFirstScope = null;

using (IServiceScope scope = provider.CreateScope())
{
    IGreeter greeter = scope.ServiceProvider.GetRequiredService<IGreeter>();
    Console.WriteLine(greeter.Greet("Ada"));

    RequestId first = scope.ServiceProvider.GetRequiredService<RequestId>();
    RequestId second = scope.ServiceProvider.GetRequiredService<RequestId>();
    Console.WriteLine($"Same inside scope: {ReferenceEquals(first, second)}");
    fromFirstScope = first;
}

using (IServiceScope scope = provider.CreateScope())
{
    RequestId other = scope.ServiceProvider.GetRequiredService<RequestId>();
    Console.WriteLine($"Same across scopes: {ReferenceEquals(fromFirstScope, other)}");
}
