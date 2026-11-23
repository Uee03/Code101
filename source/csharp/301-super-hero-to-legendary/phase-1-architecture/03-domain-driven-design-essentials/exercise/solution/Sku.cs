namespace Sales;

public sealed record Sku
{
    private Sku(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static Sku Of(string value)
    {
        var valid = value.Length is >= 3 and <= 12
            && value.All(c => char.IsAsciiLetterUpper(c) || char.IsAsciiDigit(c) || c == '-');
        if (!valid)
        {
            throw new DomainException("A SKU is 3 to 12 upper-case letters, digits or hyphens.");
        }

        return new Sku(value);
    }

    public override string ToString() => Value;
}
