class Order:
    def __init__(self, customer, prices):
        self.customer = customer
        self.prices = prices

    def total(self):
        return sum(self.prices)


class ReceiptFormatter:
    def format(self, order):
        return f"Receipt for {order.customer}: {order.total()} cents"


class SmsSender:
    def send(self, order, text):
        print(f"SMS to {order.customer}: {text}")


order = Order("Ben", [500, 250, 125])
text = ReceiptFormatter().format(order)
SmsSender().send(order, text)
