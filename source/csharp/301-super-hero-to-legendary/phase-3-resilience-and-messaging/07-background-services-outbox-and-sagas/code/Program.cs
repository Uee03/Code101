using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Outbox;

const string databaseFile = "outbox.db";
File.Delete(databaseFile);

var database = new Database($"Data Source={databaseFile}");
database.CreateSchema();

// 1. Write the business rows and the messages in one transaction.
var orders = new OrderService(database);
var firstId = orders.Place("Ada");
var secondId = orders.Place("Grace");
Console.WriteLine($"placed orders {firstId} and {secondId}; outbox rows waiting: {database.CountUnprocessed()}");

// 2. A background service relays the outbox rows to a broker that fails on purpose.
var inbox = new Inbox(database);
var broker = new FlakyBroker(inbox);
var builder = Host.CreateApplicationBuilder(args);
builder.Logging.ClearProviders();
builder.Services.AddSingleton(database);
builder.Services.AddSingleton(broker);
builder.Services.AddSingleton<OutboxRelay>();
builder.Services.AddHostedService(services => services.GetRequiredService<OutboxRelay>());

using var host = builder.Build();
await host.StartAsync();

using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
while (database.CountUnprocessed() > 0)
{
    await Task.Delay(20, timeout.Token);
}

await host.StopAsync();

var relay = host.Services.GetRequiredService<OutboxRelay>();
Console.WriteLine($"relay failures: {relay.Failures}");
Console.WriteLine($"broker deliveries: {broker.RawDeliveries}");
Console.WriteLine($"messages handled once: {inbox.Handled}");
Console.WriteLine($"outbox rows waiting: {database.CountUnprocessed()}");

// 3. A saga: the payment step fails, so the stock reservation is released.
var saga = new SagaRunner(Console.WriteLine);
var completed = await saga.RunAsync(
[
    new SagaStep("reserve-stock", () => Task.CompletedTask, () => Task.CompletedTask),
    new SagaStep("charge-payment", () => throw new InvalidOperationException("card declined"), () => Task.CompletedTask),
    new SagaStep("ship-order", () => Task.CompletedTask, () => Task.CompletedTask),
]);
Console.WriteLine($"saga result: {(completed ? "completed" : "compensated")}");
