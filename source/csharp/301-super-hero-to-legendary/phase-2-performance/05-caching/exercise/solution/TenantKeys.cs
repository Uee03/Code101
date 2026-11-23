namespace Caching;

public static class TenantKeys
{
    public static string ProductKey(string tenantId, int productId)
    {
        var valid = tenantId.Length is >= 1 and <= 32 && tenantId.All(char.IsAsciiLetterOrDigit);
        if (!valid)
        {
            throw new ArgumentException("A tenant id is 1 to 32 letters or digits.", nameof(tenantId));
        }

        return $"catalog:{tenantId}:product:{productId}";
    }
}
