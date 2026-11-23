---
track: csharp
level: 301
phase: 3
phase_name: resilience-and-messaging
lesson: 07
title: "Background services, the outbox pattern and sagas"
time: 80-100 min
prerequisites: [csharp 301.1.03, csharp 301.3.06, csharp 201.1.04, csharp 201.2.07]
versions: { dotnet_sdk: "11.0.100", target_framework: "net11.0", Microsoft.Extensions.Hosting: "11.0.0", Microsoft.Data.Sqlite: "11.0.0" }
verified: not yet run
source: source/csharp/301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas/
assets: []
---

# 07. Background services, the outbox pattern and sagas

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Write a `BackgroundService` that stops cleanly and survives a failing dependency.
- Explain the dual-write problem and fix it with a transactional outbox and an idempotent consumer.
- Predict how many deliveries and handled messages result from at-least-once delivery with two injected failures.
- Write an orchestrated saga with compensations and say when a saga is the wrong tool.

## Recap
1. (Lesson 03) Why are domain events published only after the aggregate has been saved?
   <details><summary>Answer</summary>Publishing before a failed save announces something that never happened. This lesson solves the harder version: save and publish must not diverge.</details>
2. (Lesson 06) Why must a retried operation be idempotent?
   <details><summary>Answer</summary>A retry can repeat an effect that already happened (the first request may have succeeded before the timeout). Idempotency makes the repeat harmless.</details>

## Why it matters
"Save the order, then publish `OrderPlaced`" looks like two lines of code and is actually a distributed transaction. If the process dies between them, the order exists and nobody ever learns about it; if you publish first and the save fails, you announced an order that does not exist. This is the **dual-write problem**, and it silently corrupts systems in production. The **outbox pattern** removes it: write the message to a table **in the same database transaction** as the business change, and let a background worker deliver it.

## What you will build
A console program with: an `OrderService` that writes an order and an outbox row in one transaction (SQLite, no server needed); a `BackgroundService` that relays outbox rows to a fake broker which fails on purpose (once because it is down, once because an acknowledgement is lost); an idempotent consumer with an inbox table; and a small orchestrated saga with a compensation.

## Before you start
- **Prerequisites:** C# 301 lessons [03, domain-driven design essentials](../phase-1-architecture/03-domain-driven-design-essentials.md) and [06, resilience with Polly](06-resilience-with-polly.md); C# 201 lessons [04, async/await and Task](../../201-hero-to-super-hero/phase-1-core-skills/04-async-await-and-task.md) and [07, dependency injection and options](../../201-hero-to-super-hero/phase-2-web-apis/07-dependency-injection-and-options.md).
- Tools: .NET SDK **11.0.100**. SQLite is embedded in the NuGet package; no database server. Time: 80-100 minutes (break after Step 6).
- Folder: create `lesson07` as in lesson 01 Step 1 (only `lesson07`, files directly inside) and copy `global.json` from lesson 01 Step 2.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-3-resilience-and-messaging/07-background-services-outbox-and-sagas/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. The project
**File: `Outbox.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net11.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.Extensions.Hosting" Version="11.0.0" />
    <PackageReference Include="Microsoft.Data.Sqlite" Version="11.0.0" />
  </ItemGroup>

</Project>
```
`Microsoft.Extensions.Hosting` provides `BackgroundService` and the generic host. `Microsoft.Data.Sqlite` is plain ADO.NET over SQLite, chosen so the lesson needs no server and the SQL is visible.

