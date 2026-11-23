from abc import ABC, abstractmethod


class Notifier(ABC):
    @abstractmethod
    def send_email(self, to, text):
        ...

    @abstractmethod
    def send_sms(self, to, text):
        ...

    @abstractmethod
    def send_push(self, to, text):
        ...


class EmailNotifier(Notifier):
    def send_email(self, to, text):
        return f"Email to {to}: {text}"

    def send_sms(self, to, text):
        return ""

    def send_push(self, to, text):
        return ""


class PhoneNotifier(Notifier):
    def send_email(self, to, text):
        return ""

    def send_sms(self, to, text):
        return f"SMS to {to}: {text}"

    def send_push(self, to, text):
        return f"Push to {to}: {text}"


def notify_shipped(notifier, address):
    return notifier.send_email(address, "Order shipped")
