namespace Shop.Contracts;

public sealed record ChargeRequest(int OrderId, int AmountCents);

public sealed record ChargeResult(int OrderId, string Status, string Reference);

// The module's public face. Everything else about billing is internal to the Billing module.
public interface IBillingApi
{
    Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken ct);
}
