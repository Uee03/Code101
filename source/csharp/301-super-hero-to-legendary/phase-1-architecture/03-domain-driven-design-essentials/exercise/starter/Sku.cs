namespace Sales;

// TODO: make Sku a value object like Money: private constructor, a static Of(string value) factory, and record equality.
public sealed record Sku
{
    private Sku(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static Sku Of(string value)
    {
        // TODO: reject anything that is not 3 to 12 upper-case letters, digits or hyphens.
        // Throw new DomainException("A SKU is 3 to 12 upper-case letters, digits or hyphens.")
        return new Sku(value);
    }

    public override string ToString() => Value;
}
