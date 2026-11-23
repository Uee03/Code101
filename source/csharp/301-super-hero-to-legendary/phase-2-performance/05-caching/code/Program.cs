using Caching;
using Microsoft.Extensions.Caching.Hybrid;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

var ct = CancellationToken.None;
var redis = Environment.GetEnvironmentVariable("REDIS_CONFIGURATION");

var builder = Host.CreateApplicationBuilder(args);
builder.Logging.ClearProviders();
builder.Services.AddMemoryCache();
if (!string.IsNullOrEmpty(redis))
{
    // When an IDistributedCache is registered, HybridCache uses it as its second level (L2) automatically.
    builder.Services.AddStackExchangeRedisCache(options => options.Configuration = redis);
}

builder.Services.AddHybridCache(options =>
{
    options.DefaultEntryOptions = new HybridCacheEntryOptions
    {
        Expiration = TimeSpan.FromMinutes(5),
        LocalCacheExpiration = TimeSpan.FromMinutes(1),
    };
});

using var host = builder.Build();
var memory = host.Services.GetRequiredService<IMemoryCache>();
var hybrid = host.Services.GetRequiredService<HybridCache>();
Console.WriteLine(string.IsNullOrEmpty(redis) ? "L2 cache: none (memory only)" : "L2 cache: Redis");

// 1. IMemoryCache: simple and fast, but one process only and no protection against a stampede.
var memoryCatalog = new SlowCatalog();
for (var i = 0; i < 3; i++)
{
    await memory.GetOrCreateAsync("product:1", entry =>
    {
        entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1);
        return memoryCatalog.LoadAsync(1, ct);
    });
}

Console.WriteLine($"IMemoryCache, 3 sequential calls: {memoryCatalog.Loads} load(s)");

// 2. Five callers ask for the same missing key at the same moment (a cache stampede).
var stampedeCatalog = new SlowCatalog();
await Task.WhenAll(Enumerable.Range(0, 5).Select(_ => memory.GetOrCreateAsync("product:2", entry =>
{
    entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1);
    return stampedeCatalog.LoadAsync(2, ct);
})));
Console.WriteLine($"IMemoryCache, 5 parallel callers: {stampedeCatalog.Loads} load(s) (usually more than 1; varies between runs)");

// 3. HybridCache runs the factory once per key per process and makes the other callers wait for it.
var hybridCatalog = new SlowCatalog();
await Task.WhenAll(Enumerable.Range(0, 5).Select(_ => hybrid.GetOrCreateAsync(
    "hybrid:product:3",
    token => new ValueTask<Product>(hybridCatalog.LoadAsync(3, token)),
    cancellationToken: ct).AsTask()));
Console.WriteLine($"HybridCache, 5 parallel callers: {hybridCatalog.Loads} load(s)");

// 4. Staleness and invalidation. The run id keeps keys from an earlier run (kept by Redis) out of this run.
var runId = Guid.NewGuid().ToString("N")[..8];
var catalog = new SlowCatalog();

ValueTask<Product> Read(int id) => hybrid.GetOrCreateAsync(
    $"catalog:{runId}:product:{id}",
    token => new ValueTask<Product>(catalog.LoadAsync(id, token)),
    tags: ["catalog"],
    cancellationToken: ct);

_ = await Read(7);
_ = await Read(7);
Console.WriteLine($"HybridCache, 2 sequential calls: {catalog.Loads} load(s)");

catalog.PriceCents = 1200;
var stale = await Read(7);
Console.WriteLine($"Price in the database: {catalog.PriceCents}, price served from cache: {stale.PriceCents}");

await hybrid.RemoveByTagAsync("catalog", ct);
var fresh = await Read(7);
Console.WriteLine($"After RemoveByTagAsync: price {fresh.PriceCents}, {catalog.Loads} load(s)");

await hybrid.RemoveAsync($"catalog:{runId}:product:7", ct);
_ = await Read(7);
Console.WriteLine($"After RemoveAsync: {catalog.Loads} load(s)");
