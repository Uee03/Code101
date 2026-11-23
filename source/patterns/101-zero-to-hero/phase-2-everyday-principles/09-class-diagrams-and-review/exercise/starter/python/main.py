class BookingManager:
    def book(self, ticket_kind, channel, address, seats):
        if ticket_kind == "adult":
            price = 1000
        elif ticket_kind == "child":
            price = 500
        else:
            price = 1000
        total = price * seats
        if channel == "email":
            print(f"Email to {address}: booking for {seats} seat(s), total {total}")
        elif channel == "sms":
            print(f"SMS to {address}: booking for {seats} seat(s), total {total}")
        print(f"Booking saved for {address}")


# Mixed review. The class above breaks several principles from this track.
# TODO 1: write down which smells you see (which of S, O, D, and which of DRY, KISS, YAGNI).
# TODO 2: make an abstract class PriceRule with seat_cents(), and AdultPrice (1000) and ChildPrice (500).
# TODO 3: make an abstract class Notifier with notify(address, text), and EmailNotifier and SmsNotifier.
# TODO 4: make a class BookingStore whose save(address) prints "Booking saved for <address>".
# TODO 5: change BookingManager so its constructor receives a PriceRule, a Notifier and a BookingStore,
#         and book(address, seats) uses them. Wire the objects together below. The output must not change.
# TODO 6: draw the result as a Mermaid class diagram in a file diagram.md.

manager = BookingManager()
manager.book("adult", "email", "ana@example.com", 2)
manager.book("child", "sms", "+100", 3)
