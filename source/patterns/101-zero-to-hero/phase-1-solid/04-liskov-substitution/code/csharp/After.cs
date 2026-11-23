namespace After;

public interface IPayable
{
    string Pay(int cents);
}

public interface IRefundable : IPayable
{
    string Refund(int cents);
}

public class CardPayment : IRefundable
{
    public string Pay(int cents)
    {
        return $"Card charged {cents}";
    }

    public string Refund(int cents)
    {
        return $"Card refunded {cents}";
    }
}

public class GiftCardPayment : IPayable
{
    public string Pay(int cents)
    {
        return $"Gift card used for {cents}";
    }
}

public static class Orders
{
    public static string CancelOrder(IRefundable payment, int cents)
    {
        return payment.Refund(cents);
    }
}
