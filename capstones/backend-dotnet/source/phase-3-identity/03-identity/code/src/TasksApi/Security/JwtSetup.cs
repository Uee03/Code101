using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using TasksApi.Common;

namespace TasksApi.Security;

public sealed class AuthOptions
{
    public string Issuer { get; init; } = "";
    public string MetadataAddress { get; init; } = "";
    public string Audience { get; init; } = "tasks-api";
    public bool RequireHttpsMetadata { get; init; } = true;
}

public static class JwtSetup
{
    // Validates Keycloak access tokens: signature (keys fetched and cached from the discovery document), issuer, audience, lifetime.
    public static IServiceCollection AddKeycloakJwt(this IServiceCollection services, IConfiguration configuration)
    {
        var auth = configuration.GetSection("Auth").Get<AuthOptions>() ?? new AuthOptions();
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
        {
            options.MetadataAddress = auth.MetadataAddress;
            options.RequireHttpsMetadata = auth.RequireHttpsMetadata;
            options.MapInboundClaims = false;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = auth.Issuer,
                ValidateAudience = true,
                ValidAudience = auth.Audience,
                ValidateLifetime = true,
                RequireExpirationTime = true,
                ClockSkew = TimeSpan.FromSeconds(30),
                RequireSignedTokens = true,
                ValidateIssuerSigningKey = true,
                ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
            };
            options.Events = new JwtBearerEvents
            {
                // JwtBearer also trusts the issuer written in the discovery document. We want exactly the configured one.
                OnTokenValidated = context =>
                {
                    if (context.Principal?.FindFirstValue("iss") != auth.Issuer)
                    {
                        context.Fail("The token issuer is not the configured issuer.");
                    }
                    return Task.CompletedTask;
                },
                OnChallenge = async context =>
                {
                    context.HandleResponse();
                    var invalid = context.AuthenticateFailure is not null;
                    context.Response.Headers.WWWAuthenticate = invalid
                        ? "Bearer realm=\"tasksteams\", error=\"invalid_token\""
                        : "Bearer realm=\"tasksteams\"";
                    await ProblemResponses.WriteAsync(context.HttpContext, StatusCodes.Status401Unauthorized,
                        invalid ? "The access token is invalid or has expired." : "A bearer access token is required.");
                },
            };
        });
        return services;
    }
}
