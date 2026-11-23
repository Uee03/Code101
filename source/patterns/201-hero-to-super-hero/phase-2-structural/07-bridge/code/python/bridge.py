from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def deliver(self, text: str) -> None:
        ...


class EmailChannel(Channel):
    def deliver(self, text: str) -> None:
        print(f"Email: {text}")


class SmsChannel(Channel):
    def deliver(self, text: str) -> None:
        print(f"SMS: {text}")


class Message:
    def __init__(self, channel: Channel, body: str) -> None:
        self._channel = channel
        self._body = body

    def send(self) -> None:
        self._channel.deliver(self._body)


class UrgentMessage(Message):
    def send(self) -> None:
        self._channel.deliver(f"URGENT: {self._body}")


def demo() -> None:
    channels = [EmailChannel(), SmsChannel()]
    for channel in channels:
        Message(channel, "Meeting at 10").send()
        UrgentMessage(channel, "Server down").send()
