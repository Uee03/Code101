class Order:
    def __init__(self, customer, prices):
        self.customer = customer
        self.prices = prices

    def total(self):
        return sum(self.prices)

    def receipt_text(self):
        return f"Receipt for {self.customer}: {self.total()} cents"

    def send_confirmation(self):
        print(f"SMS to {self.customer}: {self.receipt_text()}")


# TODO 1: make a class ReceiptFormatter with format(order) that returns the receipt text.
# TODO 2: make a class SmsSender with send(order, text) that prints the SMS line.
# TODO 3: remove receipt_text and send_confirmation from Order, then change the lines
#         below so the formatter and the sender do those jobs. The output must not change.

order = Order("Ben", [500, 250, 125])
order.send_confirmation()
