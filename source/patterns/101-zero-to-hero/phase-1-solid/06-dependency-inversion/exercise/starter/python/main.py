from datetime import date


class InvoiceStamper:
    def stamp(self, number):
        return f"Invoice {number} issued {date.today()}"


# TODO 1: make an abstract class Clock (ABC) with an abstract method today().
# TODO 2: make SystemClock (today() returns date.today()) and FixedClock
#         (it receives a date in __init__ and today() returns that date).
# TODO 3: give InvoiceStamper an __init__ that receives a clock and use self.clock.today() in stamp.
# TODO 4: change the two lines below so the stamper is created with FixedClock(date(2026, 1, 15)).

stamper = InvoiceStamper()
print(stamper.stamp(7))
