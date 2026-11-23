using FastEndpoints;
using Orders.Domain;

namespace Orders.Api.Features.ListOrders;

public sealed class OrderSummary
{
    public int Id { get; set; }
    public string Customer { get; set; } = "";
    public int TotalCents { get; set; }
}

public sealed class ListOrdersResponse
{
    public List<OrderSummary> Orders { get; set; } = [];
}

// GET /orders: a third slice. Keep it inside this folder; do not call GetOrderEndpoint.
public sealed class ListOrdersEndpoint(IOrderStore store) : EndpointWithoutRequest<ListOrdersResponse>
{
    public override void Configure()
    {
        Get("/orders");
        AllowAnonymous();
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        var response = new ListOrdersResponse
        {
            Orders = store.All()
                .Select(order => new OrderSummary { Id = order.Id, Customer = order.Customer, TotalCents = order.TotalCents })
                .ToList(),
        };
        await Send.OkAsync(response, ct);
    }
}
