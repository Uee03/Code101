from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def deliver(self, text: str) -> None:
        ...


class EmailChannel(Channel):
    def deliver(self, text: str) -> None:
        print(f"Email: {text}")


class Message:
    def __init__(self, channel: Channel, body: str) -> None:
        self._channel = channel
        self._body = body

    def send(self) -> None:
        self._channel.deliver(self._body)


# TODO 1: write PushChannel(Channel) whose deliver prints "Push: " followed by the text.
# TODO 2: write ReminderMessage(Message) whose send delivers "Reminder: " followed by the body.

Message(EmailChannel(), "Hello").send()
# TODO 3: send ReminderMessage(PushChannel(), "Pay rent") and then ReminderMessage(EmailChannel(), "Pay rent")
