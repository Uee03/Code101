namespace Orders.Domain;

// Owned by the inner circle: the domain states what it needs, and the outer circle adapts to it.
public interface IOrderStore
{
    int NextId();

    void Save(Order order);

    Order? Find(int id);

    // TODO 1: add a method that returns every saved order, oldest first: IReadOnlyList<Order> All();
}