### Step 2. The database helper
**File: `Database.cs`**
```csharp
using Microsoft.Data.Sqlite;

namespace Outbox;

public sealed record OutboxMessage(long Id, string Type, string Payload);

public sealed class Database(string connectionString)
{
    public SqliteConnection Open()
    {
        var connection = new SqliteConnection(connectionString);
        connection.Open();
        return connection;
    }

    public void CreateSchema()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = """
            CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY AUTOINCREMENT, customer TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS outbox (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL,
                payload TEXT NOT NULL,
                processed INTEGER NOT NULL DEFAULT 0);
            CREATE TABLE IF NOT EXISTS inbox (message_id INTEGER PRIMARY KEY);
            """;
        command.ExecuteNonQuery();
    }

    public long CountUnprocessed()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM outbox WHERE processed = 0";
        return (long)command.ExecuteScalar()!;
    }

    public List<OutboxMessage> ReadPending()
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, type, payload FROM outbox WHERE processed = 0 ORDER BY id LIMIT 10";
        using var reader = command.ExecuteReader();
        var messages = new List<OutboxMessage>();
        while (reader.Read())
        {
            messages.Add(new OutboxMessage(reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
        }

        return messages;
    }

    public void MarkProcessed(long messageId)
    {
        using var connection = Open();
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE outbox SET processed = 1 WHERE id = $id";
        command.Parameters.AddWithValue("$id", messageId);
        command.ExecuteNonQuery();
    }
}
```
Three tables carry the whole pattern: `orders` (the business data), `outbox` (messages waiting to be sent: `processed = 0`) and `inbox` (ids the consumer has already handled). All values go through **parameters** (`$id`, `$customer`), never string concatenation. `ReadPending` takes at most 10 rows in id order so a backlog cannot load the whole table into memory and the order of messages is preserved.

### Step 3. Write the order and the message in one transaction
**File: `OrderService.cs`**
```csharp
using System.Text.Json;

namespace Outbox;

public sealed class OrderService(Database database)
{
    // The order row and the outbox row are written in ONE transaction: both happen or neither does.
    public long Place(string customer)
    {
        using var connection = database.Open();
        using var transaction = connection.BeginTransaction();

        using var insertOrder = connection.CreateCommand();
        insertOrder.Transaction = transaction;
        insertOrder.CommandText = "INSERT INTO orders (customer) VALUES ($customer) RETURNING id";
        insertOrder.Parameters.AddWithValue("$customer", customer);
        var orderId = (long)insertOrder.ExecuteScalar()!;

        using var insertMessage = connection.CreateCommand();
        insertMessage.Transaction = transaction;
        insertMessage.CommandText = "INSERT INTO outbox (type, payload) VALUES ('OrderPlaced', $payload)";
        insertMessage.Parameters.AddWithValue("$payload", JsonSerializer.Serialize(new { orderId, customer }));
        insertMessage.ExecuteNonQuery();

        transaction.Commit();
        return orderId;
    }
}
```
This is the heart of the lesson. If the process crashes before `Commit`, **neither** row exists. If it crashes after, **both** exist and the relay will find the message. There is no moment at which the order exists without its message. The payload is serialized with `JsonSerializer`, not built by string concatenation, so a customer name containing a quote cannot break the JSON.

### Step 4. The consumer and the misbehaving broker
**File: `Messaging.cs`**
```csharp
namespace Outbox;

public sealed class BrokerException(string message) : Exception(message);

// The consumer side. Delivery is at-least-once, so the consumer must be idempotent: the inbox remembers message ids.
public sealed class Inbox(Database database)
{
    private int handled;

    public int Handled => Volatile.Read(ref handled);

    public void Handle(long messageId)
    {
        using var connection = database.Open();
        using var command = connection.CreateCommand();
        command.CommandText = "INSERT OR IGNORE INTO inbox (message_id) VALUES ($id)";
        command.Parameters.AddWithValue("$id", messageId);

        // One row inserted means "first time". The business effect belongs here, in the same transaction as this insert.
        if (command.ExecuteNonQuery() == 1)
        {
            Interlocked.Increment(ref handled);
        }
    }
}

// A fake message broker that misbehaves on purpose, once per message.
public sealed class FlakyBroker(Inbox inbox)
{
    private readonly object gate = new();
    private readonly HashSet<long> seen = [];
    private int rawDeliveries;

    public int RawDeliveries
    {
        get
        {
            lock (gate)
            {
                return rawDeliveries;
            }
        }
    }

    public void Publish(long messageId)
    {
        lock (gate)
        {
            var firstAttempt = seen.Add(messageId);

            // Message 1, first attempt: the broker is down and nothing is delivered.
            if (messageId == 1 && firstAttempt)
            {
                throw new BrokerException("broker unavailable");
            }

            rawDeliveries++;
            inbox.Handle(messageId);

            // Message 2, first attempt: delivered, but the acknowledgement is lost, so the publisher thinks it failed.
            if (messageId == 2 && firstAttempt)
            {
                throw new BrokerException("acknowledgement lost");
            }
        }
    }
}
```
These two failures are the two real failure shapes of any messaging system: **"not delivered"** (the publisher can safely retry) and **"delivered but I was not told"** (a retry causes a duplicate). You cannot tell them apart from the publisher's side. That is why every broker offers **at-least-once** delivery as the practical guarantee, and why consumers must be idempotent. `INSERT OR IGNORE` on a primary key is the simplest idempotency check: the second insert of the same id changes zero rows.

