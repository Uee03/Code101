public sealed class ThresholdOff(decimal threshold, decimal amount) : Discount
{
    public override string Name => $"{amount:F2} off over {threshold:F2}";

    protected override decimal Calculate(decimal price) => price >= threshold ? amount : 0m;
}
