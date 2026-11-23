from abc import ABC, abstractmethod


class PriceRule(ABC):
    @abstractmethod
    def seat_cents(self):
        ...


class AdultPrice(PriceRule):
    def seat_cents(self):
        return 1000


class ChildPrice(PriceRule):
    def seat_cents(self):
        return 500


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


class BookingStore:
    def save(self, address):
        print(f"Booking saved for {address}")


class BookingManager:
    def __init__(self, price_rule: PriceRule, notifier: Notifier, store: BookingStore):
        self.price_rule = price_rule
        self.notifier = notifier
        self.store = store

    def book(self, address, seats):
        total = self.price_rule.seat_cents() * seats
        self.notifier.notify(address, f"booking for {seats} seat(s), total {total}")
        self.store.save(address)


store = BookingStore()
BookingManager(AdultPrice(), EmailNotifier(), store).book("ana@example.com", 2)
BookingManager(ChildPrice(), SmsNotifier(), store).book("+100", 3)
