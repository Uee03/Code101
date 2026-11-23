def make_invoice(name, email, street, city, zip_code, items, coupon, country, express):
    total = 0
    for item in items:
        total += item[1] * item[2]
    if coupon == "SAVE10":
        total -= total // 10
    elif coupon == "SAVE20":
        total -= total // 5
    if country == "DE":
        total += total * 19 // 100
    elif country == "FR":
        total += total * 20 // 100
    if express:
        if country == "US":
            if total > 10000:
                total += 0
            else:
                total += 2500
        else:
            total += 4000
    address = f"{street}, {zip_code} {city}"
    return f"Invoice for {name} <{email}>\n{address}\nTotal: {total}"


def label(order_id, amount):
    return f"#{order_id}: {amount}"


class OrderManager:
    def __init__(self):
        self.orders = []

    def add(self, order):
        self.orders.append(order)

    def total(self):
        return sum(o["amount"] for o in self.orders)

    def to_csv(self):
        return "\n".join(f"{o['id']},{o['amount']}" for o in self.orders)

    def send_email(self, address):
        return f"mailed {len(self.orders)} orders to {address}"

    def print_report(self):
        return f"{len(self.orders)} orders, total {self.total()}"

    def apply_tax(self, rate):
        for o in self.orders:
            o["amount"] += o["amount"] * rate // 100
