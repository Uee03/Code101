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
    # TODO 1: create one Clock for the given day and one ReceiptPrinter that uses it.
    #         Return a Checkout that uses the printer. This function is the composition root.
    raise NotImplementedError


print(compose("2026-03-01").pay(5))
# TODO 2: print a second line that uses compose with the day "2000-01-01".
