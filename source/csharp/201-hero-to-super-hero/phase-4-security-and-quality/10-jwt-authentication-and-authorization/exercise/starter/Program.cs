using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var signingKey = new SymmetricSecurityKey(RandomNumberGenerator.GetBytes(32));

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton(new TokenIssuer(signingKey));

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = TokenIssuer.Issuer,
            ValidateAudience = true,
            ValidAudience = TokenIssuer.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = signingKey,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            NameClaimType = "name",
            RoleClaimType = "role",
        };
    });

// TODO 1: add a policy named "CanReadNotes" that requires the claim permission = notes:read.
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("CanWriteNotes", policy => policy.RequireClaim("permission", "notes:write"))
    .AddPolicy("AdminOnly", policy => policy.RequireRole("admin"));

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

Dictionary<int, string> noteOwners = new() { [1] = "ada", [2] = "grace" };

app.MapGet("/public", () => "Anyone can read this.");

app.MapGet("/me", (ClaimsPrincipal user) => new
{
    name = user.Identity?.Name,
    role = user.FindFirst("role")?.Value,
    permissions = user.FindAll("permission").Select(c => c.Value).ToArray(),
}).RequireAuthorization();

// TODO 2: map GET /notes that returns every note as { id, owner }, ordered by id, protected by the CanReadNotes policy.

app.MapGet("/notes/{id:int}", (int id, ClaimsPrincipal user) =>
{
    if (!noteOwners.TryGetValue(id, out string? owner))
    {
        return Results.NotFound();
    }

    bool isOwner = user.FindFirst("sub")?.Value == owner;
    if (isOwner || user.IsInRole("admin"))
    {
        return Results.Ok(new { id, owner });
    }

    // TODO 3: answer 404 instead of 403 so that strangers cannot learn which ids exist.
    return Results.Forbid();
}).RequireAuthorization();

app.MapPost("/notes", (ClaimsPrincipal user) =>
    Results.Created("/notes/3", new { id = 3, owner = user.FindFirst("sub")?.Value }))
    .RequireAuthorization("CanWriteNotes");

app.MapDelete("/notes/{id:int}", (int id) => Results.NoContent())
    .RequireAuthorization("AdminOnly");

if (app.Environment.IsDevelopment())
{
    app.MapPost("/dev/token", (string who, TokenIssuer issuer) =>
        DemoUsers.All.TryGetValue(who, out DemoUser? demo)
            ? Results.Text(issuer.Create(who, demo.Role, demo.Permissions))
            : Results.NotFound());
}

app.Run();