### Step 5. The relay, a BackgroundService
**File: `OutboxRelay.cs`**
```csharp
using Microsoft.Extensions.Hosting;

namespace Outbox;

// Polls the outbox table and publishes what it finds. A row is marked processed only AFTER a successful publish.
public sealed class OutboxRelay(Database database, FlakyBroker broker) : BackgroundService
{
    private int failures;

    public int Failures => Volatile.Read(ref failures);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(50));
        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    DrainOnce();
                }
                catch (BrokerException)
                {
                    // Leave the row unprocessed; the next tick tries again. Real code logs and counts this.
                    Interlocked.Increment(ref failures);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // The host is stopping. Unprocessed rows stay in the table for the next start.
        }
    }

    private void DrainOnce()
    {
        foreach (var message in database.ReadPending())
        {
            broker.Publish(message.Id);
            database.MarkProcessed(message.Id);
        }
    }
}
```
Read the order of the two lines in `DrainOnce`: **publish first, mark processed second**. A crash between them re-sends the message (a duplicate, which the inbox absorbs); the reverse order could lose it. Details of `BackgroundService`:
- `ExecuteAsync` runs for the life of the host. When the host shuts down, `stoppingToken` is cancelled, `WaitForNextTickAsync` throws `OperationCanceledException`, and the method ends cleanly.
- `PeriodicTimer` waits for the next tick without piling up overlapping runs (a slow `DrainOnce` delays the next tick instead of running twice).
- An **unhandled exception** from `ExecuteAsync` stops the whole host by default. That is why the loop catches `BrokerException`: one bad publish must not kill the service. Catch what you can handle; let genuine bugs surface.
- A `BackgroundService` is a **singleton**. If it needs scoped services (an EF Core `DbContext`), inject `IServiceScopeFactory` and create a scope per iteration.
- `DrainOnce` is synchronous here to keep the SQL obvious. In production use asynchronous database calls so that the relay does not block a thread-pool thread.

### Step 6. The saga
**File: `Saga.cs`**
```csharp
namespace Outbox;

public sealed record SagaStep(string Name, Func<Task> Execute, Func<Task> Compensate);

// An orchestrated saga: run the steps in order; if one fails, undo the finished ones in reverse order.
public sealed class SagaRunner(Action<string> log)
{
    public async Task<bool> RunAsync(IReadOnlyList<SagaStep> steps)
    {
        var finished = new Stack<SagaStep>();
        foreach (var step in steps)
        {
            try
            {
                log($"saga step: {step.Name}");
                await step.Execute();
                finished.Push(step);
            }
            catch (Exception ex)
            {
                log($"saga step {step.Name} failed: {ex.Message}");
                while (finished.Count > 0)
                {
                    var undo = finished.Pop();
                    log($"saga compensate: {undo.Name}");
                    await undo.Compensate();
                }

                return false;
            }
        }

        return true;
    }
}
```
A saga replaces a distributed transaction (which you do not have across services) with **a sequence of local transactions plus compensating actions**. Notice what the `catch` does **not** do: it does not compensate the failing step itself (it did not complete) and it compensates in **reverse** order. A compensation is a **semantic undo** ("refund", "release stock"), not a database rollback: the original effect really happened and was visible. That is why compensations must be idempotent and must themselves be retried until they succeed.

