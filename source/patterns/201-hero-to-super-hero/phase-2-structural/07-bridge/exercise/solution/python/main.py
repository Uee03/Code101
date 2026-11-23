from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def deliver(self, text: str) -> None:
        ...


class EmailChannel(Channel):
    def deliver(self, text: str) -> None:
        print(f"Email: {text}")


class PushChannel(Channel):
    def deliver(self, text: str) -> None:
        print(f"Push: {text}")


class Message:
    def __init__(self, channel: Channel, body: str) -> None:
        self._channel = channel
        self._body = body

    def send(self) -> None:
        self._channel.deliver(self._body)


class ReminderMessage(Message):
    def send(self) -> None:
        self._channel.deliver(f"Reminder: {self._body}")


Message(EmailChannel(), "Hello").send()
ReminderMessage(PushChannel(), "Pay rent").send()
ReminderMessage(EmailChannel(), "Pay rent").send()
