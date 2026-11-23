from abc import ABC, abstractmethod
from datetime import date


class Clock(ABC):
    @abstractmethod
    def today(self):
        ...


class SystemClock(Clock):
    def today(self):
        return date.today()


class FixedClock(Clock):
    def __init__(self, day):
        self.day = day

    def today(self):
        return self.day


class InvoiceStamper:
    def __init__(self, clock: Clock):
        self.clock = clock

    def stamp(self, number):
        return f"Invoice {number} issued {self.clock.today()}"


stamper = InvoiceStamper(FixedClock(date(2026, 1, 15)))
print(stamper.stamp(7))
