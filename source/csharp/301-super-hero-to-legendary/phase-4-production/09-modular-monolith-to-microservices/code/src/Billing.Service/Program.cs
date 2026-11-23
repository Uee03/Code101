using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Shop.Billing;

var builder = WebApplication.CreateBuilder(args);
var auth = builder.Configuration.GetSection("Auth");

builder.Services.AddBillingModule();

// Validate Keycloak access tokens: signature (keys come from the discovery document), issuer, audience and lifetime.
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.MetadataAddress = auth["MetadataAddress"]!;
    options.RequireHttpsMetadata = auth.GetValue("RequireHttpsMetadata", true);
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = auth["Issuer"],
        ValidateAudience = true,
        ValidAudience = auth["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.FromSeconds(30),
        ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
    };
});

// Authenticated is not enough: the caller must hold the "charge" role on this service's client in Keycloak.
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("billing-charge", policy => policy
        .RequireAuthenticatedUser()
        .RequireAssertion(context => HasClientRole(context.User, "billing-service", "charge")));

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();
app.MapBillingEndpoints("billing-charge");
app.Run();

static bool HasClientRole(ClaimsPrincipal user, string client, string role)
{
    var claim = user.FindFirst("resource_access")?.Value;
    if (claim is null)
    {
        return false;
    }

    try
    {
        using var document = JsonDocument.Parse(claim);
        return document.RootElement.TryGetProperty(client, out var entry)
            && entry.TryGetProperty("roles", out var roles)
            && roles.EnumerateArray().Any(item => item.GetString() == role);
    }
    catch (JsonException)
    {
        return false;
    }
}
