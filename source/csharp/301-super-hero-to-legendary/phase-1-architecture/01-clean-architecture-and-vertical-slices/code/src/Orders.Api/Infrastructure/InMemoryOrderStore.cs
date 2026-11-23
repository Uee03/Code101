using System.Collections.Concurrent;
using Orders.Domain;

namespace Orders.Api.Infrastructure;

public sealed class InMemoryOrderStore : IOrderStore
{
    private readonly ConcurrentDictionary<int, Order> orders = new();
    private int lastId;

    public int NextId() => Interlocked.Increment(ref lastId);

    public void Save(Order order) => orders[order.Id] = order;

    public Order? Find(int id) => orders.TryGetValue(id, out var order) ? order : null;
}
