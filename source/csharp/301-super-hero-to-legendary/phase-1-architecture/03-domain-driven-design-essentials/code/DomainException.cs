namespace Sales;

// Thrown when a business rule (an invariant) would be broken. Callers translate it into a 4xx answer, not a 500.
public sealed class DomainException(string message) : Exception(message);
