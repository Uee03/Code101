using System.Security.Claims;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

public sealed class TokenIssuer(SecurityKey key)
{
    public const string Issuer = "notes-api";
    public const string Audience = "notes-clients";

    public string Create(string userId, string role, IEnumerable<string> permissions)
    {
        var claims = new List<Claim>
        {
            new("sub", userId),
            new("name", userId),
            new("role", role),
        };
        claims.AddRange(permissions.Select(p => new Claim("permission", p)));

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = Issuer,
            Audience = Audience,
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(15),
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256),
        };

        return new JsonWebTokenHandler().CreateToken(descriptor);
    }
}
