using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace Shop.Host.Remote;

public sealed class RemoteBillingOptions
{
    public string BaseAddress { get; set; } = "";
    public string TokenEndpoint { get; set; } = "";
    public string ClientId { get; set; } = "";

    // Never put the secret in a file: supply it as the environment variable Billing__Remote__ClientSecret.
    public string ClientSecret { get; set; } = "";
}

// Gets a service-account token with the client credentials grant and reuses it until shortly before it expires.
public sealed class ServiceTokenProvider(IHttpClientFactory clients, IOptions<RemoteBillingOptions> options, TimeProvider time)
{
    private readonly SemaphoreSlim gate = new(1, 1);
    private string? token;
    private DateTimeOffset expiresAt;

    public async Task<string> GetTokenAsync(CancellationToken ct)
    {
        await gate.WaitAsync(ct);
        try
        {
            if (token is not null && time.GetUtcNow() < expiresAt)
            {
                return token;
            }

            var settings = options.Value;
            using var form = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "client_credentials",
                ["client_id"] = settings.ClientId,
                ["client_secret"] = settings.ClientSecret,
            });
            using var response = await clients.CreateClient("token").PostAsync(settings.TokenEndpoint, form, ct);
            response.EnsureSuccessStatusCode();

            using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            token = document.RootElement.GetProperty("access_token").GetString()!;
            var lifetimeSeconds = document.RootElement.GetProperty("expires_in").GetInt32();
            expiresAt = time.GetUtcNow().AddSeconds(Math.Max(lifetimeSeconds - 30, 1));
            return token;
        }
        finally
        {
            gate.Release();
        }
    }
}

// Adds "Authorization: Bearer <token>" to every outgoing call of the billing client.
public sealed class ServiceTokenHandler(ServiceTokenProvider tokens) : DelegatingHandler
{
    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetTokenAsync(cancellationToken));
        return await base.SendAsync(request, cancellationToken);
    }
}
