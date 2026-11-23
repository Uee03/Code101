using Shop.Contracts;

namespace Shop.Host.Remote;

// Same interface as the in-process module, now over HTTP: the order code cannot tell the difference.
public sealed class HttpBillingApi(HttpClient client) : IBillingApi
{
    public async Task<ChargeResult> ChargeAsync(ChargeRequest request, CancellationToken ct)
    {
        using var response = await client.PostAsJsonAsync("/billing/charges", request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<ChargeResult>(ct)
            ?? throw new InvalidOperationException("The billing service returned an empty body.");
    }
}
