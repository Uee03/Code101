from abc import ABC, abstractmethod


class Notifier(ABC):
    @abstractmethod
    def send(self, message):
        ...


class EmailNotifier(Notifier):
    def send(self, message):
        return f"Email: {message}"


class UrgentEmailNotifier(EmailNotifier):
    def send(self, message):
        return super().send(f"URGENT {message}")


class SmsNotifier(Notifier):
    def send(self, message):
        return f"SMS: {message}"


class UrgentSmsNotifier(SmsNotifier):
    def send(self, message):
        return super().send(f"URGENT {message}")
