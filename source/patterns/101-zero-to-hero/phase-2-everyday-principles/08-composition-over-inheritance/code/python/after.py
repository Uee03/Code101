from abc import ABC, abstractmethod


class Channel(ABC):
    @abstractmethod
    def deliver(self, text):
        ...


class EmailChannel(Channel):
    def deliver(self, text):
        return f"Email: {text}"


class SmsChannel(Channel):
    def deliver(self, text):
        return f"SMS: {text}"


class SlackChannel(Channel):
    def deliver(self, text):
        return f"Slack: {text}"


class Tone(ABC):
    @abstractmethod
    def decorate(self, message):
        ...


class PlainTone(Tone):
    def decorate(self, message):
        return message


class UrgentTone(Tone):
    def decorate(self, message):
        return f"URGENT {message}"


class Notifier:
    def __init__(self, channel: Channel, tone: Tone):
        self.channel = channel
        self.tone = tone

    def send(self, message):
        return self.channel.deliver(self.tone.decorate(message))
