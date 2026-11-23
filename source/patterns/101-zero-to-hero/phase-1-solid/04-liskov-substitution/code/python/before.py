from abc import ABC, abstractmethod


class PaymentMethod(ABC):
    @abstractmethod
    def pay(self, cents):
        ...

    @abstractmethod
    def refund(self, cents):
        ...


class CardPayment(PaymentMethod):
    def pay(self, cents):
        return f"Card charged {cents}"

    def refund(self, cents):
        return f"Card refunded {cents}"


class GiftCardPayment(PaymentMethod):
    def pay(self, cents):
        return f"Gift card used for {cents}"

    def refund(self, cents):
        raise RuntimeError("gift cards cannot be refunded")


def cancel_order(payment, cents):
    return payment.refund(cents)
