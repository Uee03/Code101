class Clock:
    def __init__(self, day):
        self.day = day

    def today(self):
        return self.day


class ReceiptPrinter:
    def __init__(self, clock):
        self.clock = clock

    def render(self, text):
        return f"{self.clock.today()}: {text}"


class Checkout:
    def __init__(self, printer):
        self.printer = printer

    def pay(self, amount):
        return self.printer.render(f"paid {amount}")


def compose(day):
    clock = Clock(day)
    printer = ReceiptPrinter(clock)
    return Checkout(printer)


print(compose("2026-03-01").pay(5))
print(compose("2000-01-01").pay(5))
