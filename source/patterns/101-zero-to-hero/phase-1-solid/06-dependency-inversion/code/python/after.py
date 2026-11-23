from abc import ABC, abstractmethod


class MessageSender(ABC):
    @abstractmethod
    def send(self, to, text):
        ...


class SmtpEmailSender(MessageSender):
    def send(self, to, text):
        print(f"SMTP email to {to}: {text}")


class SmsSender(MessageSender):
    def send(self, to, text):
        print(f"SMS to {to}: {text}")


class FakeSender(MessageSender):
    def __init__(self):
        self.sent = []

    def send(self, to, text):
        self.sent.append((to, text))


class OrderService:
    def __init__(self, sender: MessageSender):
        self.sender = sender

    def place_order(self, customer, item):
        self.sender.send(customer, f"Thanks for ordering {item}")
