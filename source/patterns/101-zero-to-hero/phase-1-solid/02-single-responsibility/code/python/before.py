class Invoice:
    def __init__(self, number, customer_email, items):
        self.number = number
        self.customer_email = customer_email
        self.items = items

    def total_cents(self):
        total = 0
        for _, price, qty in self.items:
            total += price * qty
        return total

    def to_text(self):
        lines = [f"Invoice {self.number}"]
        for name, _, qty in self.items:
            lines.append(f"{name} x{qty}")
        lines.append(f"Total cents: {self.total_cents()}")
        return "\n".join(lines)

    def save(self, database):
        database.append(self.to_text())

    def send_email(self):
        print(f"Email to {self.customer_email}: invoice {self.number}")
