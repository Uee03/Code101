namespace Before;

public abstract class PaymentMethod
{
    public abstract string Pay(int cents);

    public abstract string Refund(int cents);
}

public class CardPayment : PaymentMethod
{
    public override string Pay(int cents)
    {
        return $"Card charged {cents}";
    }

    public override string Refund(int cents)
    {
        return $"Card refunded {cents}";
    }
}

public class GiftCardPayment : PaymentMethod
{
    public override string Pay(int cents)
    {
        return $"Gift card used for {cents}";
    }

    public override string Refund(int cents)
    {
        throw new NotSupportedException("gift cards cannot be refunded");
    }
}

public static class Orders
{
    public static string CancelOrder(PaymentMethod payment, int cents)
    {
        return payment.Refund(cents);
    }
}
