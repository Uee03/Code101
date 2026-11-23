namespace Caching;

public static class TenantKeys
{
    // TODO: throw ArgumentException unless tenantId is 1 to 32 letters or digits (it becomes part of a cache key).
    public static string ProductKey(string tenantId, int productId) => $"catalog:{tenantId}:product:{productId}";
}
