namespace Sales;

// A value object: no identity, equal when its values are equal, immutable, and impossible to build invalid.
public sealed record Money
{
    private Money(long cents, string currency)
    {
        Cents = cents;
        Currency = currency;
    }

    public long Cents { get; }

    public string Currency { get; }

    public static Money Of(long cents, string currency)
    {
        if (cents < 0)
        {
            throw new DomainException("Money cannot be negative.");
        }

        if (currency is not { Length: 3 } || !currency.All(char.IsAsciiLetterUpper))
        {
            throw new DomainException("A currency is three upper-case letters, for example EUR.");
        }

        return new Money(cents, currency);
    }

    public static Money Zero(string currency) => Of(0, currency);

    public Money Add(Money other)
    {
        if (other.Currency != Currency)
        {
            throw new DomainException("Currencies differ.");
        }

        return new Money(checked(Cents + other.Cents), Currency);
    }

    public Money Times(int factor) => new(checked(Cents * factor), Currency);

    public override string ToString() => $"{Cents / 100}.{Cents % 100:00} {Currency}";
}
