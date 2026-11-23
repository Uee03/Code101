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


# TODO 1: write SmsNotifier(Notifier). Its __init__ receives an SmsClient and a phone number.
#         Its send(message) calls send_sms(number, message) on the client.


def finish_build(notifier: Notifier) -> None:
    notifier.send("Build finished")


finish_build(ConsoleNotifier())
# TODO 2: call finish_build with SmsNotifier(SmsClient(), "+100")
