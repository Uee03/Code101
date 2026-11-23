from abc import ABC, abstractmethod


class Notifier(ABC):
    @abstractmethod
    def send(self, message: str) -> None:
        ...


class ConsoleNotifier(Notifier):
    def send(self, message: str) -> None:
        print(f"Console: {message}")


class SmsClient:
    def send_sms(self, number: str, text: str) -> None:
        print(f"SMS to {number}: {text}")


class SmsNotifier(Notifier):
    def __init__(self, client: SmsClient, number: str) -> None:
        self._client = client
        self._number = number

    def send(self, message: str) -> None:
        self._client.send_sms(self._number, message)


def finish_build(notifier: Notifier) -> None:
    notifier.send("Build finished")


finish_build(ConsoleNotifier())
finish_build(SmsNotifier(SmsClient(), "+100"))
