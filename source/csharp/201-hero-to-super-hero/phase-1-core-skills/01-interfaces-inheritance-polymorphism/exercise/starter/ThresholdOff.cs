public sealed class ThresholdOff(decimal threshold, decimal amount) : Discount
{
    public override string Name => $"{amount:F2} off over {threshold:F2}";

    protected override decimal Calculate(decimal price)
    {
        // TODO: return amount when price is at least threshold, otherwise 0.
        return 0m;
    }
}
