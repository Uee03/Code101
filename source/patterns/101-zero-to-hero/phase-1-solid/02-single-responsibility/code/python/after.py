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


class InvoiceTextFormatter:
    def format(self, invoice):
        lines = [f"Invoice {invoice.number}"]
        for name, _, qty in invoice.items:
            lines.append(f"{name} x{qty}")
        lines.append(f"Total cents: {invoice.total_cents()}")
        return "\n".join(lines)


class InvoiceStore:
    def __init__(self):
        self.saved = []

    def save(self, invoice):
        self.saved.append(invoice)

    def count(self):
        return len(self.saved)


class EmailSender:
    def send_invoice(self, invoice):
        print(f"Email to {invoice.customer_email}: invoice {invoice.number}")
