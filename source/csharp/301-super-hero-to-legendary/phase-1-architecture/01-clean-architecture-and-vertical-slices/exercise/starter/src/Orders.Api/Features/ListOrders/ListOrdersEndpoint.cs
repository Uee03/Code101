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
        // TODO 3: map GET /orders and allow anonymous callers (this lesson has no identity).
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        // TODO 4: build the response from the order list returned by the store, then send it with Send.OkAsync.
        await Send.OkAsync(new ListOrdersResponse(), ct);
    }
}
