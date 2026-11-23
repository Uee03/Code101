from abc import ABC, abstractmethod


class Payable(ABC):
    @abstractmethod
    def pay(self, cents):
        ...


class Refundable(Payable):
    @abstractmethod
    def refund(self, cents):
        ...


class CardPayment(Refundable):
    def pay(self, cents):
        return f"Card charged {cents}"

    def refund(self, cents):
        return f"Card refunded {cents}"


class GiftCardPayment(Payable):
    def pay(self, cents):
        return f"Gift card used for {cents}"


def cancel_order(payment: Refundable, cents: int) -> str:
    return payment.refund(cents)
