from abc import ABC, abstractmethod


class Shipping(ABC):
    @abstractmethod
    def cost(self, weight_grams: int) -> int:
        ...


class Pickup(Shipping):
    def cost(self, weight_grams: int) -> int:
        return 0


class Standard(Shipping):
    def cost(self, weight_grams: int) -> int:
        return 500


class Express(Shipping):
    def cost(self, weight_grams: int) -> int:
        return 1000 + weight_grams // 10


class Order:
    def __init__(self, weight_grams: int, shipping: Shipping) -> None:
        self._weight_grams = weight_grams
        self.shipping = shipping

    def shipping_cents(self) -> int:
        return self.shipping.cost(self._weight_grams)


def demo() -> None:
    order = Order(2500, Pickup())
    print(f"pickup: {order.shipping_cents()}")
    order.shipping = Standard()
    print(f"standard: {order.shipping_cents()}")
    order.shipping = Express()
    print(f"express: {order.shipping_cents()}")
