using FastEndpoints;
using Orders.Domain;

namespace Orders.Api.Features.GetOrder;

public sealed class GetOrderRequest
{
    public int Id { get; set; }
}

public sealed class GetOrderResponse
{
    public int Id { get; set; }
    public string Customer { get; set; } = "";
    public int TotalCents { get; set; }
    public int LineCount { get; set; }
}

// GET /orders/{id}: a second slice. It shares the domain and the port, never another slice's code.
public sealed class GetOrderEndpoint(IOrderStore store) : Endpoint<GetOrderRequest, GetOrderResponse>
{
    public override void Configure()
    {
        Get("/orders/{id}");
        AllowAnonymous();
    }

    public override async Task HandleAsync(GetOrderRequest req, CancellationToken ct)
    {
        var order = store.Find(req.Id);
        if (order is null)
        {
            await Send.NotFoundAsync(ct);
            return;
        }

        var response = new GetOrderResponse
        {
            Id = order.Id,
            Customer = order.Customer,
            TotalCents = order.TotalCents,
            LineCount = order.Lines.Count,
        };
        await Send.OkAsync(response, ct);
    }
}
