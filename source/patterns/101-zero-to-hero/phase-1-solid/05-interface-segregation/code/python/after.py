from abc import ABC, abstractmethod


class EmailSender(ABC):
    @abstractmethod
    def send_email(self, to, text):
        ...


class SmsSender(ABC):
    @abstractmethod
    def send_sms(self, to, text):
        ...


class PushSender(ABC):
    @abstractmethod
    def send_push(self, to, text):
        ...


class EmailNotifier(EmailSender):
    def send_email(self, to, text):
        return f"Email to {to}: {text}"


class PhoneNotifier(SmsSender, PushSender):
    def send_sms(self, to, text):
        return f"SMS to {to}: {text}"

    def send_push(self, to, text):
        return f"Push to {to}: {text}"


def notify_shipped(sender: EmailSender, address):
    return sender.send_email(address, "Order shipped")