### Step 7. The program
**File: `Program.cs`**
```csharp
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
```
`File.Delete` starts each run from an empty database (it does nothing if the file does not exist). `AddHostedService(factory)` registers the **same singleton** as the hosted service, so the program can read `relay.Failures` afterwards. The `while` loop waits (at most 10 seconds) until the relay has drained the outbox; `CancellationTokenSource` makes a stuck run fail instead of hanging.

## Run it
**Predict first.** Message 1 fails once (broker down). Message 2 is delivered, then fails once (acknowledgement lost). How many publish **failures** will the relay count? How many **raw deliveries** reach the broker's consumer? How many messages are **handled once**?

In `lesson07`:
```text
dotnet run --project . --nologo
```
Expected output (not yet run; derived from the code):
```text
placed orders 1 and 2; outbox rows waiting: 2
relay failures: 2
broker deliveries: 3
messages handled once: 2
outbox rows waiting: 0
saga step: reserve-stock
saga step: charge-payment
saga step charge-payment failed: card declined
saga compensate: reserve-stock
saga result: compensated
```
The reasoning: tick 1 fails on message 1 (failure 1, nothing delivered). Tick 2 delivers message 1, then delivers message 2 and loses its acknowledgement (failure 2, delivery count now 2). Tick 3 delivers message 2 **again** (delivery 3) and marks it processed. The inbox ignores the duplicate, so two messages were handled once each. The program leaves `outbox.db` in the folder; delete it when you are done.

## How it works
```mermaid
sequenceDiagram
    participant S as OrderService
    participant DB as Database
    participant R as OutboxRelay
    participant B as Broker
    participant C as Consumer (inbox)
    S->>DB: BEGIN; insert order; insert outbox row; COMMIT
    loop every 50 ms
        R->>DB: read unprocessed rows
        R->>B: publish(message id)
        B->>C: deliver (may repeat)
        C->>DB: INSERT OR IGNORE inbox id
        R->>DB: mark processed (only after success)
    end
```
**The guarantees you now have.** Producer side: a message exists **if and only if** the business change committed. Delivery: **at-least-once** (never silently lost, sometimes repeated). Consumer: **effectively once**, because the effect is guarded by the inbox. "Exactly-once delivery" over a network is not something you can buy; "at-least-once plus idempotent handling" is how real systems get the same result.

**Choreography versus orchestration.** In a choreographed saga, services react to each other's events with no central coordinator (simple for two or three steps, hard to see and change as it grows). In an orchestrated saga (this lesson), one component knows the steps and the compensations (easier to read, test and monitor; it becomes a thing you must keep available and persist).

**Misconception:** "A saga gives you rollback." It does not. Between the first step and the compensation, other users can see the intermediate state (stock reserved, payment taken). Design the business states (`Pending`, `Confirmed`, `Cancelled`) so that the intermediate state is acceptable.

