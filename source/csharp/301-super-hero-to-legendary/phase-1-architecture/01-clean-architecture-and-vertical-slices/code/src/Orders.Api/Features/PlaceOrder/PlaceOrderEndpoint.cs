using FastEndpoints;
using FluentValidation;
using Orders.Domain;

namespace Orders.Api.Features.PlaceOrder;

public sealed class PlaceOrderRequest
{
    public string Customer { get; set; } = "";
    public List<PlaceOrderLine> Lines { get; set; } = [];
}

public sealed class PlaceOrderLine
{
    public string Sku { get; set; } = "";
    public int Quantity { get; set; }
    public int UnitPriceCents { get; set; }
}

public sealed class PlaceOrderResponse
{
    public int Id { get; set; }
    public string Customer { get; set; } = "";
    public int TotalCents { get; set; }
}

public sealed class PlaceOrderValidator : Validator<PlaceOrderRequest>
{
    public PlaceOrderValidator()
    {
        RuleFor(x => x.Customer).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Lines).NotEmpty().Must(lines => lines.Count <= 50).WithMessage("must have at most 50 lines");
        RuleForEach(x => x.Lines).ChildRules(line =>
        {
            line.RuleFor(l => l.Sku).NotEmpty().MaximumLength(40);
            line.RuleFor(l => l.Quantity).InclusiveBetween(1, 1000);
            line.RuleFor(l => l.UnitPriceCents).GreaterThan(0);
        });
    }
}

// POST /orders: the whole slice (request, rules, handler, response) lives in this one folder.
public sealed class PlaceOrderEndpoint(IOrderStore store) : Endpoint<PlaceOrderRequest, PlaceOrderResponse>
{
    public override void Configure()
    {
        Post("/orders");
        AllowAnonymous();
    }

    public override async Task HandleAsync(PlaceOrderRequest req, CancellationToken ct)
    {
        var lines = req.Lines.Select(l => new OrderLine(l.Sku, l.Quantity, l.UnitPriceCents));
        var order = Order.Place(store.NextId(), req.Customer, lines);
        store.Save(order);

        var response = new PlaceOrderResponse { Id = order.Id, Customer = order.Customer, TotalCents = order.TotalCents };
        await Send.ResponseAsync(response, StatusCodes.Status201Created, ct);
    }
}
