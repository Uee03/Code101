class SmtpEmailSender:
    def send(self, to, text):
        print(f"SMTP email to {to}: {text}")


class OrderService:
    def __init__(self):
        self.sender = SmtpEmailSender()

    def place_order(self, customer, item):
        self.sender.send(customer, f"Thanks for ordering {item}")