### ADR-007: Transactional outbox with a polling relay
| Field | Content |
|---|---|
| Context | Orders are saved in PostgreSQL and other services need `OrderPlaced`. A crash between save and publish has already lost events once. |
| Decision | Write an outbox row in the same transaction. A relay (a hosted service in the same process) polls and publishes with at-least-once semantics. Consumers keep an inbox keyed by message id. |
| Alternatives | Change data capture on the outbox table with a tool such as Debezium (lower latency, no polling, more infrastructure). A broker with transactional producers (ties you to one broker's semantics). |
| Consequences | + No lost events. + Works with any broker, or none. - Latency of one polling interval. - The outbox table needs cleanup. - Several relay instances can publish the same row (acceptable with idempotent consumers; otherwise lock rows, for example with `FOR UPDATE SKIP LOCKED` in PostgreSQL). |
| Revisit when | Polling load or latency becomes a measured problem: move to change data capture. |

## When not to use this
- **A single database and a single process:** if the "other service" is a method call in the same transaction, call it. An outbox adds latency and moving parts.
- **Fire-and-forget telemetry or cache notifications:** losing one is fine; a plain in-process queue (`Channel<T>`) is enough.
- **Sagas for steps that must be atomic:** if two writes truly must be all-or-nothing and can live in one database, use a database transaction and keep them in one service.
- **A hand-written relay at scale:** if you already operate a broker, evaluate your broker's or a messaging library's built-in outbox first. Read each library's current license before adopting it.

## Failure modes
- **Publish before commit:** the message can arrive before the data exists (the consumer reads a missing order). The outbox prevents it, because the relay only sees committed rows.
- **Mark processed before publish:** a crash loses the message forever. Always publish, then mark.
- **Non-idempotent consumer:** duplicates become double emails or double charges. Store the message id (or use a natural idempotency key) in the same transaction as the effect.
- **Poison message:** a message that always fails blocks the relay if it retries the same row forever and in order. Add an attempt counter, a maximum, and a **dead-letter** state with an alert.
- **Ordering assumptions:** a relay with several workers can reorder messages. If order matters per aggregate, partition by aggregate id.
- **Unbounded outbox:** processed rows pile up. Delete or archive them by age.
- **Relay crash loop:** an unhandled exception stops the host. Catch expected failures, let bugs crash loudly, and make sure the orchestrator restarts the process with a back-off.
- **Saga without persistence:** if the orchestrator's memory is the only record, a restart forgets which steps ran. Persist saga state (step, status, correlation id) after each step.
- **Compensation that can fail:** "refund" can fail too. Retry it with back-off, make it idempotent, and escalate to a human queue after N attempts.
- **Missing timeouts:** a saga step with no deadline waits forever. Each step needs a timeout (lesson 06) and a defined outcome.

## Measurements to take
- **Outbox backlog:** `SELECT COUNT(*) ... WHERE processed = 0` and the **age of the oldest unprocessed row**. This is your most important health metric; alert on the age, not just the count.
- **Publish failures per minute** and **duplicate deliveries** (inbox ignores).
- **End-to-end latency** from commit to consumer effect (p50, p99).
- **Saga outcomes** (completed, compensated, stuck) and time spent per step.
- **Table size** of `outbox` and `inbox`, and the cleanup job's duration.

## Production checklist
- [ ] Every cross-service side effect goes through an outbox row written in the business transaction.
- [ ] Consumers are idempotent (inbox table or natural key) and the effect and inbox insert share a transaction.
- [ ] The relay publishes first and marks second; failures are counted and logged with the message id.
- [ ] Poison messages are capped and dead-lettered; there is a runbook for replay.
- [ ] Outbox and inbox cleanup jobs exist and are monitored.
- [ ] `BackgroundService` code stops on `stoppingToken`, catches expected errors and uses `IServiceScopeFactory` for scoped services.
- [ ] Saga state is persisted, every step has a timeout, and compensations are idempotent and retried.
- [ ] The host's shutdown time allows an in-flight batch to finish (`HostOptions.ShutdownTimeout`).

## Try it
Rehearse a failure **later** in a saga.
1. **Guided.** Copy your finished `lesson07` to `exercise07` and add this starter file.

**File: `SagaDemo.cs`**
```csharp
namespace Outbox;

public static class SagaDemo
{
    public static async Task<bool> ShippingFailsAsync(Action<string> log)
    {
        // TODO: build three SagaStep values: reserve-stock and charge-payment succeed (their Compensate does nothing),
        // and ship-order throws new InvalidOperationException("carrier unavailable"). Run them with a SagaRunner
        // and return its result.
        await Task.CompletedTask;
        return true;
    }
}
```
Append to `Program.cs`:
```csharp
var shippingCompleted = await SagaDemo.ShippingFailsAsync(Console.WriteLine);
Console.WriteLine($"saga result: {(shippingCompleted ? "completed" : "compensated")}");
```
Expected last seven lines:
```text
saga step: reserve-stock
saga step: charge-payment
saga step: ship-order
saga step ship-order failed: carrier unavailable
saga compensate: charge-payment
saga compensate: reserve-stock
saga result: compensated
```
Check the order of the two `compensate` lines: the last finished step is undone first.

2. **Change.** Change `FlakyBroker` so message 2 is also lost on its **second** attempt. How do the four numbers in the summary change? Explain each.
3. **Stretch.** Add an `attempts` column to the outbox and a dead-letter state after 5 attempts. Which SQL statement increments it, and where in `DrainOnce` do you call it so that a crash cannot reset the count?

<details><summary>Solution (rung 1)</summary>

**File: `SagaDemo.cs`**
```csharp
namespace Outbox;

public static class SagaDemo
{
    public static async Task<bool> ShippingFailsAsync(Action<string> log)
    {
        var saga = new SagaRunner(log);
        return await saga.RunAsync(
        [
            new SagaStep("reserve-stock", () => Task.CompletedTask, () => Task.CompletedTask),
            new SagaStep("charge-payment", () => Task.CompletedTask, () => Task.CompletedTask),
            new SagaStep("ship-order", () => throw new InvalidOperationException("carrier unavailable"), () => Task.CompletedTask),
        ]);
    }
}
```
Rung 2 reasoning: failures become 3 (one more failed publish), raw deliveries become 4 (the second attempt also delivers before the ack is lost), handled stays 2 (the inbox ignores every duplicate) and the final outbox count stays 0. The invariant that must never change is **handled once = number of messages**.
</details>

## Check yourself
1. Why are the order row and the outbox row written in one transaction?
   <details><summary>Answer</summary>So that a message exists if and only if the business change committed. Two separate writes could be separated by a crash.</details>
2. **Find the bug.** A relay calls `MarkProcessed` first and `Publish` second. What goes wrong?
   <details><summary>Answer</summary>A crash or failure after marking loses the message permanently: it is processed in the table but was never sent.</details>
3. Why does the consumer keep an inbox even though the relay marks rows processed?
   <details><summary>Answer</summary>The relay can publish twice (lost acknowledgement, crash between publish and mark). The inbox makes the second delivery harmless.</details>
4. Is a saga compensation the same as a database rollback?
   <details><summary>Answer</summary>No. The original step really committed and was visible; the compensation is a new business action (refund, release) that must be idempotent and retried.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Microsoft.Data.Sqlite.SqliteException` mentioning `database is locked` (typical message) | Two processes or long transactions hold the SQLite file. | Close other programs using `outbox.db`; keep transactions short. |
| `messages handled once` is larger than the number of orders | The inbox insert is missing or uses a different id each time. | Insert the **message** id with `INSERT OR IGNORE` and check the primary key. |
| The program waits and then throws `TaskCanceledException` after about 10 seconds | The relay never drained the outbox (it crashed, or was not registered as a hosted service). | Check `AddHostedService` and that `broker.Publish` ends with success eventually. |
| Output has extra `info:` log lines | Console logging is on. | `builder.Logging.ClearProviders();` as in `Program.cs`. |
| Compiler error CS0246 for `BackgroundService` | `using Microsoft.Extensions.Hosting;` is missing from `OutboxRelay.cs`. | Add the using from Step 5. |

## Best practice
Write the message in the same transaction as the state change, deliver at-least-once, and make every consumer idempotent. Source: Background tasks with hosted services in ASP.NET Core https://learn.microsoft.com/aspnet/core/fundamentals/host/hosted-services and Saga distributed transactions pattern, Azure Architecture Center https://learn.microsoft.com/azure/architecture/patterns/saga

## Going further
- Microsoft Learn, Implement reliable background services with hosted services: https://learn.microsoft.com/aspnet/core/fundamentals/host/hosted-services (shutdown, scoped services, `BackgroundServiceExceptionBehavior`).
- The idempotency-key contract used by the platform capstone: `capstones/platform/TDD.md`.
- Lesson 09 uses these ideas when a module becomes a service.

## Summary
- You wrote a `BackgroundService` that stops cleanly and tolerates a failing broker.
- You removed the dual-write problem with a transactional outbox and absorbed duplicates with an inbox.
- You predicted failures, deliveries and handled messages from the code.
- You wrote a compensating saga and listed what makes sagas and outboxes fail in production.

## Next lesson
08. Observability with OpenTelemetry: logs, metrics and traces that let you see all of this running.
