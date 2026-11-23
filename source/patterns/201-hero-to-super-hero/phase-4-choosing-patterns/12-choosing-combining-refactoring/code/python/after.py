from abc import ABC, abstractmethod
from typing import Optional

Item = tuple[str, int, int]


class Order:
    def __init__(self, items: list[Item], shipping: str, coupon: Optional[str], email: str) -> None:
        self.items = items
        self.shipping = shipping
        self.coupon = coupon
        self.email = email


class Discount(ABC):
    @abstractmethod
    def amount(self, subtotal: int) -> int:
        ...


class NoDiscount(Discount):
    def amount(self, subtotal: int) -> int:
        return 0


class PercentOff(Discount):
    def __init__(self, percent: int) -> None:
        self._percent = percent

    def amount(self, subtotal: int) -> int:
        return subtotal * self._percent // 100


class FlatOff(Discount):
    def __init__(self, cents: int) -> None:
        self._cents = cents

    def amount(self, subtotal: int) -> int:
        return min(self._cents, subtotal)


class Shipping(ABC):
    @abstractmethod
    def cost(self) -> int:
        ...


class FlatShipping(Shipping):
    def __init__(self, cents: int) -> None:
        self._cents = cents

    def cost(self) -> int:
        return self._cents


DISCOUNTS: dict[str, Discount] = {"WELCOME10": PercentOff(10), "FIVEOFF": FlatOff(500)}
SHIPPING: dict[str, Shipping] = {
    "pickup": FlatShipping(0),
    "standard": FlatShipping(500),
    "express": FlatShipping(1500),
}


class Rule(ABC):
    def __init__(self) -> None:
        self._next: Optional["Rule"] = None

    def set_next(self, rule: "Rule") -> "Rule":
        self._next = rule
        return rule

    def check(self, order: Order) -> Optional[str]:
        problem = self.problem(order)
        if problem is not None:
            return problem
        if self._next is not None:
            return self._next.check(order)
        return None

    @abstractmethod
    def problem(self, order: Order) -> Optional[str]:
        ...


class NotEmpty(Rule):
    def problem(self, order: Order) -> Optional[str]:
        if len(order.items) == 0:
            return "cart is empty"
        return None


class PositiveQuantities(Rule):
    def problem(self, order: Order) -> Optional[str]:
        for name, _price, quantity in order.items:
            if quantity <= 0:
                return f"bad quantity for {name}"
        return None


class KnownShipping(Rule):
    def problem(self, order: Order) -> Optional[str]:
        if order.shipping not in SHIPPING:
            return f"unknown shipping {order.shipping}"
        return None


class Listener(ABC):
    @abstractmethod
    def order_placed(self, email: str, total: int) -> str:
        ...


class EmailNotice(Listener):
    def order_placed(self, email: str, total: int) -> str:
        return f"email to {email}: order total {total}"


class AuditLog(Listener):
    def order_placed(self, email: str, total: int) -> str:
        return "log: order placed"


class Checkout:
    def __init__(self, rules: Rule, listeners: list[Listener]) -> None:
        self._rules = rules
        self._listeners = listeners

    def place(self, order: Order) -> list[str]:
        problem = self._rules.check(order)
        if problem is not None:
            return [f"error: {problem}"]
        subtotal = sum(price * quantity for _name, price, quantity in order.items)
        discount = DISCOUNTS.get(order.coupon or "", NoDiscount()).amount(subtotal)
        shipping = SHIPPING[order.shipping].cost()
        taxable = subtotal - discount
        tax = taxable * 20 // 100
        total = taxable + tax + shipping
        lines = [
            f"subtotal: {subtotal}",
            f"discount: {discount}",
            f"shipping: {shipping}",
            f"tax: {tax}",
            f"total: {total}",
        ]
        for listener in self._listeners:
            lines.append(listener.order_placed(order.email, total))
        return lines


def place_order(items: list[Item], shipping: str, coupon: Optional[str], email: str) -> list[str]:
    rules = NotEmpty()
    rules.set_next(PositiveQuantities()).set_next(KnownShipping())
    checkout = Checkout(rules, [EmailNotice(), AuditLog()])
    return checkout.place(Order(items, shipping, coupon, email))
