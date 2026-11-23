from abc import ABC, abstractmethod


class DiscountRule(ABC):
    @abstractmethod
    def apply(self, total_cents):
        ...


class NoDiscount(DiscountRule):
    def apply(self, total_cents):
        return total_cents


class PercentDiscount(DiscountRule):
    def __init__(self, percent):
        self.percent = percent

    def apply(self, total_cents):
        return total_cents - total_cents * self.percent // 100


class Notifier(ABC):
    @abstractmethod
    def notify(self, address, text):
        ...


class EmailNotifier(Notifier):
    def notify(self, address, text):
        print(f"Email to {address}: {text}")


class SmsNotifier(Notifier):
    def notify(self, address, text):
        print(f"SMS to {address}: {text}")


class OrderStore:
    def __init__(self):
        self.addresses = []

    def save(self, address):
        self.addresses.append(address)
        print(f"Saved order for {address}")

    def count(self):
        return len(self.addresses)


class OrderProcessor:
    def __init__(self, discount: DiscountRule, notifier: Notifier, store: OrderStore):
        self.discount = discount
        self.notifier = notifier
        self.store = store

    def process(self, address, items):
        subtotal = 0
        for _, price, qty in items:
            subtotal += price * qty
        total = self.discount.apply(subtotal)
        self.notifier.notify(address, f"order total {total}")
        self.store.save(address)
